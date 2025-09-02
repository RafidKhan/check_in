import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;

class CheckInModel {
  final String id;
  final String userId;
  final osm.GeoPoint checkInPoint;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final bool isCheckedOut;

  CheckInModel({
    required this.id,
    required this.userId,
    required this.checkInPoint,
    required this.checkInTime,
    this.checkOutTime,
    this.isCheckedOut = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'checkInPoint': _convertToFirestoreGeoPoint(checkInPoint),
      'checkInTime': firestore.Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null ? firestore.Timestamp.fromDate(checkOutTime!) : null,
      'isCheckedOut': isCheckedOut,
    };
  }

  // Create from Firestore DocumentSnapshot
  factory CheckInModel.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CheckInModel(
      id: doc.id,
      userId: data['userId'] as String,
      checkInPoint: _convertToOsmGeoPoint(data['checkInPoint'] as firestore.GeoPoint),
      checkInTime: (data['checkInTime'] as firestore.Timestamp).toDate(),
      checkOutTime: data['checkOutTime'] != null
          ? (data['checkOutTime'] as firestore.Timestamp).toDate()
          : null,
      isCheckedOut: data['isCheckedOut'] as bool? ?? false,
    );
  }

  // Helper methods for GeoPoint conversion
  static firestore.GeoPoint _convertToFirestoreGeoPoint(osm.GeoPoint point) {
    return firestore.GeoPoint(point.latitude, point.longitude);
  }

  static osm.GeoPoint _convertToOsmGeoPoint(firestore.GeoPoint point) {
    return osm.GeoPoint(latitude: point.latitude, longitude: point.longitude);
  }

  // Check if this check-in is for today
  bool get isToday {
    final now = DateTime.now();
    return checkInTime.year == now.year &&
        checkInTime.month == now.month &&
        checkInTime.day == now.day;
  }

  // Get duration of check-in
  Duration? get duration {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    }
    return null;
  }

  // Copy with method for updates
  CheckInModel copyWith({
    String? id,
    String? userId,
    osm.GeoPoint? checkInPoint,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool? isCheckedOut,
  }) {
    return CheckInModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInPoint: checkInPoint ?? this.checkInPoint,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      isCheckedOut: isCheckedOut ?? this.isCheckedOut,
    );
  }
}