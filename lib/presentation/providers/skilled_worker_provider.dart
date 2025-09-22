import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:skillzaar/core/examples/services/recaptcha_service.dart';
import 'package:skillzaar/presentation/providers/notification_provider.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../core/services/job_request_service.dart';
import '../../../core/services/user_storage_service.dart';

import '../../core/examples/services/notification_service.dart'
    as example_notif;

import '../../../core/services/location_tracking_service.dart';
import 'dart:io';

String formatPhoneNumber(String input) {
  input = input.trim().replaceAll(' ', '');
  // Remove all spaces
  if (input.startsWith('+')) return input;
  if (input.startsWith('0') && input.length == 11) {
    return '+92' + input.substring(1);
  }
  if (input.length == 10 && input.startsWith('3')) {
    return '+92$input';
  }
  return input;
}

class SkilledWorkerProvider with ChangeNotifier {
  // Firebase phone auth state
  int? _resendToken;

  // User session management
  bool _isLoggedIn = false;
  String? _loggedInUserId;
  String? _loggedInPhoneNumber;

  bool get isLoggedIn => _isLoggedIn;
  String? get loggedInUserId => _loggedInUserId;
  String? get loggedInPhoneNumber => _loggedInPhoneNumber;
  bool get isOtpSent => _verificationId != null;

  /// Set logged in state for direct login (without OTP)
  void setLoggedInState({required String userId, required String phoneNumber}) {
    _isLoggedIn = true;
    _loggedInUserId = userId;
    _loggedInPhoneNumber = phoneNumber;
    _currentPhoneNumber = phoneNumber;

    // Start location tracking for the worker
    LocationTrackingService().startLocationTracking(userId);

    // Save FCM token and start Firestore notifications listener if available
    try {
      final notificationProvider = NotificationProvider();
      final token = notificationProvider.notificationService.fcmToken;
      if (token != null && token.isNotEmpty) {
        example_notif.NotificationService().saveTokenForUser(
          userId: userId,
          userCollection: 'Tokens',
          token: token,
        );
      }
      // Listen to Firestore notifcation collection for real-time docs
      example_notif.NotificationService().startFirestoreNotificationListener(
        userId: userId,
        collectionName: 'notifcation',
      );
    } catch (e) {
      // Non-fatal
      print('⚠️ Could not setup notifications on login: $e');
    }

    notifyListeners();
    print('✅ Skilled Worker logged in state set: $userId, $phoneNumber');
  }

