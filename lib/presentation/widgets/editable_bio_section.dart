import 'package:flutter/material.dart';

class EditableBioSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final int minLength;
  final int maxLength;

  const EditableBioSection({
    Key? key,
    required this.controller,
    required this.onChanged,
    this.minLength = 20,
    this.maxLength = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Bio',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tell clients about your skills, experience, and what makes you unique',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Material(
          child: TextField(
            controller: controller,
            maxLines: 4,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: 'Describe your skills, experience, and professional approach...',
              prefixIcon: const Icon(Icons.description, color: Colors.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              helperText: 'Minimum $minLength characters required',
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            final length = controller.text.length;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$length/$maxLength',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (length < minLength)
                  Text(
                    'Need ${minLength - length} more characters',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade600),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
