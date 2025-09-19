import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../widgets/worker_tracking_map.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Tracking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadJobAndWorkerData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_jobData == null) {
      return const Center(child: Text('Job not found'));
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
                _jobData!['title_en'] ?? _jobData!['title'] ?? 'Job Title',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _jobData!['description_en'] ??
                    _jobData!['description'] ??
                    'No description',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              // Service type information
              if (_jobData!['serviceType'] != null) ...[
                const SizedBox(height: 8),
                _buildServiceTypeInfo(),
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
                          'No address',
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
                        _workerData!['name'] ?? 'Worker',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _workerData!['phoneNumber'] ?? 'No phone',
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
                                  ? 'Online'
                                  : 'Offline',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Last seen: ${_formatLastSeen(_workerData!['lastSeen'])}',
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

  Widget _buildServiceTypeInfo() {
    final serviceType = _jobData!['serviceType'] as String?;

    if (serviceType == null) return const SizedBox.shrink();

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

  String _formatLastSeen(dynamic lastSeen) {
    if (lastSeen == null) return 'Never';

    DateTime lastSeenTime;
    if (lastSeen is Timestamp) {
      lastSeenTime = lastSeen.toDate();
    } else {
      return 'Unknown';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeenTime);

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
}
