import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class SkilledWorkerLoginScreen extends StatefulWidget {
  const SkilledWorkerLoginScreen({super.key});

  @override
  State<SkilledWorkerLoginScreen> createState() =>
      _SkilledWorkerLoginScreenState();
}

class _SkilledWorkerLoginScreenState extends State<SkilledWorkerLoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isLoading = false;

  bool isValidPhoneNumber(String phone) {
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
    final l10n = AppLocalizations.of(context)!;

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
                Text(
                  l10n.skilledWorkerLogin,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.enterPhoneLoginWorkerDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: Colors.black),
                ),
                const SizedBox(height: 24),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l10n.mobileNumber,
                        hintText: l10n.enterPhoneHint,
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
                                    SnackBar(
                                      content: Text(l10n.pleaseEnterPhone),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                // Validate phone number length (minimum 11 digits)
                                if (!isValidPhoneNumber(input)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.phoneValidError),
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

                                    print(
                                      '✅ Admin-created account - logging in directly',
                                    );

                                    // Check for active job after successful login
                                    await _checkForActiveJobSkilledWorker(
                                      context,
                                      skilledWorkerProvider,
                                    );
                                  } else {
                                    print(
                                      '📝 Skilled worker not found, showing register message',
                                    );
                                    // User is not registered, show register message
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.noAccountFoundWorker,
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.errorCheckingAccount(
                                            e.toString(),
                                          ),
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
                              : Text(
                                l10n.continueGuest,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Signup option removed - skilled worker accounts are created by admin
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkForActiveJobSkilledWorker(
    BuildContext context,
    SkilledWorkerProvider skilledWorkerProvider,
  ) async {
    try {
      print('[Skilled Worker Login] Checking for active job after login...');

      final skilledWorkerId = skilledWorkerProvider.loggedInUserId;
      final skilledWorkerPhone = skilledWorkerProvider.loggedInPhoneNumber;

      if (skilledWorkerId == null || skilledWorkerId.isEmpty) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/skilled-worker-home',
          (route) => false,
        );
        return;
      }

      // Check for active assigned job
      final assignedJob = await JobRequestService.getActiveAssignedJobForWorker(
        skilledWorkerId,
      );

      print('[Skilled Worker Login] Active assigned job result: $assignedJob');

      if (assignedJob != null) {
        final assignedJobId = assignedJob['assignedJobId'] as String?;
        final status = assignedJob['status'] as String?;

        if (assignedJobId != null && assignedJobId.isNotEmpty) {
          print(
            '[Skilled Worker Login] Found active assigned job - AssignedJobId: $assignedJobId, Status: $status',
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

      // Check for completed job that needs worker rating
      print(
        '[Skilled Worker Login] Checking for completed job needing worker rating...',
      );
      final completedJob =
          await JobRequestService.getCompletedJobNeedingWorkerRating(
            skilledWorkerId,
          );

      print(
        '[Skilled Worker Login] Completed job needing rating result: $completedJob',
      );

      if (completedJob != null) {
        final assignedJobId = completedJob['assignedJobId'] as String?;
        final jobTitle = completedJob['jobTitle'] as String?;
        final assignmentStatus = completedJob['assignmentStatus'] as String?;
        final workerRatingCompleted =
            completedJob['workerRatingCompleted'] as bool?;

        print('[Skilled Worker Login] Job details:');
        print('  - AssignedJobId: $assignedJobId');
        print('  - Job Title: $jobTitle');
        print('  - Assignment Status: $assignmentStatus');
        print('  - Worker Rating Completed: $workerRatingCompleted');

        if (assignedJobId != null && assignedJobId.isNotEmpty) {
          print(
            '[Skilled Worker Login] Found completed job needing rating - AssignedJobId: $assignedJobId',
          );

          // Navigate to job poster rating screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/rate-job-poster',
            (route) => false,
            arguments: {
              'assignedJobId': assignedJobId,
              'isJobCompletion': true,
            },
          );
          return;
        }
      } else {
        print('[Skilled Worker Login] No completed job needing rating found');
      }

      // No active job found, proceed to home screen
      print('[Skilled Worker Login] No active job found, going to home screen');
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-home',
        (route) => false,
      );
    } catch (e) {
      print('[Skilled Worker Login] Error checking for active job: $e');
      // On error, go to home screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-home',
        (route) => false,
      );
    }
  }
}
