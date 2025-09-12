import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/home_profile_provider.dart';
import '../../../core/services/job_request_service.dart';
import 'navigate_to_job_screen.dart';

class JobDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final DateTime? date;
  final String description;
  final String jobId;
  final String jobPosterId;

  const JobDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.date,
    required this.description,
    required this.jobId,
    required this.jobPosterId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UIStateProvider>(
      builder: (context, uiProvider, child) {
        return _JobDetailContent(
          uiProvider: uiProvider,
          imageUrl: imageUrl,
          title: title,
          location: location,
          date: date,
          description: description,
          jobId: jobId,
          jobPosterId: jobPosterId,
        );
      },
    );
  }
}

class _JobDetailContent extends StatefulWidget {
  final UIStateProvider uiProvider;
  final String imageUrl;
  final String title;
  final String location;
  final DateTime? date;
  final String description;
  final String jobId;
  final String jobPosterId;

  const _JobDetailContent({
    required this.uiProvider,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.date,
    required this.description,
    required this.jobId,
    required this.jobPosterId,
  });

  @override
  State<_JobDetailContent> createState() => _JobDetailContentState();
}

class _JobDetailContentState extends State<_JobDetailContent> {
  Map<String, dynamic>? _jobData;
  bool _isLoadingJobData = true;

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  Future<void> _loadJobData() async {
    try {
      final jobData = await JobRequestService.getJobDetails(widget.jobId);
      if (!mounted) return;
      widget.uiProvider.setLoading(false);
      setState(() {
        _jobData = jobData;
        _isLoadingJobData = false;
      });
    } catch (e) {
      if (!mounted) return;
      widget.uiProvider.setLoading(false);
      setState(() {
        _isLoadingJobData = false;
      });
    }
  }

