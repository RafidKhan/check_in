import 'package:check_in/modules/login/view/login_screen.dart';
import 'package:check_in/utils/extensions.dart';
import 'package:check_in/utils/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../utils/connectivity_service.dart';
import '../../home_page/view/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((e) async {
      await NetworkConnection.instance.initialize();
      if (NetworkConnection.instance.isInternet) {
        _checkLoginStatus();
      }
    });
  }

  Future<void> _checkLoginStatus() async {
    // Check if user is logged in with Firebase Auth
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;

    // Navigate based on login status
    if (isLoggedIn) {
      Navigation.pushReplacement(const HomeScreen());
    } else {
      Navigation.pushReplacement(const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: context.width,
        height: context.height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade50,
              ),
              child: const Icon(
                Icons.location_on, // Map Pin
                size: 80,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              "Check In",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Never miss your attendance!",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
