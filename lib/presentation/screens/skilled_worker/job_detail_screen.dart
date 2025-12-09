import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../providers/home_profile_provider.dart';
import '../../../core/services/job_request_service.dart';
import 'navigate_to_job_screen.dart';
import '../../providers/skilled_worker_provider.dart';

class JobDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String location;
  final DateTime? date;
  final String description;
  final String jobId;
  final String jobPosterId;
  final String? requestId;

  const JobDetailScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.date,
    required this.description,
    required this.jobId,
    required this.jobPosterId,
    this.requestId,
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
          requestId: requestId,
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
  final String? requestId;

  const _JobDetailContent({
    required this.uiProvider,
    required this.imageUrl,
    required this.title,
    required this.location,
    required this.date,
    required this.description,
    required this.jobId,
    required this.jobPosterId,
    this.requestId,
  });

  @override
  State<_JobDetailContent> createState() => _JobDetailContentState();
}

class _JobDetailContentState extends State<_JobDetailContent> {
  Map<String, dynamic>? _jobData;
  bool _isLoadingJobData = true;
  bool _navigatedOnComplete = false;

  @override
  void initState() {
    super.initState();
    _loadJobData();
  }

  Future<void> _loadJobData() async {
    try {
      // First check if the skilled worker is assigned to this job
      final skilledWorkerId = await JobRequestService.getSkilledWorkerId();
      if (skilledWorkerId == null) {
        if (!mounted) return;
        widget.uiProvider.setLoading(false);
        _showAssignmentError();
        return;
      }

      final isAssigned = await JobRequestService.isSkilledWorkerAssignedToJob(
        jobId: widget.jobId,
        skilledWorkerId: skilledWorkerId,
      );

      if (!isAssigned) {
        if (!mounted) return;
        widget.uiProvider.setLoading(false);
        _showAssignmentError();
        return;
      }

      // If assigned, load job data
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
      _showAssignmentError();
    }
  }

