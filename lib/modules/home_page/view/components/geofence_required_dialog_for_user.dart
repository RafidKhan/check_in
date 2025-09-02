import 'package:check_in/utils/navigation.dart';
import 'package:flutter/material.dart';

class GeoFenceRequiredDialogForUser extends StatelessWidget {
  const GeoFenceRequiredDialogForUser({super.key});

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: AlertDialog(
        title: Row(
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
              "No geofence created for check in. Contact with Admin for support",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
