import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

String formatPhoneNumber(String input) {
  input = input.trim();

  // Remove any spaces, dashes, or parentheses
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

class PhoneAuthProvider with ChangeNotifier {
  String? _verificationId;
  bool _isLoading = false;
  String? _error;
  String? _currentPhoneNumber;
  int? _resendToken;

  // Text controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String? get verificationId => _verificationId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentPhoneNumber => _currentPhoneNumber;
  bool get isOtpSent => _verificationId != null;

  // Method to clear errors and reset state
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Method to reset OTP state
  void resetOtpState() {
    _verificationId = null;
    _error = null;
    _isLoading = false;
    _resendToken = null;
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  Future<void> sendOtp(
    String phoneNumber,
    BuildContext context, {
    bool isUser = false,
  }) async {
    // Reset state
    _isLoading = true;
    _error = null;
    _verificationId = null;
    notifyListeners();

    final formatted = formatPhoneNumber(phoneNumber);

    print('📱 Sending OTP to: $formatted');
    print('📱 Original input: $phoneNumber');

    // Validate phone number format
    if (!formatted.startsWith('+92') || formatted.length != 13) {
      _error =
          'Please enter a valid Pakistani phone number (e.g., 03XX-XXXXXXX)';
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      await fb_auth.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formatted,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          print('✅ Auto-verification completed');
          // Auto-retrieval or instant verification
          try {
            final userCredential = await fb_auth.FirebaseAuth.instance
                .signInWithCredential(credential);
            print(
              '✅ User signed in automatically: ${userCredential.user?.uid}',
            );
            _isLoading = false;
            notifyListeners();
          } catch (e) {
            print('❌ Auto-verification sign-in failed: $e');
            _error = 'Auto-verification failed: $e';
            _isLoading = false;
            notifyListeners();
          }
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          print('❌ Verification failed: ${e.code} - ${e.message}');

          String errorMessage;
          switch (e.code) {
            case 'too-many-requests':
              errorMessage =
                  'Too many requests. Please try again later or use a different device.';
              break;
            case 'invalid-phone-number':
              errorMessage =
                  'Invalid phone number format. Please check your number.';
              break;
            case 'quota-exceeded':
              errorMessage = 'SMS quota exceeded. Please try again later.';
              break;
            case 'missing-phone-number':
              errorMessage = 'Phone number is required.';
              break;
            case 'invalid-verification-code':
              errorMessage = 'Invalid verification code.';
              break;
            case 'invalid-verification-id':
              errorMessage =
                  'Invalid verification ID. Please request OTP again.';
              break;
            case 'network-request-failed':
              errorMessage =
                  'Network error. Please check your internet connection.';
              break;
            default:
              errorMessage = 'Verification failed: ${e.message ?? e.code}';
          }

          _error = errorMessage;
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ OTP sent successfully. Verification ID: $verificationId');
          _verificationId = verificationId;
          _currentPhoneNumber = formatted;
          _resendToken = resendToken;
          _isLoading = false;
          notifyListeners();

          // Navigate to OTP screen after successful OTP send
          if (context.mounted) {
            print('🚀 Navigating to OTP screen');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent to your phone number'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushNamed(
              context,
              '/job-poster-otp',
              arguments: {'phone': formatted, 'isSignUp': true},
            );
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏰ Auto-retrieval timeout. Verification ID: $verificationId');
          _verificationId = verificationId;
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('❌ Exception in sendOtp: $e');
      _error = 'Failed to send OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }

    // Add a timeout fallback
    Future.delayed(const Duration(seconds: 65), () {
      if (_isLoading && _verificationId == null) {
        print('⏰ OTP request timed out');
        _error = 'OTP request timed out. Please try again.';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> verifyOtp(
    String smsCode,
    BuildContext context, {
    bool isUser = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Verifying OTP: $smsCode');
    print('🔐 Verification ID: $_verificationId');

    try {
      if (_verificationId == null) {
        _error = 'No verification ID. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Allow 6-digit OTP (Firebase standard)
      if (smsCode.length != 6) {
        _error = 'Please enter the 6-digit OTP code.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      print('🔐 Attempting to sign in with credential...');
      final userCredential = await fb_auth.FirebaseAuth.instance
          .signInWithCredential(credential);
      print('✅ Successfully signed in: ${userCredential.user?.uid}');

      // On success, create user in Firestore (JobPosters collection)
      final userId = userCredential.user?.uid ?? _currentPhoneNumber;
      final jobPosterDoc = FirebaseFirestore.instance
          .collection('JobPosters')
          .doc(userId);
      final doc = await jobPosterDoc.get();

      if (!doc.exists) {
        print('📝 Creating new job poster document...');
        await jobPosterDoc.set({
          'userId': userId,
          'phoneNumber': _currentPhoneNumber,
          'displayName': 'Job Poster',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });
        print('✅ Job poster document created successfully');
      } else {
        print('📝 Job poster document already exists');
      }

      _isLoading = false;
      notifyListeners();
    } on fb_auth.FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'invalid-verification-code':
          errorMessage = 'Invalid OTP code. Please check and try again.';
          break;
        case 'invalid-verification-id':
          errorMessage = 'Invalid verification ID. Please request OTP again.';
          break;
        case 'session-expired':
          errorMessage = 'OTP session expired. Please request a new OTP.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'Verification failed: ${e.message ?? e.code}';
      }

      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ General Exception in verifyOtp: $e');
      _error = 'Failed to verify OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to create job poster in Firebase (called from OTP screen)
  Future<void> createJobPosterInFirebase(BuildContext context) async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final jobPosterDoc = FirebaseFirestore.instance
            .collection('JobPosters')
            .doc(user.uid);
        final doc = await jobPosterDoc.get();

        if (!doc.exists) {
          await jobPosterDoc.set({
            'userId': user.uid,
            'phoneNumber': _currentPhoneNumber,
            'displayName': 'Job Poster',
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });
          print('✅ Job poster document created successfully');
        }
      }
    } catch (e) {
      print('❌ Error creating job poster: $e');
      rethrow;
    }
  }

  // Removed test and local verification logic. Now uses Firebase only.
}
