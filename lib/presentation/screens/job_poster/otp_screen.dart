import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/phone_auth_provider.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class JobPosterOtpScreen extends StatefulWidget {
  final String phone;

  const JobPosterOtpScreen({super.key, required this.phone});

  @override
  State<JobPosterOtpScreen> createState() => _JobPosterOtpScreenState();
}

class _JobPosterOtpScreenState extends State<JobPosterOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String get _otpCode => _otpControllers.map((c) => c.text.trim()).join();

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isSignUp = args?['isSignUp'] == true;

    if (_otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterOtp)),
      );
      return;
    }

    String? error;

    if (isSignUp) {
      final phoneAuth = Provider.of<PhoneAuthProvider>(context, listen: false);
      error = await phoneAuth.verifyOtpCode(_otpCode);

      if (error == null && mounted) {
        // Also update AuthStateProvider so the drawer shows the correct name
        final authState = Provider.of<AuthStateProvider>(
          context,
          listen: false,
        );
        await authState.setJobPosterSignedIn(
          id: phoneAuth.loggedInUserId!,
          name: phoneAuth.pendingDisplayName ?? phoneAuth.loggedInPhoneNumber,
          phone: phoneAuth.loggedInPhoneNumber,
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-home',
          (route) => false,
        );
        return;
      }
    } else {
      final auth = Provider.of<AuthStateProvider>(context, listen: false);
      error = await auth.verifyOtpCode(_otpCode, widget.phone);

      // On successful login, decide next screen based on active job/profile status
      if (error == null && mounted) {
        final next = await auth.determineNextScreen();
        log("determine nextt: " + next.toString());
        switch (next) {
          case NextScreen.activeJobJobPoster:
            final userId = auth.userId;
            if (userId != null && userId.isNotEmpty) {
              try {
                // Resolve active request for this poster to get jobId + requestId
                final active =
                    await JobRequestService.getActiveRequestForPoster(
                      userId,
                      posterPhone: widget.phone,
                    );

                final jobId =
                    active != null ? active['jobId']?.toString() : null;
                final requestId =
                    active != null ? active['requestId']?.toString() : null;

                if (jobId != null && jobId.isNotEmpty) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/job-poster-accepted-details',
                    (route) => false,
                    arguments: {'jobId': jobId, 'requestId': requestId ?? ''},
                  );
                  return;
                }

                // Fallback: if active request missing, but JobPosters has activeJobId
                final doc =
                    await FirebaseFirestore.instance
                        .collection('JobPosters')
                        .doc(userId)
                        .get();
                final data = doc.data() ?? {};
                final activeJobId = data['activeJobId'] as String?;

                if (activeJobId != null && activeJobId.isNotEmpty) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/job-poster-accepted-details',
                    (route) => false,
                    arguments: {
                      'jobId': activeJobId,
                      // requestId optional under new schema
                    },
                  );
                  return;
                }
              } catch (_) {
                // Fallback handled below
              }
            }

            // Fallback to home if no active job details found
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/job-poster-home',
              (route) => false,
            );
            return;

          case NextScreen.completeProfile:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/job-poster-profile',
              (route) => false,
            );
            return;

          case NextScreen.homeJobPoster:
          default:
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/job-poster-home',
              (route) => false,
            );
            return;
        }
      }
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // If login success → provider/status will handle navigation for login flow
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final bool isSignUp = args?['isSignUp'] == true;

    final auth = Provider.of<AuthStateProvider>(context);
    final phoneAuth = Provider.of<PhoneAuthProvider>(context);

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.verifyOtp)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.otpSentTo(widget.phone)),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 50,
                  height: 60,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    onChanged: (value) => _onOtpChanged(value, index),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed:
                  (isSignUp
                          ? phoneAuth.isLoading
                          : auth.status == AuthStatus.loggingIn)
                      ? null
                      : _verifyOtp,
              child:
                  (isSignUp
                          ? phoneAuth.isLoading
                          : auth.status == AuthStatus.loggingIn)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.verifyButton),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                // Implement resend OTP functionality if needed
              },
              child: Text(l10n.resendOtp),
            ),
          ],
        ),
      ),
    );
  }
}
