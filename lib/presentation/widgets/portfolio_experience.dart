import 'package:flutter/material.dart';
class PortfolioExperience extends StatelessWidget {
  final String experience;
  const PortfolioExperience({Key? key, required this.experience}) : super(key: key);
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
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text('Experience', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              experience.isNotEmpty ? '$experience years' : 'Experience not specified',
              style: TextStyle(
                fontSize: 16,
                color: experience.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                fontStyle: experience.isEmpty ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
