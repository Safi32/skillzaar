import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/theme/app_theme.dart';


class SkilledWorkerLoginScreen extends StatefulWidget {
  const SkilledWorkerLoginScreen({super.key});

  @override
  State<SkilledWorkerLoginScreen> createState() =>
      _SkilledWorkerLoginScreenState();
}

class _SkilledWorkerLoginScreenState extends State<SkilledWorkerLoginScreen> {
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
    final skilledWorkerProvider = Provider.of<SkilledWorkerProvider>(context);

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
                Icon(Icons.lock_outline, size: 48, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'Skilled Worker Log In',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your mobile number to explore jobs',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.black),
                ),
                const SizedBox(height: 24),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number',
                      ),
                      enabled: !isLoading,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          isLoading
                              ? null
                              : () async {
                                final input = phoneController.text.trim();
                                if (input.isEmpty) {
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
                                if (!isValidPhoneNumber(input)) {
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
                                  final formattedPhone = formatPhoneNumber(
                                    input,
                                  );

                                  // Check if user is already registered
                                  print(
                                    '🔍 Checking skilled worker existence:',
                                  );
                                  print('📱 Formatted phone: $formattedPhone');

                                  final userExists =
                                      await UserDataService.userExistsByPhone(
                                        phoneNumber: formattedPhone,
                                        userType: 'skilled_worker',
                                      );

                                  print('✅ Skilled worker exists: $userExists');

                                  if (userExists) {
                                    print(
                                      '🏠 Navigating to skilled worker home screen',
                                    );

                                    // Get user data to get the actual user ID
                                    final userData =
                                        await UserDataService.getUserDataByPhone(
                                          phoneNumber: formattedPhone,
                                          userType: 'skilled_worker',
                                        );

                                    String userId;
                                    if (userData != null && userData.exists) {
                                      userId = userData.id;
                                      print(
                                        '✅ Found existing user with ID: $userId',
                                      );
                                    } else {
                                      // Fallback: generate dynamic user ID
                                      userId =
                                          'skilled_worker_${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}_${DateTime.now().millisecondsSinceEpoch}';
                                    }

                                    // Set authentication state in provider
                                    skilledWorkerProvider.setLoggedInState(
                                      userId: userId,
                                      phoneNumber: formattedPhone,
                                    );

                                    // Check approval status before redirecting
                                    final userDataMap =
                                        userData?.data()
                                            as Map<String, dynamic>?;
                                    final approvalStatus =
                                        userDataMap?['approvalStatus'] ??
                                        'pending';

                                    if (approvalStatus == 'approved') {
                                      // User is approved, navigate to home screen
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/skilled-worker-home',
                                        (route) => false,
                                      );
                                    } else {
                                      // User is not approved, redirect to approval waiting screen
                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/skilled-worker-approval-waiting',
                                        (route) => false,
                                        arguments: {
                                          'userId': userId,
                                          'phoneNumber': formattedPhone,
                                        },
                                      );
                                    }
                                  } else {
                                    print(
                                      '📝 Skilled worker not found, showing register message',
                                    );
                                    // User is not registered, show register message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No account found with this phone number. Please register first.',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error checking account: $e',
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

                                // COMMENTED OUT OTP CODE - TO BE USED DURING DEPLOYMENT
                                /*
                                // Start verification and navigate immediately so user can enter OTP
                                skilledWorkerProvider.verifyPhone(rawInput);
                                if (!mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  '/skilled-worker-otp',
                                  arguments: {
                                    'phone': rawInput,
                                    'isSignUp': false,
                                  },
                                );
                                */
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
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/skilled-worker-signup');
                      },
                      child: const Text(
                        'Sign up',
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
