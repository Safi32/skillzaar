import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_state_provider.dart';
import '../screens/job_poster/job_poster_home_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      // OTP sent → go to OTP screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserOtpScreen(phoneNumber: _phoneController.text.trim()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('User Registration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Enter your phone number to register",
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            auth.status == AuthStatus.loggingIn
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _sendOtp,
                    child: const Text("Send OTP"),
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

    final error =
        await auth.verifyOtpCode(_otpController.text.trim(), widget.phoneNumber);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    // Wait for provider to move into loggedIn state
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);

    // AUTO NAVIGATION if logged in
    if (auth.status == AuthStatus.loggedIn &&
        auth.role == "job_poster") {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const JobPosterHomeScreen()),
          (route) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Enter OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("OTP sent to ${widget.phoneNumber}"),
            const SizedBox(height: 20),

            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "OTP",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            auth.status == AuthStatus.loggingIn
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text("Verify OTP"),
                  ),
          ],
        ),
      ),
    );
  }
}
