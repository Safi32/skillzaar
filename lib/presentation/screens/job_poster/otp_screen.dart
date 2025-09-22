import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/recaptcha_service.dart';
import '../../providers/phone_auth_provider.dart';
import '../../widgets/recaptcha_widget.dart';

class JobPosterOTPScreen extends StatefulWidget {
  const JobPosterOTPScreen({super.key});

  @override
  State<JobPosterOTPScreen> createState() => _JobPosterOTPScreenState();
}

class _JobPosterOTPScreenState extends State<JobPosterOTPScreen> {
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());
  String? phoneNumber;
  bool _isVerifying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get phone number from arguments (support both keys for safety)
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    phoneNumber = args?['phoneNumber'] ?? args?['phone'];
  }

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

  Future<void> _verifyOtp() async {
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    final phoneAuthProvider = Provider.of<PhoneAuthProvider>(
      context,
      listen: false,
    );

    // Get the isSignUp flag from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final isSignUp = args?['isSignUp'] ?? false;

    final success = await phoneAuthProvider.verifyOtp(
      otpCode,
      context,
      isSignUp: isSignUp,
    );

    setState(() {
      _isVerifying = false;
    });

    if (success) {
      // OTP verification successful, navigation will be handled by the provider
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number verified successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(phoneAuthProvider.error ?? 'OTP verification failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _resendOtp() async {
    if (phoneNumber == null) return;

    final phoneAuthProvider = Provider.of<PhoneAuthProvider>(
      context,
      listen: false,
    );

    // Clear previous OTP
    for (var controller in otpControllers) {
      controller.clear();
    }
    focusNodes[0].requestFocus();

    // Send new OTP
    phoneAuthProvider.sendOtp(phoneNumber!, context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Verify Phone Number',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // App logo or icon
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    Icons.sms_outlined,
                    color: Colors.green.shade700,
                    size: 36,
                  ),
                ),
              ),
              const Text(
                'Enter Verification Code',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit code to\n$phoneNumber',
                style: const TextStyle(fontSize: 15, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // reCAPTCHA Widget (for web platforms)
              if (ReCaptchaService.isRecaptchaRequired)
                ReCaptchaWidget(
                  phoneNumber: phoneNumber ?? '',
                  onSuccess: () {
                    print('✅ reCAPTCHA completed for job poster');
                  },
                  onError: (error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('reCAPTCHA verification failed: $error'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  onExpired: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'reCAPTCHA verification expired. Please try again.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),

              if (ReCaptchaService.isRecaptchaRequired)
                const SizedBox(height: 20),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 45,
                    height: 55,
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
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              // Verify Button
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
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child:
                      _isVerifying
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Verify OTP',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),

              const SizedBox(height: 24),

              // Resend OTP
              TextButton(
                onPressed: _isVerifying ? null : _resendOtp,
                child: const Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),

              const Spacer(),

              // Terms text
              const Text(
                'By continuing, you accept our Terms & Privacy Policy.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
