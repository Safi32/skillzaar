import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/auth_state_provider.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  late final AuthStateProvider auth;
  bool _sending = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    auth = Provider.of<AuthStateProvider>(context, listen: false);
  }

  bool _isValidPhone(String phone) {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.length == 11 && clean.startsWith('0')) return true;
    if (clean.length == 10) return true;
    if (clean.length == 12 && clean.startsWith('92')) return true;
    if (clean.length == 13 && clean.startsWith('+92')) return true;
    return false;
  }

  String _formatPhone(String input) {
    input = input.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (input.startsWith('+')) return input;
    if (input.startsWith('0') && input.length == 11)
      return '+92${input.substring(1)}';
    if (input.startsWith('92') && input.length == 12) return '+$input';
    if (input.length == 10) return '+92$input';
    if (input.length == 11 && !input.startsWith('0')) return '+92$input';
    return input;
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String role) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final phone = _formatPhone(phoneController.text.trim());
    final password = passwordController.text.trim();

    if (role == 'skilled_worker') {
      setState(() => _sending = true);
      final error = await auth.loginSkilledWorker(phone, password);
      setState(() => _sending = false);

      if (error != null) {
        setState(() => isLoading = false);
        if (mounted) _showError(error);
        return;
      }

      final next = await auth.determineNextScreen();
      if (!mounted) return;

      switch (next) {
        case NextScreen.activeJobSkilledWorker:
          final workerId = auth.userId;
          if (workerId != null && workerId.isNotEmpty) {
            final assignedJob =
                await JobRequestService.getActiveAssignedJobForWorker(workerId);
            final assignedJobId = assignedJob?['assignedJobId'] as String?;
            if (assignedJobId != null && assignedJobId.isNotEmpty && mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/assigned-job-detail',
                (r) => false,
                arguments: {
                  'assignedJobId': assignedJobId,
                  'userType': 'skilled_worker',
                },
              );
              return;
            }
          }
          if (mounted)
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/skilled-worker-home',
              (r) => false,
            );
          break;
        case NextScreen.homeSkilledWorker:
        default:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/skilled-worker-home',
            (r) => false,
          );
      }
    } else {
      setState(() => _sending = true);
      final error = await auth.loginJobPosterWithPhonePassword(phone, password);
      setState(() => _sending = false);

      if (error != null) {
        setState(() => isLoading = false);
        if (mounted) _showError(error);
        return;
      }

      if (!mounted) return;
      final next = await auth.determineNextScreen();
      if (!mounted) return;

      switch (next) {
        case NextScreen.activeJobJobPoster:
          final userId = auth.userId;
          if (userId != null && userId.isNotEmpty) {
            try {
              final active = await JobRequestService.getActiveRequestForPoster(
                userId,
              );
              final jobId = active?['jobId']?.toString();
              final requestId = active?['requestId']?.toString();
              if (jobId != null && jobId.isNotEmpty && mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/job-poster-accepted-details',
                  (route) => false,
                  arguments: {'jobId': jobId, 'requestId': requestId ?? ''},
                );
                setState(() => isLoading = false);
                return;
              }
            } catch (_) {}
          }
          if (mounted)
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
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final l10n = AppLocalizations.of(context)!;
    final String role = args?['role'] ?? 'job_poster';
    final String description =
        role == 'skilled_worker'
            ? l10n.loginAsSkilledWorkerDesc
            : l10n.loginAsJobPosterDesc;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.25,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(19, 185, 75, 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.15,
            right: -size.width * 0.25,
            child: Container(
              width: size.width * 0.8,
              height: size.width * 0.8,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(19, 185, 75, 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          color: AppColors.green,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Image.asset(
                            'assets/applogo.png',
                            height: 52,
                            width: 52,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n.welcomeToSkillzaar,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.green,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 32),
                            // Phone field
                            TextFormField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: l10n.mobileNumber,
                                labelStyle: const TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                hintText: l10n.enterPhoneHint,
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: const Icon(
                                  Icons.phone,
                                  color: AppColors.green,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.green,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                final v = value?.trim() ?? '';
                                if (v.isEmpty)
                                  return 'Phone number is required';
                                if (!_isValidPhone(v))
                                  return 'Enter a valid Pakistani phone number';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Password field
                            TextFormField(
                              controller: passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: l10n.password,
                                labelStyle: const TextStyle(
                                  color: AppColors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                                hintText: l10n.enterPasswordHint,
                                filled: true,
                                fillColor: Colors.grey[100],
                                prefixIcon: const Icon(
                                  Icons.lock,
                                  color: AppColors.green,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.green,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty)
                                  return 'Password is required';
                                if (value.length < 6)
                                  return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
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
                                  shadowColor: const Color.fromRGBO(
                                    19,
                                    185,
                                    75,
                                    0.5,
                                  ),
                                ),
                                onPressed:
                                    (isLoading || _sending)
                                        ? null
                                        : () => _handleLogin(role),
                                child:
                                    (isLoading || _sending)
                                        ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : Text(
                                          l10n.loginButton,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (role == 'job_poster')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      "${l10n.dontHaveAccount} ",
                                      style: const TextStyle(fontSize: 15),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap:
                                        () => Navigator.pushNamed(
                                          context,
                                          '/job-poster-signup',
                                        ),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: AppColors.green,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.termsPolicyAccept,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
