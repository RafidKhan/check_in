import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../../model/road_info.dart';

class HomeState {
  final GeoPoint? selectedCheckInPoint;
  final GeoPoint? geoFenceCenter;
  final MapController? mapController;
  final RoadInfoModel? roadInfo;
  final double geoFenceRadius;

  const HomeState({
    this.selectedCheckInPoint,
    this.geoFenceCenter,
    this.mapController,
    this.roadInfo,
    this.geoFenceRadius=0,
  });

  HomeState copyWith({
    GeoPoint? selectedCheckInPoint,
    GeoPoint? geoFenceCenter,
    MapController? mapController,
    RoadInfoModel? roadInfo,
    double? geoFenceRadius,
  }) {
    return HomeState(
      selectedCheckInPoint: selectedCheckInPoint ?? this.selectedCheckInPoint,
      geoFenceCenter: geoFenceCenter ?? this.geoFenceCenter,
      mapController: mapController ?? this.mapController,
      roadInfo: roadInfo ?? this.roadInfo,
      geoFenceRadius: geoFenceRadius ?? this.geoFenceRadius,
    );
  }
}
