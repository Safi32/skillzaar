import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class TestNotificationScreen extends StatelessWidget {
  const TestNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Initialized: ${notificationProvider.isInitialized}',
                        ),
                        Text('Loading: ${notificationProvider.isLoading}'),
                        Text(
                          'FCM Token: ${notificationProvider.fcmToken?.substring(0, 20) ?? 'Not available'}...',
                        ),
                        if (notificationProvider.error != null)
                          Text(
                            'Error: ${notificationProvider.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Test Job Notification Button
                ElevatedButton(
                  onPressed:
                      notificationProvider.isLoading
                          ? null
                          : () =>
                              _sendTestJobNotification(notificationProvider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child:
                      notificationProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Send Test Job Notification'),
                ),

                const SizedBox(height: 16),

                // Refresh Token Button
                ElevatedButton(
                  onPressed:
                      notificationProvider.isLoading
                          ? null
                          : () => notificationProvider.refreshToken(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Refresh FCM Token'),
                ),

                const SizedBox(height: 16),

                // Unsubscribe Button
                ElevatedButton(
                  onPressed:
                      notificationProvider.isLoading
                          ? null
                          : () =>
                              notificationProvider
                                  .unsubscribeFromJobNotifications(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Unsubscribe from Job Notifications'),
                ),

                const SizedBox(height: 20),

                // Instructions
                Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Instructions:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '1. Make sure notifications are enabled in device settings',
                        ),
                        Text('2. Tap "Send Test Job Notification" to test'),
                        Text(
                          '3. Check if notification appears in notification panel',
                        ),
                        Text(
                          '4. For real notifications, post a job from the job posting screen',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendTestJobNotification(NotificationProvider provider) async {
    await provider.sendJobNotification(
      jobTitle: 'Test Job - Plumber Needed',
      jobDescription:
          'Need a skilled plumber to fix a leaking pipe in the kitchen. Urgent work required.',
      jobId: 'test_job_${DateTime.now().millisecondsSinceEpoch}',
      location: 'Karachi, Pakistan',

    );
  }
}
