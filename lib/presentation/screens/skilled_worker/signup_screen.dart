import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/theme/app_theme.dart';


class SkilledWorkerSignUpScreen extends StatefulWidget {
  const SkilledWorkerSignUpScreen({super.key});

  @override
  State<SkilledWorkerSignUpScreen> createState() =>
      _SkilledWorkerSignUpScreenState();
}

class _SkilledWorkerSignUpScreenState extends State<SkilledWorkerSignUpScreen> {
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: size.height * 0.08,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.lock_outline, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Skilled Worker Sign Up',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter Your Phone Number',
                    prefixIcon: const Icon(Icons.phone, color: Colors.green),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : () async {
                              final phone = phoneController.text.trim();
                              if (phone.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                ScaffoldMessenger.of(context).showSnackBar(
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
                                final formattedPhone = formatPhoneNumber(phone);

                                // Generate dynamic user ID based on phone number
                                final userId =
                                    'skilled_worker_${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}_${DateTime.now().millisecondsSinceEpoch}';

                                // Check if user already exists
                                final userExists =
                                    await UserDataService.userExistsByPhone(
                                      phoneNumber: formattedPhone,
                                      userType: 'skilled_worker',
                                    );

                                if (userExists) {
                                  // User already exists, show error
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                                await UserDataService.createSkilledWorker(
                                  userId: userId,
                                  phoneNumber: formattedPhone,
                                  displayName: 'Skilled Worker',
                                );

                                // Set logged in state in provider
                                final skilledWorkerProvider =
                                    Provider.of<SkilledWorkerProvider>(
                                      context,
                                      listen: false,
                                    );
                                skilledWorkerProvider.setLoggedInState(
                                  userId: userId,
                                  phoneNumber: formattedPhone,
                                );

                                // Navigate to CNIC screen (skip OTP)
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/skilled-worker-cnic',
                                    (route) => false,
                                    arguments: {'userId': userId},
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Registration failed: $e'),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 1,
                    ),
                    child:
                        isLoading
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/skilled-worker-login');
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
