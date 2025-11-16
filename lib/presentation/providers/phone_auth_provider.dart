import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import 'dart:async';
import '../../core/services/firestore_retry_service.dart';
import '../../core/services/job_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/auth_state_provider.dart';
import 'package:skillzaar/core/examples/services/notification_service.dart'
    as example_notif;
import 'package:skillzaar/core/services/firebase_test_service.dart';

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

  // Basic resend cooldown/backoff to avoid Firebase throttle
  DateTime? _nextAllowedRequestAt;
  int _baseCooldownSeconds = 30; // initial cooldown between requests
  int _maxCooldownSeconds = 600; // cap at 10 minutes
  // Tracks cooldown only; no need for separate failure counter

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
  void setLoggedInUserId(String? value) {
    _loggedInUserId = value;
    notifyListeners();
  }

  String? get loggedInPhoneNumber => _loggedInPhoneNumber;

  Future<void> _saveFcmTokenAndStartListener() async {
    try {
      if (_loggedInUserId == null) return;
      final notifService = example_notif.NotificationService();
      final token = notifService.fcmToken;
      if (token != null && token.isNotEmpty) {
        await notifService.saveTokenForUser(
          userId: _loggedInUserId!,
          userCollection: 'Tokens',
          token: token,
        );
        await FirebaseFirestore.instance
            .collection('notifcation')
            .doc(_loggedInUserId!)
            .set({
              'userId': _loggedInUserId!,
              'userType': 'job_poster',
              'fcmToken': token,
              'updatedAt': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        notifService.startFirestoreNotificationListener(
          userId: _loggedInUserId!,
          collectionName: 'notifcation',
        );
      }
    } catch (e) {
      print('⚠️ Could not save FCM token for job poster: $e');
    }
  }

  /// Set logged in state for direct login (without OTP)
  void setLoggedInState({required String userId, required String phoneNumber}) {
    _isLoggedIn = true;
    _loggedInUserId = userId;
    _loggedInPhoneNumber = phoneNumber;
    _currentPhoneNumber = phoneNumber;
    notifyListeners();
    print('✅ Job Poster logged in state set: $userId, $phoneNumber');
  }

  /// Persist lightweight session flags so app can restore role on cold start
  Future<void> persistLoginRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', role);
      if (_loggedInUserId != null)
        await prefs.setString('userId', _loggedInUserId!);
      if (_loggedInPhoneNumber != null)
        await prefs.setString('phoneNumber', _loggedInPhoneNumber!);
      print('✅ Persisted login role: $role');
    } catch (e) {
      print('⚠️ Could not persist login role: $e');
    }
  }

  /// Verify OTP and sign in (job posters)
  Future<bool> verifyOtp(
    String smsCode,
    BuildContext context, {
    bool isSignUp = false,
  }) async {
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

      // Persist role centrally so app can restore session on cold start
      try {
        final authState = Provider.of<AuthStateProvider>(
          context,
          listen: false,
        );
        if (userCred.user != null) {
          await authState.setSignedIn(user: userCred.user!, role: 'job_poster');
        }
      } catch (e) {
        // Non-fatal: provider may not be available in some contexts
        print('\u26a0\ufe0f Could not persist auth state via provider: $e');
      }

      // Save FCM token and start Firestore notifications listener
      await _saveFcmTokenAndStartListener();

      await _createJobPosterDocument();
      await _checkAndSetActiveJobFlags();

      print('✅ Job Poster OTP verification successful: $_loggedInUserId');
      _isLoading = false;
      notifyListeners();

      // Navigate to appropriate screen after successful verification
      if (context.mounted) {
        if (isSignUp) {
          // For signup, go to home screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-home',
            (route) => false,
            arguments: {'userId': _loggedInUserId},
          );
        } else {
          // For login, check for active jobs
          await checkJobOnLogin(pn, context);
        }
      }

      return true;
    } catch (e) {
      print('❌ OTP verify error: $e');
      _error = 'Failed to verify OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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
              .collection('AssignedJobs')
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
        final status = (active['status'] as String?)?.trim();

        if (jobId != null &&
            jobId.isNotEmpty &&
            requestId != null &&
            requestId.isNotEmpty) {
          print(
            '✅ Found active job - jobId: $jobId, requestId: $requestId, status: $status',
          );

          // Navigate based on status
          final isInProgress = status == 'in_progress';
          final route =
              isInProgress
                  ? '/job-poster-job-detail'
                  : '/job-poster-accepted-details';

          Navigator.pushNamedAndRemoveUntil(
            context,
            route,
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

        // Fallback 1: Check AssignedJobs directly by jobPosterId
        try {
          final accepted =
              await FirebaseFirestore.instance
                  .collection('AssignedJobs')
                  .where('jobPosterId', isEqualTo: _loggedInUserId)
                  .where('isActive', isEqualTo: true)
                  // Prefer assigned or accepted assignments, newest first if available
                  .limit(1)
                  .get();
          if (accepted.docs.isNotEmpty) {
            final doc = accepted.docs.first;
            final d = doc.data();
            final jobId = d['jobId'] as String?;
            // Some schemas don't store requestId; fall back to document ID
            final requestId =
                (d['requestId'] as String?)?.trim().isNotEmpty == true
                    ? (d['requestId'] as String)
                    : doc.id;
            if (jobId != null && jobId.isNotEmpty) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/job-poster-accepted-details',
                (route) => false,
                arguments: {'jobId': jobId, 'requestId': requestId},
              );
              return;
            }
          }
        } catch (e) {
          print('⚠️ Fallback AssignedJobs check failed: $e');
        }

        // Fallback 2: Check JobRequests by poster id regardless of isActive
        try {
          final reqs =
              await FirebaseFirestore.instance
                  .collection('AssignedJobs')
                  .where('jobPosterId', isEqualTo: _loggedInUserId)
                  .where(
                    'status',
                    whereIn: ['in_progress', 'accepted', 'assigned'],
                  )
                  .limit(1)
                  .get();
          if (reqs.docs.isNotEmpty) {
            final d = reqs.docs.first.data();
            final jobId = d['jobId'] as String?;
            final requestId = reqs.docs.first.id;
            final status = (d['status'] as String?)?.trim();
            if (jobId != null && jobId.isNotEmpty) {
              final isInProgress = status == 'in_progress';
              final route =
                  isInProgress
                      ? '/job-poster-job-detail'
                      : '/job-poster-accepted-details';
              Navigator.pushNamedAndRemoveUntil(
                context,
                route,
                (route) => false,
                arguments: {'jobId': jobId, 'requestId': requestId},
              );
              return;
            }
          }
        } catch (e) {
          print('⚠️ Fallback JobRequests check failed: $e');
        }
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
    // Clear token and stop listener
    if (_loggedInUserId != null) {
      try {
        example_notif.NotificationService().stopFirestoreNotificationListener();
        FirebaseFirestore.instance
            .collection('notifcation')
            .doc(_loggedInUserId!)
            .set({
              'fcmToken': null,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        FirebaseFirestore.instance
            .collection('JobPosters')
            .doc(_loggedInUserId!)
            .set({
              'fcmToken': FieldValue.delete(),
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}
    }
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
  int get cooldownRemainingSeconds {
    if (_nextAllowedRequestAt == null) return 0;
    final now = DateTime.now();
    final remaining = _nextAllowedRequestAt!.difference(now).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

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
  }) async {
    // Test Firebase configuration first
    await testFirebaseConfiguration();

    // Guard against spamming verifyPhoneNumber
    final remaining = cooldownRemainingSeconds;
    if (remaining > 0) {
      _error = 'Please wait ${remaining}s before requesting a new code.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    _verificationId = null;
    notifyListeners();

    final input = formatPhoneNumber(phoneNumber);
    print('📱 Sending OTP to: $input');
    print('🔐 isSignUp: $isSignUp');

    // Set the next allowed request time preemptively to enforce cooldown
    _nextAllowedRequestAt = DateTime.now().add(
      Duration(seconds: _baseCooldownSeconds),
    );

    // Always proceed with Firebase phone verification using real OTP
    _proceedWithPhoneVerification(input, context, isSignUp);
  }

  // Direct-login helper kept for reference (unused when OTP is enabled)
  // String _generateLocalUserId(String phone) {
  //   final digitsOnly = phone.replaceAll(RegExp(r'[^0-9]'), '');
  //   return 'JOB_POSTER_${digitsOnly}';
  // }

  void _proceedWithPhoneVerification(
    String input,
    BuildContext context,
    bool isSignUp,
  ) {
    print('🔐 Starting phone verification for: $input');
    print('🔐 isSignUp: $isSignUp');

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
          await _saveFcmTokenAndStartListener();
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
        print('❌ Phone verification failed: ${e.code} - ${e.message}');
        _error = e.message ?? e.code;

        // Handle specific error codes
        if (e.code == 'too-many-requests') {
          _error = 'Too many requests. Please wait before trying again.';
          final doubled = _baseCooldownSeconds * 2;
          _baseCooldownSeconds =
              doubled > _maxCooldownSeconds ? _maxCooldownSeconds : doubled;
          _nextAllowedRequestAt = DateTime.now().add(
            Duration(seconds: _baseCooldownSeconds),
          );
        } else if (e.code == 'invalid-phone-number') {
          _error = 'Invalid phone number format. Please check and try again.';
        } else if (e.code == 'quota-exceeded') {
          _error = 'SMS quota exceeded. Please try again later.';
        } else if (e.code == 'app-not-authorized') {
          _error =
              'App not authorized for phone authentication. Please contact support.';
        } else if (e.code == 'missing-client-identifier') {
          _error =
              'App configuration issue. Please restart the app and try again.';
          print('❌ Missing client identifier - check Firebase configuration');
        } else {
          _error = 'Phone verification failed: ${e.message ?? e.code}';
        }

        _isLoading = false;
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) async {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _currentPhoneNumber = input;
        _baseCooldownSeconds = 30; // reset to base after successful send
        _isLoading = false;
        notifyListeners();
        print('✅ OTP sent to: $input');
        print('📱 verificationId received');

        // Navigate to OTP screen only after code is actually sent
        if (context.mounted) {
          Navigator.pushNamed(
            context,
            '/job-poster-otp',
            arguments: {'phoneNumber': input, 'isSignUp': isSignUp},
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

  /// Test Firebase configuration for debugging
  Future<void> testFirebaseConfiguration() async {
    print('🔍 Testing Firebase configuration...');
    final result = await FirebaseTestService.testFirebaseConfiguration();
    print('🔍 Firebase test result: $result');

    if (result['success'] == true) {
      print('✅ Firebase configuration is working');
    } else {
      print('❌ Firebase configuration issue: ${result['error']}');
      _error = 'Firebase configuration issue: ${result['error']}';
      notifyListeners();
    }
  }

  /// Deactivate and permanently delete the current job poster account.
  /// This deletes the Firestore user document and then deletes the Auth user.
  /// Returns true if deletion succeeded, false otherwise.
  Future<bool> deactivateAndDeleteCurrentUser(BuildContext context) async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        _error = 'No authenticated user.';
        notifyListeners();
        return false;
      }

      final String userId = user.uid;

      // Stop notifications and clear token if any
      try {
        example_notif.NotificationService().stopFirestoreNotificationListener();
        await FirebaseFirestore.instance
            .collection('notifcation')
            .doc(userId)
            .set({
              'fcmToken': null,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}

      // Delete Firestore profile document for Job Poster
      try {
        await FirebaseFirestore.instance
            .collection('JobPosters')
            .doc(userId)
            .delete();
      } catch (e) {
        // If document already gone, continue
        print('⚠️ Firestore JobPoster delete warning: $e');
      }

      // Optionally: clean lightweight user-related flags in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_job_${userId}');
        await prefs.remove('active_job_${userId}_jobId');
        await prefs.remove('active_job_${userId}_requestId');
      } catch (_) {}

      // Finally delete the Firebase Auth user
      try {
        await user.delete();
      } on fb_auth.FirebaseAuthException catch (e) {
        // If requires recent login, inform caller
        if (e.code == 'requires-recent-login') {
          _error =
              'Please reauthenticate to delete your account. Log in again and retry.';
          notifyListeners();
          return false;
        }
        _error = 'Failed to delete account: ${e.message ?? e.code}';
        notifyListeners();
        return false;
      }

      // Clear local session state
      _isLoggedIn = false;
      _loggedInUserId = null;
      _loggedInPhoneNumber = null;
      _currentPhoneNumber = null;
      _verificationId = null;
      _error = null;
      notifyListeners();

      return true;
    } catch (e) {
      print('❌ Deactivate/delete failed: $e');
      _error = 'Account deletion failed. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
