import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;
  String? _currentUserId;
  bool _isTracking = false;

  Future<bool> startLocationTracking(String userId) async {
    try {    
      final permission = await _checkLocationPermission();
      if (!permission) {
        return false;
      }

      _currentUserId = userId;
      _isTracking = true;      
      _startStreamingLocationUpdates();

      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopLocationTracking() async {
    _isTracking = false;
    _currentUserId = null;

    await _positionStream?.cancel();
    _positionStream = null;

    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Check if location tracking is active
  bool get isTracking => _isTracking;

  /// Start streaming location updates to Firestore
  void _startStreamingLocationUpdates() {
    // Cancel any existing streams/timers
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15, // Update when user moves 15 meters
      ),
    ).listen((position) async {
      if (!_isTracking || _currentUserId == null) return;
      try {
        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(_currentUserId!)
            .update({
              'currentLocation': GeoPoint(
                position.latitude,
                position.longitude,
              ),
              'lastLocationUpdate': FieldValue.serverTimestamp(),
              'isOnline': true,
            });
      } catch (e) {
        print('Error streaming location update: $e');
      }
    });

    // Also push an immediate update
    _updateLocation();
  }

  /// Update current location to Firestore
  Future<void> _updateLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (_currentUserId != null) {
        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(_currentUserId!)
            .update({
              'currentLocation': GeoPoint(
                position.latitude,
                position.longitude,
              ),
              'lastLocationUpdate': FieldValue.serverTimestamp(),
              'isOnline': true,
            });
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  /// Check and request location permission
  Future<bool> _checkLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await _checkLocationPermission();
      if (!permission) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Calculate distance between two points
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Get location stream for real-time updates
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }

  /// Set worker as offline
  Future<void> setWorkerOffline(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(userId)
          .update({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error setting worker offline: $e');
    }
  }
}