  /// Verify OTP and sign in (skilled worker)
  Future<bool> login(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Skilled Worker OTP verify: $phoneNumber');

    try {
      if (_verificationId == null) {
        _error = 'No verification ID. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final userCred = await fb_auth.FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      _isLoggedIn = true;
      _loggedInPhoneNumber = phoneNumber;
      _currentPhoneNumber = phoneNumber;
      _loggedInUserId = userCred.user?.uid;

      print('✅ Skilled Worker login successful: $_loggedInUserId');

      // Save FCM token and start Firestore notifications listener
      try {
        final notifService = example_notif.NotificationService();
        final token = notifService.fcmToken;
        if (_loggedInUserId != null && token != null && token.isNotEmpty) {
          await notifService.saveTokenForUser(
            userId: _loggedInUserId!,
            userCollection: 'Tokens',
            token: token,
          );

          // Also save/update a token record in 'notifcation' collection for admin panel
          await FirebaseFirestore.instance
              .collection('notifcation')
              .doc(_loggedInUserId!)
              .set({
                'userId': _loggedInUserId!,
                'userType': 'skilled_worker',
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
        print('⚠️ Could not setup notifications on worker login: $e');
      }

      // Check for active job and set SharedPreferences flags
      await _checkAndSetActiveJobFlags();

      // Start location tracking for the worker
      if (_loggedInUserId != null) {
        // Fire and forget; service handles permission checks internally
        LocationTrackingService().startLocationTracking(_loggedInUserId!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Login error: $e');
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP and sign up (skilled worker)
  Future<bool> signup(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Skilled Worker OTP signup: $phoneNumber');

    try {
      if (_verificationId == null) {
        _error = 'No verification ID. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      final userCred = await fb_auth.FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      _isLoggedIn = true;
      _loggedInPhoneNumber = phoneNumber;
      _currentPhoneNumber = phoneNumber;
      _loggedInUserId = userCred.user?.uid;

      print('✅ Skilled Worker signup successful: $_loggedInUserId');

      // Create skilled worker document
      await _createSkilledWorkerDocument();

      // Start location tracking for the worker
      if (_loggedInUserId != null) {
        LocationTrackingService().startLocationTracking(_loggedInUserId!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Signup error: $e');
      _error = 'Signup failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create skilled worker document in Firestore
  Future<void> _createSkilledWorkerDocument() async {
    if (_loggedInUserId == null || _loggedInPhoneNumber == null) return;

    try {
      final skilledWorkerDoc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(_loggedInUserId!)
              .get();

      if (!skilledWorkerDoc.exists) {
        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(_loggedInUserId!)
            .set({
              'userId': _loggedInUserId!,
              'phoneNumber': _loggedInPhoneNumber!,
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'isApproved': false, // Requires admin approval
              'approvalStatus': 'pending', // Pending approval
              'currentLatitude': _currentLatitude,
              'currentLongitude': _currentLongitude,
              'currentAddress': _currentAddress,
              'locationUpdatedAt': FieldValue.serverTimestamp(),
            });
        print('✅ Skilled worker document created');
      }
    } catch (e) {
      print('❌ Error creating skilled worker document: $e');
      _error = 'Failed to create profile: ${e.toString()}';
    }
  }

  /// Check for active job and set SharedPreferences flags for immediate redirect
  Future<void> _checkAndSetActiveJobFlags() async {
    if (_loggedInUserId == null) return;

    try {
      print('🔍 Checking for active job for worker: $_loggedInUserId');
      final active = await JobRequestService.getActiveRequestForWorker(
        _loggedInUserId!,
        skilledWorkerPhone: _loggedInPhoneNumber,
      );

      if (active != null) {
        final jobId = active['jobId'] as String?;
        if (jobId != null && jobId.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('active_job_$_loggedInUserId', true);
          await prefs.setString('active_job_${_loggedInUserId}_jobId', jobId);
          print(
            '✅ Found active job on login: jobId=$jobId, set SharedPrefs flags',
          );
        }
      } else {
        print('ℹ️ No active job found for worker: $_loggedInUserId');
      }
    } catch (e) {
      print('❌ Error checking active job on login: $e');
    }
  }

  /// Simple job check on login - direct navigation approach
  Future<void> checkJobOnLogin(String phoneNumber, BuildContext context) async {
    try {
      print(
        '🔍 checkJobOnLogin: Checking for active job for phone: $phoneNumber',
      );

      // First, let's check what's actually in the JobRequests collection
      print('🔍 Checking JobRequests collection directly...');
      final allRequests =
          await FirebaseFirestore.instance
              .collection('JobRequests')
              .where('skilledWorkerPhone', isEqualTo: phoneNumber)
              .get();

      print(
        '📋 Found ${allRequests.docs.length} JobRequests for phone $phoneNumber',
      );
      for (var doc in allRequests.docs) {
        print('📋 JobRequest: ${doc.id} = ${doc.data()}');
      }

      // Check for active job request using the service
      final workerId = 'SKILLED_WORKER_${phoneNumber.replaceAll('0', '')}';
      print('🔍 Looking for active job with workerId: $workerId');

      final active = await JobRequestService.getActiveRequestForWorker(
        workerId,
        skilledWorkerPhone: phoneNumber,
      );

      print('📋 Active job result: $active');

      if (active != null) {
        final jobId = active['jobId'] as String?;
        if (jobId != null && jobId.isNotEmpty) {
          print('✅ Found active job, getting job details for jobId: $jobId');

          // Get job details
          final job = await JobRequestService.getJobDetails(jobId);
          print('📋 Job details: $job');

          if (job != null) {
            print('✅ Job details found, navigating to job detail');
            print(
              '🚀 Calling Navigator.pushNamedAndRemoveUntil with jobId: $jobId',
            );
            // Navigate to Job Details screen using named route (same as ActiveWorkGate)
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/skilled-worker-job-detail',
              (route) => false,
              arguments: {
                'imageUrl': job['Image'] ?? '',
                'title': job['title_en'] ?? job['title_ur'] ?? '',
                'location': job['Address'] ?? job['Location'] ?? '',
                'date':
                    job['createdAt'] != null
                        ? (job['createdAt'] as Timestamp).toDate()
                        : null,
                'description':
                    job['description_en'] ?? job['description_ur'] ?? '',
                'jobId': jobId,
                'jobPosterId': active['jobPosterId'] ?? '',
                'requestId': active['requestId'],
              },
            );
            print('✅ Navigation call completed');
            return;
          } else {
            print('❌ Job details not found for jobId: $jobId');
          }
        } else {
          print('❌ Active job found but jobId is null or empty');
        }
      } else {
        print('❌ No active job found');
      }

      print('ℹ️ No active job found, navigating to home');
      // Go to Home screen using named route
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-home',
        (route) => false,
      );
    } catch (e) {
      print('❌ Error in checkJobOnLogin: $e');
      // Fallback to home on error
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-home',
        (route) => false,
      );
    }
  }

  /// Logout method
  void logout() {
    // Stop location tracking
    if (_loggedInUserId != null) {
      LocationTrackingService().setWorkerOffline(_loggedInUserId!);
      LocationTrackingService().stopLocationTracking();
    }

    // Stop Firestore notifications listener
    try {
      example_notif.NotificationService().stopFirestoreNotificationListener();
    } catch (_) {}

    _isLoggedIn = false;
    _loggedInUserId = null;
    _loggedInPhoneNumber = null;
    _currentPhoneNumber = null;
    _verificationId = null;
    _error = null;
    _success = null;
    notifyListeners();
    print('👋 Skilled Worker logged out');
  }

  /// Deprecated: Do not use. Enforce real Firebase verification.
  Future<bool> verifyOtp(String smsCode) async {
    _error =
        'Deprecated method verifyOtp() was called. Please use login(phone, code).';
    notifyListeners();
    return false;
  }

  String? _verificationId;
  bool _isLoading = false;
  String? _error;
  String? _success;
  String? _currentPhoneNumber;
  bool _hasPaidFee = false;
  // Temp image files during registration
  File? _cnicFrontFile;
  File? _cnicBackFile;

  // Location related fields
  double? _currentLatitude;
  double? _currentLongitude;
  String _currentAddress = '';
  bool _isLocationLoading = false;
  String? _locationError;
  bool _hasLocationPermission = false;
  bool _isLocationServiceEnabled = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;
  bool get hasPaidFee => _hasPaidFee;
  File? get cnicFrontFile => _cnicFrontFile;
  File? get cnicBackFile => _cnicBackFile;

  void setCnicImages(File front, File back) {
    _cnicFrontFile = front;
    _cnicBackFile = back;
    notifyListeners();
  }

  /// Upload CNIC images immediately and persist URLs to Firestore
  Future<Map<String, String>> uploadCnicImages({
    required File front,
    required File back,
  }) async {
    if (!_isLoggedIn || _loggedInUserId == null) {
      throw Exception('User not logged in');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final frontUrl = await UserStorageService.uploadUserImage(
        userId: _loggedInUserId!,
        file: front,
        pathSegment: 'cnic_front',
      );
      final backUrl = await UserStorageService.uploadUserImage(
        userId: _loggedInUserId!,
        file: back,
        pathSegment: 'cnic_back',
      );

      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(_loggedInUserId!)
          .set({
            'CNICFront': frontUrl,
            'CNICBack': backUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _cnicFrontFile = front;
      _cnicBackFile = back;
      _isLoading = false;
      notifyListeners();
      return {'front': frontUrl, 'back': backUrl};
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to upload CNIC images: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Upload profile picture immediately and persist URL to Firestore
  Future<String> uploadProfileImage(File image) async {
    if (!_isLoggedIn || _loggedInUserId == null) {
      throw Exception('User not logged in');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = await UserStorageService.uploadUserImage(
        userId: _loggedInUserId!,
        file: image,
        pathSegment: 'profile',
      );

      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(_loggedInUserId!)
          .set({
            'ProfilePicture': url,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to upload profile image: $e';
      notifyListeners();
      rethrow;
    }
  }

  // Location getters
  double? get currentLatitude => _currentLatitude;
  double? get currentLongitude => _currentLongitude;
  String get currentAddress => _currentAddress;
  bool get isLocationLoading => _isLocationLoading;
  String? get locationError => _locationError;
  bool get hasLocationPermission => _hasLocationPermission;
  bool get isLocationServiceEnabled => _isLocationServiceEnabled;

  void setPaidFee(bool value) {
    _hasPaidFee = value;
    notifyListeners();
  }

  /// Initialize location services for skilled worker
  Future<void> initializeLocationServices() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _isLocationServiceEnabled = serviceEnabled;

      if (!serviceEnabled) {
        _locationError =
            'Please turn on location services on your mobile device to get your current location automatically.';
        _isLocationLoading = false;
        notifyListeners();
        return;
      }

      // Check and request location permissions
      bool hasPermission = await PermissionHandler.requestLocationPermissions();
      _hasLocationPermission = hasPermission;

      if (!hasPermission) {
        _locationError =
            'Location permissions are required. Please enable location permissions in your device settings.';
        _isLocationLoading = false;
        notifyListeners();
        return;
      }

      // Get current location
      await getCurrentLocation();
    } catch (e) {
      _locationError = 'Error initializing location services: $e';
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  /// Get current location of skilled worker
  Future<void> getCurrentLocation() async {
    if (!_hasLocationPermission) {
      _locationError = 'Location permission not granted';
      notifyListeners();
      return;
    }

    if (!_isLocationServiceEnabled) {
      _locationError =
          'Please turn on location services on your mobile device to get your current location automatically.';
      notifyListeners();
      return;
    }

    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLatitude = position.latitude;
      _currentLongitude = position.longitude;

      // Get address from coordinates
      await _getAddressFromCoordinates(position.latitude, position.longitude);

      // Update location in Firestore if user is logged in
      await _updateLocationInFirestore();

      _isLocationLoading = false;
      _locationError = null;
      notifyListeners();
    } catch (e) {
      _locationError = 'Error getting current location: $e';
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  /// Get address from coordinates
  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _currentAddress = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');
      }
    } catch (e) {
      _currentAddress =
          'Location coordinates: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
  }

  /// Update location in Firestore
  Future<void> _updateLocationInFirestore() async {
    try {
      // Use test authentication instead of Firebase Auth
      if (_isLoggedIn &&
          _loggedInUserId != null &&
          _currentLatitude != null &&
          _currentLongitude != null) {
        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(_loggedInUserId!)
            .update({
              'currentLatitude': _currentLatitude,
              'currentLongitude': _currentLongitude,
              'currentAddress': _currentAddress,
              'locationUpdatedAt': FieldValue.serverTimestamp(),
            });
        print('✅ Location updated in Firestore for user: $_loggedInUserId');
      } else {
        print(
          '⚠️ Cannot update location: User not logged in or location not available',
        );
      }
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  /// Set location manually (for testing or manual input)
  void setLocation(double latitude, double longitude, String address) {
    _currentLatitude = latitude;
    _currentLongitude = longitude;
    _currentAddress = address;
    _updateLocationInFirestore();
    notifyListeners();
  }

  /// Clear location error
  void clearLocationError() {
    _locationError = null;
    notifyListeners();
  }

  /// Refresh location
  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }

  /// Check if location is available and ready
  bool get isLocationReady =>
      _currentLatitude != null &&
      _currentLongitude != null &&
      _hasLocationPermission &&
      _isLocationServiceEnabled;

  void verifyPhone(String phoneNumber) async {
    _isLoading = true;
    _error = null;
    _verificationId = null;
    notifyListeners();

    final input = phoneNumber.trim();
    print('📱 Sending OTP (skilled worker) to: "$input"');

    // Temporary bypass: direct login without OTP
    try {
      final formatted = formatPhoneNumber(input);
      final digitsOnly = formatted.replaceAll(RegExp(r'[^0-9]'), '');
      final localUserId = 'SKILLED_WORKER_\${digitsOnly}';

      _currentPhoneNumber = formatted;
      _loggedInPhoneNumber = formatted;
      _loggedInUserId = localUserId;
      _isLoggedIn = true;

      // Save FCM token and start Firestore notifications listener
      try {
        final notifService = example_notif.NotificationService();
        final token = notifService.fcmToken;
        if (_loggedInUserId != null && token != null && token.isNotEmpty) {
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
                'userType': 'skilled_worker',
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
        print('⚠️ Could not setup notifications on worker direct login: $e');
      }

      // Ensure worker document exists
      await _createSkilledWorkerDocument();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Direct login failed: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _proceedWithPhoneVerification(String input) {
    // Firebase OTP flow temporarily disabled; keeping code commented for future use.
    /*
    fb_auth.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatPhoneNumber(input),
      forceResendingToken: _resendToken,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        try {
          final userCred = await fb_auth.FirebaseAuth.instance
              .signInWithCredential(credential);
          _currentPhoneNumber = input;
          _loggedInPhoneNumber = input;
          _loggedInUserId = userCred.user?.uid;
          _isLoggedIn = true;
          _isLoading = false;
          notifyListeners();
        } catch (e) {
          _error = 'Auto verification failed: ${e.toString()}';
          _isLoading = false;
          notifyListeners();
        }
      },
      verificationFailed: (fb_auth.FirebaseAuthException e) {
        print('❌ verificationFailed: ${e.code} - ${e.message}');
        _error = e.message ?? e.code;
        _isLoading = false;
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) {
        print('✅ codeSent received, verificationId set');
        _verificationId = verificationId;
        _resendToken = resendToken;
        _currentPhoneNumber = input;
        _isLoading = false;
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('⏰ codeAutoRetrievalTimeout, verificationId retained');
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
      },
    );
    */
  }

  Future<void> signInWithOTP(String smsCode, VoidCallback onSuccess) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Verifying OTP: $smsCode for phone: $_currentPhoneNumber');

    try {
      // DEV TEST BYPASS: Accept Firebase Console test number for skilled worker
      final pn = (_currentPhoneNumber ?? '').replaceAll(' ', '');
      final testWorkerPhones = <String>{
        '+923115798273',
        '03115798273',
        '3115798273',
      };
      if (testWorkerPhones.contains(pn) && smsCode.trim() == '123456') {
        _isLoggedIn = true;
        _loggedInPhoneNumber = pn;
        _loggedInUserId =
            'SKILLED_WORKER_TEST_${pn.replaceAll(RegExp(r'[^0-9]'), '')}';
        _isLoading = false;
        notifyListeners();
        onSuccess();
        return;
      }

      if (_verificationId == null) {
        _error = 'No verification ID. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } on fb_auth.FirebaseAuthException catch (e) {
      _error = 'Verification failed: ${e.message ?? e.code}';
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to verify OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postSkilledWorker({
    required String name,
    required int age,
    required String city,
    required int workingRadiusKm,
    File? profileImage,
  }) async {
    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    // Enforce real authentication
    if (!_isLoggedIn || _loggedInUserId == null) {
      _isLoading = false;
      _error = 'Please verify your phone number first.';
      notifyListeners();
      return;
    }

    final String skilledWorkerId = _loggedInUserId!;
    final String phoneNumber = _loggedInPhoneNumber ?? 'unknown';
    final String displayName = name;

    // Check if skilled worker exists, if not create one
    try {
      final skilledWorkerDoc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(skilledWorkerId)
              .get();

      if (!skilledWorkerDoc.exists) {
        // Create skilled worker document
        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(skilledWorkerId)
            .set({
              'userId': skilledWorkerId,
              'phoneNumber': phoneNumber,
              'displayName': displayName,
              'createdAt': FieldValue.serverTimestamp(),
              'isActive': true,
              'isApproved': false, // Requires admin approval
              'approvalStatus': 'pending', // Pending approval
              'currentLatitude': _currentLatitude,
              'currentLongitude': _currentLongitude,
              'currentAddress': _currentAddress,
              'locationUpdatedAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      _error = 'Failed to create skilled worker profile: $e';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Placeholder urls before upload
    String profileUrl = 'https://via.placeholder.com/150';
    String cnicFrontUrl = 'https://via.placeholder.com/300x200?text=CNIC+Front';
    String cnicBackUrl = 'https://via.placeholder.com/300x200?text=CNIC+Back';

    // Upload images if available
    try {
      if (profileImage != null) {
        profileUrl = await UserStorageService.uploadUserImage(
          userId: skilledWorkerId,
          file: profileImage,
          pathSegment: 'profile',
        );
      }
      if (_cnicFrontFile != null) {
        cnicFrontUrl = await UserStorageService.uploadUserImage(
          userId: skilledWorkerId,
          file: _cnicFrontFile!,
          pathSegment: 'cnic_front',
        );
      }
      if (_cnicBackFile != null) {
        cnicBackUrl = await UserStorageService.uploadUserImage(
          userId: skilledWorkerId,
          file: _cnicBackFile!,
          pathSegment: 'cnic_back',
        );
      }
    } catch (e) {
      // Non-fatal: continue with placeholders but record error
      print('Image upload failed: $e');
    }

    final workerData = {
      'Name': name,
      'Age': age,
      'City': city,
      'workingRadiusKm': workingRadiusKm,
      'ProfilePicture': profileUrl,
      'CNICFront': cnicFrontUrl,
      'CNICBack': cnicBackUrl,
      'skilledWorkerId': skilledWorkerId,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
      'isApproved': false, // Requires admin approval
      'approvalStatus': 'pending', // Pending approval
      'currentLatitude': _currentLatitude,
      'currentLongitude': _currentLongitude,
      'currentAddress': _currentAddress,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(skilledWorkerId)
          .set(workerData, SetOptions(merge: true));
      _success =
          'Skilled worker registered successfully! Worker ID: $skilledWorkerId';
      _isLoading = false;
      // Clear temp images after successful save
      _cnicFrontFile = null;
      _cnicBackFile = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to register skilled worker: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearStatus() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}
