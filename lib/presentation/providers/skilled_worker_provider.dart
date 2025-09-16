import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/permission_handler.dart';
import '../../../core/services/job_request_service.dart';


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
  static const List<String> _allowedTestNumbers = [
    '03115798273',
    '03092939350',
  ];

  static const String _testOtp = '123456';

  // User session management
  bool _isLoggedIn = false;
  String? _loggedInUserId;
  String? _loggedInPhoneNumber;

  bool get isLoggedIn => _isLoggedIn;
  String? get loggedInUserId => _loggedInUserId;
  String? get loggedInPhoneNumber => _loggedInPhoneNumber;

  /// Login method for skilled workers
  Future<bool> login(String phoneNumber, String otp) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔐 Skilled Worker Login: $phoneNumber');

    try {
      // Verify phone number is allowed
      if (!_allowedTestNumbers.contains(phoneNumber.trim())) {
        _error = 'Only the two test numbers are allowed for login.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Verify OTP
      if (otp != _testOtp) {
        _error = 'Invalid OTP code. Please use 123456.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Simulate successful login
      _isLoggedIn = true;
      _loggedInUserId = 'SKILLED_WORKER_${phoneNumber.replaceAll('0', '')}';
      _loggedInPhoneNumber = phoneNumber;
      _currentPhoneNumber = phoneNumber;

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

  /// Verifies the OTP using test authentication
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

      // Only allow 6-digit OTP
      if (smsCode != _testOtp) {
        _error = 'Invalid OTP code. Please use 123456.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

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
    print('📱 Verifying phone: "$input"');

    // Only allow the two test numbers
    if (!_allowedTestNumbers.contains(input)) {
      _error = 'Only the two test numbers are allowed for login/signup.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Simulate OTP sent
    _verificationId = 'test_verification_id';
    _currentPhoneNumber = input;
    _isLoading = false;
    notifyListeners();

    print('✅ Test OTP sent to phone: $input');
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

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _isLoading = false;
      notifyListeners();
      onSuccess();
    } on FirebaseAuthException catch (e) {
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

    final workerData = {
      'Name': name,
      'Age': age,
      'City': city,
      'ProfilePicture': 'https://via.placeholder.com/150',
      'CNICFront': 'https://via.placeholder.com/300x200?text=CNIC+Front',
      'CNICBack': 'https://via.placeholder.com/300x200?text=CNIC+Back',
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
