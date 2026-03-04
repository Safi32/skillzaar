import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import 'package:skillzaar/presentation/widgets/contact_info_tile.dart';
import 'package:skillzaar/presentation/widgets/contact_section.dart';
import 'package:skillzaar/presentation/widgets/faq_item.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contactUs),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.support_agent, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  Text(
                    l10n.wereHereToHelp,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.getInTouchWithSupport,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ContactSection(
              title: l10n.getInTouch,
              children: [
                ContactInfoTile(
                  icon: Icons.phone,
                  title: l10n.callUs,
                  subtitle: '+92 300 1234567',
                ),
                ContactInfoTile(
                  icon: Icons.email,
                  title: l10n.emailUs,
                  subtitle: 'support@skillzaar.com',
                ),
                ContactInfoTile(
                  icon: Icons.chat,
                  title: l10n.whatsApp,
                  subtitle: l10n.messageUsOnWhatsApp,
                ),
              ],
            ),

            const SizedBox(height: 24),
            ContactSection(
              title: l10n.officeHours,
              children: [
                ContactInfoTile(
                  icon: Icons.access_time,
                  title: l10n.mondayFriday,
                  subtitle: '9:00 AM - 6:00 PM',
                ),
                ContactInfoTile(
                  icon: Icons.access_time,
                  title: l10n.saturday,
                  subtitle: '10:00 AM - 4:00 PM',
                ),
                ContactInfoTile(
                  icon: Icons.access_time,
                  title: l10n.sunday,
                  subtitle: l10n.closed,
                ),
              ],
            ),

            const SizedBox(height: 24),
            ContactSection(
              title: l10n.faq,
              children: [
                FAQItem(
                  question: l10n.howToPostJob,
                  answer: l10n.howToPostJobAns,
                ),
                FAQItem(
                  question: l10n.howToViewRequests,
                  answer: l10n.howToViewRequestsAns,
                ),
                FAQItem(
                  question: l10n.canIEditJobs,
                  answer: l10n.canIEditJobsAns,
                ),
                FAQItem(
                  question: l10n.howToContactWorkers,
                  answer: l10n.howToContactWorkersAns,
                ),
              ],
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.report_problem),
                label: Text(l10n.reportAnIssue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
