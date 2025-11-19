import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class WorkerTrackingMap extends StatefulWidget {
  final String jobId;
  final String? workerId;
  final LatLng? jobLocation;

  const WorkerTrackingMap({
    Key? key,
    required this.jobId,
    this.workerId,
    this.jobLocation,
  }) : super(key: key);

  @override
  State<WorkerTrackingMap> createState() => _WorkerTrackingMapState();
}

class _WorkerTrackingMapState extends State<WorkerTrackingMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;
  LatLng? _jobLocation;
  LatLng? _workerLocation;
  bool _isLoading = true;
  String? _workerName;
  bool _isWorkerOnline = false;
  DateTime? _lastLocationUpdate;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _workerSub;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _jobLocation = widget.jobLocation ?? _currentLocation;
        _isLoading = false;
      });

      // Load worker location if workerId is provided
      if (widget.workerId != null) {
        await _loadWorkerLocation();
        _listenToWorkerLocation();
      }

      _updateMarkers();
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWorkerLocation() async {
    try {
      final workerDoc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(widget.workerId!)
              .get();

      if (workerDoc.exists) {
        final data = workerDoc.data()!;
        final location = data['currentLocation'] as GeoPoint?;
        final lastUpdate = data['lastLocationUpdate'] as Timestamp?;
        final isOnline = data['isOnline'] as bool? ?? false;

        if (location != null) {
          setState(() {
            _workerLocation = LatLng(location.latitude, location.longitude);
            _workerName = data['name'] as String?;
            _isWorkerOnline = isOnline;
            _lastLocationUpdate = lastUpdate?.toDate();
          });
        }
      }
    } catch (e) {
      print('Error loading worker location: $e');
    }
  }

  void _listenToWorkerLocation() {
    if (widget.workerId == null) return;
    _workerSub?.cancel();
    _workerSub = FirebaseFirestore.instance
        .collection('SkilledWorkers')
        .doc(widget.workerId!)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;
          final data = doc.data();
          if (data == null) return;
          final location = data['currentLocation'] as GeoPoint?;
          final lastUpdate = data['lastLocationUpdate'] as Timestamp?;
          final isOnline = data['isOnline'] as bool? ?? false;
          setState(() {
            if (location != null) {
              _workerLocation = LatLng(location.latitude, location.longitude);
            }
            _workerName = data['name'] as String?;
            _isWorkerOnline = isOnline;
            _lastLocationUpdate = lastUpdate?.toDate();
          });
          _updateMarkers();
        });
  }

  void _updateMarkers() {
    _markers.clear();

    // Add current location marker
    if (_currentLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );
    }

    // Add job location marker
    if (_jobLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('job_location'),
          position: _jobLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Job Location',
            snippet: 'Work location',
          ),
        ),
      );
    }

    // Add worker location marker
    if (_workerLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('worker_location'),
          position: _workerLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: _workerName ?? 'Worker',
            snippet: _isWorkerOnline ? 'Online' : 'Offline',
          ),
        ),
      );
    }

    setState(() {});
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _refreshWorkerLocation() async {
    if (widget.workerId != null) {
      await _loadWorkerLocation();
      _updateMarkers();
    }
  }

  double _calculateDistance() {
    if (_jobLocation != null && _workerLocation != null) {
      return Geolocator.distanceBetween(
        _jobLocation!.latitude,
        _jobLocation!.longitude,
        _workerLocation!.latitude,
        _workerLocation!.longitude,
      );
    }
    return 0.0;
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatLastUpdate() {
    if (_lastLocationUpdate == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(_lastLocationUpdate!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header with worker info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        _isWorkerOnline ? Colors.green : Colors.grey,
                    radius: 8,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _workerName ?? 'Worker',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isWorkerOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isWorkerOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshWorkerLocation,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Location',
                  ),
                ],
              ),
              if (_workerLocation != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distance: ${_formatDistance(_calculateDistance())}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Updated: ${_formatLastUpdate()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Map
        Expanded(
          child: GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _jobLocation ?? _currentLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _workerSub?.cancel();
    super.dispose();
  }
}
