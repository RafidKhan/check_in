import 'package:check_in/modules/home_page/controller/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:check_in/utils/firebase_firestore_services/user_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/check_in_model.dart';
import '../../model/user_model.dart';

class CheckInBottomSheet extends ConsumerStatefulWidget {
  const CheckInBottomSheet({super.key});

  @override
  ConsumerState<CheckInBottomSheet> createState() => _CheckInBottomSheetState();
}

class _CheckInBottomSheetState extends ConsumerState<CheckInBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeController);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Today\'s Check-Ins',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${state.checkIns.length} check-ins',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: state.checkIns.length,
              itemBuilder: (context, index) {
                final checkIn = state.checkIns[index];

                return _CheckInListItem(checkIn: checkIn);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInListItem extends StatefulWidget {
  final CheckInModel checkIn;

  const _CheckInListItem({required this.checkIn});

  @override
  State<_CheckInListItem> createState() => _CheckInListItemState();
}

class _CheckInListItemState extends State<_CheckInListItem> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: UserService().getUserInfo(widget.checkIn.userId),
      builder: (context, data) {
        if (data.connectionState == ConnectionState.done) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: data.data?.photoURL != null
                    ? NetworkImage(data.data?.photoURL ?? "")
                    : null,
                child: data.data?.photoURL == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              title: Text(
                data.data?.displayName ?? 'Unknown User',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check-in: ${_formatTime(widget.checkIn.checkInTime)}'),
                  if (widget.checkIn.checkOutTime != null)
                    Text(
                      'Check-out: ${_formatTime(widget.checkIn.checkOutTime!)}',
                    ),
                  if (widget.checkIn.duration != null)
                    Text(
                      'Duration: ${_formatDuration(widget.checkIn.duration!)}',
                    ),
                  Text(
                    'Status: ${widget.checkIn.isCheckedOut ? 'Checked Out' : 'Active'}',
                  ),
                ],
              ),
              trailing: Icon(
                widget.checkIn.isCheckedOut
                    ? Icons.check_circle
                    : Icons.access_time,
                color: widget.checkIn.isCheckedOut
                    ? Colors.green
                    : Colors.orange,
              ),
              onTap: () {
                // Show detailed view if needed
                _showCheckInDetails(context, widget.checkIn, data.data);
              },
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  void _showCheckInDetails(
    BuildContext context,
    CheckInModel checkIn,
    UserModel? user,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check-in Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user != null) ...[
                _buildDetailRow('User', user.displayName ?? 'Unknown'),
                _buildDetailRow('Email', user.email),
              ],
              _buildDetailRow('Check-in Time', checkIn.checkInTime.toString()),
              if (checkIn.checkOutTime != null)
                _buildDetailRow(
                  'Check-out Time',
                  checkIn.checkOutTime!.toString(),
                ),
              if (checkIn.duration != null)
                _buildDetailRow('Duration', _formatDuration(checkIn.duration!)),
              _buildDetailRow(
                'Location',
                'Lat: ${checkIn.checkInPoint.latitude.toStringAsFixed(6)}, '
                    'Lng: ${checkIn.checkInPoint.longitude.toStringAsFixed(6)}',
              ),
              _buildDetailRow(
                'Status',
                checkIn.isCheckedOut ? 'Checked Out' : 'Active',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
