import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import 'package:skillzaar/core/theme/app_theme.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import '../../providers/phone_auth_provider.dart';
import '../../providers/auth_state_provider.dart';
import '../job_poster/otp_screen.dart';

class JobPosterSignUpScreen extends StatefulWidget {
  const JobPosterSignUpScreen({super.key});

  @override
  State<JobPosterSignUpScreen> createState() => _JobPosterSignUpScreenState();
}

class _JobPosterSignUpScreenState extends State<JobPosterSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _isValidPhone(String v) {
    final c = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return (c.length == 11 && c.startsWith('0')) ||
        c.length == 10 ||
        (c.length == 12 && c.startsWith('92')) ||
        (c.length == 13 && c.startsWith('+92'));
  }

  bool _isValidEmail(String v) =>
      RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final l10n = AppLocalizations.of(context)!;
    final pap = Provider.of<PhoneAuthProvider>(context, listen: false);
    final phone = formatPhoneNumber(_phoneCtrl.text.trim());

    try {
      // 1. Check duplicate
      final exists = await UserDataService.userExistsByPhone(
        phoneNumber: phone,
        userType: 'job_poster',
      );
      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.userExistsError),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // 2. Store pending profile
      pap.setPendingJobPosterProfile(
        displayName: _usernameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // 3. Send OTP — await the verificationId directly
      print('🚀 About to call sendOtp for: $phone');
      final verificationId = await pap.sendOtp(phone);
      print('✅ sendOtp returned verificationId: $verificationId');

      if (!mounted) return;

      // Handle auto-verification case
      if (verificationId == '__auto__') {
        print(
          '🔄 Auto-verification detected, proceeding directly to verification',
        );
        // Auto-verification happened, proceed directly to OTP verification
        // This simulates entering a dummy OTP since it's already verified
        final auth = Provider.of<AuthStateProvider>(context, listen: false);
        await auth.setJobPosterSignedIn(
          id: pap.loggedInUserId!,
          name: pap.pendingDisplayName ?? pap.loggedInPhoneNumber,
          phone: pap.loggedInPhoneNumber,
        );

        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-home',
          (_) => false,
        );
        return;
      }

      // 4. Navigate to OTP screen, passing verificationId as a constructor param
      print('🧭 Navigating to OTP screen...');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => JobPosterOtpScreen(
                phone: phone,
                verificationId: verificationId,
                isSignUp: true,
              ),
        ),
      );
      print('✅ Navigation completed');
    } catch (e) {
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('app-not-authorized')) {
          errorMessage =
              'Firebase configuration error. Please check SHA-1 fingerprint in Firebase Console.';
        } else if (e.toString().contains('network-request-failed')) {
          errorMessage =
              'Network error. Please check your internet connection.';
        } else if (e.toString().contains('captcha-check-failed')) {
          errorMessage = 'reCAPTCHA verification failed. Please try again.';
        } else {
          errorMessage = '${l10n.registrationFailed}: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bubbles pinned to full screen — IgnorePointer so they don't block taps
          IgnorePointer(
            child: SizedBox(
              width: screenSize.width,
              height: screenSize.height,
              child: Stack(
                children: [
                  Positioned(
                    top: -screenSize.height * 0.15,
                    left: -screenSize.width * 0.25,
                    child: Container(
                      width: screenSize.width * 0.8,
                      height: screenSize.width * 0.8,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(19, 185, 75, 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -screenSize.height * 0.15,
                    right: -screenSize.width * 0.25,
                    child: Container(
                      width: screenSize.width * 0.8,
                      height: screenSize.width * 0.8,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(19, 185, 75, 0.1),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
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
                          padding: const EdgeInsets.only(right: 12),
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
                // Scrollable form
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.createAccount,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.joinAsJobPoster,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          _field(
                            controller: _usernameCtrl,
                            label: l10n.username,
                            hint: l10n.enterNameHint,
                            icon: Icons.person,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Name is required';
                              if (v.trim().length < 3)
                                return 'At least 3 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _emailCtrl,
                            label: l10n.email,
                            hint: l10n.enterEmailHint,
                            icon: Icons.email,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Email is required';
                              if (!_isValidEmail(v.trim()))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _passwordCtrl,
                            label: l10n.password,
                            hint: l10n.enterPasswordHint,
                            icon: Icons.lock,
                            obscure: _obscurePass,
                            suffix: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscurePass = !_obscurePass,
                                  ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters';
                              if (!RegExp(r'[A-Za-z]').hasMatch(v))
                                return 'Must contain a letter';
                              if (!RegExp(r'[0-9]').hasMatch(v))
                                return 'Must contain a number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _confirmCtrl,
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            icon: Icons.lock_outline,
                            obscure: _obscureConfirm,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed:
                                  () => setState(
                                    () => _obscureConfirm = !_obscureConfirm,
                                  ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Please confirm password';
                              if (v != _passwordCtrl.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _field(
                            controller: _phoneCtrl,
                            label: l10n.mobileNumber,
                            hint: l10n.enterPhoneHint,
                            icon: Icons.phone,
                            keyboard: TextInputType.phone,
                            inputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Phone is required';
                              if (!_isValidPhone(v.trim()))
                                return 'Enter a valid Pakistani number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _loading ? null : _submit,
                              child:
                                  _loading
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        l10n.signUp,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            l10n.termsOfServicePrivacy,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                        ],
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextInputAction inputAction = TextInputAction.next,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textInputAction: inputAction,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.green,
          fontWeight: FontWeight.w600,
        ),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: Icon(icon, color: AppColors.green),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.green, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
