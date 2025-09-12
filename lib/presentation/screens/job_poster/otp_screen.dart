import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/phone_auth_provider.dart';
import '../../providers/job_poster_firebase_extension.dart';

class JobPosterOTPScreen extends StatefulWidget {
  const JobPosterOTPScreen({super.key});

  @override
  State<JobPosterOTPScreen> createState() => _JobPosterOTPScreenState();
}

class _JobPosterOTPScreenState extends State<JobPosterOTPScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (final controller in otpControllers) {
      controller.addListener(_onOtpFieldsChanged);
    }
  }

  void _onOtpFieldsChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.removeListener(_onOtpFieldsChanged);
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  String get otpCode =>
      otpControllers.map((controller) => controller.text).join();

  bool get isOtpValid =>
      otpControllers.every(
        (controller) =>
            controller.text.isNotEmpty &&
            RegExp(r'^[0-9]$').hasMatch(controller.text),
      ) &&
      otpControllers.length == 6;

  @override
  Widget build(BuildContext context) {
    final phoneAuthProvider = Provider.of<PhoneAuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App logo or icon
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.verified_user_outlined,
                        color: Colors.green.shade700,
                        size: 36,
                      ),
                    ),
                  ),
                  const Text(
                    'Verify your number',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'We have sent a 6-digit code to your phone number.',
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                      (index) => SizedBox(
                        width: 48,
                        height: 56,
                        child: TextField(
                          controller: otpControllers[index],
                          focusNode: focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (value) => _onOtpChanged(value, index),
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.green,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.grey),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Resend code',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!isOtpValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter the 6-digit code'),
                            ),
                          );
                          return;
                        }
                        try {
                          await phoneAuthProvider.verifyOtp(
                            otpCode,
                            context,
                            isUser: false,
                          );
                          if (phoneAuthProvider.error == null) {
                            // Register the user in Firestore using the extension
                            await phoneAuthProvider.createJobPosterInFirebase(
                              context,
                            );
                            // ignore: use_build_context_synchronously
                            Navigator.pushReplacementNamed(
                              context,
                              '/job-poster-home',
                              arguments: {
                                'userId': phoneAuthProvider.currentPhoneNumber,
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(phoneAuthProvider.error!)),
                            );
                          }
                        } finally {
                          if (mounted) setState(() {});
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:
                          phoneAuthProvider.isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Continue',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (phoneAuthProvider.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        phoneAuthProvider.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
