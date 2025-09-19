import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import '../../providers/phone_auth_provider.dart';


class JobPosterSignUpScreen extends StatefulWidget {
  const JobPosterSignUpScreen({Key? key}) : super(key: key);

  @override
  State<JobPosterSignUpScreen> createState() => _JobPosterSignUpScreenState();
}

class _JobPosterSignUpScreenState extends State<JobPosterSignUpScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  // Phone number validation function
  bool isValidPhoneNumber(String phone) {
    // Remove any spaces, dashes, or parentheses
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it's 11 digits (Pakistani number format)
    if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) {
      return true;
    }

    // Check if it's 10 digits (without leading 0)
    if (cleanPhone.length == 10) {
      return true;
    }

    // Check if it's 12 digits starting with 92
    if (cleanPhone.length == 12 && cleanPhone.startsWith('92')) {
      return true;
    }

    // Check if it's 13 digits starting with +92
    if (cleanPhone.length == 13 && cleanPhone.startsWith('+92')) {
      return true;
    }

    return false;
  }

  // Format phone number to standard format
  String formatPhoneNumber(String input) {
    input = input.trim();
    input = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If already starts with +, return as is
    if (input.startsWith('+')) {
      return input;
    }

    // If starts with 0 and is 11 digits (Pakistani number)
    if (input.startsWith('0') && input.length == 11) {
      return '+92' + input.substring(1);
    }

    // If starts with 92 and is 12 digits
    if (input.startsWith('92') && input.length == 12) {
      return '+' + input;
    }

    // If 10 digits, assume Pakistani number
    if (input.length == 10) {
      return '+92' + input;
    }

    // If 11 digits without 0, assume Pakistani number
    if (input.length == 11 && !input.startsWith('0')) {
      return '+92' + input;
    }

    // Return as is if no pattern matches
    return input;
  }

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
                              isLoading
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
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Validate phone number length (minimum 11 digits)
                                    if (!isValidPhoneNumber(phone)) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Phone number must be at least 11 digits',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      // Format phone number
                                      final formattedPhone = formatPhoneNumber(
                                        phone,
                                      );

                                      // Generate dynamic user ID based on phone number
                                      final userId =
                                          'job_poster_${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}_${DateTime.now().millisecondsSinceEpoch}';

                                      // Check if user already exists
                                      final userExists =
                                          await UserDataService.userExistsByPhone(
                                            phoneNumber: formattedPhone,
                                            userType: 'job_poster',
                                          );

                                      if (userExists) {
                                        // User already exists, show error
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'User already exists with this phone number. Please login instead.',
                                            ),
                                            backgroundColor: Colors.orange,
                                          ),
                                        );
                                        setState(() {
                                          isLoading = false;
                                        });
                                        return;
                                      }

                                      // Create user in Firestore
                                      await UserDataService.createJobPoster(
                                        userId: userId,
                                        phoneNumber: formattedPhone,
                                        displayName: 'Job Poster',
                                      );

                                      // Set logged in state in provider
                                      final phoneAuthProvider =
                                          Provider.of<PhoneAuthProvider>(
                                            context,
                                            listen: false,
                                          );
                                      phoneAuthProvider.setLoggedInState(
                                        userId: userId,
                                        phoneNumber: formattedPhone,
                                      );

                                      // Navigate to home screen
                                      if (mounted) {
                                        Navigator.pushNamedAndRemoveUntil(
                                          context,
                                          '/job-poster-home',
                                          (route) => false,
                                          arguments: {'userId': userId},
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Registration failed: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  },
                          child:
                              isLoading
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
