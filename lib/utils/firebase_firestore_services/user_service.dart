import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../modules/home_page/model/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Check user info, insert if not exists, then fetch
  Future<UserModel> checkAndCreateUser() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user logged in');
    }

    final String userId = currentUser.uid;

    try {
      // 1. Check if user exists
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();

      UserModel user;

      if (userDoc.exists) {
        // 2a. If exists, fetch and return user info
        user = UserModel.fromFirestore(userDoc);
        print('User already exists: ${user.email}');
      } else {
        // 2b. If not exists, insert new user
        user = UserModel(
          uid: userId,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName,
          photoURL: currentUser.photoURL,
          userType: 'User',
          // Default role
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Insert into Firestore
        await _usersCollection.doc(userId).set(user.toJson());
        print('New user created: ${user.email}');
      }

      // 3. Fetch and return the user info (ensures we have latest data)
      final DocumentSnapshot updatedDoc = await _usersCollection
          .doc(userId)
          .get();
      return UserModel.fromFirestore(updatedDoc);
    } catch (e) {
      print('Error in checkAndCreateUser: $e');
      rethrow;
    }
  }

  // Optional: Separate methods if needed later
  Future<UserModel?> getUserInfo(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _usersCollection.doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      rethrow;
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toJson());
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }
}
