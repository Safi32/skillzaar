import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import 'package:skillzaar/presentation/providers/phone_auth_provider.dart';
import 'package:skillzaar/presentation/providers/skilled_worker_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_toast.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    if (input.startsWith('92') && input.length == 12) return '+$input';
    if (input.length == 10) return '+92$input';
    if (input.length == 11 && !input.startsWith('0')) return '+92$input';
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
    final String role = args?['role'] ?? 'job_poster';
    final String description =
        role == 'skilled_worker'
            ? 'Enter your mobile number to login as a Skilled Worker.'
            : 'Enter your mobile number to join as a Job Poster.';
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Green accent shape at top
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
            // Top-right app logo
            Positioned(
              top: 16,
              right: 16,
              child: SizedBox(
                height: 80,
                width: 80,
                child: Image.asset("assets/applogo.png", fit: BoxFit.contain),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 12,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Title
                        Flexible(
                          child: Text(
                            "Welcome to Skillzaar",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Phone field
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Mobile Number",
                            labelStyle: TextStyle(
                              color: AppColors.green,
                              fontWeight: FontWeight.w600,
                            ),
                            hintText: "03XXXXXXXXX",
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.phone,
                              color: AppColors.green,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.green,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.green.withOpacity(0.5),
                            ),
                            onPressed:
                                isLoading ? null : () => _handleLogin(role),
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
                                    : Text(
                                      "Continue",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Signup link
                        if (role == 'job_poster')
                          Flexible(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    "Don't have an account? ",
                                    style: TextStyle(fontSize: 15),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/job-poster-signup',
                                    );
                                  },
                                  child: Text(
                                    "Sign up",
                                    style: TextStyle(
                                      color: AppColors.green,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        Flexible(
                          child: Text(
                            "By signing up, you accept our Terms & Privacy Policy.",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Future<void> _handleLogin(String role) async {
    final input = phoneController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!isValidPhoneNumber(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number must be at least 11 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final formattedPhone = formatPhoneNumber(input);

      // Check if user is already registered
      final userType =
          role == 'skilled_worker' ? 'skilled_worker' : 'job_poster';

      print('🔍 Checking user existence:');
      print('📱 Formatted phone: $formattedPhone');
      print('👤 User type: $userType');

      final userExists = await UserDataService.userExistsByPhone(
        phoneNumber: formattedPhone,
        userType: userType,
      );

      print('✅ User exists: $userExists');
      print(
        '📱 Checking for user with phone: $formattedPhone in collection: $userType',
      );

      if (userExists) {
        if (role == 'skilled_worker') {
          // Skilled worker continues with direct login (admin-created accounts)
          print('🏠 Skilled worker exists; logging in directly');

          // Get user data to get the actual user ID
          final userData = await UserDataService.getUserDataByPhone(
            phoneNumber: formattedPhone,
            userType: userType,
          );

          String userId;
          if (userData != null && userData.exists) {
            userId = userData.id;
          } else {
            userId =
                '${userType}_${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}_${DateTime.now().millisecondsSinceEpoch}';
          }

          final skilledWorkerProvider = Provider.of<SkilledWorkerProvider>(
            context,
            listen: false,
          );
          skilledWorkerProvider.setLoggedInState(
            userId: userId,
            phoneNumber: formattedPhone,
          );

          // Show portfolio setup reminder for skilled workers
          ToastOverlay.instance.showToast(
            context: context,
            title: 'Portfolio Required',
            message:
                'Please complete your portfolio first. Without a portfolio, jobs cannot be assigned to you.',
            type: ToastType.warning,
            duration: const Duration(seconds: 4),
          );

          await _checkForActiveJobSkilledWorker(context, skilledWorkerProvider);
        } else {
          // Job poster now uses OTP flow
          print('📨 Sending OTP to existing job poster: $formattedPhone');
          final phoneAuthProvider = Provider.of<PhoneAuthProvider>(
            context,
            listen: false,
          );
          phoneAuthProvider.sendOtp(formattedPhone, context);
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/job-poster-otp',
              arguments: {'phoneNumber': formattedPhone, 'isSignUp': false},
            );
          }
        }
      } else {
        print('📝 User not found, showing register message');
        if (role == 'skilled_worker') {
          // Skilled workers cannot self-register
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No account found with this phone number. Please contact admin to create your skilled worker account.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          // Job poster: start OTP for registration
          final formatted = formattedPhone;
          final phoneAuthProvider = Provider.of<PhoneAuthProvider>(
            context,
            listen: false,
          );
          print('📝 New job poster; sending OTP for signup: $formatted');
          phoneAuthProvider.sendOtp(formatted, context, isSignUp: true);
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/job-poster-otp',
              arguments: {'phoneNumber': formatted, 'isSignUp': true},
            );
          }
        }
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _checkForActiveJobSkilledWorker(
    BuildContext context,
    SkilledWorkerProvider skilledWorkerProvider,
  ) async {
    try {
      print(
        '[Login Screen] Checking for active job after skilled worker login...',
      );

      final skilledWorkerId = skilledWorkerProvider.loggedInUserId;

      if (skilledWorkerId == null || skilledWorkerId.isEmpty) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/skilled-worker-home',
          (route) => false,
        );
        return;
      }

      // Check for active assigned job
      print(
        '[Login Screen] Checking for assigned job with skilledWorkerId: $skilledWorkerId',
      );
      final assignedJob = await JobRequestService.getActiveAssignedJobForWorker(
        skilledWorkerId,
      );

      print('[Login Screen] Active assigned job result: $assignedJob');

      if (assignedJob != null) {
        final assignedJobId = assignedJob['assignedJobId'] as String?;
        final status = assignedJob['status'] as String?;

        if (assignedJobId != null && assignedJobId.isNotEmpty) {
          print(
            '[Login Screen] Found active assigned job - AssignedJobId: $assignedJobId, Status: $status',
          );

          // Navigate to assigned job detail screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/assigned-job-detail',
            (route) => false,
            arguments: {
              'assignedJobId': assignedJobId,
              'userType': 'skilled_worker',
            },
          );
          return;
        }
      }

      // No active job found, proceed to home screen
      print('[Login Screen] No active job found, going to home screen');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-home',
        (route) => false,
      );
    } catch (e) {
      print('[Login Screen] Error checking for active job: $e');
      // On error, go to home screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-home',
        (route) => false,
      );
    }
  }
}
