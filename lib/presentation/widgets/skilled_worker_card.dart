import 'package:flutter/material.dart';
class SkilledWorkerCard extends StatelessWidget {
  final Map<String, dynamic>? request;
  const SkilledWorkerCard({Key? key, required this.request}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Skilled Worker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text((request?['skilledWorkerName'] ?? 'Unknown').toString(), style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text((request?['skilledWorkerPhone'] ?? 'N/A').toString(), style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
