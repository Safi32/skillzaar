import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import 'package:provider/provider.dart';
import '../../providers/phone_auth_provider.dart' as app_auth;

/// Normalized view model for job data coming from either legacy `Job`
/// or new `jobs` collection. Keeps UI access keys stable.
class JobViewData {
  final Map<String, dynamic> _data;

  JobViewData._(this._data);

  static JobViewData fromFirestore(Map<String, dynamic> raw) {
    final details = (raw['details'] as Map<String, dynamic>?) ?? const {};

    // Compute normalized fields with compatibility fallbacks
    final normalized = <String, dynamic>{
      // Title/description
      'title_en': details['title'] ?? raw['title_en'] ?? raw['title'],
      'title_ur': raw['title_ur'],
      'description_en':
          details['description'] ?? raw['description_en'] ?? raw['description'],
      'description_ur': raw['description_ur'],

      // Location/address
      'Address': details['address'] ?? raw['Address'] ?? raw['Location'],
      'Location': details['location'] ?? raw['Location'] ?? raw['Address'],

      // Media/date/budget
      'Image': details['imageUrl'] ?? raw['Image'] ?? raw['imageUrl'],
      'createdAt': raw['createdAt'] ?? details['createdAt'],
      'budget': raw['budget'] ?? details['budget'],
    };

    return JobViewData._(normalized);
  }

  Map<String, dynamic> toMap() => _data;
}

class JobPosterDetailScreen extends StatefulWidget {
  const JobPosterDetailScreen({super.key});

  @override
  State<JobPosterDetailScreen> createState() => _JobPosterDetailScreenState();
}

class _JobPosterDetailScreenState extends State<JobPosterDetailScreen> {
  String? _currentUserId;
  String? _currentUserPhone;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserPhone = user.phoneNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer FirebaseAuth user; fall back to PhoneAuthProvider (test auth)
    final phoneAuth = Provider.of<app_auth.PhoneAuthProvider>(
      context,
      listen: false,
    );
    final effectiveUserId = _currentUserId ?? phoneAuth.loggedInUserId;
    final effectiveUserPhone =
        _currentUserPhone ?? phoneAuth.loggedInPhoneNumber;

