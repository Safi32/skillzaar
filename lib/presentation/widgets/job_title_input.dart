import 'package:flutter/material.dart';
class JobTitleInput extends StatelessWidget {
  final TextEditingController controller;
  const JobTitleInput({Key? key, required this.controller}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Job Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g. Need a Plumber',
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
