import 'package:check_in/utils/navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:permission_handler/permission_handler.dart';

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
        await setMapController(
          context,
          fallbackLocation: GeoPoint(latitude: 23.8103, longitude: 90.4125),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Default location set because of : $error'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> setMapController(
    BuildContext context, {
    GeoPoint? fallbackLocation,
  }) async {
    GeoPoint initialPosition;

    if (fallbackLocation != null) {
      initialPosition = fallbackLocation;
    } else {
      final currentLocation = await location.getLocation();
      initialPosition = GeoPoint(
        latitude: currentLocation.latitude ?? 0,
        longitude: currentLocation.longitude ?? 0,
      );
    }

    final mapController = MapController(initPosition: initialPosition);
    state = state.copyWith(mapController: mapController);
    Navigator.pop(context);

    state.mapController?.listenerMapSingleTapping.addListener(() async {
      final tappedPoint = state.mapController?.listenerMapSingleTapping.value;
      if (tappedPoint != null) {
        checkForGeoFence(tappedPoint);
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
      state = state.copyWith(selectedCheckInPoint: point);
      await state.mapController?.addMarker(
        point,
        markerIcon: const MarkerIcon(
          icon: Icon(Icons.navigation, color: Colors.green, size: 48),
        ),
      );
    } else {
      ScaffoldMessenger.of(Navigation.globalKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('You have already checked in'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void checkForGeoFence(GeoPoint point) {
    if (state.geoFenceCenter == null) {
      final context = Navigation.globalKey.currentContext!;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create Geofence first to check in'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      setCheckInPoint(point);
    }
  }
}