  Future<void> requestForJob(BuildContext context) async {
    // Check if portfolio is complete first using the new method
    final homeProfileProvider = Provider.of<HomeProfileProvider>(
      context,
      listen: false,
    );

    // Check if user can request jobs (has completed portfolio)
    final canRequest = await homeProfileProvider.canRequestJobs();
    if (!canRequest) {
      // Show message to complete portfolio
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete your portfolio to send job requests'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    String skilledWorkerId;
    String skilledWorkerName;
    String skilledWorkerPhone;

    if (user != null) {
      skilledWorkerId =
          await JobRequestService.getSkilledWorkerId() ?? user.uid;
      skilledWorkerName = user.displayName ?? 'Skilled Worker';
      skilledWorkerPhone = user.phoneNumber ?? '0000000000';
    } else {
      skilledWorkerId = 'TEST_SKILLED_WORKER_ID';
      skilledWorkerName = 'Test Skilled Worker';
      skilledWorkerPhone = '+923115798273';
    }

    final actualJobPosterId =
        await JobRequestService.getJobPosterId(widget.jobId) ??
        widget.jobPosterId;

    final hasRequested = await JobRequestService.hasRequestedJob(
      widget.jobId,
      skilledWorkerId,
    );
    if (hasRequested) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have already requested this job.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await JobRequestService.createJobRequest(
      jobId: widget.jobId,
      jobPosterId: actualJobPosterId,
      skilledWorkerId: skilledWorkerId,
      skilledWorkerName: skilledWorkerName,
      skilledWorkerPhone: skilledWorkerPhone,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent to job poster!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _isJobRequestAccepted() async {
    try {
      print('🔍 Checking job request status for job ID: ${widget.jobId}');

      // Simply check if there's an accepted job request for this job ID
      final requests =
          await FirebaseFirestore.instance
              .collection('JobRequests')
              .where('jobId', isEqualTo: widget.jobId)
              .where('status', isEqualTo: 'accepted')
              .get();

      print(
        '🔍 Found ${requests.docs.length} accepted job requests for job ID: ${widget.jobId}',
      );

      if (requests.docs.isNotEmpty) {
        final requestData = requests.docs.first.data();
        print('🔍 Accepted job request data: $requestData');
        return true; // Found an accepted request for this job
      }

      print('❌ No accepted job requests found for job ID: ${widget.jobId}');
      return false;
    } catch (e) {
      print('❌ Error checking job request status: $e');
      return false;
    }
  }

  Future<String> _getJobRequestStatus() async {
    try {
      print('🔍 Getting job request status for job ID: ${widget.jobId}');

      // Simply check if there are any job requests for this job ID
      final requests =
          await FirebaseFirestore.instance
              .collection('JobRequests')
              .where('jobId', isEqualTo: widget.jobId)
              .get();

      print(
        '🔍 Found ${requests.docs.length} total job requests for job ID: ${widget.jobId}',
      );

      if (requests.docs.isEmpty) {
        print('❌ No job requests found for job ID: ${widget.jobId}');
        return 'none';
      }

      // Get the first request to check its status
      final requestData = requests.docs.first.data();
      final status = requestData['status'] as String? ?? 'pending';

      print('🔍 Job request status: $status');
      print('🔍 Full request data: $requestData');

      return status;
    } catch (e) {
      print('❌ Error getting job request status: $e');
      return 'none';
    }
  }

  void _navigateToJob(BuildContext context) async {
    // Simply navigate to the job since the button is only enabled when status is accepted
    if (_jobData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job location data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final lat =
        _jobData!['Latitude'] is double
            ? _jobData!['Latitude']
            : (_jobData!['Latitude'] as num?)?.toDouble();
    final lng =
        _jobData!['Longitude'] is double
            ? _jobData!['Longitude']
            : (_jobData!['Longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job coordinates not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => NavigateToJobScreen(
              jobId: widget.jobId,
              jobTitle: widget.title,
              jobAddress: widget.location,
              jobLatitude: lat,
              jobLongitude: lng,
            ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Date not available';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Date not available';
    } catch (e) {
      return 'Date not available';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body:
          _isLoadingJobData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                        child: Image.network(
                          (widget.imageUrl.isNotEmpty
                                  ? widget.imageUrl
                                  : (_jobData?['ImageUrl'] ??
                                      _jobData?['imageUrl'] ??
                                      _jobData?['Image'] ??
                                      ''))
                              .toString(),
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.work,
                                  color: Colors.green,
                                  size: 64,
                                ),
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_jobData?['title_en'] ?? 'Job Title').toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Location:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_jobData?['Address'] ??
                                    _jobData?['Location'] ??
                                    'Location not specified')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Display creation date from job data
                          Row(
                            children: [
                              Text(
                                'Date:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDate(_jobData?['createdAt']),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Job Description:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (_jobData?['description_en'] ??
                                    'No description available')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Portfolio completion warning
                          FutureBuilder<bool>(
                            future:
                                Provider.of<HomeProfileProvider>(
                                  context,
                                  listen: false,
                                ).canRequestJobs(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink(); // Don't show warning while loading
                              }

                              final canRequest = snapshot.data ?? false;
                              if (canRequest) {
                                return const SizedBox.shrink(); // Don't show warning if portfolio is complete
                              }

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Complete your portfolio to send job requests',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<bool>(
                                  future:
                                      Provider.of<HomeProfileProvider>(
                                        context,
                                        listen: false,
                                      ).canRequestJobs(),
                                  builder: (context, snapshot) {
                                    final isLoading =
                                        snapshot.connectionState ==
                                        ConnectionState.waiting;
                                    final canRequest = snapshot.data ?? false;

                                    if (isLoading) {
                                      return ElevatedButton.icon(
                                        onPressed: null,
                                        icon: const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        label: const Text('Loading...'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade400,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      );
                                    }

                                    if (!canRequest) {
                                      return ElevatedButton.icon(
                                        onPressed:
                                            null, // Disabled when portfolio incomplete
                                        icon: const Icon(Icons.work),
                                        label: const Text('Send Request'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey.shade400,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      );
                                    }

                                    return FutureBuilder<String>(
                                      future: _getJobRequestStatus(),
                                      builder: (context, snapshot) {
                                        final status = snapshot.data ?? 'none';
                                        final isLoading =
                                            snapshot.connectionState ==
                                            ConnectionState.waiting;

                                        if (isLoading) {
                                          return ElevatedButton.icon(
                                            onPressed: null,
                                            icon: const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white),
                                              ),
                                            ),
                                            label: const Text('Loading...'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.grey.shade400,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                            ),
                                          );
                                        }

                                        switch (status) {
                                          case 'none':
                                            return ElevatedButton.icon(
                                              onPressed:
                                                  () => requestForJob(context),
                                              icon: const Icon(Icons.send),
                                              label: const Text('Send Request'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                            );
                                          case 'pending':
                                            return ElevatedButton.icon(
                                              onPressed: null,
                                              icon: const Icon(Icons.schedule),
                                              label: const Text(
                                                'Request Pending',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                            );
                                          case 'accepted':
                                            return ElevatedButton.icon(
                                              onPressed: null,
                                              icon: const Icon(
                                                Icons.check_circle,
                                              ),
                                              label: const Text(
                                                'Request Accepted',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                            );
                                          default:
                                            return ElevatedButton.icon(
                                              onPressed:
                                                  () => requestForJob(context),
                                              icon: const Icon(Icons.send),
                                              label: const Text('Send Request'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                              ),
                                            );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: FutureBuilder<bool>(
                                  future: _isJobRequestAccepted(),
                                  builder: (context, snapshot) {
                                    final isAccepted = snapshot.data ?? false;
                                    final isLoading =
                                        snapshot.connectionState ==
                                        ConnectionState.waiting;

                                    // Debug info
                                    print(
                                      '🔍 Navigate button - Status: $isAccepted, Loading: $isLoading',
                                    );

                                    return ElevatedButton.icon(
                                      onPressed:
                                          isLoading
                                              ? null
                                              : (isAccepted
                                                  ? () =>
                                                      _navigateToJob(context)
                                                  : null),
                                      icon:
                                          isLoading
                                              ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : Icon(
                                                isAccepted
                                                    ? Icons.directions
                                                    : Icons.schedule,
                                                color:
                                                    isAccepted
                                                        ? Colors.white
                                                        : Colors.grey.shade600,
                                              ),
                                      label: Text(
                                        isLoading
                                            ? 'Loading...'
                                            : isAccepted
                                            ? 'Navigate'
                                            : 'Pending Approval',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isAccepted
                                                ? Colors.green
                                                : Colors.grey.shade400,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    );
                                  },
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
    );
  }
}
