import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/phone_auth_provider.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;
  const LogoutDialog({super.key, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            Provider.of<PhoneAuthProvider>(
              context,
              listen: false,
            ).setLoggedInUserId(null);
            onLogout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Log Out'),
        ),
      ],
    );
  }
}
