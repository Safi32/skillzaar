import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../../core/services/job_request_service.dart';
import '../../../core/config/google_maps_config.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class NavigateToJobScreen extends StatelessWidget {
  final String jobId;
  final String jobTitle;
  final String jobAddress;
  final double jobLatitude;
  final double jobLongitude;

  const NavigateToJobScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.jobAddress,
    required this.jobLatitude,
    required this.jobLongitude,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<SkilledWorkerProvider, UIStateProvider>(
      builder: (context, skilledWorkerProvider, uiProvider, child) {
        return _NavigateToJobContent(
          skilledWorkerProvider: skilledWorkerProvider,
          uiProvider: uiProvider,
          jobId: jobId,
          jobTitle: jobTitle,
          jobAddress: jobAddress,
          jobLatitude: jobLatitude,
          jobLongitude: jobLongitude,
        );
      },
    );
  }
}

class _NavigateToJobContent extends StatefulWidget {
  final SkilledWorkerProvider skilledWorkerProvider;
  final UIStateProvider uiProvider;
  final String jobId;
  final String jobTitle;
  final String jobAddress;
  final double jobLatitude;
  final double jobLongitude;

  const _NavigateToJobContent({
    required this.skilledWorkerProvider,
    required this.uiProvider,
    required this.jobId,
    required this.jobTitle,
    required this.jobAddress,
    required this.jobLatitude,
    required this.jobLongitude,
  });

  @override
  State<_NavigateToJobContent> createState() => _NavigateToJobContentState();
}

class _NavigateToJobContentState extends State<_NavigateToJobContent> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _workerLocation;
  LatLng? _jobLocation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  Future<void> _initializeMap() async {
    if (!mounted) return;
    final provider = Provider.of<SkilledWorkerProvider>(context, listen: false);

    // Check if location is already available
    if (provider.currentLatitude != null && provider.currentLongitude != null) {
      _workerLocation = LatLng(
        provider.currentLatitude!,
        provider.currentLongitude!,
      );
      _jobLocation = LatLng(widget.jobLatitude, widget.jobLongitude);
      _addMarkers();
      _isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    // Try to initialize location services if not available
    try {
      await provider.initializeLocationServices();

      // Wait a moment for location to be fetched
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (provider.currentLatitude != null &&
          provider.currentLongitude != null) {
        _workerLocation = LatLng(
          provider.currentLatitude!,
          provider.currentLongitude!,
        );
        _jobLocation = LatLng(widget.jobLatitude, widget.jobLongitude);
        _addMarkers();
        _isLoading = false;
        if (mounted) setState(() {});
      } else {
        _error = provider.locationError ?? 'Worker location not available';
        _isLoading = false;
        if (mounted) setState(() {});
      }
    } catch (e) {
      _error = 'Error initializing location: $e';
      _isLoading = false;
      if (mounted) setState(() {});
    }
  }

  void _addMarkers() {
    if (_workerLocation != null && _jobLocation != null) {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('worker_location'),
          position: _workerLocation!,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Starting point',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('job_location'),
          position: _jobLocation!,
          infoWindow: InfoWindow(
            title: widget.jobTitle,
            snippet: widget.jobAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
  }

  Future<void> _launchNavigation() async {
    final provider = Provider.of<SkilledWorkerProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    if (provider.currentLatitude == null || provider.currentLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enableLocationServicesToGetDirections),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await JobRequestService.launchNavigation(
        fromLat: provider.currentLatitude!,
        fromLng: provider.currentLongitude!,
        toLat: widget.jobLatitude,
        toLng: widget.jobLongitude,
        toAddress: widget.jobAddress,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error launching navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SkilledWorkerProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.navigateTo} ${widget.jobTitle}'),
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
                        l10n.workerLocationNotAvailable,
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error ?? l10n.enableLocationServicesToGetDirections,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              widget.uiProvider.startLoading();
                              setState(() {
                                _isLoading = true;
                                _error = null;
                              });
                              await _initializeMap();
                              widget.uiProvider.stopLoading();
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(l10n.retry),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Navigate back to job details
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.arrow_back),
                            label: Text(l10n.goBack),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
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
                              Icons.route,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.routeInformation,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.currentAddress.isNotEmpty
                                    ? provider.currentAddress
                                    : l10n.yourCurrentLocation,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.jobAddress,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (provider.currentLatitude != null)
                          Row(
                            children: [
                              Icon(
                                Icons.straighten,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${l10n.distanceLabel}: ${JobRequestService.calculateDistance(provider.currentLatitude!, provider.currentLongitude!, widget.jobLatitude, widget.jobLongitude).toStringAsFixed(1)} km',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _launchNavigation,
                            icon: const Icon(Icons.directions),
                            label: Text(l10n.getDirections),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                                _jobLocation ?? const LatLng(30.3753, 69.3451),
                            zoom: GoogleMapsConfig.defaultZoom,
                          ),
                          markers: _markers,
                          polylines: _polylines,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          mapToolbarEnabled: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
