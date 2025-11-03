import 'package:flutter/material.dart';

class RetryDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const RetryDialog({Key? key, required this.onCancel, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save Failed'),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Failed to save your portfolio. This could be due to:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'Please check your internet connection and ensure all required fields are completed.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Retry'),
        ),
      ],
    );
  }
}

class ProfileHelpDialog extends StatelessWidget {
  final VoidCallback onGotIt;
  const ProfileHelpDialog({Key? key, required this.onGotIt}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Portfolio Setup Help'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Complete your portfolio to showcase your professional capabilities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('• Select your skills and categories'),
            Text('• Add your years of experience'),
            Text('• Set your hourly rate'),
            Text('• Describe your availability'),
            Text('• Write a professional bio (min. 20 characters)'),
            Text('• Add portfolio pictures (optional)'),
            SizedBox(height: 8),
            Text(
              'This portfolio will be visible to potential clients.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onGotIt,
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
