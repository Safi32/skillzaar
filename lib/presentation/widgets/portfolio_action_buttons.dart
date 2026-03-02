import 'package:flutter/material.dart';
class PortfolioActionButtons extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;
  const PortfolioActionButtons({super.key, required this.onAccept, required this.onReject});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.check),
            label: const Text('Accept Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: onAccept,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.close),
            label: const Text('Reject Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onPressed: onReject,
          ),
        ),
      ],
    );
  }
}
