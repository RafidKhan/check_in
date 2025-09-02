import 'dart:async';
import 'dart:math';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import 'package:check_in/modules/home_page/model/user_model.dart';
import 'package:check_in/modules/home_page/view/components/geofence_required_dialog.dart';
import 'package:check_in/modules/home_page/view/components/radius_input_bottom_sheet.dart';
import 'package:check_in/utils/enum.dart';
import 'package:check_in/utils/extensions.dart';
import 'package:check_in/utils/firebase_firestore_services/geofence_service.dart';
import 'package:check_in/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:permission_handler/permission_handler.dart';

import '../../../utils/firebase_firestore_services/geofence_converter.dart';
import '../../../utils/firebase_firestore_services/user_service.dart';
import '../model/geofence_model.dart';
import '../view/components/geofence_required_dialog_for_user.dart';
import '../view/components/location_permission_required.dart';
import 'state/home_state.dart';

final homeController =
    StateNotifierProvider.autoDispose<HomeController, HomeState>(
      (ref) => HomeController(),
    );

class HomeController extends StateNotifier<HomeState> {
  HomeController() : super(const HomeState());

  final Location location = Location();
  final geofenceService = GeoFenceService();
  final userService = UserService();
  StreamSubscription<LocationData>? _locationSubscription;
  MarkerIcon? _currentLocationMarker;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> initMap(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    await requestLocationPermission(
      onSuccess: () async {
        await setMapController(context);
      },
      onError: (error) async {
        Navigation.pop();
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const LocationPermissionDialog(),
        );
      },
    );
  }

  Future<void> setMapController(BuildContext context) async {
    final currentLocation = await location.getLocation();
    final initialPosition = GeoPoint(
      latitude: currentLocation.latitude ?? 0,
      longitude: currentLocation.longitude ?? 0,
    );

    final mapController = MapController(initPosition: initialPosition);

    state = state.copyWith(mapController: mapController);
    Navigator.pop(context);
    await _fetchGeoFenceData();

    if (state.geoFenceCenter == null && state.geoFenceRadius == 0) {
      await showDialog(
        context: context,
        builder: (context) {
          return state.userType == UserType.Admin
              ? const GeoFenceRequiredDialog()
              : const GeoFenceRequiredDialogForUser();
        },
      );
    }

    if (state.userType == UserType.Admin) {
      if (state.geoFenceCenter == null && state.geoFenceRadius == 0) {
        state.mapController?.listenerMapSingleTapping.addListener(() async {
          final tappedPoint =
              state.mapController?.listenerMapSingleTapping.value;
          if (tappedPoint != null) {
            inputGeoFenceRadius(tappedPoint);
          }
        });
      } else {
        await _drawGeoFenceMarker();
        _startLocationTracking();
      }
    } else {
      await _drawGeoFenceMarker();
      _startLocationTracking();
    }
  }

  Future<void> requestLocationPermission({
    required Function() onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      var status = await Permission.location.status;

      if (status.isGranted) {
        onSuccess();
        return;
      }

      if (status.isDenied || status.isRestricted || status.isLimited) {
        status = await Permission.location.request();
        if (status.isGranted) {
          onSuccess();
          return;
        } else if (status.isPermanentlyDenied) {
          onError(
            "Location permission permanently denied. Please enable it from settings.",
          );
          await openAppSettings();
          return;
        }
      }

      onError("Location permission denied.");
    } catch (e) {
      onError("Error requesting location permission");
    }
  }

  Future<void> checkIn() async {
    final context = Navigation.globalKey.currentContext!;
    if (state.selectedCheckInPoint != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already checked in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await requestLocationPermission(
      onSuccess: () async {
        try {
          final currentLocation = await location.getLocation();
          final point = GeoPoint(
            latitude: currentLocation.latitude ?? 0,
            longitude: currentLocation.longitude ?? 0,
          );

          Navigator.pop(context);

          if (state.selectedCheckInPoint == null) {
            if (state.geoFenceCenter == null) {
              _showGeofenceRequiredDialog(point);
              return;
            }

            if (isInsideGeofence(point)) {
              state = state.copyWith(
                selectedCheckInPoint: point,
                checkInTime: DateTime.now(),
              );
              await state.mapController?.addMarker(
                point,
                markerIcon: const MarkerIcon(
                  icon: Icon(Icons.navigation, color: Colors.green, size: 48),
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Check-in successful! You are inside the geofence.',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Check-in failed! You are outside the geofence.',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You have already checked in'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error getting location: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      onError: (errorMessage) {
        Navigator.pop(context);
        ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      },
    );
  }

  void _showGeofenceRequiredDialog(GeoPoint point) {
    final context = Navigation.globalKey.currentContext!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fence, color: Colors.blue),
            SizedBox(width: 10),
            Text('Geofence Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to create a geofence before you can check in.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'A geofence defines the area where check-ins are allowed.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              inputGeoFenceRadius(point);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Geofence'),
          ),
        ],
      ),
    );
  }

  Future<void> inputGeoFenceRadius(GeoPoint point) async {
    if (state.geoFenceCenter == null) {
      await showDialog(
        context: Navigation.globalKey.currentContext!,
        builder: (context) => const RadiusInputBottomSheet(),
      ).then((radius) async {
        if (radius != null) {
          await _createGeofence(point, radius);
        }
      });
    } else {
      ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Geofence set already'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createGeofence(GeoPoint center, double radiusMeters) async {
    await geofenceService.createOrUpdateGeoFence(center, radiusMeters);

    await _fetchGeoFenceData();

    await _drawGeoFenceMarker();

    // Start live location tracking after creating geofence
    _startLocationTracking();

    ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('Geofence created with $radiusMeters meters radius'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _drawGeoFenceMarker() async {
    print("STEP:: 1");
    if (state.geoFenceCenter != null && state.geoFenceRadius != 0) {
      print("STEP:: 2");
      final circleZone = CircleOSM(
        centerPoint: state.geoFenceCenter!,
        radius: state.geoFenceRadius,
        key:
            'Geofence_${state.geoFenceCenter!.latitude}_${state.geoFenceCenter!.longitude}',
        color: Colors.blue.withOpacity(0.3),
        strokeWidth: 2.0,
      );

      await state.mapController?.drawCircle(circleZone);

      await state.mapController?.addMarker(
        state.geoFenceCenter!,
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.fence, color: Colors.blue, size: 48),
        ),
      );
      print("STEP:: 3");
    } else {
      print("STEP:: 4");
    }
  }

  void _startLocationTracking() async {
    if (state.isTracking) return;

    _currentLocationMarker = const MarkerIcon(
      icon: Icon(Icons.navigation, color: Colors.white, size: 24),
    );

    state = state.copyWith(isTracking: true);

    _locationSubscription = location.onLocationChanged.listen(
      (LocationData locationData) async {
        if (locationData.latitude != null && locationData.longitude != null) {
          final newLocation = GeoPoint(
            latitude: locationData.latitude!,
            longitude: locationData.longitude!,
          );

          state = state.copyWith(currentLocation: newLocation);
          await _updateCurrentLocationMarker(newLocation);
          _checkGeofenceStatus(newLocation);
        }
      },
      onError: (error) {
        print('Location tracking error: $error');
        ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Location tracking error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _updateCurrentLocationMarker(GeoPoint newLocation) async {
    if (state.currentLocation != null) {
      await state.mapController?.removeMarker(state.currentLocation!);
    }

    await state.mapController?.addMarker(
      newLocation,
      markerIcon: _currentLocationMarker!,
    );
  }

  void _checkGeofenceStatus(GeoPoint currentLocation) {
    final isInside = isInsideGeofence(currentLocation);

    if (isInside) {
      _updateMarkerColor(Colors.green);
    } else {
      _updateMarkerColor(Colors.red);
      //auto check out if left from location
      if (state.selectedCheckInPoint != null && state.checkInTime != null) {
        //condition to check if checked in. If not, allow to check in first.
        checkOut();
      }
    }
  }

  Future<void> _updateMarkerColor(Color color) async {
    if (state.currentLocation != null && _currentLocationMarker != null) {
      _currentLocationMarker = const MarkerIcon(
        icon: Icon(Icons.navigation, color: Colors.white, size: 24),
      );

      await state.mapController?.removeMarker(state.currentLocation!);
      await state.mapController?.addMarker(
        state.currentLocation!,
        markerIcon: _currentLocationMarker!,
      );
    }
  }

  bool isInsideGeofence(GeoPoint point) {
    if (state.geoFenceCenter == null || state.geoFenceRadius == 0) {
      return false;
    }

    final center = state.geoFenceCenter!;
    final radius = state.geoFenceRadius;

    final distance = _calculateDistance(
      point.latitude,
      point.longitude,
      center.latitude,
      center.longitude,
    );

    return distance <= radius;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  void checkOut() {
    // Cancel location tracking subscription
    _locationSubscription?.cancel();

    // Remove check-in marker if exists
    if (state.selectedCheckInPoint != null) {
      state.mapController?.removeMarker(state.selectedCheckInPoint!);
    }

    // Remove current location marker if exists
    if (state.currentLocation != null) {
      state.mapController?.removeMarker(state.currentLocation!);
    }

    // Update state to stop tracking and record checkout time
    state = state.copyWith(
      isTracking: false,
      checkOutTime: DateTime.now(),
      selectedCheckInPoint: null, // Reset check-in point
      currentLocation: null, // Clear current location
    );

    // Show checkout confirmation
    ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Checked out successfully'),
        backgroundColor: Colors.blue,
      ),
    );

    print('User checked out at ${DateTime.now()}');
  }

  Future<void> initializeUser(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final user = await userService.checkAndCreateUser();
      state = state.copyWith(
        userModel: UserModel.fromJson(user.toJson()),
        userType: user.userType.getUserType,
      );
      Navigation.pop();
    } catch (e) {
      print('Failed to initialize user: $e');
      Navigation.pop();
    }
  }

  Future<void> _fetchGeoFenceData() async {
    try {
      final GeoFenceModel? geoFenceData = await geofenceService
          .getActiveGeoFence();

      if (geoFenceData != null) {
        // Convert Firestore GeoPoint to OSM GeoPoint for the map
        final osm.GeoPoint osmCenter = GeoPointConverter.toOsmGeoPoint(
          geoFenceData.center,
        );

        state = state.copyWith(
          geoFenceCenter: osmCenter,
          geoFenceRadius: geoFenceData.radius,
        );
      }
    } catch (e) {
      print('Error fetching geofence data: $e');
    }
  }
}
