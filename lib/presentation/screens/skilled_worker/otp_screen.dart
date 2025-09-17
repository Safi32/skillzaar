import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/job_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SkilledWorkerOTPScreen extends StatefulWidget {
  const SkilledWorkerOTPScreen({super.key});

  @override
  State<SkilledWorkerOTPScreen> createState() => _SkilledWorkerOTPScreenState();
}

class _SkilledWorkerOTPScreenState extends State<SkilledWorkerOTPScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    setState(() {}); // Ensure UI updates for button state
    if (value.length == 1 && index < 5) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }
  }

  String get otpCode =>
      otpControllers.map((controller) => controller.text).join();

  Future<void> _checkForActiveJob(
    BuildContext context,
    SkilledWorkerProvider provider,
  ) async {
    try {
      print('[OTP Screen] Checking for active job after login...');

      // Check SharedPreferences first
      final prefs = await SharedPreferences.getInstance();
      final spKey = 'active_job_${provider.loggedInUserId!}';
      final spActive = prefs.getBool(spKey) ?? false;
      final spJobId = prefs.getString('${spKey}_jobId');

      print('[OTP Screen] SharedPrefs - Active: $spActive, JobId: $spJobId');

      if (spActive && spJobId != null && spJobId.isNotEmpty) {
        // Get job details and navigate to job detail screen
        final job = await JobRequestService.getJobDetails(spJobId);
        if (job != null) {
          print(
            '[OTP Screen] Found active job via SharedPrefs, redirecting...',
          );
          Navigator.pushReplacementNamed(
            context,
            '/skilled-worker-job-detail',
            arguments: {
              'imageUrl': job['Image'] ?? '',
              'title': job['title_en'] ?? job['title_ur'] ?? '',
              'location': job['Address'] ?? job['Location'] ?? '',
              'date': DateTime.tryParse(
                (job['createdAt']?.toDate()?.toString()) ?? '',
              ),
              'description':
                  job['description_en'] ?? job['description_ur'] ?? '',
              'jobId': spJobId,
              'jobPosterId': job['jobPosterId'] ?? '',
            },
          );
          return;
        }
      }

      // Fallback: Check Firebase for active job
      final active = await JobRequestService.getActiveRequestForWorker(
        provider.loggedInUserId!,
        skilledWorkerPhone: provider.loggedInPhoneNumber,
      );

      print('[OTP Screen] Firebase active job result: $active');

      if (active != null) {
        final job = await JobRequestService.getJobDetails(active['jobId']);
        if (job != null) {
          print('[OTP Screen] Found active job via Firebase, redirecting...');
          Navigator.pushReplacementNamed(
            context,
            '/skilled-worker-job-detail',
            arguments: {
              'imageUrl': job['Image'] ?? '',
              'title': job['title_en'] ?? job['title_ur'] ?? '',
              'location': job['Address'] ?? job['Location'] ?? '',
              'date': DateTime.tryParse(
                (job['createdAt']?.toDate()?.toString()) ?? '',
              ),
              'description':
                  job['description_en'] ?? job['description_ur'] ?? '',
              'jobId': active['jobId'],
              'jobPosterId': active['jobPosterId'],
              'requestId': active['requestId'],
            },
          );
          return;
        }
      }

      // No active job found, proceed to home screen
      print('[OTP Screen] No active job found, going to home screen');
      Navigator.pushReplacementNamed(
        context,
        '/skilled-worker-home',
        arguments: {'userId': provider.loggedInUserId},
      );
    } catch (e) {
      print('[OTP Screen] Error checking for active job: $e');
      // On error, proceed to home screen
      Navigator.pushReplacementNamed(
        context,
        '/skilled-worker-home',
        arguments: {'userId': provider.loggedInUserId},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final skilledWorkerProvider = Provider.of<SkilledWorkerProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: size.width * 0.08,
            vertical: size.height * 0.08,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Icon(Icons.verified_user_outlined, size: 64, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the 6-digit code sent to your phone',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 50,
                    height: 60,
                    child: TextField(
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

              // Resend OTP Button
              TextButton(
                onPressed: () {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  final phone = args?['phone'] as String?;
                  if (phone != null && phone.isNotEmpty) {
                    Provider.of<SkilledWorkerProvider>(
                      context,
                      listen: false,
                    ).verifyPhone(phone);
                  }
                },
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      otpCode.length == 6 && !skilledWorkerProvider.isLoading
                          ? () async {
                            setState(() {});
                            // Get phone number from arguments
                            final args =
                                ModalRoute.of(context)?.settings.arguments
                                    as Map<String, dynamic>?;
                            final phoneNumber = args?['phone'] ?? '';
                            final isSignUp = args?['isSignUp'] == true;

                            final loginSuccess = await skilledWorkerProvider
                                .login(phoneNumber, otpCode);
                            if (loginSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '✅ Login successful! Welcome back.',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );

                              if (isSignUp) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/skilled-worker-cnic',
                                );
                              } else {
                                // Check for active job after successful login
                                await _checkForActiveJob(
                                  context,
                                  skilledWorkerProvider,
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    skilledWorkerProvider.error ??
                                        '❌ Login failed. Use 123456 for testing.',
                                  ),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              setState(() {}); // To show error
                            }
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 1,
                  ),
                  child:
                      skilledWorkerProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 24),

              // Error message
              if (skilledWorkerProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    skilledWorkerProvider.error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
