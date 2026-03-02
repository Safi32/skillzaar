import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationStateProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isManualMode = false;
  String _selectedAddress = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  LatLng? _center;
  Set<Marker> _markers = {};
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isManualMode => _isManualMode;
  String get selectedAddress => _selectedAddress;
  double? get selectedLatitude => _selectedLatitude;
  double? get selectedLongitude => _selectedLongitude;
  LatLng? get center => _center;
  Set<Marker> get markers => _markers;
  String? get errorMessage => _errorMessage;

  // Loading state management
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Mode management
  void toggleMode() {
    _isManualMode = !_isManualMode;
    notifyListeners();
  }

  void setManualMode(bool manual) {
    _isManualMode = manual;
    notifyListeners();
  }

  // Address management
  void setSelectedAddress(String address) {
    _selectedAddress = address;
    notifyListeners();
  }

  // Location management
  void setSelectedLocation(double latitude, double longitude) {
    _selectedLatitude = latitude;
    _selectedLongitude = longitude;
    notifyListeners();
  }

  void setCenter(LatLng center) {
    _center = center;
    notifyListeners();
  }

  // Marker management
  void addMarker(Marker marker) {
    _markers.clear();
    _markers.add(marker);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  // Error management
  void setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Reset state
  void reset() {
    _isLoading = false;
    _isManualMode = false;
    _selectedAddress = '';
    _selectedLatitude = null;
    _selectedLongitude = null;
    _center = null;
    _markers.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
