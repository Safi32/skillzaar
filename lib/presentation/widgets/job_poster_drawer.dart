import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/auth_state_provider.dart';
import 'package:skillzaar/presentation/screens/job_poster/contact_us_screen.dart';

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
    final authState = Provider.of<AuthStateProvider>(context, listen: false);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.green),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.green),
                ),
                const SizedBox(height: 12),
                Text(
                  (authState.role == 'job_poster' && authState.user != null)
                      ? 'Job Poster'
                      : 'Guest User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Welcome to Skillzaar',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add_box, color: Colors.green),
            title: const Text('Post New Job'),
            onTap: onPostJob,
          ),

          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.green),
            title: const Text('All Ads'),
            onTap: onAllAds,
          ),
          ListTile(
            leading: const Icon(Icons.work, color: Colors.green),
            title: const Text('My Ads'),
            onTap: onMyAds,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.support_agent, color: Colors.green),
            title: const Text('Contact Us'),
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
            title: const Text('Log Out'),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}
