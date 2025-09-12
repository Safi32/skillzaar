import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/utils/permission_handler.dart';

String formatPhoneNumber(String input) {
  input = input.trim().replaceAll(' ', '');
  // Remove all spaces
  if (input.startsWith('+')) return input;
  if (input.startsWith('0') && input.length == 11) {
    return '+92' + input.substring(1);
  }
  if (input.length == 10 && input.startsWith('3')) {
    // e.g. 3115798273 (no leading zero)
    return '+92' + input;
  }
  return input;
}

// Removed test numbers - using real Firebase authentication only

class SkilledWorkerProvider with ChangeNotifier {
  /// Verifies the OTP using Firebase authentication
  Future<bool> verifyOtp(String smsCode) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_verificationId == null) {
        _error = 'No verification ID. Please request OTP again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = 'Verification failed: ${e.message ?? e.code}';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
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
      final user = FirebaseAuth.instance.currentUser;
      if (user != null &&
          _currentLatitude != null &&
          _currentLongitude != null) {
        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(user.uid)
            .update({
              'currentLatitude': _currentLatitude,
              'currentLongitude': _currentLongitude,
              'currentAddress': _currentAddress,
              'locationUpdatedAt': FieldValue.serverTimestamp(),
            });
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
    notifyListeners();
    final formatted = formatPhoneNumber(phoneNumber);
    print('📱 Verifying phone: "$formatted"');

    // Use Firebase phone authentication
    FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: formatted,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        print('✅ Auto-verification completed');
        _isLoading = false;
        notifyListeners();
      },
      verificationFailed: (FirebaseAuthException e) {
        print('❌ Verification failed: ${e.code} - ${e.message}');
        _error = 'Verification failed: ${e.message ?? e.code}';
        _isLoading = false;
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) {
        print('✅ OTP sent successfully. Verification ID: $verificationId');
        _verificationId = verificationId;
        _currentPhoneNumber = formatted;
        _isLoading = false;
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('⏰ Auto-retrieval timeout. Verification ID: $verificationId');
        _verificationId = verificationId;
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

    final user = FirebaseAuth.instance.currentUser;

    // For testing purposes, use a default skilled worker ID if user is not logged in
    String skilledWorkerId;
    String phoneNumber;
    String displayName;

    if (user != null) {
      skilledWorkerId = user.uid;
      phoneNumber = user.phoneNumber ?? '0000000000';
      displayName = user.displayName ?? name;

      // Check if skilled worker exists, if not create one
      try {
        final skilledWorkerDoc =
            await FirebaseFirestore.instance
                .collection('SkilledWorkers')
                .doc(user.uid)
                .get();

        if (!skilledWorkerDoc.exists) {
          // Create skilled worker document
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(user.uid)
              .set({
                'userId': user.uid,
                'phoneNumber': user.phoneNumber ?? '0000000000',
                'displayName': user.displayName ?? 'Skilled Worker',
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
          .doc(user!.uid)
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
