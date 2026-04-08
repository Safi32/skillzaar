import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/config/google_maps_config.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class WorkerTrackingScreen extends StatefulWidget {
  final String workerId;
  final String jobTitle;
  final String jobLocation;
  final double jobLatitude;
  final double jobLongitude;

  const WorkerTrackingScreen({
    super.key,
    required this.workerId,
    required this.jobTitle,
    required this.jobLocation,
    required this.jobLatitude,
    required this.jobLongitude,
  });

  @override
  State<WorkerTrackingScreen> createState() => _WorkerTrackingScreenState();
}

class _WorkerTrackingScreenState extends State<WorkerTrackingScreen> {
  Set<Marker> _markers = {};
  LatLng? _workerLocation;
  LatLng? _jobLocation;
  bool _isLoading = true;
  String? _error;
  String _workerName = 'Worker';
  String _workerPhone = '';
  double _distance = 0.0;
  String _lastUpdateTime = '';

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  void _initializeTracking() {
    _jobLocation = LatLng(widget.jobLatitude, widget.jobLongitude);
    _addJobMarker();
    _startWorkerTracking();
  }

  void _addJobMarker() {
    if (_jobLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('job_location'),
          position: _jobLocation!,
          infoWindow: InfoWindow(
            title: widget.jobTitle,
            snippet: widget.jobLocation,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  void _addWorkerMarker() {
    if (_workerLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('worker_location'),
          position: _workerLocation!,
          infoWindow: InfoWindow(
            title:
                '${AppLocalizations.of(context)!.skilledWorkerText}: $_workerName',
            snippet: 'Last seen: $_lastUpdateTime',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
  }

  void _startWorkerTracking() {
    // Listen to worker location updates from Firestore
    FirebaseFirestore.instance
        .collection('SkilledWorkers')
        .doc(widget.workerId)
        .snapshots()
        .listen(
          (snapshot) {
            if (snapshot.exists && mounted) {
              final data = snapshot.data()!;

              setState(() {
                _workerName =
                    data['Name'] ?? data['skilledWorkerName'] ?? 'Worker';
                _workerPhone = data['phoneNumber'] ?? '';

                final lat = data['currentLatitude'] as double?;
                final lng = data['currentLongitude'] as double?;

                if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
                  _workerLocation = LatLng(lat, lng);
                  _isLoading = false;
                  _error = null;

                  // Calculate distance
                  if (_jobLocation != null) {
                    _distance = _calculateDistance(
                      _workerLocation!.latitude,
                      _workerLocation!.longitude,
                      _jobLocation!.latitude,
                      _jobLocation!.longitude,
                    );
                  }

                  // Update last seen time
                  final lastUpdate = data['lastLocationUpdate'] as Timestamp?;
                  if (lastUpdate != null) {
                    _lastUpdateTime =
                        '${lastUpdate.toDate().hour}:${lastUpdate.toDate().minute.toString().padLeft(2, '0')}';
                  } else {
                    _lastUpdateTime = 'Now';
                  }

                  // Update markers
                  _markers.clear();
                  _addJobMarker();
                  _addWorkerMarker();
                } else {
                  _error = 'Worker location not available';
                  _isLoading = false;
                }
              });
            } else {
              setState(() {
                _error = 'Worker not found';
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            setState(() {
              _error = 'Error tracking worker: $error';
              _isLoading = false;
            });
          },
        );
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.trackWorker} - ${widget.jobTitle}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.orange.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.workerTrackingUnavailable,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? l10n.unableToTrackWorkerLocation,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _startWorkerTracking();
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : SafeArea(
                child: Column(
                  children: [
                    // Worker Info Card
                    Container(
                      margin: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                      ),
                      padding: const EdgeInsets.all(10),
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
                                Icons.person,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.skilledWorkerText}: $_workerName',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.distanceToJob}: ${_distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.lastUpdate}: $_lastUpdateTime',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (_workerPhone.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${l10n.phoneText}: $_workerPhone',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Map
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            onMapCreated: (GoogleMapController controller) {
                              // Map controller not needed for this implementation
                            },
                            initialCameraPosition: CameraPosition(
                              target:
                                  _jobLocation ??
                                  const LatLng(30.3753, 69.3451),
                              zoom: GoogleMapsConfig.defaultZoom,
                            ),
                            markers: _markers,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: true,
                            mapToolbarEnabled: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
