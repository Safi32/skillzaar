import 'package:flutter/material.dart';
class StatusIndicator extends StatelessWidget {
  final String? status;
  const StatusIndicator({Key? key, required this.status}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final isAccepted = status == 'accepted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isAccepted ? Colors.orange : Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAccepted ? Icons.schedule : Icons.work, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            isAccepted ? 'Request Accepted - Ready to Start' : 'Work In Progress',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
