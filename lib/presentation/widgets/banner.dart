import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class HireBanner extends StatelessWidget {
  const HireBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA847), Color(0xFF13B94B), Color(0xFF2DD36F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(19, 185, 75, 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative circle top-right
          Positioned(
            top: -20,
            right: 80,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          // Decorative circle bottom-left
          Positioned(
            bottom: -16,
            left: -16,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              top: 20,
              bottom: 20,
              right: 130,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⭐  Top Rated Workers',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Main headline
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: l10n.hireHighlyQualified,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                      TextSpan(
                        text: '\n${l10n.qualified}',
                        style: GoogleFonts.pacifico(
                          textStyle: const TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                      ),
                      TextSpan(text: '  '),
                      TextSpan(
                        text: l10n.professionals,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // const SizedBox(height: 12),
                // // CTA chip
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 14,
                //     vertical: 7,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: const Text(
                //     'Post a Job',
                //     style: TextStyle(
                //       fontSize: 12,
                //       color: Color(0xFF0EA847),
                //       fontWeight: FontWeight.w700,
                //       letterSpacing: 0.2,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          // Worker image
          Positioned(
            right: -4,
            bottom: 0,
            child: Image.asset(
              'assets/workers.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
