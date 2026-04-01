import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_state_provider.dart';
import '../screens/job_poster/job_poster_home_screen.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  State<UserRegistrationScreen> createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();

  Future<void> _sendOtp() async {
    final auth = Provider.of<AuthStateProvider>(context, listen: false);

    final error = await auth.sendOtpToPhone(_phoneController.text.trim());

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } else {
      // OTP sent → go to OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => UserOtpScreen(phoneNumber: _phoneController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.userRegistration)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.enterPhoneToRegister,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            auth.status == AuthStatus.loggingIn
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _sendOtp,
                  child: Text(l10n.sendOtp),
                ),
          ],
        ),
      ),
    );
  }
}

class UserOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const UserOtpScreen({super.key, required this.phoneNumber});

  @override
  State<UserOtpScreen> createState() => _UserOtpScreenState();
}

class _UserOtpScreenState extends State<UserOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  Future<void> _verifyOtp() async {
    final auth = Provider.of<AuthStateProvider>(context, listen: false);

    final error = await auth.verifyOtpCode(
      _otpController.text.trim(),
      widget.phoneNumber,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // Wait for provider to move into loggedIn state
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // AUTO NAVIGATION if logged in
    if (auth.status == AuthStatus.loggedIn && auth.role == "job_poster") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const JobPosterHomeScreen()),
          (route) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.enterOtp)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.otpSentTo(widget.phoneNumber)),
            const SizedBox(height: 20),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.verifyOtp,
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            auth.status == AuthStatus.loggingIn
                ? const CircularProgressIndicator()
                : ElevatedButton(
                  onPressed: _verifyOtp,
                  child: Text(l10n.verifyOtp),
                ),
          ],
        ),
      ),
    );
  }
}
