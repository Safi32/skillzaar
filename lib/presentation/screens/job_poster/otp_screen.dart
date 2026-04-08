import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/theme/app_theme.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/phone_auth_provider.dart';

class JobPosterOtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final bool isSignUp;

  const JobPosterOtpScreen({
    super.key,
    required this.phone,
    required this.verificationId,
    this.isSignUp = false,
  });

  @override
  State<JobPosterOtpScreen> createState() => _JobPosterOtpScreenState();
}

class _JobPosterOtpScreenState extends State<JobPosterOtpScreen> {
  final List<TextEditingController> _ctrl = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String? _error;

  // verificationId may be updated on resend
  late String _verificationId;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
  }

  @override
  void dispose() {
    for (final c in _ctrl) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _ctrl.map((c) => c.text.trim()).join();

  void _onChanged(String value, int index) {
    if (value.length == 1 && index < 5) {
      _focus[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focus[index - 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _verify() async {
    if (_otp.length != 6) {
      setState(() => _error = 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    if (widget.isSignUp) {
      // ── Signup: PhoneAuthProvider handles Firebase sign-in + Firestore doc ──
      final pap = Provider.of<PhoneAuthProvider>(context, listen: false);
      final err = await pap.verifyOtp(
        verificationId: _verificationId,
        smsCode: _otp,
      );

      if (!mounted) return;

      if (err != null) {
        setState(() {
          _loading = false;
          _error = err;
        });
        return;
      }

      // Sync AuthStateProvider so the rest of the app knows who is logged in
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
    } else {
      // ── Login: AuthStateProvider handles OTP verification ──
      final auth = Provider.of<AuthStateProvider>(context, listen: false);
      final err = await auth.verifyOtpCode(_otp, widget.phone);

      if (!mounted) return;

      if (err != null) {
        setState(() {
          _loading = false;
          _error = err;
        });
        return;
      }

      final next = await auth.determineNextScreen();
      if (!mounted) return;

      switch (next) {
        case NextScreen.completeProfile:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-profile',
            (_) => false,
          );
          break;
        default:
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-home',
            (_) => false,
          );
      }
    }
  }

  Future<void> _resend() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final pap = Provider.of<PhoneAuthProvider>(context, listen: false);
    try {
      final newId = await pap.sendOtp(widget.phone);
      if (!mounted) return;
      setState(() {
        _verificationId = newId;
        _loading = false;
        for (final c in _ctrl) {
          c.clear();
        }
      });
      _focus[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP resent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative bubbles
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.08,
                      vertical: 24,
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 64,
                          color: AppColors.green,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.verifyOtp,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.otpSentTo(widget.phone),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // OTP boxes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            6,
                            (i) => SizedBox(
                              width: 48,
                              height: 58,
                              child: TextFormField(
                                controller: _ctrl[i],
                                focusNode: _focus[i],
                                keyboardType: TextInputType.number,
                                textInputAction:
                                    i < 5
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (v) => _onChanged(v, i),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppColors.green,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Error
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Verify button
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
                                (_loading || _otp.length != 6) ? null : _verify,
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
                                      l10n.verifyButton,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Resend
                        TextButton(
                          onPressed: _loading ? null : _resend,
                          child: Text(
                            l10n.resendOtp,
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
