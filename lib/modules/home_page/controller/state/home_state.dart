import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import '../../model/road_info.dart';

class HomeState {
  final GeoPoint? selectedCheckInPoint;
  final MapController? mapController;
  final RoadInfoModel? roadInfo;

  const HomeState({
    this.selectedCheckInPoint,
    this.mapController,
    this.roadInfo,
  });

  HomeState copyWith({
    GeoPoint? selectedCheckInPoint,
    MapController? mapController,
    RoadInfoModel? roadInfo,
  }) {
    return HomeState(
      selectedCheckInPoint: selectedCheckInPoint ?? this.selectedCheckInPoint,
      mapController: mapController ?? this.mapController,
      roadInfo: roadInfo ?? this.roadInfo,
    );
  }

  HomeState removeCheckInPoint() {
    return HomeState(
      selectedCheckInPoint: null,
      mapController: mapController,
      roadInfo: roadInfo,
    );
  }
}
