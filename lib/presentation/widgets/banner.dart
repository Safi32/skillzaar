import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class HireBanner extends StatelessWidget {
  const HireBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.sizeOf(context).width,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                children: [
                  TextSpan(
                    text: AppLocalizations.of(context)!.hireHighlyQualified,
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)!.qualified,
                    style: GoogleFonts.pacifico(
                      // 👈 different font
                      textStyle: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  TextSpan(text: AppLocalizations.of(context)!.professionals),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Image.asset('assets/workers.png', width: 130, height: 120),
          ),
        ],
      ),
    );
  }
}
