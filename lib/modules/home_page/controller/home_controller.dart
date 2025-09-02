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

import '../../../utils/firebase_firestore_services/check_in_service.dart';
import '../../../utils/firebase_firestore_services/geofence_converter.dart';
import '../../../utils/firebase_firestore_services/user_service.dart';
import '../model/custom_geo_point.dart';
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
  final checkInService = CheckInService();
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
            _inputGeoFenceRadius(tappedPoint);
          }
        });
      } else {
        await _checkForDataInFireStore();
      }
    } else {
      await _checkForDataInFireStore();
    }
  }

  Future<void> _checkForDataInFireStore() async {
    final currentLocation = await location.getLocation();
    state = state.copyWith(
      currentLocation: CustomGeoPoint(
        lat: currentLocation.latitude ?? 0,
        lon: currentLocation.longitude ?? 0,
      ),
    );

    await _drawGeoFenceMarker();
    await _getTodaysCheckIn();
    if (state.checkInTime == null && state.selectedCheckInPoint == null) {
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
              return;
            }

            if (isInsideGeofence(point)) {
              await checkInService.checkIn(point);

              await _getTodaysCheckIn();
              // state = state.copyWith(
              //   selectedCheckInPoint: point,
              //   checkInTime: DateTime.now(),
              // );
              // await state.mapController?.addMarker(
              //   point,
              //   markerIcon: const MarkerIcon(
              //     icon: Icon(Icons.navigation, color: Colors.green, size: 48),
              //   ),
              // );

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

  Future<void> _inputGeoFenceRadius(GeoPoint point) async {
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
    if (state.geoFenceCenter != null && state.geoFenceRadius != 0) {
      final circleZone = CircleOSM(
        centerPoint: osm.GeoPoint(
          latitude: state.geoFenceCenter!.lat,
          longitude: state.geoFenceCenter!.lon,
        ),
        radius: state.geoFenceRadius,
        key:
            'Geofence_${state.geoFenceCenter!.lat}_${state.geoFenceCenter!.lon}',
        color: Colors.blue.withOpacity(0.3),
        strokeWidth: 2.0,
      );

      await state.mapController?.drawCircle(circleZone);

      await state.mapController?.addMarker(
        osm.GeoPoint(
          latitude: state.geoFenceCenter!.lat,
          longitude: state.geoFenceCenter!.lon,
        ),
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.fence, color: Colors.blue, size: 48),
        ),
      );
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

          state = state.copyWith(
            currentLocation: CustomGeoPoint(
              lat: newLocation.latitude,
              lon: newLocation.longitude,
            ),
          );
          await _updateCurrentLocationMarker(newLocation);
          await _checkGeofenceStatus(newLocation);
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
      await state.mapController?.removeMarker(
        osm.GeoPoint(
          latitude: state.currentLocation!.lat,
          longitude: state.currentLocation!.lon,
        ),
      );
    }

    await state.mapController?.addMarker(
      newLocation,
      markerIcon: _currentLocationMarker!,
    );
  }

  Future<void> _checkGeofenceStatus(GeoPoint currentLocation) async {
    final isInside = isInsideGeofence(currentLocation);

    if (isInside) {
      _updateMarkerColor(Colors.green);
    } else {
      _updateMarkerColor(Colors.red);
      //auto check out if left from location
      if (state.selectedCheckInPoint != null && state.checkInTime != null) {
        //condition to check if checked in. If not, allow to check in first.
        await checkOut();
      }
    }
  }

  Future<void> _updateMarkerColor(Color color) async {
    if (state.currentLocation != null && _currentLocationMarker != null) {
      _currentLocationMarker = const MarkerIcon(
        icon: Icon(Icons.navigation, color: Colors.white, size: 24),
      );

      await state.mapController?.removeMarker(
        osm.GeoPoint(
          latitude: state.currentLocation!.lat,
          longitude: state.currentLocation!.lon,
        ),
      );
      await state.mapController?.addMarker(
        osm.GeoPoint(
          latitude: state.currentLocation!.lat,
          longitude: state.currentLocation!.lon,
        ),
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
      center.lat,
      center.lon,
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

  Future<void> checkOut() async {
    try {
      // 1. Save checkout to Firestore
      await checkInService.checkOut();

      // 2. Fetch check out data
      await _getTodaysCheckIn();

      // 3. Remove check-in marker if exists
      if (state.selectedCheckInPoint != null) {
        await state.mapController?.removeMarker(
          osm.GeoPoint(
            latitude: state.selectedCheckInPoint!.lat,
            longitude: state.selectedCheckInPoint!.lon,
          ),
        );
      }

      // 4. Remove current location marker if exists
      if (state.currentLocation != null) {
        await state.mapController?.removeMarker(
          osm.GeoPoint(
            latitude: state.currentLocation!.lat,
            longitude: state.currentLocation!.lon,
          ),
        );
      }

      state = state.copyWith(isTracking: false);

      ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Checked out successfully'),
          backgroundColor: Colors.blue,
        ),
      );

      print('✅ User checked out at ${DateTime.now()}');
    } catch (e) {
      print('❌ Error during checkout: $e');
      ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Checkout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          geoFenceCenter: CustomGeoPoint(
            lat: osmCenter.latitude,
            lon: osmCenter.longitude,
          ),
          geoFenceRadius: geoFenceData.radius,
        );
      }
    } catch (e) {
      print('Error fetching geofence data: $e');
    }
  }

  Future<void> _getTodaysCheckIn() async {
    try {
      final result = await checkInService.getTodaysCheckIn();

      // Debug the GeoPoint types
      if (result != null) {
        state = state.copyWith(
          selectedCheckInPoint: CustomGeoPoint(
            lat: result.checkInPoint.latitude,
            lon: result.checkInPoint.longitude,
          ),
          checkInTime: result.checkInTime,
          checkOutTime: result.checkOutTime,
        );

        print("TIME IS:${state.checkInTime}");

        await state.mapController?.addMarker(
          result.checkInPoint,
          markerIcon: const MarkerIcon(
            icon: Icon(Icons.navigation, color: Colors.green, size: 48),
          ),
        );
      }
    } catch (e) {
      print('Error getting today\'s check-in: $e');
    }
  }
}
