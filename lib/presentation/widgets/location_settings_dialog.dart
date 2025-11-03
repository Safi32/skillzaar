import 'package:flutter/material.dart';
class LocationSettingsDialog extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const LocationSettingsDialog({super.key, required this.onOpenSettings});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.location_off, color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          const Text('Location Disabled', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location access is permanently denied. To enable location features:', style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          Text('1. Go to Settings'),
          Text('2. Tap Privacy & Security'),
          Text('3. Tap Location Services'),
          Text('4. Enable for this app'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOpenSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
