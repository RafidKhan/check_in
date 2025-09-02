import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

class GeoFenceModel {
  final String id;
  final firestore.GeoPoint center; // Explicitly use firestore GeoPoint
  final double radius;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GeoFenceModel({
    required this.id,
    required this.center,
    required this.radius,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'center': center,
      'radius': radius,
      'createdBy': createdBy,
      'createdAt': firestore.Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? firestore.Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create from Firestore DocumentSnapshot
  factory GeoFenceModel.fromFirestore(firestore.DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GeoFenceModel(
      id: doc.id,
      center: data['center'] as firestore.GeoPoint,
      radius: (data['radius'] as num).toDouble(),
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as firestore.Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as firestore.Timestamp).toDate()
          : null,
    );
  }

  // Copy with method for updates
  GeoFenceModel copyWith({
    String? id,
    firestore.GeoPoint? center,
    double? radius,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeoFenceModel(
      id: id ?? this.id,
      center: center ?? this.center,
      radius: radius ?? this.radius,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}