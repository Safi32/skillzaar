import 'package:flutter/material.dart';

class FeeDialog extends StatelessWidget {
  final VoidCallback? onAccept;
  const FeeDialog({Key? key, this.onAccept}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Monthly Access'),
      content: const Text('Please pay the monthly fee to continue.'),
      actions: [
        TextButton(
          onPressed: onAccept ?? () => Navigator.of(context).pop(),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
