import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'dart:async';
import '../../core/services/firestore_retry_service.dart';
import '../../core/services/user_data_service.dart';
import '../../core/services/job_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Text controllers
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // Resend token for Firebase phone auth
  int? _resendToken;

  // User session management
  bool _isLoggedIn = false;
  String? _loggedInUserId;
  String? _loggedInPhoneNumber;

  bool get isLoggedIn => _isLoggedIn;
  String? get loggedInUserId => _loggedInUserId;
  String? get loggedInPhoneNumber => _loggedInPhoneNumber;

  /// Verify OTP and sign in (job posters)
  Future<bool> verifyOtp(String smsCode, BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Verifying OTP (job poster)');

    try {
      if (_verificationId == null) {
        _error = 'No verification ID. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCred = await fb_auth.FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final pn = _currentPhoneNumber ?? '';
      _isLoggedIn = true;
      _loggedInUserId = userCred.user?.uid;
      _loggedInPhoneNumber = pn;

      await _createJobPosterDocument();
      await _checkAndSetActiveJobFlags();

      print('✅ Job Poster OTP verification successful: $_loggedInUserId');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ OTP verify error: $e');
      _error = 'Failed to verify OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check for active job and set SharedPreferences flags for immediate redirect
  Future<void> _checkAndSetActiveJobFlags() async {
    if (_loggedInUserId == null) return;

    try {
      print('🔍 Checking for active job for job poster: $_loggedInUserId');
      print('🔍 Job poster phone: $_loggedInPhoneNumber');

      final active = await JobRequestService.getActiveRequestForPoster(
        _loggedInUserId!,
        posterPhone: _loggedInPhoneNumber,
      );

      print('🔍 Active job result in provider: $active');

      if (active != null) {
        final jobId = active['jobId'] as String?;
        final requestId = active['requestId'] as String?;
        if (jobId != null &&
            jobId.isNotEmpty &&
            requestId != null &&
            requestId.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('active_job_$_loggedInUserId', true);
          await prefs.setString('active_job_${_loggedInUserId}_jobId', jobId);
          await prefs.setString(
            'active_job_${_loggedInUserId}_requestId',
            requestId,
          );
          print(
            '✅ Found active job on login: jobId=$jobId, requestId=$requestId, set SharedPrefs flags',
          );
        } else {
          print(
            '❌ Active job found but jobId or requestId is null/empty - jobId: "$jobId", requestId: "$requestId"',
          );
        }
      } else {
        print('ℹ️ No active job found for job poster: $_loggedInUserId');
      }
    } catch (e) {
      print('❌ Error checking active job on login: $e');
    }
  }

  /// Simple job check on login - direct navigation approach for job posters
  Future<void> checkJobOnLogin(String phoneNumber, BuildContext context) async {
    try {
      print(
        '🔍 checkJobOnLogin: Checking for active job for job poster phone: $phoneNumber',
      );

      // Note: Removed the isActive check from JobPoster document as it's set to true for all users
      // and should not be used to determine if there's an active job request

      // First, let's check what's actually in the JobRequests collection
      print('🔍 Checking JobRequests collection directly...');
      final allRequests =
          await FirebaseFirestore.instance
              .collection('JobRequests')
              .where('jobPosterId', isEqualTo: _loggedInUserId)
              .get();

      print(
        '📋 Found ${allRequests.docs.length} JobRequests for job poster $_loggedInUserId',
      );
      for (var doc in allRequests.docs) {
        print('📋 JobRequest: ${doc.id} = ${doc.data()}');
      }

      // Check for active job request using the service
      print('🔍 Looking for active job with jobPosterId: $_loggedInUserId');

      final active = await JobRequestService.getActiveRequestForPoster(
        _loggedInUserId!,
        posterPhone: phoneNumber,
      );

      print('📋 Active job result: $active');

      if (active != null) {
        final jobId = active['jobId'] as String?;
        final requestId = active['requestId'] as String?;

        if (jobId != null &&
            jobId.isNotEmpty &&
            requestId != null &&
            requestId.isNotEmpty) {
          print(
            '✅ Found active job, navigating to job detail for jobId: $jobId, requestId: $requestId',
          );

          // Navigate to Job Poster Accepted Details screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-accepted-details',
            (route) => false,
            arguments: {'jobId': jobId, 'requestId': requestId},
          );
          print('✅ Navigation call completed');
          return;
        } else {
          print(
            '❌ Active job found but jobId or requestId is null/empty - jobId: "$jobId", requestId: "$requestId"',
          );
        }
      } else {
        print('❌ No active job found');
      }

      print('ℹ️ No active job found, navigating to home');
      // Go to Home screen using named route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/job-poster-home',
        (route) => false,
        arguments: {'userId': _loggedInUserId},
      );
    } catch (e) {
      print('❌ Error in checkJobOnLogin: $e');
      // Fallback to home on error
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/job-poster-home',
        (route) => false,
        arguments: {'userId': _loggedInUserId},
      );
    }
  }

  /// Create job poster document in Firebase
  Future<void> _createJobPosterDocument() async {
    try {
      if (_loggedInUserId == null) return;

      // Check if job poster document already exists
      final doc =
          await FirebaseFirestore.instance
              .collection('JobPosters')
              .doc(_loggedInUserId!)
              .get();

      if (!doc.exists) {
        // Create job poster document
        await FirebaseFirestore.instance
            .collection('JobPosters')
            .doc(_loggedInUserId!)
            .set({
              'userId': _loggedInUserId!,
              'phoneNumber': _loggedInPhoneNumber ?? 'unknown',
              'displayName': 'Job Poster',
              'email': '',
              'isActive': true,
              'isVerified': true,
              'userType': 'job_poster',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'lastLoginAt': FieldValue.serverTimestamp(),
              'profileCompleted': false,
              'settings': {
                'notifications': true,
                'emailNotifications': false,
                'smsNotifications': true,
              },
              'stats': {'jobsPosted': 0, 'jobsCompleted': 0, 'totalSpent': 0.0},
            });
        print('✅ Job poster document created: $_loggedInUserId');
      } else {
        // Update last login time
        await FirebaseFirestore.instance
            .collection('JobPosters')
            .doc(_loggedInUserId!)
            .update({'lastLoginAt': FieldValue.serverTimestamp()});
        print('✅ Job poster document updated: $_loggedInUserId');
      }
    } catch (e) {
      print('❌ Error creating job poster document: $e');
    }
  }

  /// Logout method
  void logout() {
    _isLoggedIn = false;
    _loggedInUserId = null;
    _loggedInPhoneNumber = null;
    _currentPhoneNumber = null;
    _verificationId = null;
    _error = null;
    notifyListeners();
    print('👋 Job Poster logged out');
  }

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
    notifyListeners();
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  void sendOtp(
    String phoneNumber,
    BuildContext context, {
    bool isUser = false,
    bool isSignUp = false,
  }) {
    _isLoading = true;
    _error = null;
    _verificationId = null;
    notifyListeners();

    final input = formatPhoneNumber(phoneNumber);
    print('📱 Sending OTP to: $input');

    fb_auth.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: input,
      forceResendingToken: _resendToken,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        // Auto verification may happen on some devices/SIMs. We will sign in the user,
        // but we will NOT auto-navigate; the UI flow remains consistent.
        try {
          final userCred = await fb_auth.FirebaseAuth.instance
              .signInWithCredential(credential);
          _currentPhoneNumber = input;
          final pn = _currentPhoneNumber ?? '';
          _isLoggedIn = true;
          _loggedInUserId = userCred.user?.uid;
          _loggedInPhoneNumber = pn;
          await _createJobPosterDocument();
          await _checkAndSetActiveJobFlags();
          _isLoading = false;
          notifyListeners();
          // Do not navigate automatically here; let UI decide next step
        } catch (e) {
          _error = 'Auto verification failed: ${e.toString()}';
          _isLoading = false;
          notifyListeners();
        }
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        _error = e.message ?? e.code;
        _isLoading = false;
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _currentPhoneNumber = input;
        _isLoading = false;
        notifyListeners();
        if (context.mounted) {
          Navigator.pushNamed(
            context,
            '/job-poster-otp',
            arguments: {'phone': input, 'isSignUp': isSignUp},
          );
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Method to create job poster in Firebase (called from OTP screen)
  Future<void> createJobPosterInFirebase(BuildContext context) async {
    try {
      // Ensure we have a real authenticated session
      if (_isLoggedIn && _loggedInUserId != null) {
        await UserDataService.createJobPoster(
          userId: _loggedInUserId!,
          phoneNumber: _loggedInPhoneNumber ?? 'unknown',
          displayName: 'Job Poster',
        );
      }
    } catch (e) {
      print('❌ Error creating job poster: $e');

      // Provide user-friendly error message
      if (e is FirebaseException) {
        _error =
            'Failed to create user profile. ${FirestoreRetryService.getUserFriendlyErrorMessage(e)}';
      } else {
        _error =
            'Failed to create user profile. ${FirestoreRetryService.getUserFriendlyErrorMessageForException(e is Exception ? e : Exception(e.toString()))}';
      }

      notifyListeners();
      rethrow;
    }
  }

  // Method to check Firestore connection status
  Future<bool> checkFirestoreConnection() async {
    try {
      // Try to access a simple collection to test connection
      await FirebaseFirestore.instance
          .collection('JobPosters')
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      print('✅ Firestore connection successful');
      return true;
    } on FirebaseException catch (e) {
      print('❌ Firestore connection failed: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('❌ Firestore connection check failed: $e');
      return false;
    }
  }

  // Method to show connection status in UI
  Future<void> showConnectionStatus(BuildContext context) async {
    final isConnected = await checkFirestoreConnection();
    if (!isConnected) {
      _error =
          'Unable to connect to server. Please check your internet connection and try again.';
      notifyListeners();
    }
  }

  // Method to retry profile creation if it failed earlier
  Future<void> retryProfileCreation() async {
    try {
      // Ensure we have a real authenticated session
      if (_isLoggedIn && _loggedInUserId != null) {
        await FirestoreRetryService.retryOperation(() async {
          final jobPosterDoc = FirebaseFirestore.instance
              .collection('JobPosters')
              .doc(_loggedInUserId!);
          final doc = await jobPosterDoc.get();

          if (!doc.exists) {
            print('📝 Retrying job poster document creation...');
            await jobPosterDoc.set({
              'userId': _loggedInUserId!,
              'phoneNumber': _loggedInPhoneNumber,
              'displayName': 'Job Poster',
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
            });
            print('✅ Job poster document created successfully on retry');
            _error = null; // Clear any previous error
            notifyListeners();
          }
        }, operationName: 'retryProfileCreation');
      }
    } catch (e) {
      print('❌ Retry profile creation failed: $e');
    }
  }

  // Removed test and local verification logic. Now uses Firebase only.
}
