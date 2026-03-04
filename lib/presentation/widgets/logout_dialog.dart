import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/phone_auth_provider.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class LogoutDialog extends StatelessWidget {
  final VoidCallback onLogout;
  const LogoutDialog({super.key, required this.onLogout});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.logout),
      content: Text(l10n.logoutConfirmMsg),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
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
          child: Text(l10n.logout),
        ),
      ],
    );
  }
}
