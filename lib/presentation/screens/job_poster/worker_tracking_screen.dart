import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/worker_tracking_map.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class WorkerTrackingScreen extends StatefulWidget {
  final String jobId;
  final String? workerId;

  const WorkerTrackingScreen({Key? key, required this.jobId, this.workerId})
    : super(key: key);

  @override
  State<WorkerTrackingScreen> createState() => _WorkerTrackingScreenState();
}

class _WorkerTrackingScreenState extends State<WorkerTrackingScreen> {
  LatLng? _jobLocation;
  bool _isLoading = true;
  Map<String, dynamic>? _jobData;
  Map<String, dynamic>? _workerData;

  @override
  void initState() {
    super.initState();
    _loadJobAndWorkerData();
  }

  Future<void> _loadJobAndWorkerData() async {
    try {
      // Load job data
      final jobDoc =
          await FirebaseFirestore.instance
              .collection('Job')
              .doc(widget.jobId)
              .get();

      if (jobDoc.exists) {
        setState(() {
          _jobData = jobDoc.data()!;
        });

        // Get job location
        final location = _jobData!['location'] as GeoPoint?;
        if (location != null) {
          setState(() {
            _jobLocation = LatLng(location.latitude, location.longitude);
          });
        }
      }

      // Load worker data if workerId is provided
      if (widget.workerId != null) {
        final workerDoc =
            await FirebaseFirestore.instance
                .collection('SkilledWorkers')
                .doc(widget.workerId!)
                .get();

        if (workerDoc.exists) {
          setState(() {
            _workerData = workerDoc.data()!;
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trackWorker),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadJobAndWorkerData,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refreshLocation,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_jobData == null) {
      return Center(child: Text(l10n.jobNotFound));
    }

    return Column(
      children: [
        // Job info card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _jobData!['title_en'] ??
                    _jobData!['title'] ??
                    _jobData!['title_ur'] ??
                    l10n.jobTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _jobData!['description_en'] ??
                    _jobData!['description'] ??
                    _jobData!['description_ur'] ??
                    l10n.noDescription,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              // Service type information
              if (_jobData!['serviceType'] != null) ...[
                const SizedBox(height: 8),
                _buildServiceTypeInfo(l10n),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _jobData!['Address'] ??
                          _jobData!['address'] ??
                          l10n.noAddress,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Worker info card
        if (_workerData != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage:
                      _workerData!['profileImageUrl'] != null
                          ? NetworkImage(_workerData!['profileImageUrl'])
                          : null,
                  child:
                      _workerData!['profileImageUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _workerData!['name'] ??
                            _workerData!['skilledWorkerName'] ??
                            l10n.skilledWorkerText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _workerData!['phoneNumber'] ?? l10n.noPhoneInfo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (_workerData!['isOnline'] ?? false)
                                      ? Colors.green
                                      : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (_workerData!['isOnline'] ?? false)
                                  ? l10n.statusOnline
                                  : l10n.statusOffline,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${l10n.lastSeenLabel}: ${_formatLastSeen(_workerData!['lastSeen'], l10n)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Map
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: WorkerTrackingMap(
                jobId: widget.jobId,
                workerId: widget.workerId,
                jobLocation: _jobLocation,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceTypeInfo(AppLocalizations l10n) {
    final serviceType = _localizeValue(
      _jobData!['serviceType'] as String?,
      l10n,
    );

    if (serviceType.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          const Text('🛠', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              serviceType,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _localizeValue(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty || value == 'null') return '';
    final lower = value.toLowerCase().trim();
    bool isUrdu = l10n.contactUs == 'ہم سے رابطہ کریں';
    if (lower == 'cleaning services') return l10n.cleaningServices;
    if (lower == 'plumbing services') return l10n.plumbingServices;
    if (lower == 'roofing services') return l10n.roofingServices;
    if (lower == 'electrical services') return l10n.electricalServices;
    if (lower == 'car care services') return l10n.carCareServices;
    if (lower == 'islamabad') return isUrdu ? 'اسلام آباد' : 'Islamabad';
    if (lower == 'lahore') return isUrdu ? 'لاہور' : 'Lahore';
    if (lower == 'karachi') return isUrdu ? 'کراچی' : 'Karachi';
    if (lower == 'rawalpindi') return isUrdu ? 'راولپنڈی' : 'Rawalpindi';
    if (lower == 'peshawar') return isUrdu ? 'پشاور' : 'Peshawar';
    return value;
  }

  String _formatLastSeen(dynamic lastSeen, AppLocalizations l10n) {
    if (lastSeen == null) return l10n.neverLabel;

    DateTime lastSeenTime;
    if (lastSeen is Timestamp) {
      lastSeenTime = lastSeen.toDate();
    } else {
      return l10n.unknown;
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenTime);

    if (difference.inMinutes < 1) {
      return l10n.justNowLabel;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${l10n.minutesAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${l10n.hoursAgo}';
    } else {
      return '${difference.inDays}${l10n.daysAgo}';
    }
  }
}
