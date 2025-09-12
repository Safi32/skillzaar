import 'package:flutter/material.dart';
class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onTurnOnLocation;
  const LocationPermissionDialog({super.key, required this.onTurnOnLocation});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.location_on, color: Colors.green, size: 28),
          const SizedBox(width: 8),
          const Text('Location Access', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('To help you post jobs with accurate locations, we need access to your location.', style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          Text('This will help:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 8),
          Text('• Post jobs with precise locations'),
          Text('• Find nearby skilled workers'),
          Text('• Improve job matching accuracy'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onTurnOnLocation();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Turn On Location', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
