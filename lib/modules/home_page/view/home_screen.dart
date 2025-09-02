import 'package:check_in/utils/google_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controller/home_controller.dart';
import 'components/home_map_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    final controller = ref.read(homeController.notifier);
    Future(() {
      controller.initMap(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image.network(
              user?.photoURL ?? "",
              errorBuilder: (context, error, _) => const Icon(Icons.error),
            ),
          ),
        ),
        title: Text(
          user?.displayName ?? "Welcome",
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              GoogleAuthService.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        backgroundColor: Colors.lightBlue,
      ),
      body: const HomeMapView(),
    );
  }
}
