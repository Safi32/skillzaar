import 'dart:async';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillzaar/core/examples/services/notification_service.dart'
    as notif;
import 'package:skillzaar/core/services/job_request_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Phone formatter (used by screens too)
// ─────────────────────────────────────────────────────────────────────────────
String formatPhoneNumber(String input) {
  input = input.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

  // Log the formatting process
  print('📱 Formatting phone: "$input"');

  if (input.startsWith('+')) {
    print('📱 Already has +, returning: $input');
    return input;
  }

  if (input.startsWith('0') && input.length == 11) {
    final formatted = '+92${input.substring(1)}';
    print('📱 Pakistani format (0...), returning: $formatted');
    return formatted;
  }

  if (input.startsWith('92') && input.length == 12) {
    final formatted = '+$input';
    print('📱 Country code format, returning: $formatted');
    return formatted;
  }

  if (input.length == 10) {
    final formatted = '+92$input';
    print('📱 10-digit format, returning: $formatted');
    return formatted;
  }

  if (input.length == 11 && !input.startsWith('0')) {
    final formatted = '+92$input';
    print('📱 11-digit format, returning: $formatted');
    return formatted;
  }

  print('📱 No format match, returning as-is: $input');
  return input;
}

// ─────────────────────────────────────────────────────────────────────────────
// PhoneAuthProvider
// Single responsibility: send OTP → verify OTP → create Firestore doc.
// No navigation. No listeners. Callers await and act on the result.
// ─────────────────────────────────────────────────────────────────────────────
class PhoneAuthProvider with ChangeNotifier {
  // Pending profile (set before OTP is sent)
  String? pendingDisplayName;
  String? pendingEmail;
  String? pendingPassword;

  // Post-verification session
  bool _isLoggedIn = false;
  String? _loggedInUserId;
  String? _loggedInPhoneNumber;

  // UI state
  bool _isLoading = false;
  String? _error;

  // Firebase resend token
  int? _resendToken;

  // ── Getters ──────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  String? get loggedInUserId => _loggedInUserId;
  String? get loggedInPhoneNumber => _loggedInPhoneNumber;

  void setPendingJobPosterProfile({
    required String displayName,
    required String email,
    required String password,
  }) {
    pendingDisplayName = displayName;
    pendingEmail = email;
    pendingPassword = password;
  }

