import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;

class GeoPointConverter {
  // Convert flutter_osm_plugin GeoPoint to cloud_firestore GeoPoint
  static firestore.GeoPoint toFirestoreGeoPoint(osm.GeoPoint osmGeoPoint) {
    return firestore.GeoPoint(osmGeoPoint.latitude, osmGeoPoint.longitude);
  }

  // Convert cloud_firestore GeoPoint to flutter_osm_plugin GeoPoint
  static osm.GeoPoint toOsmGeoPoint(firestore.GeoPoint firestoreGeoPoint) {
    return osm.GeoPoint(
      latitude: firestoreGeoPoint.latitude,
      longitude: firestoreGeoPoint.longitude,
    );
  }

  // Convert cloud_firestore GeoPoint from Firestore document to OSM GeoPoint
  static osm.GeoPoint fromFirestoreToOsm(Map<String, dynamic> data) {
    final geoPointData = data['center'] as firestore.GeoPoint;
    return osm.GeoPoint(
      latitude: geoPointData.latitude,
      longitude: geoPointData.longitude,
    );
  }
}