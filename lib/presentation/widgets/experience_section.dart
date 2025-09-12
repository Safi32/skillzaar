import 'package:flutter/material.dart';
class ExperienceSection extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  const ExperienceSection({Key? key, required this.controller, required this.onChanged}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Years of Experience', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        const Text('How many years of professional experience do you have?', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),
        Material(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 5',
              prefixIcon: const Icon(Icons.work_history, color: Colors.green),
              suffixText: 'years',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
