import 'package:flutter/material.dart';
class PortfolioSkills extends StatelessWidget {
  final List<dynamic> skills;
  const PortfolioSkills({Key? key, required this.skills}) : super(key: key);
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
                Icon(Icons.work, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text('Skills & Expertise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (skills.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(skill.toString(), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w500)),
                  );
                }).toList(),
              )
            else
              Text('No skills listed', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}