  void _showAssignmentError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This job is not assigned to you. Please contact admin for more information.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 50, left: 16, right: 16),
      ),
    );

    // Navigate back to jobs screen after showing the message
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _navigateToRatingPage(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Get job poster details
      final jobPosterId = data?['jobPosterId'] as String? ?? widget.jobPosterId;
      final jobPosterDetails = await JobRequestService.getJobPosterDetails(
        jobPosterId,
      );

      if (jobPosterDetails != null) {
        // Navigate to rating page
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/skilled-worker-rate-job-poster',
          (route) => false,
          arguments: {
            'jobPosterDetails': jobPosterDetails,
            'requestId': data?['requestId'] ?? widget.requestId,
          },
        );
      } else {
        // Fallback: navigate to home if job poster details not found
        print('❌ Job poster details not found, navigating to home');
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/skilled-worker-home',
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Error navigating to rating page: $e');
      // Fallback: navigate to home on error
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-home',
        (route) => false,
      );
    }
  }

  // Request functionality has been removed - skilled workers can no longer send requests

  Future<bool> _isJobRequestAccepted() async {
    try {
      print('🔍 Checking job request status for job ID: ${widget.jobId}');

      // Simply check if there's an accepted job request for this job ID
      final requests =
          await FirebaseFirestore.instance
              .collection('JobRequests')
              .where('jobId', isEqualTo: widget.jobId)
              .where('status', whereIn: ['accepted', 'in_progress'])
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

      // Check if job has any active requests first
      final hasActiveRequests = await JobRequestService.hasActiveRequests(
        widget.jobId,
      );
      if (hasActiveRequests) {
        final activeRequest = await JobRequestService.getActiveRequestForJob(
          widget.jobId,
        );
        final status = activeRequest?['status'] ?? 'in_progress';
        print('🔍 Job has active requests with status: $status');
        return status;
      }

      // Request functionality removed - skilled workers can no longer send requests

      print('❌ No job requests found for job ID: ${widget.jobId}');
      return 'none';
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

    // Check if location services are available before navigating
    final provider = Provider.of<SkilledWorkerProvider>(context, listen: false);

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Preparing navigation...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );

    // Try to initialize location services if not already available
    if (provider.currentLatitude == null || provider.currentLongitude == null) {
      try {
        await provider.initializeLocationServices();
        // Wait a moment for location to be fetched
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        print('Error initializing location: $e');
      }
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
    // If requestId is provided, enforce back-block and completion redirect; else behave normally
    if (widget.requestId != null && widget.requestId!.isNotEmpty) {
      return WillPopScope(
        onWillPop: () async => false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance
                  .collection('JobRequests')
                  .doc(widget.requestId)
                  .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data();
            final status = data?['status'] as String?;
            final isActive = data?['isActive'] as bool?;

            // Handle job completion, cancellation, or deactivation
            if (!_navigatedOnComplete &&
                (status == 'completed' ||
                    status == 'cancelled' ||
                    isActive == false)) {
              _navigatedOnComplete = true;
              print(
                '🔄 Skilled Worker: Job status changed to $status, isActive: $isActive',
              );
              print('🔄 Skilled Worker: Redirecting to home screen...');

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                // Show appropriate message based on status
                if (status == 'cancelled') {
                  print('🔄 Skilled Worker: Showing cancellation message');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Job has been cancelled by the job poster. Redirecting to home...',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                } else if (status == 'completed') {
                  print('🔄 Skilled Worker: Showing completion message');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Job has been completed. Please rate the job poster...',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 3),
                    ),
                  );

                  // Navigate to rating page for job poster
                  _navigateToRatingPage(context, data);
                  return; // Don't navigate to home, rating page will handle it
                }

                print('🔄 Skilled Worker: Navigating to /skilled-worker-home');
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/skilled-worker-home',
                  (route) => false,
                );
              });
            }
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
                                    (_jobData?['title_en'] ?? 'Job Title')
                                        .toString(),
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
                                        'Budget:',
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
                                    'Rs. ${(_jobData?['budget'] ?? 'Not specified').toString()}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Text(
                                        'Job Poster Phone:',
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
                                    (data?['jobPosterPhone'] ??
                                            _jobData?['jobPosterPhone'] ??
                                            'Not available')
                                        .toString(),
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
                                    future: Provider.of<HomeProfileProvider>(
                                      context,
                                      listen: false,
                                    ).canRequestJobs(context),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const SizedBox.shrink(); // Don't show warning while loading
                                      }

                                      final canRequest = snapshot.data ?? false;
                                      if (canRequest) {
                                        return const SizedBox.shrink(); // Don't show warning if portfolio is complete
                                      }

                                      return const SizedBox.shrink(); // Portfolio warning removed - requests are no longer available
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
                                              ).canRequestJobs(context),
                                          builder: (context, snapshot) {
                                            final isLoading =
                                                snapshot.connectionState ==
                                                ConnectionState.waiting;
                                            final canRequest =
                                                snapshot.data ?? false;

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

                                            if (!canRequest) {
                                              return ElevatedButton.icon(
                                                onPressed:
                                                    null, // Disabled when portfolio incomplete
                                                icon: const Icon(Icons.work),
                                                label: const Text(
                                                  'Send Request',
                                                ),
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

                                            return FutureBuilder<String>(
                                              future: _getJobRequestStatus(),
                                              builder: (context, snapshot) {
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
                                                    label: const Text(
                                                      'Loading...',
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.grey.shade400,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                          ),
                                                    ),
                                                  );
                                                }

                                                return Container(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.blue.shade200,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.info_outline,
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade600,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          'Job requests are not available. Please contact the job poster directly.',
                                                          style: TextStyle(
                                                            color:
                                                                Colors
                                                                    .blue
                                                                    .shade800,
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
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
                                            final isAccepted =
                                                snapshot.data ?? false;
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
                                                              _navigateToJob(
                                                                context,
                                                              )
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
                                                                : Colors
                                                                    .grey
                                                                    .shade600,
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
                                                padding:
                                                    const EdgeInsets.symmetric(
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
          },
        ),
      );
    }
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
                          Row(
                            children: [
                              Text(
                                'Job Poster Phone:',
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
                            (_jobData?['jobPosterPhone'] ?? 'Not available')
                                .toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Portfolio completion warning
                          FutureBuilder<bool>(
                            future: Provider.of<HomeProfileProvider>(
                              context,
                              listen: false,
                            ).canRequestJobs(context),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SizedBox.shrink(); // Don't show warning while loading
                              }

                              final canRequest = snapshot.data ?? false;
                              if (canRequest) {
                                return const SizedBox.shrink(); // Don't show warning if portfolio is complete
                              }

                              return const SizedBox.shrink(); // Portfolio warning removed - requests are no longer available
                            },
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<bool>(
                                  future: _isJobRequestAccepted(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        height: 50,
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }

                                    final isAccepted = snapshot.data ?? false;

                                    if (isAccepted) {
                                      return ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Job Approved!'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                        ),
                                        label: const Text('Job Approval'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      );
                                    }

                                    // Fallback to existing logic if not accepted
                                    return FutureBuilder<bool>(
                                      future: Provider.of<HomeProfileProvider>(
                                        context,
                                        listen: false,
                                      ).canRequestJobs(context),
                                      builder: (context, snapshot) {
                                        final isLoading =
                                            snapshot.connectionState ==
                                            ConnectionState.waiting;
                                        final canRequest =
                                            snapshot.data ?? false;

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

                                        if (!canRequest) {
                                          return ElevatedButton.icon(
                                            onPressed: null,
                                            icon: const Icon(Icons.work),
                                            label: const Text('Send Request'),
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

                                        return FutureBuilder<String>(
                                          future: _getJobRequestStatus(),
                                          builder: (context, snapshot) {
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

                                            return Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.blue.shade200,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.info_outline,
                                                    color: Colors.blue.shade600,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Job requests are not available. Please contact the job poster directly.',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade800,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        );
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
                          const SizedBox(height: 16),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
