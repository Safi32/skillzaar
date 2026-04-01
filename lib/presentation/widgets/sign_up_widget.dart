import 'package:flutter/material.dart';
import 'package:skillzaar/core/theme/app_theme.dart';

class SignUpWidget extends StatelessWidget {
  const SignUpWidget({
    super.key,
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.green,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Phone Input
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.green, width: 2),
            ),
            prefixIcon: Icon(icon, color: AppColors.green),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }
}