  void setLoggedInState({required String userId, required String phoneNumber}) {
    _isLoggedIn = true;
    _loggedInUserId = userId;
    _loggedInPhoneNumber = phoneNumber;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── sendOtp ───────────────────────────────────────────────────────────────
  // Returns the verificationId string on success, or throws with a message.
  // The caller (signup screen) awaits this and passes the ID to the OTP screen.
  // ─────────────────────────────────────────────────────────────────────────
  Future<String> sendOtp(String rawPhone) async {
    final phone = formatPhoneNumber(rawPhone);
    final completer = Completer<String>();

    _isLoading = true;
    _error = null;
    notifyListeners();

    log('🚀 Starting OTP send process for: $phone');

    // Test Firebase Auth availability
    try {
      final currentUser = fb.FirebaseAuth.instance.currentUser;
      log(
        '🔍 Firebase Auth instance available, current user: ${currentUser?.uid ?? 'none'}',
      );
    } catch (e) {
      log('❌ Firebase Auth instance error: $e');
    }

    fb.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (fb.PhoneAuthCredential credential) {
        // Auto-verified on some Android devices — complete with a special marker.
        // The OTP screen handles this case.
        log('✅ verificationCompleted (auto-verification)');
        log('🔍 Completer completed status: ${completer.isCompleted}');
        _isLoading = false;
        notifyListeners();
        if (!completer.isCompleted) {
          log('✅ Completing with __auto__ marker for auto-verification');
          completer.complete('__auto__');
        } else {
          log('⚠️ Completer already completed, ignoring verificationCompleted');
        }
      },
      verificationFailed: (fb.FirebaseAuthException e) {
        log('❌ verificationFailed: ${e.code} - ${e.message}');
        log('❌ Full error details: $e');
        _isLoading = false;
        _error = _friendlyError(e);
        notifyListeners();
        if (!completer.isCompleted) {
          completer.completeError(_error!);
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        log('📱 codeSent - verificationId: $verificationId');
        log('🔄 resendToken: $resendToken');
        log('🔍 Completer completed status: ${completer.isCompleted}');
        _resendToken = resendToken;
        _isLoading = false;
        notifyListeners();
        if (!completer.isCompleted) {
          log('✅ Completing completer with verificationId');
          completer.complete(verificationId);
        } else {
          log('⚠️ Completer already completed, ignoring codeSent');
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        log('⏰ codeAutoRetrievalTimeout - verificationId: $verificationId');
        // Timeout — verificationId is still valid for manual entry.
        // Only complete if not already done.
        if (!completer.isCompleted) {
          log('⏰ Completing with verificationId from timeout');
          completer.complete(verificationId);
        }
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 90), // Increased timeout
      onTimeout: () {
        log('⏰ OTP request timed out after 90 seconds');
        _isLoading = false;
        _error =
            'OTP request timed out. Please check your connection and try again.';
        notifyListeners();
        throw Exception(_error);
      },
    );
  }

  // ── verifyOtp ─────────────────────────────────────────────────────────────
  // Returns null on success, error string on failure.
  // ─────────────────────────────────────────────────────────────────────────
  Future<String?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCred = await fb.FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCred.user;
      if (user == null) throw Exception('Sign-in returned null user.');

      // Link email/password if provided (signup flow)
      if (pendingEmail != null &&
          pendingEmail!.isNotEmpty &&
          pendingPassword != null &&
          pendingPassword!.isNotEmpty) {
        try {
          final emailCred = fb.EmailAuthProvider.credential(
            email: pendingEmail!.trim(),
            password: pendingPassword!,
          );
          await user.linkWithCredential(emailCred);
          if (pendingDisplayName != null && pendingDisplayName!.isNotEmpty) {
            await user.updateDisplayName(pendingDisplayName!.trim());
          }
        } on fb.FirebaseAuthException catch (e) {
          log('email link warning: ${e.code}');
        }
      }

      _isLoggedIn = true;
      _loggedInUserId = user.uid;
      _loggedInPhoneNumber = user.phoneNumber ?? '';

      await _createJobPosterDocument();
      await _checkAndSetActiveJobFlags();
      await _saveFcmToken();

      _isLoading = false;
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      _isLoading = false;
      _error =
          e.code == 'invalid-verification-code'
              ? 'Incorrect OTP. Please check and try again.'
              : (e.message ?? 'Verification failed.');
      notifyListeners();
      return _error;
    } catch (e) {
      _isLoading = false;
      _error = 'Verification failed. Please try again.';
      notifyListeners();
      return _error;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _friendlyError(fb.FirebaseAuthException e) {
    log('🔍 Processing Firebase error: ${e.code} - ${e.message}');
    switch (e.code) {
      case 'too-many-requests':
        return 'Too many requests. Please wait before trying again.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorized for Firebase Auth. Please contact support.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      case 'web-context-already-presented':
        return 'Authentication already in progress. Please wait.';
      case 'web-context-cancelled':
        return 'Authentication was cancelled. Please try again.';
      case 'missing-client-identifier':
        return 'Missing app configuration. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'internal-error':
        return 'Internal error occurred. Please try again later.';
      default:
        log('⚠️ Unhandled Firebase Auth error: ${e.code}');
        return e.message ?? 'Authentication error: ${e.code}';
    }
  }

  Future<void> _createJobPosterDocument() async {
    if (_loggedInUserId == null) return;
    try {
      final ref = FirebaseFirestore.instance
          .collection('JobPosters')
          .doc(_loggedInUserId!);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set({
          'userId': _loggedInUserId!,
          'phoneNumber': _loggedInPhoneNumber ?? '',
          'displayName':
              (pendingDisplayName?.trim().isNotEmpty == true)
                  ? pendingDisplayName
                  : 'Job Poster',
          'email': pendingEmail ?? '',
          'password': pendingPassword ?? '',
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
      } else {
        await ref.update({'lastLoginAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      log('_createJobPosterDocument error: $e');
    }
  }

  Future<void> _checkAndSetActiveJobFlags() async {
    if (_loggedInUserId == null) return;
    try {
      final active = await JobRequestService.getActiveRequestForPoster(
        _loggedInUserId!,
        posterPhone: _loggedInPhoneNumber,
      );
      if (active != null) {
        final jobId = active['jobId'] as String?;
        final requestId = active['requestId'] as String?;
        if (jobId != null && requestId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('active_job_$_loggedInUserId', true);
          await prefs.setString('active_job_${_loggedInUserId}_jobId', jobId);
          await prefs.setString(
            'active_job_${_loggedInUserId}_requestId',
            requestId,
          );
        }
      }
    } catch (e) {
      log('_checkAndSetActiveJobFlags error: $e');
    }
  }

  Future<void> _saveFcmToken() async {
    if (_loggedInUserId == null) return;
    try {
      final service = notif.NotificationService();
      final token = service.fcmToken;
      if (token != null && token.isNotEmpty) {
        await service.saveTokenForUser(
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

        // Send welcome notification
        await _sendWelcomeNotification();

        // Start notification listener after a short delay to avoid immediate notifications
        Future.delayed(const Duration(seconds: 3), () {
          service.startFirestoreNotificationListener(
            userId: _loggedInUserId!,
            collectionName: 'notifcation',
          );
        });
      }
    } catch (e) {
      log('_saveFcmToken error: $e');
    }
  }

  Future<void> _sendWelcomeNotification() async {
    if (_loggedInUserId == null) return;
    try {
      // First, clean up any existing empty notifications for this user
      final existingNotifications =
          await FirebaseFirestore.instance
              .collection('notifcation')
              .where('userId', isEqualTo: _loggedInUserId!)
              .get();

      for (final doc in existingNotifications.docs) {
        final data = doc.data();
        final title = (data['title'] ?? '').toString().trim();
        final body = (data['body'] ?? '').toString().trim();

        // Delete empty or generic notifications
        if (title.isEmpty || body.isEmpty || title == 'Notification') {
          await doc.reference.delete();
          log('🗑️ Deleted empty notification: $title');
        }
      }

      // Create a welcome notification document
      await FirebaseFirestore.instance.collection('notifcation').add({
        'userId': _loggedInUserId!,
        'title': 'Welcome to Skillzaar! 🎉',
        'body':
            'Your account has been created successfully. Start posting jobs and find skilled workers in your area.',
        'delivered': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {'type': 'welcome', 'action': 'none'},
      });
      log('✅ Welcome notification created');
    } catch (e) {
      log('❌ Failed to create welcome notification: $e');
    }
  }

  Future<bool> deactivateAndDeleteCurrentUser() async {
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final uid = user.uid;
      try {
        await FirebaseFirestore.instance
            .collection('JobPosters')
            .doc(uid)
            .delete();
      } catch (_) {}
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_job_$uid');
        await prefs.remove('active_job_${uid}_jobId');
        await prefs.remove('active_job_${uid}_requestId');
      } catch (_) {}
      await user.delete();
      _isLoggedIn = false;
      _loggedInUserId = null;
      _loggedInPhoneNumber = null;
      _error = null;
      notifyListeners();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _error =
          e.code == 'requires-recent-login'
              ? 'Please log in again before deleting your account.'
              : 'Failed to delete account: ${e.message ?? e.code}';
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Account deletion failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _isLoggedIn = false;
    _loggedInUserId = null;
    _loggedInPhoneNumber = null;
    _error = null;
    notifyListeners();
  }
}
