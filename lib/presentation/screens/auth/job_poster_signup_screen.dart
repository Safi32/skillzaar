import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import 'package:skillzaar/core/theme/app_theme.dart';
import '../../providers/phone_auth_provider.dart';

class JobPosterSignUpScreen extends StatefulWidget {
  const JobPosterSignUpScreen({Key? key}) : super(key: key);

  @override
  State<JobPosterSignUpScreen> createState() => _JobPosterSignUpScreenState();
}

class _JobPosterSignUpScreenState extends State<JobPosterSignUpScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  bool isValidPhoneNumber(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleanPhone.length == 11 && cleanPhone.startsWith('0')) return true;
    if (cleanPhone.length == 10) return true;
    if (cleanPhone.length == 12 && cleanPhone.startsWith('92')) return true;
    if (cleanPhone.length == 13 && cleanPhone.startsWith('+92')) return true;
    return false;
  }

  String formatPhoneNumber(String input) {
    input = input.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (input.startsWith('+')) return input;
    if (input.startsWith('0') && input.length == 11) {
      return '+92${input.substring(1)}';
    }
    if (input.startsWith('92') && input.length == 12) {
      return '+$input';
    }
    if (input.length == 10) {
      return '+92$input';
    }
    if (input.length == 11 && !input.startsWith('0')) {
      return '+92$input';
    }
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
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.25,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 12.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios),
                  color: AppColors.green,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // App Logo on top-right
            Positioned(
              top: 20,
              right: 20,
              child: Image.asset(
                'assets/applogo.png', // your app logo path
                height: 128,
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Consumer<PhoneAuthProvider>(
                  builder: (context, phoneAuthProvider, _) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Page Title
                        Text(
                          'Create an Account',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join Skillzaar as a Job Poster',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // Label
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Mobile Number',
                            style: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Phone Input
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '03XXXXXXXXX',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: AppColors.green,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.phone_rounded,
                              color: AppColors.green,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Continue Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.green.withOpacity(0.4),
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
                                      if (!isValidPhoneNumber(phone)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Invalid phone number',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      setState(() => isLoading = true);

                                      try {
                                        final formattedPhone =
                                            formatPhoneNumber(phone);

                                        final userExists =
                                            await UserDataService.userExistsByPhone(
                                              phoneNumber: formattedPhone,
                                              userType: 'job_poster',
                                            );

                                        if (userExists) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'User already exists. Please login.',
                                              ),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          setState(() => isLoading = false);
                                          return;
                                        }

                                        // Start OTP signup flow for job poster
                                        final phoneAuthProvider =
                                            Provider.of<PhoneAuthProvider>(
                                              context,
                                              listen: false,
                                            );
                                        phoneAuthProvider.sendOtp(
                                          formattedPhone,
                                          context,
                                          isSignUp: true,
                                        );
                                        // Navigation now handled in provider after OTP is sent
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
                                        if (mounted)
                                          setState(() => isLoading = false);
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
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Terms
                        Text(
                          'By signing up, you agree to our\nTerms of Service & Privacy Policy',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.15,
              right: -size.width * 0.25,
              child: Container(
                width: size.width * 0.8,
                height: size.width * 0.8,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
