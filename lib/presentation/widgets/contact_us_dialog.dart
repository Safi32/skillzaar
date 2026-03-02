import 'package:flutter/material.dart';
class ContactUsDialog extends StatelessWidget {
  const ContactUsDialog({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contact Us'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get in touch with us:'),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.email, color: Colors.green),
              SizedBox(width: 8),
              Text('support@skillzaar.com'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.phone, color: Colors.green),
              SizedBox(width: 8),
              Text('+92 300 1234567'),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
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
          child: const Text('Close'),
        ),
      ],
    );
  }
}
