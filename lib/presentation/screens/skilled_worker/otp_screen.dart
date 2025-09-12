import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/theme/app_theme.dart';

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

  Future<bool> _isProfileComplete(String skilledWorkerId) async {
    // For test: simulate Firestore check
    // In real app, fetch from Firestore and check required fields
    // Here, return false to always force registration flow for test
    return false;
  }

  String get otpCode =>
      otpControllers.map((controller) => controller.text).join();

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
                  // TODO: Implement resend OTP functionality
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
                            final isValid = await skilledWorkerProvider
                                .verifyOtp(otpCode);
                            if (isValid) {
                              // For test: always go to CNIC/profile setup first
                              // In real app, check Firestore for profile completeness
                              final skilledWorkerId = 'TEST_SKILLED_WORKER_ID';
                              final complete = await _isProfileComplete(
                                skilledWorkerId,
                              );
                              if (complete) {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/skilled-worker-home',
                                );
                              } else {
                                Navigator.pushReplacementNamed(
                                  context,
                                  '/skilled-worker-cnic',
                                );
                              }
                            } else {
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
