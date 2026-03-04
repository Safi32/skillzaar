import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class JobDescriptionInput extends StatelessWidget {
  final TextEditingController controller;
  const JobDescriptionInput({Key? key, required this.controller})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.jobDescription,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.jobDescriptionHint,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 16,
            ),
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
