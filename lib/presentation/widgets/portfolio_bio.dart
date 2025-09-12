import 'package:flutter/material.dart';
class PortfolioBio extends StatelessWidget {
  final String bio;
  const PortfolioBio({Key? key, required this.bio}) : super(key: key);
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
                Icon(Icons.description, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text('Professional Bio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              bio.isNotEmpty ? bio : 'No bio provided',
              style: TextStyle(
                fontSize: 16,
                color: bio.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                fontStyle: bio.isEmpty ? FontStyle.italic : FontStyle.normal,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
