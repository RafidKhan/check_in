import 'package:check_in/utils/navigation.dart';
import 'package:flutter/material.dart';

class GeoFenceRequiredDialog extends StatelessWidget {
  const GeoFenceRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.fence, color: Colors.blue),
            SizedBox(width: 10),
            Text('Geofence Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You need to create a geofence first before checking in.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'A geofence defines the area where check-ins are allowed.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigation.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create Geofence'),
          ),
        ],
      ),
    );
  }
}
