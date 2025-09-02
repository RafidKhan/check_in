import 'package:check_in/utils/google_auth_service.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            GoogleAuthService.signOut();
          },
          child: Text("Sign Out"),
        ),
      ),
    );
  }
}