    if (effectiveUserId == null && effectiveUserPhone == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job & Worker Details'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: JobRequestService.getActiveRequestForPoster(
          effectiveUserId ?? '',
          posterPhone: effectiveUserPhone,
        ),
        builder: (context, activeSnapshot) {
          if (activeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final active = activeSnapshot.data;
          if (active == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No Active Jobs',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You don\'t have any ongoing job right now.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final jobId = (active['jobId'] as String?)?.trim();
          final requestId = (active['requestId'] as String?) ?? '';
          if (jobId == null || jobId.isEmpty) {
            return const Center(child: Text('Invalid job data'));
          }

          return _buildJobDetailContent(jobId, requestId, active);
        },
      ),
    );
  }

  Widget _buildJobDetailContent(
    String jobId,
    String requestId,
    Map<String, dynamic> requestData,
  ) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: JobRequestService.getJobDetails(jobId),
      builder: (context, jobSnapshot) {
        if (jobSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobData = jobSnapshot.data;
        if (jobData == null) {
          return const Center(child: Text('Job not found'));
        }

        return _buildJobDetailBody(jobId, requestId, jobData, requestData);
      },
    );
  }

  Widget _buildJobDetailBody(
    String jobId,
    String requestId,
    Map<String, dynamic> jobData,
    Map<String, dynamic> requestData,
  ) {
    // Extract job details
    final jobTitle = jobData['title_en'] ?? jobData['title_ur'] ?? 'No Title';
    final jobDescription =
        jobData['description_en'] ??
        jobData['description_ur'] ??
        jobData['description'] ??
        'No Description';
    final jobLocation =
        jobData['Location'] ?? jobData['Address'] ?? 'No Location';
    final jobSalary = jobData['budget']?.toString() ?? 'Not specified';
    final jobImage = (jobData['Image'] ?? '').toString();
    final createdAt = jobData['createdAt'];
    DateTime? createdAtDate;
    if (createdAt is Timestamp) {
      createdAtDate = createdAt.toDate();
    } else if (createdAt is DateTime) {
      createdAtDate = createdAt;
    }

    // Extract skilled worker details
    final skilledWorkerName = requestData['skilledWorkerName'] ?? 'Unknown';
    final skilledWorkerPhone = requestData['skilledWorkerPhone'] ?? 'Unknown';
    final skilledWorkerId = requestData['skilledWorkerId'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Optional Job Image
          if (jobImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                jobImage,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (jobImage.isNotEmpty) const SizedBox(height: 16),

          // Job Details Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.work, color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Job Details',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.title, 'Title', jobTitle),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.description,
                    'Description',
                    jobDescription,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.location_on, 'Location', jobLocation),
                  const SizedBox(height: 12),
                  if (createdAtDate != null)
                    _buildDetailRow(
                      Icons.calendar_today,
                      'Posted On',
                      createdAtDate.toString(),
                    ),
                  if (createdAtDate != null) const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.attach_money,
                    'Budget',
                    'Rs. $jobSalary',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Skilled Worker Details Card (enrich by fetching worker profile)
          FutureBuilder<Map<String, dynamic>?>(
            future: JobRequestService.getSkilledWorkerDetails(skilledWorkerId),
            builder: (context, workerSnap) {
              final worker = workerSnap.data;
              final displayName =
                  (worker?['displayName'] ?? skilledWorkerName).toString();
              final displayPhone =
                  (worker?['phoneNumber'] ?? skilledWorkerPhone).toString();
              final rating = worker?['rating']?.toString();
              final skills =
                  (worker?['skills'] is List)
                      ? (worker?['skills'] as List).join(', ')
                      : worker?['skills']?.toString();

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'Skilled Worker Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        Icons.person_outline,
                        'Name',
                        displayName,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.phone, 'Phone', displayPhone),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.badge,
                        'Worker ID',
                        skilledWorkerId,
                      ),
                      if (rating != null) const SizedBox(height: 12),
                      if (rating != null)
                        _buildDetailRow(Icons.star, 'Rating', rating),
                      if (skills != null) const SizedBox(height: 12),
                      if (skills != null)
                        _buildDetailRow(Icons.build, 'Skills', skills),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to rate worker screen
                    Navigator.pushNamed(
                      context,
                      '/job-poster-rate-worker',
                      arguments: {
                        'skilledWorkerDetails': {
                          'name': skilledWorkerName,
                          'phone': skilledWorkerPhone,
                          'id': skilledWorkerId,
                        },
                        'requestId': requestId,
                      },
                    );
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Rate Worker'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCancelJobDialog(jobId, requestId);
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Job'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCancelJobDialog(String jobId, String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Job'),
          content: const Text(
            'Are you sure you want to cancel this job? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _cancelJob(jobId, requestId);
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelJob(String jobId, String requestId) async {
    try {
      // Get current user info
      final phoneAuth = Provider.of<app_auth.PhoneAuthProvider>(
        context,
        listen: false,
      );
      final effectiveUserId = _currentUserId ?? phoneAuth.loggedInUserId;

      if (effectiveUserId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to identify job poster'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get skilled worker ID from request data
      final requestDoc =
          await FirebaseFirestore.instance
              .collection('JobRequests')
              .doc(requestId)
              .get();

      if (!requestDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job request not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final requestData = requestDoc.data() as Map<String, dynamic>;
      final skilledWorkerId = requestData['skilledWorkerId'] as String?;

      if (skilledWorkerId == null || skilledWorkerId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to identify skilled worker'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancelling job...'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Cancel the job using the comprehensive method
      print('🔄 Job Poster: Starting job cancellation...');
      final success = await JobRequestService.cancelJob(
        jobId: jobId,
        requestId: requestId,
        jobPosterId: effectiveUserId,
        skilledWorkerId: skilledWorkerId,
      );

      if (mounted) {
        if (success) {
          print(
            '🔄 Job Poster: Job cancelled successfully, redirecting to home...',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Job cancelled successfully. Both users will be redirected to home.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to home screen after successful cancellation
          print('🔄 Job Poster: Navigating to /job-poster-home');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-home',
            (route) => false,
          );
        } else {
          print('❌ Job Poster: Failed to cancel job');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to cancel job. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error in _cancelJob: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
