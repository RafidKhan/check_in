import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../../model/road_info.dart';

class HomeState {
  final GeoPoint? selectedCheckInPoint;
  final GeoPoint? geoFenceCenter;
  final MapController? mapController;
  final RoadInfoModel? roadInfo;

  const HomeState({
    this.selectedCheckInPoint,
    this.geoFenceCenter,
    this.mapController,
    this.roadInfo,
  });

  HomeState copyWith({
    GeoPoint? selectedCheckInPoint,
    GeoPoint? geoFenceCenter,
    MapController? mapController,
    RoadInfoModel? roadInfo,
  }) {
    return HomeState(
      selectedCheckInPoint: selectedCheckInPoint ?? this.selectedCheckInPoint,
      geoFenceCenter: geoFenceCenter ?? this.geoFenceCenter,
      mapController: mapController ?? this.mapController,
      roadInfo: roadInfo ?? this.roadInfo,
    );
  }
}
