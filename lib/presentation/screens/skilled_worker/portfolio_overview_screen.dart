import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/home_profile_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class PortfolioOverviewScreen extends StatelessWidget {
  const PortfolioOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProfileProvider>(
      builder: (context, homeProfileProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Portfolio Overview'),
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPortfolioStatusCard(homeProfileProvider, context),
                const SizedBox(height: 24),
                _buildMissingInfoSection(homeProfileProvider),
                const SizedBox(height: 24),
                _buildActionButtons(context, homeProfileProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioStatusCard(
    HomeProfileProvider provider,
    BuildContext context,
  ) {
    final l10n = AppLocalizations.of(context)!;
    String displayMessage = provider.profileCompletionMessage;

    if (provider.profileCompletionMessage ==
        'Portfolio Complete! You can now request jobs.') {
      displayMessage = l10n.portfolioCompleteMessage;
    } else if (provider.profileCompletionMessage.startsWith(
      'Complete your portfolio to request jobs. Missing: ',
    )) {
      final missingString = provider.profileCompletionMessage.substring(
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
                  provider.isProfileComplete ? Icons.check_circle : Icons.info,
                  color:
                      provider.isProfileComplete ? Colors.green : Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.isProfileComplete
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
                  onPressed: () => _showHelpDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: provider.profileCompletionPercentage,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                provider.isProfileComplete ? Colors.green : Colors.green,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.percentComplete(
                (provider.profileCompletionPercentage * 100).round().toString(),
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
              style: TextStyle(
                fontSize: 14,
                color:
                    provider.isProfileComplete
                        ? Colors.green.shade700
                        : Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingInfoSection(HomeProfileProvider provider) {
    if (provider.isProfileComplete) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Missing Information',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            if (!provider.hasSkills) ...[
              _buildMissingItem('Skills & Categories', Icons.category),
              const SizedBox(height: 8),
            ],
            if (!provider.hasExperience) ...[
              _buildMissingItem('Years of Experience', Icons.work_history),
              const SizedBox(height: 8),
            ],
            if (!provider.hasBio) ...[
              _buildMissingItem('Professional Bio', Icons.description),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMissingItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.red.shade600, size: 20),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.red.shade600, fontSize: 14)),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    HomeProfileProvider provider,
  ) {
    return Column(
      children: [
        if (!provider.isProfileComplete) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/skilled-worker-home-profile');
              },
              icon: const Icon(Icons.edit),
              label: const Text('Complete Portfolio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Job Details'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: BorderSide(color: AppColors.green),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
