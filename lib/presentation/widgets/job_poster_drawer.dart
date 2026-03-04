import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/auth_state_provider.dart';
import 'package:skillzaar/presentation/screens/job_poster/contact_us_screen.dart';
import 'package:skillzaar/presentation/providers/locale_provider.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class JobPosterDrawer extends StatelessWidget {
  final VoidCallback onPostJob;
  final VoidCallback onAllAds;
  final VoidCallback onMyAds;
  final VoidCallback onLogout;

  const JobPosterDrawer({
    super.key,
    required this.onPostJob,
    required this.onAllAds,
    required this.onMyAds,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final authState = Provider.of<AuthStateProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.green),
                ),
                const SizedBox(height: 12),
                Text(
                  authState.userId == null
                      ? l10n.guestUser
                      : authState.currentUser?.name ?? l10n.jobPoster,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  l10n.welcome,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_box, color: Colors.green),
            title: Text(l10n.postJob),
            onTap: onPostJob,
          ),
          ListTile(
            leading: const Icon(Icons.work, color: Colors.green),
            title: Text(l10n.myAds),
            onTap: onMyAds,
          ),
          const Divider(),
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              final isUrdu = localeProvider.locale.languageCode == 'ur';
              return ListTile(
                leading: const Icon(Icons.language, color: Colors.blue),
                title: Text(isUrdu ? 'English' : 'اردو (Urdu)'),
                onTap: () {
                  localeProvider.toggleLocale();
                },
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.green),
            title: Text(l10n.contactUs),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactUsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
