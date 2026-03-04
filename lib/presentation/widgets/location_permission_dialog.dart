import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class LocationPermissionDialog extends StatelessWidget {
  final VoidCallback onTurnOnLocation;
  const LocationPermissionDialog({super.key, required this.onTurnOnLocation});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.green, size: 28),
          const SizedBox(width: 8),
          Text(
            l10n.locationAccess,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.locationAccessDesc, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Text(
            l10n.thisWillHelp,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text('• ${l10n.preciseLocations}'),
          Text('• ${l10n.nearbyWorkers}'),
          Text('• ${l10n.matchingAccuracy}'),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onTurnOnLocation();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            l10n.turnOnLocation,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
