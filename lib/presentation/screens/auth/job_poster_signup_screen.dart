import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/phone_auth_provider.dart';

class JobPosterSignUpScreen extends StatefulWidget {
  const JobPosterSignUpScreen({Key? key}) : super(key: key);

  @override
  State<JobPosterSignUpScreen> createState() => _JobPosterSignUpScreenState();
}

class _JobPosterSignUpScreenState extends State<JobPosterSignUpScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Consumer<PhoneAuthProvider>(
                builder: (context, phoneAuthProvider, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.green.shade100,
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Sign up for Skillzaar',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Enter your mobile number to register as a Job Poster.',
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mobile Number',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.green),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.green,
                              width: 2,
                            ),
                          ),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.green,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed:
                              phoneAuthProvider.isLoading
                                  ? null
                                  : () async {
                                    final phone = phoneController.text.trim();
                                    if (phone.isEmpty) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please enter your phone number',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    // Send OTP - navigation will happen in the callback
                                    await phoneAuthProvider.sendOtp(
                                      phone,
                                      context,
                                    );
                                  },
                          child:
                              phoneAuthProvider.isLoading
                                  ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
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
                      Text(
                        'By signing up, you accept our Terms & Privacy Policy.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
