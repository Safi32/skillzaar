import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class HourlyRateSection extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  const HourlyRateSection({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.hourlyRateLabel,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.hourlyRateDesc,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Material(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: l10n.egHourlyRate,
              prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
              suffixText: l10n.pkrPerHour,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
