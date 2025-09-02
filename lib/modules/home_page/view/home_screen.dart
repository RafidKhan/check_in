import 'package:check_in/utils/extensions.dart';
import 'package:check_in/utils/google_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    super.initState();
    final controller = ref.read(homeController.notifier);
    Future(() {
      controller.initializeUser(context).then((value) {
        controller.initMap(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final state = ref.watch(homeController);
    final controller = ref.read(homeController.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipOval(
            child: Image.network(
              user?.photoURL ?? "",
              errorBuilder: (context, error, _) => const Icon(Icons.person),
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
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          const HomeMapView(),

          // Tracking Status Indicator (Top Right)
          if (state.isTracking)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Geofence Status Indicator (Top Left)
          if (state.geoFenceCenter != null && state.currentLocation != null)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      state.currentLocation != null &&
                          controller.isInsideGeofence(state.currentLocation!)
                      ? Colors.green.withOpacity(0.9)
                      : Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.currentLocation != null &&
                              controller.isInsideGeofence(
                                state.currentLocation!,
                              )
                          ? Icons.check_circle
                          : Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.currentLocation != null &&
                              controller.isInsideGeofence(
                                state.currentLocation!,
                              )
                          ? 'Inside Geofence'
                          : 'Outside Geofence',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Check In Button with GeoFence info
          if (state.geoFenceRadius != 0 && state.geoFenceCenter != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Geofence Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Radius: ${state.geoFenceRadius.toStringAsFixed(2)} meters',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Center: ${state.geoFenceCenter!.latitude.toStringAsFixed(6)}, '
                          '${state.geoFenceCenter!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (state.currentLocation != null &&
                      controller.isInsideGeofence(state.currentLocation!)) ...[
                    if (state.selectedCheckInPoint == null) ...[
                      ElevatedButton(
                        onPressed: () {
                          controller.checkIn();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Check In",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ] else ...[
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (state.checkOutTime == null) ...[
                            ElevatedButton(
                              onPressed: () {
                                controller.checkOut();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                "Check Out",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],

                          if (state.checkInTime != null) ...[
                            Text(
                              "Check In: ${DateFormat(" hh:mm a").format(state.checkInTime!)}",
                            ),
                          ],

                          if (state.checkOutTime != null) ...[
                            Text(
                              "Check Out: ${DateFormat("hh:mm a").format(state.checkOutTime!)}",
                            ),
                          ],
                          if (state.checkInTime != null &&
                              state.checkOutTime != null) ...[
                            Text(
                              state.checkInTime!.workDuration(
                                state.checkOutTime!,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
