import 'package:flutter/foundation.dart';

class ReCaptchaService {
  /// Show reCAPTCHA verification for phone authentication
  static Future<void> verifyWithReCaptcha({
    required String phoneNumber,
    required VoidCallback onSuccess,
    required Function(String) onError,
    required VoidCallback onExpired,
  }) async {
    try {
      if (kIsWeb) {
        // For web platform, reCAPTCHA is handled by Firebase Auth automatically
        // The verification will be triggered when verifyPhoneNumber is called
        print(
          '🌐 Web platform detected - reCAPTCHA will be handled by Firebase Auth',
        );
        // Add a small delay to ensure Firebase is properly initialized
        await Future.delayed(const Duration(milliseconds: 500));
        onSuccess();
      } else {
        // For mobile platforms, reCAPTCHA is handled automatically by Firebase
        print('📱 Mobile platform detected - reCAPTCHA handled automatically');
        onSuccess();
      }
    } catch (e) {
      print('❌ reCAPTCHA verification error: $e');
      onError(e.toString());
    }
  }

  /// Check if reCAPTCHA is required for the current platform
  static bool get isRecaptchaRequired => kIsWeb;

  /// Get reCAPTCHA site key for web platform
  static String get recaptchaSiteKey {
    if (kIsWeb) {
      // This should be replaced with your actual reCAPTCHA site key
      // You can get this from Google reCAPTCHA Admin Console
      return '6Lf...'; // Replace with your actual site key
    }
    return '';
  }
}
