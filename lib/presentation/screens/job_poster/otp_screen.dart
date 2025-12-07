import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/phone_auth_provider.dart';
import '../job_poster/job_poster_home_screen.dart';

class JobPosterOtpScreen extends StatefulWidget {
  final String phone;

  const JobPosterOtpScreen({super.key, required this.phone});

  @override
  State<JobPosterOtpScreen> createState() => _JobPosterOtpScreenState();
}

class _JobPosterOtpScreenState extends State<JobPosterOtpScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String get _otpCode =>
      _otpControllers.map((c) => c.text.trim()).join();

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
        const SnackBar(content: Text('Please enter the 6-digit code')),
      );
      return;
    }

    String? error;

    if (isSignUp) {
      final phoneAuth =
          Provider.of<PhoneAuthProvider>(context, listen: false);
      error = await phoneAuth.verifyOtpCode(_otpCode);

      if (error == null && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-home',
          (route) => false,
        );
        return;
      }
    } else {
      final auth = Provider.of<AuthStateProvider>(context, listen: false);
      error = await auth.verifyOtpCode(
        _otpCode,
        widget.phone,
      );
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
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

    // AUTO NAVIGATE ON SUCCESS LOGIN (login flow only)
    if (!isSignUp &&
        auth.status == AuthStatus.loggedIn &&
        auth.role == "job_poster") {
      // Delay navigation so build() completes safely
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const JobPosterHomeScreen()),
          (route) => false,
        );
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("OTP sent to ${widget.phone}"),
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
                  (isSignUp ? phoneAuth.isLoading : auth.status == AuthStatus.loggingIn)
                      ? null
                      : _verifyOtp,
              child:
                  (isSignUp ? phoneAuth.isLoading : auth.status == AuthStatus.loggingIn)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Verify"),
            ),

            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                // Implement resend OTP functionality if needed
              },
              child: const Text("Resend OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
