import 'dart:math';

import 'package:check_in/modules/home_page/view/components/geofence_required_dialog.dart';
import 'package:check_in/modules/home_page/view/components/radius_input_bottom_sheet.dart';
import 'package:check_in/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:permission_handler/permission_handler.dart';

import '../view/components/location_permission_required.dart';
import 'state/home_state.dart';

final homeController =
    StateNotifierProvider.autoDispose<HomeController, HomeState>(
      (ref) => HomeController(),
    );

class HomeController extends StateNotifier<HomeState> {
  HomeController() : super(const HomeState());

  final Location location = Location();

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
        // await setMapController(
        //   context,
        //   fallbackLocation: GeoPoint(latitude: 23.8041, longitude: 90.4152),
        // );
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
    if (state.geoFenceCenter == null && state.geoFenceRadius == 0) {
      await showDialog(
        context: context,
        builder: (context) {
          return const GeoFenceRequiredDialog();
        },
      );
    }

    state.mapController?.listenerMapSingleTapping.addListener(() async {
      final tappedPoint = state.mapController?.listenerMapSingleTapping.value;
      if (tappedPoint != null) {
        checkForGeoFenceTap(tappedPoint);
      }
    });
  }

  Future<void> requestLocationPermission({
    required Function() onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      var status = await Permission.location.status;

      if (status.isGranted) {
        // Permission already granted
        onSuccess();
        return;
      }

      if (status.isDenied || status.isRestricted || status.isLimited) {
        // Request permission
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

  Future<void> setCheckInPoint(GeoPoint point) async {
    if (state.selectedCheckInPoint == null) {
      // Check if point is inside any geofence
      if (_isInsideGeofence(point)) {
        state = state.copyWith(selectedCheckInPoint: point);
        await state.mapController?.addMarker(
          point,
          markerIcon: const MarkerIcon(
            icon: Icon(Icons.navigation, color: Colors.green, size: 48),
          ),
        );

        ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Check-in successful! You are inside the geofence.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
          const SnackBar(
            content: Text('Check-in failed! You are outside the geofence.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('You have already checked in'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> inputGeoFenceRadius(GeoPoint point) async {
    if (state.geoFenceCenter == null) {
      await showDialog(
        context: Navigation.globalKey.currentContext!,
        builder: (context) => const RadiusInputBottomSheet(),
      ).then((radius) async {
        if (radius != null) {
          // Create geofence
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
    try {
      // Create circle zone for geofence
      final circleZone = CircleOSM(
        centerPoint: center,
        radius: radiusMeters,
        key: 'Geofence_${center.latitude}_${center.longitude}',
        color: Colors.blue.withOpacity(0.3),
        strokeWidth: 2.0,
      );

      // Add to map
      await state.mapController?.drawCircle(circleZone);

      // Store geofence data
      state = state.copyWith(
        geoFenceCenter: center,
        geoFenceRadius: radiusMeters,
      );

      // Add marker for geofence center
      await state.mapController?.addMarker(
        center,
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.fence, color: Colors.blue, size: 48),
        ),
      );

      ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Geofence created with $radiusMeters meters radius'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error creating geofence: $e');
      ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Failed to create geofence'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isInsideGeofence(GeoPoint point) {
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
    const earthRadius = 6371000; // meters

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

  void checkForGeoFenceTap(GeoPoint point) {
    if (state.geoFenceCenter == null) {
      inputGeoFenceRadius(point);
    } else {
      setCheckInPoint(point);
    }
  }
}
