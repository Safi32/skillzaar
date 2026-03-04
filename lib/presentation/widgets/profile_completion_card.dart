import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class ProfileCompletionCard extends StatelessWidget {
  final bool isProfileComplete;
  final double completionPercentage;
  final String completionMessage;
  final VoidCallback onHelp;
  const ProfileCompletionCard({
    Key? key,
    required this.isProfileComplete,
    required this.completionPercentage,
    required this.completionMessage,
    required this.onHelp,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String displayMessage = completionMessage;

    if (completionMessage == 'Portfolio Complete! You can now request jobs.') {
      displayMessage = l10n.portfolioCompleteMessage;
    } else if (completionMessage.startsWith(
      'Complete your portfolio to request jobs. Missing: ',
    )) {
      final missingString = completionMessage.substring(
        'Complete your portfolio to request jobs. Missing: '.length,
      );
      final fields = missingString.split(', ');
      List<String> localizedFields = [];
      for (var f in fields) {
        if (f == 'skills')
          localizedFields.add(l10n.skillsText);
        else if (f == 'experience')
          localizedFields.add(l10n.experienceText);
        else if (f == 'bio')
          localizedFields.add(l10n.bioText);
        else
          localizedFields.add(f);
      }
      displayMessage =
          '${l10n.completePortfolioRequestJobs}: ${localizedFields.join(', ')}';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isProfileComplete ? Icons.check_circle : Icons.info,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isProfileComplete
                        ? l10n.portfolioComplete
                        : l10n.portfolioSetupRequired,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.green),
                  onPressed: onHelp,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completionPercentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.percentComplete(
                (completionPercentage * 100).round().toString(),
              ),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              displayMessage,
              style: TextStyle(fontSize: 14, color: Colors.green.shade700),
            ),
          ],
        ),
      ),
    );
  }
}
