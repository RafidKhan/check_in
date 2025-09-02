import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class HomeState {
  final GeoPoint? selectedCheckInPoint;
  final GeoPoint? geoFenceCenter;
  final MapController? mapController;
  final double geoFenceRadius;
  final GeoPoint? currentLocation;
  final bool isTracking;

  const HomeState({
    this.selectedCheckInPoint,
    this.geoFenceCenter,
    this.mapController,
    this.geoFenceRadius = 0,
    this.currentLocation,
    this.isTracking = false,
  });

  HomeState copyWith({
    GeoPoint? selectedCheckInPoint,
    GeoPoint? geoFenceCenter,
    MapController? mapController,
    double? geoFenceRadius,
    GeoPoint? currentLocation,
    bool? isTracking,
  }) {
    return HomeState(
      selectedCheckInPoint: selectedCheckInPoint ?? this.selectedCheckInPoint,
      geoFenceCenter: geoFenceCenter ?? this.geoFenceCenter,
      mapController: mapController ?? this.mapController,
      geoFenceRadius: geoFenceRadius ?? this.geoFenceRadius,
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
    );
  }
}