import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/skilled_worker_provider.dart';

class LocationStatusWidget extends StatelessWidget {
  const LocationStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SkilledWorkerProvider>(context);

    if (provider.isLocationLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.blue.shade50,
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Getting your location...',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (provider.locationError != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.green.shade50,
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.locationError!,
                style: TextStyle(color: Colors.green.shade700, fontSize: 14),
              ),
            ),
            ElevatedButton(
              onPressed: () => provider.initializeLocationServices(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.currentLatitude != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.green.shade50,
        child: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Location: ${provider.currentAddress}',
                style: TextStyle(color: Colors.green.shade700, fontSize: 14),
              ),
            ),
            IconButton(
              onPressed: () => provider.refreshLocation(),
              icon: Icon(Icons.refresh, color: Colors.green.shade700, size: 20),
              tooltip: 'Refresh location',
            ),
          ],
        ),
      );
    }

    // No location available
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Icon(Icons.location_off, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Location not available. Turn on location services on your device.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
