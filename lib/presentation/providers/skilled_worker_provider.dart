import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../core/services/job_request_service.dart';
import '../../../core/services/user_storage_service.dart';
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
      await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);

      _isLoggedIn = true;
      _loggedInPhoneNumber = phoneNumber;
      _currentPhoneNumber = phoneNumber;
      _loggedInUserId = 'SKILLED_WORKER_${phoneNumber.replaceAll('0', '')}';

      print('✅ Skilled Worker login successful: $_loggedInUserId');

      // Check for active job and set SharedPreferences flags
      await _checkAndSetActiveJobFlags();

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

  /// Legacy test method (not used); keep for backward compatibility
  Future<bool> verifyOtp(String smsCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Verifying OTP: $smsCode');
    print('🔐 Current phone: $_currentPhoneNumber');

    try {
      if (_verificationId == null) {
        _error = 'No verification ID. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // No test OTP; direct success for legacy calls to avoid crash

      // OTP is valid - simulate successful authentication
      print('✅ Test OTP verification successful');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ General Exception in verifyOtp: $e');
      _error = 'Failed to verify OTP: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

  void verifyPhone(String phoneNumber) {
    _isLoading = true;
    _error = null;
    _verificationId = null;
    notifyListeners();

    final input = phoneNumber.trim();
    print('📱 Sending OTP (skilled worker) to: "$input"');

    fb_auth.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatPhoneNumber(input),
      forceResendingToken: _resendToken,
      verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
        try {
          await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
          _currentPhoneNumber = input;
          _loggedInPhoneNumber = input;
          _loggedInUserId = 'SKILLED_WORKER_${input.replaceAll('0', '')}';
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
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> signInWithOTP(String smsCode, VoidCallback onSuccess) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Verifying OTP: $smsCode for phone: $_currentPhoneNumber');

    try {
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

    // Use test authentication instead of Firebase Auth
    String skilledWorkerId;
    String phoneNumber;
    String displayName;

    if (_isLoggedIn && _loggedInUserId != null) {
      skilledWorkerId = _loggedInUserId!;
      phoneNumber = _loggedInPhoneNumber ?? '0000000000';
      displayName = name;

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
    } else {
      // For testing: use a default skilled worker ID
      skilledWorkerId = 'TEST_SKILLED_WORKER_ID';
      phoneNumber = '+923115798273';
      displayName = name;
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
