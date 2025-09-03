import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart' as osm;
import '../../modules/home_page/model/check_in_model.dart';

class CheckInService {
  final firestore.FirebaseFirestore _firestore =
      firestore.FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  firestore.CollectionReference get _checkinsCollection =>
      _firestore.collection('checkins');

  /// Get today's check-in record (completely index-free)
  Future<CheckInModel?> getTodaysCheckIn() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      // Get ALL user's check-ins and filter locally - no index required
      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in querySnapshot.docs) {
        final checkIn = CheckInModel.fromFirestore(doc);
        if (checkIn.isToday) {
          return checkIn;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user has already checked in today
  Future<bool> hasCheckedInToday() async {
    final todaysCheckIn = await getTodaysCheckIn();
    return todaysCheckIn != null;
  }

  /// Create a new check-in record
  Future<CheckInModel> checkIn(osm.GeoPoint checkInPoint) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      // First check if already checked in today using the safe method
      final hasCheckedIn = await hasCheckedInToday();
      if (hasCheckedIn) {
        throw Exception('Already checked in today');
      }

      final checkInModel = CheckInModel(
        id: '',
        userId: currentUser.uid,
        checkInPoint: checkInPoint,
        checkInTime: DateTime.now(),
      );

      final docRef = await _checkinsCollection.add(checkInModel.toJson());
      return checkInModel.copyWith(id: docRef.id);
    } catch (e) {
      print('Error during check-in: $e');
      rethrow;
    }
  }

  /// Check out from today's check-in
  Future<CheckInModel> checkOut() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    try {
      final todaysCheckIn = await getTodaysCheckIn();
      if (todaysCheckIn == null) {
        throw Exception('No check-in found for today');
      }

      if (todaysCheckIn.isCheckedOut) {
        throw Exception('Already checked out today');
      }

      final checkOutTime = DateTime.now();

      await _checkinsCollection.doc(todaysCheckIn.id).update({
        'checkOutTime': firestore.Timestamp.fromDate(checkOutTime),
        'isCheckedOut': true,
      });

      return todaysCheckIn.copyWith(
        checkOutTime: checkOutTime,
        isCheckedOut: true,
      );
    } catch (e) {
      print('Error during check-out: $e');
      rethrow;
    }
  }

  /// Get user's check-in history (last 30 days)
  Future<List<CheckInModel>> getCheckInHistory({int limit = 30}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      // Get all check-ins and filter/sort locally
      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      // Convert to models and sort by date
      final checkIns = querySnapshot.docs
          .map((doc) => CheckInModel.fromFirestore(doc))
          .toList();

      // Sort by date descending and take limit
      checkIns.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      return checkIns.take(limit).toList();
    } catch (e) {
      print('Error getting check-in history: $e');
      return [];
    }
  }

  /// Get current check-in status (checked in but not checked out)
  Future<CheckInModel?> getCurrentCheckIn() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      // Get all user's check-ins and filter locally
      final querySnapshot = await _checkinsCollection
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in querySnapshot.docs) {
        final checkIn = CheckInModel.fromFirestore(doc);
        if (!checkIn.isCheckedOut && checkIn.isToday) {
          return checkIn;
        }
      }
      return null;
    } catch (e) {
      print('Error getting current check-in: $e');
      return null;
    }
  }

  /// Get all check-ins for today (for admin purposes)
  Future<List<CheckInModel>> getTodaysAllCheckIns() async {
    try {
      // Get current date boundaries
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

      // Get all check-ins from today
      final querySnapshot = await _checkinsCollection
          .where(
            'checkInTime',
            isGreaterThanOrEqualTo: firestore.Timestamp.fromDate(startOfDay),
          )
          .where(
            'checkInTime',
            isLessThanOrEqualTo: firestore.Timestamp.fromDate(endOfDay),
          )
          .orderBy('checkInTime', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return CheckInModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      print("EXC: $e");
      return [];
    }
  }
}
