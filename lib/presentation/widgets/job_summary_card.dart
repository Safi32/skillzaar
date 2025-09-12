import 'package:flutter/material.dart';
class JobSummaryCard extends StatelessWidget {
  final Map<String, dynamic>? job;
  const JobSummaryCard({Key? key, required this.job}) : super(key: key);
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
            Text(
              (job?['title_en'] ?? job?['title'] ?? job?['title_ur'] ?? job?['Name'] ?? job?['JobTitle'] ?? 'Job').toString(),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (job?['Address'] ?? job?['JobAddress'] ?? job?['location'] ?? '').toString(),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Job Description:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              (job?['description_en'] ?? job?['description_ur'] ?? job?['Description'] ?? 'No description available').toString(),
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
