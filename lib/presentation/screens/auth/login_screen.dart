import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';

import '../../../core/services/job_request_service.dart';
import '../../providers/phone_auth_provider.dart';
import '../../providers/skilled_worker_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String role =
        args != null && args['role'] != null
            ? args['role'] as String
            : 'job_poster';
    final String description =
        role == 'skilled_worker'
            ? 'Enter your mobile number to join as a Skilled Worker.'
            : 'Enter your mobile number to join as a Job Poster.';

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
                  Text(
                    'Welcome to Skillzaar',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Mobile Number',
                      style: TextStyle(
                        color: Colors.green.shade700,
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
                      prefixIcon: const Icon(Icons.phone, color: Colors.green),
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
                                  final userType =
                                      role == 'skilled_worker'
                                          ? 'skilled_worker'
                                          : 'job_poster';

                                  print('🔍 Checking user existence:');
                                  print('📱 Formatted phone: $formattedPhone');
                                  print('👤 User type: $userType');

                                  final userExists =
                                      await UserDataService.userExistsByPhone(
                                        phoneNumber: formattedPhone,
                                        userType: userType,
                                      );

                                  print('✅ User exists: $userExists');
                                  print(
                                    '📱 Checking for user with phone: $formattedPhone in collection: $userType',
                                  );

                                  if (userExists) {
                                    print(
                                      '🏠 Navigating to home screen for $userType',
                                    );

                                    // Get user data to get the actual user ID
                                    final userData =
                                        await UserDataService.getUserDataByPhone(
                                          phoneNumber: formattedPhone,
                                          userType: userType,
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
                                          '${userType}_${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}_${DateTime.now().millisecondsSinceEpoch}';
                                    }

                                    // Set authentication state in providers
                                    if (role == 'skilled_worker') {
                                      final skilledWorkerProvider =
                                          Provider.of<SkilledWorkerProvider>(
                                            context,
                                            listen: false,
                                          );
                                      // Set logged in state for skilled worker
                                      skilledWorkerProvider.setLoggedInState(
                                        userId: userId,
                                        phoneNumber: formattedPhone,
                                      );

                                      Navigator.pushNamedAndRemoveUntil(
                                        context,
                                        '/skilled-worker-home',
                                        (route) => false,
                                      );
                                    } else {
                                      final phoneAuthProvider =
                                          Provider.of<PhoneAuthProvider>(
                                            context,
                                            listen: false,
                                          );
                                      // Set logged in state for job poster
                                      phoneAuthProvider.setLoggedInState(
                                        userId: userId,
                                        phoneNumber: formattedPhone,
                                      );

                                      // Check for active job after successful login
                                      await _checkForActiveJobPoster(
                                        context,
                                        phoneAuthProvider,
                                      );
                                    }
                                  } else {
                                    print(
                                      '📝 User not found, showing register message',
                                    );
                                    // User is not registered, show register message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
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
                        if (role == 'skilled_worker') {
                          // Send OTP for skilled worker and navigate to OTP screen
                          final provider = Provider.of<SkilledWorkerProvider>(
                            context,
                            listen: false,
                          );
                          provider.verifyPhone(input);
                          await Future.delayed(
                            const Duration(milliseconds: 100),
                          );
                          if (context.mounted && provider.error == null) {
                            Navigator.pushNamed(
                              context,
                              '/skilled-worker-otp',
                              arguments: {'phone': input},
                            );
                          } else if (context.mounted &&
                              provider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(provider.error!)),
                            );
                          }
                        } else {
                          // Send OTP for job poster and navigate to OTP screen
                          final phoneAuthProvider =
                              Provider.of<PhoneAuthProvider>(
                                context,
                                listen: false,
                              );
                          phoneAuthProvider.sendOtp(input, context);

                          // If there was an error, show it
                          if (context.mounted &&
                              phoneAuthProvider.error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  phoneAuthProvider.error ?? 'Error',
                                ),
                              ),
                            );
                          }
                        }
                        */
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(fontSize: 15),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (role == 'skilled_worker') {
                            Navigator.pushNamed(
                              context,
                              '/skilled-worker-signup',
                            );
                          } else {
                            Navigator.pushNamed(context, '/job-poster-signup');
                          }
                        },
                        child: const Text(
                          'Sign up',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'By signing up, you accept our Terms & Privacy Policy.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkForActiveJobPoster(
    BuildContext context,
    PhoneAuthProvider phoneAuthProvider,
  ) async {
    try {
      print('[Login Screen] Checking for active job after job poster login...');

      final jobPosterId = phoneAuthProvider.loggedInUserId;
      final jobPosterPhone = phoneAuthProvider.loggedInPhoneNumber;

      if (jobPosterId == null || jobPosterId.isEmpty) {
        // No user ID, go to home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-home',
          (route) => false,
        );
        return;
      }

      // Check for active job
      final active = await JobRequestService.getActiveRequestForPoster(
        jobPosterId,
        posterPhone: jobPosterPhone,
      );

      print('[Login Screen] Active job result: $active');

      if (active != null) {
        final jobId = active['jobId'] as String?;
        final requestId = active['requestId'] as String?;
        final status = active['status'] as String?;

        if (jobId != null && jobId.isNotEmpty) {
          print(
            '[Login Screen] Found active job - JobId: $jobId, Status: $status',
          );

          // Redirect based on job status
          if (status == 'in_progress') {
            // In progress jobs go to job detail screen
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/job-poster-job-detail',
              (route) => false,
              arguments: {'jobId': jobId, 'requestId': requestId},
            );
            return;
          } else if (status == 'accepted') {
            // Accepted jobs go to accepted details screen
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/job-poster-accepted-details',
              (route) => false,
              arguments: {'jobId': jobId, 'requestId': requestId},
            );
            return;
          }
        }
      }

      // No active job found, proceed to home screen
      print('[Login Screen] No active job found, going to home screen');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/job-poster-home',
        (route) => false,
      );
    } catch (e) {
      print('[Login Screen] Error checking for active job: $e');
      // On error, proceed to home screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/job-poster-home',
        (route) => false,
      );
    }
  }
}
