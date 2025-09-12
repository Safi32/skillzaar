import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/widgets/contact_info_tile.dart';
import 'package:skillzaar/presentation/widgets/contact_section.dart';
import 'package:skillzaar/presentation/widgets/faq_item.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
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
                  const Text(
                    'We\'re Here to Help!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with our support team',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ContactSection(
              title: 'Get in Touch',
              children: [
                ContactInfoTile(
                  icon: Icons.phone,
                  title: 'Call Us',
                  subtitle: '+92 300 1234567',
                  
                ),
                ContactInfoTile(
                  icon: Icons.email,
                  title: 'Email Us',
                  subtitle: 'support@skillzaar.com',
                  
                ),
                ContactInfoTile(
                  icon: Icons.chat,
                  title: 'WhatsApp',
                  subtitle: 'Message us on WhatsApp',
                   
                ),
              ],
            ),

            const SizedBox(height: 24),
            ContactSection(
              title: 'Office Hours',
              children: [
                ContactInfoTile(
                  icon: Icons.access_time,
                  title: 'Monday - Friday',
                  subtitle: '9:00 AM - 6:00 PM',
                ),
                ContactInfoTile(
                  icon: Icons.access_time,
                  title: 'Saturday',
                  subtitle: '10:00 AM - 4:00 PM',
                ),
                ContactInfoTile(
                  icon: Icons.access_time,
                  title: 'Sunday',
                  subtitle: 'Closed',
                ),
              ],
            ),

            const SizedBox(height: 24),
            ContactSection(
              title: 'Frequently Asked Questions',
              children: [
                FAQItem(
                  question: 'How do I post a job?',
                  answer:
                      'Go to the "Post New Job" section from the drawer menu and fill in the required details.',
                ),
                FAQItem(
                  question: 'How do I view job requests?',
                  answer:
                      'Navigate to the "Requests" tab to see all requests for your posted jobs.',
                ),
                FAQItem(
                  question: 'Can I edit my posted jobs?',
                  answer:
                      'Yes, you can edit your jobs from the "My Ads" section.',
                ),
                FAQItem(
                  question: 'How do I contact skilled workers?',
                  answer:
                      'You can contact workers through the requests they send for your jobs.',
                ),
              ],
            ),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  
                },
                icon: const Icon(Icons.report_problem),
                label: const Text('Report an Issue'),
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