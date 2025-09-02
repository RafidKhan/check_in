import 'package:check_in/modules/home_page/model/user_model.dart';
import 'package:check_in/utils/enum.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class HomeState {
  final GeoPoint? selectedCheckInPoint;
  final GeoPoint? geoFenceCenter;
  final MapController? mapController;
  final double geoFenceRadius;
  final GeoPoint? currentLocation;
  final bool isTracking;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final UserModel? userModel;
  final UserType userType;

  const HomeState({
    this.selectedCheckInPoint,
    this.geoFenceCenter,
    this.mapController,
    this.geoFenceRadius = 0,
    this.currentLocation,
    this.isTracking = false,
    this.checkInTime,
    this.checkOutTime,
    this.userModel,
    this.userType = UserType.RegularUser,
  });

  HomeState copyWith({
    GeoPoint? selectedCheckInPoint,
    GeoPoint? geoFenceCenter,
    MapController? mapController,
    double? geoFenceRadius,
    GeoPoint? currentLocation,
    bool? isTracking,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    UserModel? userModel,
    UserType? userType,
  }) {
    return HomeState(
      selectedCheckInPoint: selectedCheckInPoint ?? this.selectedCheckInPoint,
      geoFenceCenter: geoFenceCenter ?? this.geoFenceCenter,
      mapController: mapController ?? this.mapController,
      geoFenceRadius: geoFenceRadius ?? this.geoFenceRadius,
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      userModel: userModel ?? this.userModel,
      userType: userType ?? this.userType,
    );
  }
}
