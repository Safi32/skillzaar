import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class ContactUsDialog extends StatelessWidget {
  const ContactUsDialog({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.contactUs),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.getInTouchWithUs),
          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.email, color: Colors.green),
              SizedBox(width: 8),
              Text('support@skillzaar.com'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.phone, color: Colors.green),
              SizedBox(width: 8),
              Text('+92 300 1234567'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.location_on, color: Colors.green),
              SizedBox(width: 8),
              Text('Islamabad, Pakistan'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
