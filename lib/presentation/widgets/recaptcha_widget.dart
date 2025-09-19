import 'package:flutter/material.dart';
import 'package:skillzaar/core/examples/services/recaptcha_service.dart';


class ReCaptchaWidget extends StatelessWidget {
  final String phoneNumber;
  final VoidCallback onSuccess;
  final Function(String) onError;
  final VoidCallback onExpired;

  const ReCaptchaWidget({
    super.key,
    required this.phoneNumber,
    required this.onSuccess,
    required this.onError,
    required this.onExpired,
  });

  @override
  Widget build(BuildContext context) {
    if (!ReCaptchaService.isRecaptchaRequired) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Security Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'reCAPTCHA verification will be required when you send the OTP. This helps protect against spam and abuse.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
              color: Colors.white,
            ),
            child: const Center(
              child: Text(
                'reCAPTCHA will appear automatically when needed',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Note: reCAPTCHA is handled automatically by Firebase Auth',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
