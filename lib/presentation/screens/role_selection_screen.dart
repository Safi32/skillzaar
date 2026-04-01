import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/locale_provider.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  void initState() {
    getAppVersion();
    super.initState();
  }

  late bool isLoading = false;

  late String version = '';
  late String buildNumber = '';
  Future<void> getAppVersion() async {
    setState(() {
      isLoading = true;
    });
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      version = packageInfo.version; // e.g. 1.0.3
      buildNumber = packageInfo.buildNumber; // e.g. 42
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, child) {
              final isUrdu = localeProvider.locale.languageCode == 'ur';
              return TextButton(
                onPressed: () => localeProvider.toggleLocale(),
                child: Text(
                  isUrdu ? 'English' : 'اردو',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Green accent shape at top
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Logo on top right
            Positioned(
              top: 16,
              right: 16,
              child: Image.asset(
                "assets/applogo.png", // Replace with your actual logo asset
                width: 150,
                height: 150,
              ),
            ),

            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // App name
                    Text(
                      l10n.findJobsHireTalent,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    // Secondary tagline
                    Text(
                      l10n.chooseRole,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 50),

                    // Buttons as cards
                    _buildRoleCard(
                      context,
                      title: l10n.iAmJobPoster,
                      subtitle: l10n.postJobsHire,
                      color: AppColors.green.withAlpha(200),
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/job-poster-login',
                          arguments: {'role': 'job_poster'},
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildRoleCard(
                      context,
                      title: l10n.iAmSkilledWorker,
                      subtitle: l10n.findApplyJobs,
                      color: AppColors.green.withAlpha(200),
                      textColor: Colors.white,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/skilled-worker-login',
                          arguments: {'role': 'skilled_worker'},
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Text(
                      l10n.or,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/job-poster-home');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.green.shade200),
                        ),
                      ),
                      child: Text(
                        l10n.continueGuest,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.28,
              right: -size.width * 0.05,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // app version
                    !isLoading
                        ? Text(
                          'Version: $version+$buildNumber',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        )
                        : const Text("-"),
                    const SizedBox(height: 4),
                    Text(
                      '© 2024 Skillzaar. All rights reserved.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.green.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
