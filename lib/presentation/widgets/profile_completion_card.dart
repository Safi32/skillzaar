import 'package:flutter/material.dart';
class ProfileCompletionCard extends StatelessWidget {
  final bool isProfileComplete;
  final double completionPercentage;
  final String completionMessage;
  final VoidCallback onHelp;
  const ProfileCompletionCard({Key? key, required this.isProfileComplete, required this.completionPercentage, required this.completionMessage, required this.onHelp}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProfileComplete ? Icons.check_circle : Icons.info,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isProfileComplete ? 'Portfolio Complete!' : 'Portfolio Setup Required',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.green),
                  onPressed: onHelp,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completionPercentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              '${(completionPercentage * 100).round()}% Complete',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              completionMessage,
              style: TextStyle(fontSize: 14, color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
