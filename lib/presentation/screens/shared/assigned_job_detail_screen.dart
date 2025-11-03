import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../skilled_worker/navigate_to_job_screen.dart';
import 'worker_tracking_screen.dart';

class AssignedJobDetailScreen extends StatelessWidget {
  final String assignedJobId;
  final String userType;

  const AssignedJobDetailScreen({
    super.key,
    required this.assignedJobId,
    this.userType = 'skilled_worker',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.green.withOpacity(0.2),
        centerTitle: true,
        title: const Text(
          "Assigned Job Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('AssignedJobs')
                .doc(assignedJobId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading job details: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('Job details not found'));
          }

          // Map AssignedJobs fields to our expected structure
          final jobDetails = {
            'jobName': data['jobTitle'] ?? 'No Title',
            'jobLocation': data['jobLocation'] ?? 'No Location',
            'budget': data['jobPrice']?.toString() ?? 'Not Specified',
            'jobDescription': data['jobDescription'] ?? 'No Description',
            'createdAt': data['jobCreatedAt'],
            'urgency': 'Normal',
            'estimatedDuration': 'Not Specified',
            'serviceType': data['jobServiceType'] ?? 'Not Specified',
            'jobImage': data['jobImage'] ?? '',
          };

          final skilledWorkerDetails = {
            'skilledWorkerName': data['workerName'] ?? 'Unknown',
            'phoneNumber': data['workerPhone'] ?? 'Not Available',
            'skilledWorkerCity': data['workerCity'] ?? 'Not Specified',
            'averageRating': data['workerRating']?.toString() ?? 'No Rating',
            'skilledWorkerExperience':
                data['workerExperience'] ?? 'Not Specified',
            'hourlyRate': 'Not Specified',
            'skilledWorkerDescription': 'Skilled Worker',
            'profileImage': data['workerProfileImage'] ?? '',
          };

          final jobPosterDetails = {
            'name': data['jobPosterName'] ?? 'Unknown',
            'phoneNumber': data['jobPosterPhone'] ?? 'Not Available',
            'email': 'Not Available',
            'address': data['jobLocation'] ?? 'Not Specified',
          };

          final status = data['assignmentStatus'] as String? ?? 'unknown';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Job Details Card
                _buildGlassCard(
                  title: "Job Details",
                  children: [
                    _buildInfoRow(
                      "📌 Job Title",
                      jobDetails['jobName'] ?? 'No Title',
                    ),
                    _buildInfoRow(
                      "📍 Location",
                      jobDetails['jobLocation'] ?? 'No Location',
                    ),
                    // Budget removed per requirements
                    _buildInfoRow(
                      "📝 Description",
                      jobDetails['jobDescription'] ?? 'No Description',
                    ),
                    _buildInfoRow(
                      "📅 Created",
                      _formatDate(jobDetails['createdAt']),
                    ),
                    _buildInfoRow(
                      "⚡ Urgency",
                      jobDetails['urgency'] ?? 'Normal',
                    ),
                    _buildInfoRow(
                      "⏱️ Duration",
                      jobDetails['estimatedDuration'] ?? 'Not Specified',
                    ),
                    _buildInfoRow("📊 Status", status.toUpperCase()),
                  ],
                ),

                const SizedBox(height: 20),

                // Skilled Worker Details Card
                _buildGlassCard(
                  title: "Skilled Worker Details",
                  children: [
                    _buildInfoRow(
                      "👤 Name",
                      skilledWorkerDetails['skilledWorkerName'] ?? 'Unknown',
                    ),
                    _buildInfoRow(
                      "📞 Phone",
                      skilledWorkerDetails['phoneNumber'] ?? 'Not Available',
                    ),
                    _buildInfoRow(
                      "🏙️ City",
                      skilledWorkerDetails['skilledWorkerCity'] ??
                          'Not Specified',
                    ),
                    _buildInfoRow(
                      "⭐ Rating",
                      skilledWorkerDetails['averageRating']?.toString() ??
                          'No Rating',
                    ),
                    _buildInfoRow(
                      "💼 Experience",
                      skilledWorkerDetails['skilledWorkerExperience'] ??
                          'Not Specified',
                    ),
                    _buildInfoRow(
                      "💰 Rate",
                      skilledWorkerDetails['hourlyRate']?.toString() ??
                          'Not Specified',
                    ),
                    _buildInfoRow(
                      "📋 Description",
                      skilledWorkerDetails['skilledWorkerDescription'] ??
                          'No Description',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Job Poster Details Card (if available)
                if (jobPosterDetails.isNotEmpty)
                  _buildGlassCard(
                    title: "Job Poster Details",
                    children: [
                      _buildInfoRow(
                        "👤 Name",
                        jobPosterDetails['name'] ?? 'Unknown',
                      ),
                      _buildInfoRow(
                        "📞 Phone",
                        jobPosterDetails['phoneNumber'] ?? 'Not Available',
                      ),
                      _buildInfoRow(
                        "📧 Email",
                        jobPosterDetails['email'] ?? 'Not Available',
                      ),
                      _buildInfoRow(
                        "📍 Address",
                        jobPosterDetails['address'] ?? 'Not Specified',
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                // Action Buttons - Different for each user type
                if (userType == 'skilled_worker') ...[
                  // Skilled Worker Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _neonButton(
                          text: "Call",
                          color: Colors.green,
                          onTap: () {
                            _makePhoneCall(
                              context,
                              jobPosterDetails['phoneNumber'],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _neonButton(
                          text: "Navigate",
                          color: Colors.blue,
                          onTap: () {
                            _navigateToJobDetail(context, data['jobId']);
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Job Poster Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _neonButton(
                          text: "Track Worker",
                          color: Colors.green,
                          onTap: () {
                            _trackWorker(context, data);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _neonButton(
                          text: "Complete Job",
                          color: Colors.green,
                          onTap: () {
                            _completeJob(context, assignedJobId);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _neonButton(
                          text: "Cancel Job",
                          color: Colors.red,
                          onTap: () {
                            _cancelJob(context, assignedJobId);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Glassmorphic Card
  Widget _buildGlassCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _neonButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not Available';
    try {
      if (date is Timestamp) {
        return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
      }
      return date.toString();
    } catch (e) {
      return 'Date not available';
    }
  }

  void _makePhoneCall(BuildContext context, String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateJobStatus(
    BuildContext context,
    String assignedJobId,
    String currentStatus,
  ) {
    // TODO: Implement job status update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job status update functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _completeJob(BuildContext context, String assignedJobId) {
    // Navigate to rating screen
    Navigator.pushNamed(
      context,
      '/rate-skilled-worker',
      arguments: {'assignedJobId': assignedJobId, 'isJobCompletion': true},
    );
  }

  void _cancelJob(BuildContext context, String assignedJobId) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Job'),
            content: const Text(
              'Are you sure you want to cancel this job? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Update job status to cancelled
        await FirebaseFirestore.instance
            .collection('AssignedJobs')
            .doc(assignedJobId)
            .update({
              'assignmentStatus': 'cancelled',
              'isActive': false,
              'cancelledAt': FieldValue.serverTimestamp(),
            });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job cancelled successfully'),
            backgroundColor: Colors.red,
          ),
        );

        // Navigate to home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          userType == 'skilled_worker'
              ? '/skilled-worker-home'
              : '/job-poster-home',
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling job: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _trackWorker(
    BuildContext context,
    Map<String, dynamic> assignedJobData,
  ) {
    final workerId = assignedJobData['workerId'] as String?;
    final jobTitle = assignedJobData['jobTitle'] ?? 'Job';
    final jobLocation = assignedJobData['jobLocation'] ?? 'Job Location';

    // Get job coordinates
    final jobLocationCoordinates =
        assignedJobData['jobLocationCoordinates'] as Map<String, dynamic>?;
    final jobLat = jobLocationCoordinates?['latitude'] as double? ?? 0.0;
    final jobLng = jobLocationCoordinates?['longitude'] as double? ?? 0.0;

    if (workerId != null && workerId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WorkerTrackingScreen(
                workerId: workerId,
                jobTitle: jobTitle,
                jobLocation: jobLocation,
                jobLatitude: jobLat,
                jobLongitude: jobLng,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker ID not available for tracking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToJobDetail(BuildContext context, String? jobId) async {
    try {
      // Get job details from the AssignedJobs collection
      final assignedJobDoc =
          await FirebaseFirestore.instance
              .collection('AssignedJobs')
              .doc(assignedJobId)
              .get();

      if (assignedJobDoc.exists) {
        final assignedJobData = assignedJobDoc.data()!;

        // Extract job details from AssignedJobs collection
        final jobTitle = assignedJobData['jobTitle'] ?? 'Job';
        final jobLocation = assignedJobData['jobLocation'] ?? 'Job Location';
        final jobIdFromAssigned = assignedJobData['jobId'] as String?;

        // Get coordinates directly from AssignedJobs collection
        final jobLocationCoordinates =
            assignedJobData['jobLocationCoordinates'] as Map<String, dynamic>?;
        final lat = jobLocationCoordinates?['latitude'] as double? ?? 0.0;
        final lng = jobLocationCoordinates?['longitude'] as double? ?? 0.0;

        print('🔍 Coordinates from AssignedJobs - Lat: $lat, Lng: $lng');

        if (lat != 0.0 && lng != 0.0) {
          // Navigate directly to NavigateToJobScreen using data from AssignedJobs
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => NavigateToJobScreen(
                    jobId: jobIdFromAssigned ?? 'unknown',
                    jobTitle: jobTitle,
                    jobAddress: jobLocation,
                    jobLatitude: lat,
                    jobLongitude: lng,
                  ),
            ),
          );
        } else {
          print('❌ Invalid coordinates: lat=$lat, lng=$lng');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Job location coordinates not available in assigned job',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assigned job not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error navigating to job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
