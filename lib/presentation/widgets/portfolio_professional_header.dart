import 'package:flutter/material.dart';
class PortfolioProfessionalHeader extends StatelessWidget {
  final String skilledWorkerName;
  const PortfolioProfessionalHeader({Key? key, required this.skilledWorkerName}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.green.shade100,
              child: Icon(Icons.person, size: 40, color: Colors.green.shade700),
            ),
            const SizedBox(height: 16),
            Text(
              skilledWorkerName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Professional Portfolio',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
