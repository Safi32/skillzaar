import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/auth_state_provider.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late final AuthStateProvider auth;
  bool _sending = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // init in didChangeDependencies would also work; we use this to cache provider
    // but DO NOT call provider methods here that depend on context (we don't).
     auth = Provider.of<AuthStateProvider>(context, listen: false);
  }


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
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String role) async {
    setState(() {
      isLoading = true;
    });

    if (role == "skilled_worker") {
      final raw = phoneController.text.trim();
      final password = passwordController.text.trim();
      if (raw.isEmpty) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')),
        );
        return;
      }
      if (!isValidPhoneNumber(raw)) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number must be valid')),
        );
        return;
      }
      if (password.isEmpty) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password')),
        );
        return;
      }

      final phone = formatPhoneNumber(raw);

      setState(() => _sending = true);
      final error = await auth.loginSkilledWorker(phone, password);
      setState(() => _sending = false);

      if (error != null) {
        setState(() {
  isLoading = false;
});
    
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }

      // After successful login, ask provider where to go
      final next = await auth.determineNextScreen();
      if (!mounted) return;

      switch (next) {
        case NextScreen.activeJobSkilledWorker:
          // Fetch the active assigned job so we can pass a valid assignedJobId
          final workerId = auth.userId;
          if (workerId != null && workerId.isNotEmpty) {
            final assignedJob =
                await JobRequestService.getActiveAssignedJobForWorker(workerId);

            final assignedJobId =
                assignedJob != null ? assignedJob['assignedJobId'] as String? : null;

            if (assignedJobId != null && assignedJobId.isNotEmpty) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/assigned-job-detail',
                (r) => false,
                arguments: {
                  'assignedJobId': assignedJobId,
                  'userType': 'skilled_worker',
                },
              );
              break;
            }
          }
          // Fallback: if for some reason we couldn't resolve an assigned job, go home
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/skilled-worker-home',
            (r) => false,
          );
          break;
        case NextScreen.homeSkilledWorker:
        default:
          Navigator.pushNamedAndRemoveUntil(context, '/skilled-worker-home', (r) => false);
      }
    } else {
      // job_poster -> phone/password login
      final raw = phoneController.text.trim();
      final password = passwordController.text.trim();

      if (raw.isEmpty) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your phone number')),
        );
        return;
      }

      if (!isValidPhoneNumber(raw)) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number must be valid')),
        );
        return;
      }

      if (password.isEmpty) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your password')),
        );
        return;
      }

      final phone = formatPhoneNumber(raw);

      setState(() => _sending = true);
      final error = await auth.loginJobPosterWithPhonePassword(phone, password);
      setState(() => _sending = false);

      if (error != null) {
        setState(() {
          isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }

      if (!mounted) return;

      // After successful login, route based on next screen
      final next = await auth.determineNextScreen();
      switch (next) {
        case NextScreen.activeJobJobPoster:
          // Best-effort: try to resolve active job and open details
          final userId = auth.userId;
          if (userId != null && userId.isNotEmpty) {
            try {
              final active = await JobRequestService.getActiveRequestForPoster(
                userId,
              );
              final jobId = active != null ? active['jobId']?.toString() : null;
              final requestId =
                  active != null ? active['requestId']?.toString() : null;

              if (jobId != null && jobId.isNotEmpty) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/job-poster-accepted-details',
                  (route) => false,
                  arguments: {
                    'jobId': jobId,
                    'requestId': requestId ?? '',
                  },
                );
                setState(() {
                  isLoading = false;
                });
                return;
              }
            } catch (_) {
              // Fallback handled below
            }
          }

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-home',
            (route) => false,
          );
          break;

        case NextScreen.completeProfile:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-profile',
            (route) => false,
          );
          break;

        case NextScreen.homeJobPoster:
        default:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-home',
            (route) => false,
          );
          break;
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String role = args?['role'] ?? 'job_poster';
    final String description = role == 'skilled_worker'
        ? 'Enter your mobile number and password to login as a Skilled Worker.'
        : 'Enter your mobile number and password to login as a Job Poster.';
    final size = MediaQuery.of(context).size;

    // show loading when provider status is loggingIn OR our local _sending
   

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
                        // Phone/password fields
                        if (role == 'skilled_worker') ...[
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Mobile Number",
                              labelStyle: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: "Enter your phone number",
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
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: "Enter your password",
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: Icon(
                                Icons.lock,
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
                        ]
                        else ...[
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: "Mobile Number",
                              labelStyle: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: "Enter your phone number",
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
                          const SizedBox(height: 16),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: "Password",
                              labelStyle: TextStyle(
                                color: AppColors.green,
                                fontWeight: FontWeight.w600,
                              ),
                              hintText: "Enter your password",
                              filled: true,
                              fillColor: Colors.grey[100],
                              prefixIcon: Icon(
                                Icons.lock,
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
                        ],
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
                                (isLoading || _sending) ? null : () => _handleLogin(role),
                            child: (isLoading || _sending)
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
                                    Navigator.pushNamed(context, '/job-poster-signup');
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
}
