import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/auth_state_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/phone_auth_provider.dart';
import 'package:skillzaar/presentation/widgets/profile_section.dart';
import 'package:skillzaar/presentation/widgets/profile_item.dart';
import 'package:skillzaar/presentation/widgets/profile_action_button.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class JobPosterProfileScreen extends StatelessWidget {
  const JobPosterProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer2<UIStateProvider, AuthStateProvider>(
      builder: (context, uiProvider, authProvider, child) {
        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 160,
            ),
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
                        authProvider.userId == null
                            ? l10n.guestUser
                            : authProvider.currentUser?.name ?? "-",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        authProvider.userId == null
                            ? l10n.guestUser
                            : authProvider.currentUser?.role ?? "-",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ProfileSection(
                  title: l10n.personalInformation,
                  children:
                      authProvider.userId == null
                          ? [Text(l10n.loginToViewDetails)]
                          : [
                            ProfileItem(
                              icon: Icons.phone,
                              label: l10n.phoneNumber,
                              value: authProvider.currentUser?.phone ?? "-",
                            ),
                            ProfileItem(
                              icon: Icons.email,
                              label: l10n.email,
                              value: authProvider.currentUser?.email ?? "-",
                            ),
                            ProfileItem(
                              icon: Icons.location_on,
                              label: l10n.location,
                              value: '-',
                            ),
                          ],
                ),

                const SizedBox(height: 24),
                ProfileSection(
                  title: l10n.statistics,
                  children:
                      authProvider.userId == null
                          ? [Text(l10n.loginToViewDetails)]
                          : [
                            ProfileItem(
                              icon: Icons.work,
                              label: l10n.totalJobsPosted,
                              value: '-',
                            ),
                            ProfileItem(
                              icon: Icons.people,
                              label: l10n.activeRequests,
                              value: '-',
                            ),
                            ProfileItem(
                              icon: Icons.check_circle,
                              label: l10n.completedJobs,
                              value: '-',
                            ),
                          ],
                ),

                const SizedBox(height: 24),
                ProfileSection(
                  title: l10n.actions,
                  children:
                      authProvider.userId == null
                          ? [Text(l10n.loginToViewDetails)]
                          : [
                            ProfileActionButton(
                              icon: Icons.person_off,
                              label: l10n.deactivateAccount,
                              onTap: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: Text(l10n.deactivateAccount),
                                        content: Text(
                                          l10n.deactivateConfirmMsg,
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.of(
                                                  context,
                                                ).pop(false),
                                            child: Text(l10n.cancel),
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
                                            child: Text(l10n.delete),
                                          ),
                                        ],
                                      ),
                                );

                                if (shouldDelete == true) {
                                  final ui = context.read<UIStateProvider>();
                                  final success =
                                      await context
                                          .read<PhoneAuthProvider>()
                                          .deactivateAndDeleteCurrentUser();

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
                                      l10n.deleteFailed,
                                      l10n.deleteFailedMsg,
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
