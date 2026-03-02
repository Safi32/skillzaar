import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/google_maps_config.dart';
import '../../../core/utils/permission_handler.dart';
import '../providers/ui_state_provider.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(String address, double latitude, double longitude)
  onLocationSelected;
  final String initialAddress;
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerWidget({
    super.key,
    required this.onLocationSelected,
    this.initialAddress = '',
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _center;
  String _selectedAddress = '';
  double? _selectedLatitude;
  double? _selectedLongitude;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _manualAddressController =
      TextEditingController();
  bool _isLoading = false;
  bool _isManualMode = false;

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress;
    _manualAddressController.text = widget.initialAddress;
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatitude = widget.initialLatitude;
      _selectedLongitude = widget.initialLongitude;
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _addMarker(_center!);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _manualAddressController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      if (_isManualMode) {
        _manualAddressController.text = _selectedAddress;
      } else {
        if (_selectedLatitude != null && _selectedLongitude != null) {
          _getAddressFromCoordinates(_selectedLatitude!, _selectedLongitude!);
        }
      }
    });
  }

  void _onManualAddressChanged(String address) {
    setState(() {
      _selectedAddress = address;
    });

    // For manual mode, we'll use a default location (can be updated later)
    // For now, we'll use the last known coordinates or a default
    if (_selectedLatitude != null && _selectedLongitude != null) {
      widget.onLocationSelected(
        address,
        _selectedLatitude!,
        _selectedLongitude!,
      );
    } else {
      // Use a default location (e.g., center of Pakistan)
      const defaultLat = 30.3753;
      const defaultLng = 69.3451;
      _selectedLatitude = defaultLat;
      _selectedLongitude = defaultLng;
      _center = LatLng(defaultLat, defaultLng);
      _addMarker(_center!);
      widget.onLocationSelected(address, defaultLat, defaultLng);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Check and request location permissions
      bool hasPermission = await PermissionHandler.requestLocationPermissions();
      if (!hasPermission) {
        _showErrorSnackBar(
          'Location permissions are required to get your current location',
        );
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar(
          'Location services are disabled. Please enable location services in your device settings.',
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = newCenter;
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      _addMarker(newCenter);
      await _getAddressFromCoordinates(position.latitude, position.longitude);

      // Show location success toast
      if (context.mounted) {
        context.read<UIStateProvider>().showLocationToast(
          context,
          '📍 Location access granted! GPS is now active.',
        );
      }

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newCenter, GoogleMapsConfig.defaultZoom),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error getting current location: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Selected Location'),
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLatitude = newPosition.latitude;
              _selectedLongitude = newPosition.longitude;
            });
            _getAddressFromCoordinates(
              newPosition.latitude,
              newPosition.longitude,
            );
          },
        ),
      );
    });
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _selectedAddress = address;
          _manualAddressController.text = address;
        });

        widget.onLocationSelected(address, lat, lng);
      }
    } catch (e) {
      _showErrorSnackBar('Error getting address: $e');
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedLatitude = position.latitude;
      _selectedLongitude = position.longitude;
    });
    _addMarker(position);
    _getAddressFromCoordinates(position.latitude, position.longitude);
  }

  void _onCameraMove(CameraPosition position) {
    // Update center when camera moves
    setState(() {
      _center = position.target;
    });
  }

  void _onCameraIdle() {
    // When camera stops moving, get the address for the center position
    if (_center != null &&
        _selectedLatitude != null &&
        _selectedLongitude != null) {
      _getAddressFromCoordinates(_center!.latitude, _center!.longitude);
    }
  }

  void _showErrorSnackBar(String message) {
    // Show error toast instead of SnackBar
    if (context.mounted) {
      context.read<UIStateProvider>().showErrorToast(
        context,
        'Location Error',
        message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Toggle
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_isManualMode) _toggleMode();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          !_isManualMode ? AppColors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.my_location,
                          color:
                              !_isManualMode
                                  ? Colors.white
                                  : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Auto Location',
                            style: TextStyle(
                              color:
                                  !_isManualMode
                                      ? Colors.white
                                      : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_isManualMode) _toggleMode();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isManualMode ? AppColors.green : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_location,
                          color:
                              _isManualMode
                                  ? Colors.white
                                  : Colors.grey.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Manual Address',
                            style: TextStyle(
                              color:
                                  _isManualMode
                                      ? Colors.white
                                      : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Manual Address Input (when in manual mode) - Now using Google Places
        if (_isManualMode) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Address Entry',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search and select the exact address where the job needs to be done. This will automatically get the precise coordinates.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                GooglePlaceAutoCompleteTextField(
                  textEditingController: _manualAddressController,
                  googleAPIKey: GoogleMapsConfig.apiKey,
                  inputDecoration: InputDecoration(
                    hintText:
                        'Search for an address (e.g., House 123, Street 45, City)',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  debounceTime: 800,
                  countries: [GoogleMapsConfig.defaultCountry],
                  isLatLngRequired: true,
                  getPlaceDetailWithLatLng: (Prediction prediction) {
                    if (prediction.lat != null && prediction.lng != null) {
                      final lat = double.parse(prediction.lat!);
                      final lng = double.parse(prediction.lng!);
                      final newCenter = LatLng(lat, lng);

                      setState(() {
                        _center = newCenter;
                        _selectedLatitude = lat;
                        _selectedLongitude = lng;
                        _selectedAddress = prediction.description ?? '';
                      });

                      _addMarker(newCenter);
                      widget.onLocationSelected(_selectedAddress, lat, lng);

                      // Show success toast instead of SnackBar
                      if (context.mounted) {
                        context.read<UIStateProvider>().showSuccessToast(
                          context,
                          'Location Selected!',
                          'Address: $_selectedAddress',
                        );
                      }
                    }
                  },
                  itemClick: (Prediction prediction) {
                    _manualAddressController.text =
                        prediction.description ?? '';
                    _manualAddressController
                        .selection = TextSelection.fromPosition(
                      TextPosition(
                        offset: _manualAddressController.text.length,
                      ),
                    );
                  },
                  seperatedBuilder: const Divider(),
                  isCrossBtnShown: true,
                ),
              ],
            ),
          ),
        ] else ...[
          // Search Bar (when in auto mode)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: GoogleMapsConfig.apiKey,
              inputDecoration: InputDecoration(
                hintText: 'Search for a location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              debounceTime: 800,
              countries: [GoogleMapsConfig.defaultCountry],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) {
                if (prediction.lat != null && prediction.lng != null) {
                  final lat = double.parse(prediction.lat!);
                  final lng = double.parse(prediction.lng!);
                  final newCenter = LatLng(lat, lng);

                  setState(() {
                    _center = newCenter;
                    _selectedLatitude = lat;
                    _selectedLongitude = lng;
                  });

                  _addMarker(newCenter);
                  _getAddressFromCoordinates(lat, lng);

                  if (_mapController != null) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        newCenter,
                        GoogleMapsConfig.defaultZoom,
                      ),
                    );
                  }
                }
              },
              itemClick: (Prediction prediction) {
                _searchController.text = prediction.description ?? '';
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _searchController.text.length),
                );
              },
              seperatedBuilder: const Divider(),
              isCrossBtnShown: true,
            ),
          ),
        ],

        // Map Container (only show in auto mode)
        if (!_isManualMode) ...[
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  if (_center != null)
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _center!,
                        zoom: GoogleMapsConfig.defaultZoom,
                      ),
                      markers: _markers,
                      onTap: _onMapTap,
                      onCameraMove: _onCameraMove,
                      onCameraIdle: _onCameraIdle,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    )
                  else
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Getting your location...'),
                        ],
                      ),
                    ),

                  // Custom location button
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton.small(
                      onPressed: _getCurrentLocation,
                      backgroundColor: AppColors.green,
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),

                  // Loading indicator
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ),
        ],

        // Selected Location Info
        if (_selectedAddress.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _isManualMode ? Icons.edit_location : Icons.location_on,
                      color: AppColors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isManualMode ? 'Manual Address' : 'Selected Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_selectedAddress, style: const TextStyle(fontSize: 14)),
                if (_selectedLatitude != null &&
                    _selectedLongitude != null &&
                    !_isManualMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Coordinates: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                if (_isManualMode)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Note: Address selected with precise coordinates',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
