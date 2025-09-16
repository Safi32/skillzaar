import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillzaar/core/services/job_request_service.dart';

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
    if (_currentUserId == null || _currentUserPhone == null) {
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
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('JobRequests')
                .where('jobPosterId', isEqualTo: _currentUserId)
                .where('status', isEqualTo: 'accepted')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    'You don\'t have any accepted job requests at the moment.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Get the first accepted job request
          final jobRequest = snapshot.data!.docs.first;
          final requestData = jobRequest.data() as Map<String, dynamic>;
          final jobId = requestData['jobId'] as String?;
          final requestId = jobRequest.id;

          if (jobId == null) {
            return const Center(child: Text('Invalid job data'));
          }

          return _buildJobDetailContent(jobId, requestId, requestData);
        },
      ),
    );
  }

  Widget _buildJobDetailContent(
    String jobId,
    String requestId,
    Map<String, dynamic> requestData,
  ) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: JobRequestService.streamJobDoc(jobId),
      builder: (context, jobSnapshot) {
        if (jobSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobData = jobSnapshot.data?.data();
        if (jobData == null) {
          return const Center(child: Text('Job not found'));
        }

        // Extract job details
        final jobTitle =
            jobData['title_en'] ?? jobData['title_ur'] ?? 'No Title';
        final jobDescription =
            jobData['description_en'] ??
            jobData['description_ur'] ??
            'No Description';
        final jobLocation =
            jobData['Location'] ?? jobData['Address'] ?? 'No Location';
        final jobSalary = jobData['budget']?.toString() ?? 'Not specified';

        // Extract skilled worker details
        final skilledWorkerName = requestData['skilledWorkerName'] ?? 'Unknown';
        final skilledWorkerPhone =
            requestData['skilledWorkerPhone'] ?? 'Unknown';
        final skilledWorkerId = requestData['skilledWorkerId'] ?? '';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      _buildDetailRow(
                        Icons.location_on,
                        'Location',
                        jobLocation,
                      ),
                      const SizedBox(height: 12),
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

              // Skilled Worker Details Card
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
                        skilledWorkerName,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(Icons.phone, 'Phone', skilledWorkerPhone),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        Icons.badge,
                        'Worker ID',
                        skilledWorkerId,
                      ),
                    ],
                  ),
                ),
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
      },
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
      // Update job status to cancelled
      await FirebaseFirestore.instance.collection('Jobs').doc(jobId).update({
        'status': 'cancelled',
      });

      // Update job request status to cancelled
      await FirebaseFirestore.instance
          .collection('JobRequests')
          .doc(requestId)
          .update({'status': 'cancelled'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
