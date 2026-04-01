import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class RetryDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const RetryDialog({Key? key, required this.onCancel, required this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.saveFailed),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.saveFailedDesc,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.checkConnectionMsg,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: onCancel, child: Text(l10n.cancel)),
        ElevatedButton(
          onPressed: onRetry,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: Text(l10n.retry),
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
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.portfolioSetupHelp),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.completePortfolioSteps,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(l10n.stepSkills),
            Text(l10n.stepExperience),
            Text(l10n.stepRate),
            Text(l10n.stepAvailability),
            Text(l10n.stepBio),
            Text(l10n.stepPictures),
            const SizedBox(height: 8),
            Text(
              l10n.portfolioVisibleToClients,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: onGotIt, child: Text(l10n.gotIt))],
    );
  }
}
