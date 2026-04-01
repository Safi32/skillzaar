import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class LocationSettingsDialog extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const LocationSettingsDialog({super.key, required this.onOpenSettings});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.location_off, color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          Text(
            l10n.locationDisabled,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.locationPermanentlyDenied,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(l10n.goToSettings),
          Text(l10n.tapPrivacy),
          Text(l10n.tapLocationServices),
          Text(l10n.enableForApp),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onOpenSettings();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            l10n.openSettings,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
