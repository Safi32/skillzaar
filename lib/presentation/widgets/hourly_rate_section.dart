import 'package:flutter/material.dart';
class HourlyRateSection extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  const HourlyRateSection({Key? key, required this.controller, required this.onChanged}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hourly Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        const Text('What is your preferred hourly rate for your services?', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 20),
        Material(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 25',
              prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
              suffixText: 'PKR/hour',
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
