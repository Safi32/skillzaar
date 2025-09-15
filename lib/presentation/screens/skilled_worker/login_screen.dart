import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/job_request_service.dart';
import 'job_detail_screen.dart';
import 'skilled_worker_home_screen.dart';

class SkilledWorkerLoginScreen extends StatefulWidget {
  const SkilledWorkerLoginScreen({super.key});

  @override
  State<SkilledWorkerLoginScreen> createState() =>
      _SkilledWorkerLoginScreenState();
}

class _SkilledWorkerLoginScreenState extends State<SkilledWorkerLoginScreen> {
  final TextEditingController phoneController = TextEditingController();

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
                      enabled: !skilledWorkerProvider.isLoading,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (skilledWorkerProvider.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      skilledWorkerProvider.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          skilledWorkerProvider.isLoading
                              ? null
                              : () async {
                                final rawInput = phoneController.text.trim();
                                if (rawInput.isEmpty) {
                                  context.read<UIStateProvider>().showWarningToast(
                                    context,
                                    'Phone Required',
                                    'Please enter a phone number to continue.',
                                  );
                                  return;
                                }

                                // For now, directly navigate to home screen
                                // In real app, you would verify the phone number first

                                // Show success toast
                                context
                                    .read<UIStateProvider>()
                                    .showSuccessToast(
                                      context,
                                      'Welcome Back!',
                                      'Successfully logged in to your account.',
                                    );

                                // Wait a bit for user to read the toast
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );

                                // Check for any accepted job request for this worker
                                final skilledWorkerId =
                                    await JobRequestService.getSkilledWorkerId() ??
                                    'TEST_SKILLED_WORKER_ID';
                                final acceptedRequest =
                                    await JobRequestService.getAcceptedRequestForWorker(
                                      skilledWorkerId,
                                    );

                                if (acceptedRequest != null) {
                                  final jobId =
                                      acceptedRequest['jobId'] as String;
                                  final jobData =
                                      await JobRequestService.getJobDetails(
                                        jobId,
                                      ) ??
                                      {};
                                  final imageUrl =
                                      (jobData['ImageUrl'] ??
                                              jobData['imageUrl'] ??
                                              '')
                                          .toString();
                                  final title =
                                      (jobData['JobTitle'] ??
                                              jobData['title'] ??
                                              'Job')
                                          .toString();
                                  final location =
                                      (jobData['JobAddress'] ??
                                              jobData['location'] ??
                                              '')
                                          .toString();
                                  final description =
                                      (jobData['Description'] ??
                                              jobData['description'] ??
                                              '')
                                          .toString();
                                  final jobPosterId =
                                      (jobData['jobPosterId'] ?? '').toString();

                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder:
                                          (_) => JobDetailScreen(
                                            imageUrl: imageUrl,
                                            title: title,
                                            location: location,
                                            date: null,
                                            description: description,
                                            jobId: jobId,
                                            jobPosterId: jobPosterId,
                                          ),
                                    ),
                                  );
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              const SkilledWorkerHomeScreen(),
                                    ),
                                  );
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
                          skilledWorkerProvider.isLoading
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
