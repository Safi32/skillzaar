import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/phone_auth_provider.dart';
import 'package:skillzaar/presentation/widgets/profile_section.dart';
import 'package:skillzaar/presentation/widgets/profile_item.dart';
import 'package:skillzaar/presentation/widgets/profile_action_button.dart';

class JobPosterProfileScreen extends StatelessWidget {
  const JobPosterProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<UIStateProvider, PhoneAuthProvider>(
      builder: (context, uiProvider, authProvider, child) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green.shade100,
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        authProvider.loggedInUserId == null
                            ? "Guest User"
                            : 'Job Poster',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.loggedInUserId == null
                            ? "Guest User"
                            : 'Job Poster',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ProfileSection(
                  title: 'Personal Information',
                  children:
                      authProvider.loggedInUserId == null
                          ? [Text("Login to view details")]
                          : [
                            ProfileItem(
                              icon: Icons.phone,
                              label: 'Phone Number',
                              value: 'Not provided',
                            ),
                            ProfileItem(
                              icon: Icons.email,
                              label: 'Email',
                              value: 'Not provided',
                            ),
                            ProfileItem(
                              icon: Icons.location_on,
                              label: 'Location',
                              value: 'Not provided',
                            ),
                          ],
                ),

                const SizedBox(height: 24),
                ProfileSection(
                  title: 'Statistics',
                  children:
                      authProvider.loggedInUserId == null
                          ? [Text("Login to view details")]
                          : [
                            ProfileItem(
                              icon: Icons.work,
                              label: 'Total Jobs Posted',
                              value: '0',
                            ),
                            ProfileItem(
                              icon: Icons.people,
                              label: 'Active Requests',
                              value: '0',
                            ),
                            ProfileItem(
                              icon: Icons.check_circle,
                              label: 'Completed Jobs',
                              value: '0',
                            ),
                          ],
                ),

                const SizedBox(height: 24),
                ProfileSection(
                  title: 'Actions',
                  children:
                      authProvider.loggedInUserId == null
                          ? [Text("Login to view details")]
                          : [
                            ProfileActionButton(
                              icon: Icons.edit,
                              label: 'Edit Profile',
                              onTap: () {
                                context.read<UIStateProvider>().showInfoToast(
                                  context,
                                  'Coming Soon',
                                  'Edit profile functionality will be available soon!',
                                );
                              },
                            ),
                            ProfileActionButton(
                              icon: Icons.settings,
                              label: 'Settings',
                              onTap: () {
                                context.read<UIStateProvider>().showInfoToast(
                                  context,
                                  'Coming Soon',
                                  'Settings functionality will be available soon!',
                                );
                              },
                            ),
                            ProfileActionButton(
                              icon: Icons.person_off,
                              label: 'Deactivate Account',
                              onTap: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Deactivate Account'),
                                        content: const Text(
                                          'This will permanently delete your account and data. Continue?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                );

                                if (shouldDelete == true) {
                                  final ui = context.read<UIStateProvider>();
                                  final success = await context
                                      .read<PhoneAuthProvider>()
                                      .deactivateAndDeleteCurrentUser(context);

                                  if (success && context.mounted) {
                                    // Navigate to login/landing
                                    Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      '/job-poster-login',
                                      (route) => false,
                                    );
                                  } else {
                                    ui.showErrorToast(
                                      context,
                                      'Delete failed',
                                      'Could not delete account. Re-login may be required.',
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
