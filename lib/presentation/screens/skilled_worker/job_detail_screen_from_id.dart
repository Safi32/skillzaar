import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_state_provider.dart';
import '../../../core/services/job_request_service.dart';
import 'navigate_to_job_screen.dart';
import '../../providers/skilled_worker_provider.dart';

class JobDetailScreenFromId extends StatelessWidget {
  final String jobId;

  const JobDetailScreenFromId({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Consumer<UIStateProvider>(
      builder: (context, uiProvider, child) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance
                  .collection('Job')
                  .doc(jobId)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error loading job: ${snapshot.error}'),
                ),
              );
            }

            final data = snapshot.data?.data();
            if (data == null) {
              return const Scaffold(body: Center(child: Text('Job not found')));
            }

            return _JobDetailContent(
              uiProvider: uiProvider,
              imageUrl: data['jobImage'] ?? '',
              title: data['title_en'] ?? data['jobTitle'] ?? 'No Title',
              location: data['jobLocation'] ?? 'No Location',
              date:
                  data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : null,
              description:
                  data['description_en'] ??
                  data['jobDescription'] ??
                  'No Description',
              jobId: jobId,
              jobPosterId: data['jobPosterId'] ?? '',
              requestId: null,
            );
          },
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
  bool _isLoading = false;
  bool _isJobAssigned = false;

  @override
  void initState() {
    super.initState();
    _checkJobAssignment();
  }

  Future<void> _checkJobAssignment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current skilled worker ID from provider
      final skilledWorkerProvider = Provider.of<SkilledWorkerProvider>(
        context,
        listen: false,
      );
      final skilledWorkerId = skilledWorkerProvider.loggedInUserId;

      if (skilledWorkerId != null && skilledWorkerId.isNotEmpty) {
        final isAssigned = await JobRequestService.isSkilledWorkerAssignedToJob(
          jobId: widget.jobId,
          skilledWorkerId: skilledWorkerId,
        );

        setState(() {
          _isJobAssigned = isAssigned;
        });

        if (!isAssigned) {
          _showAssignmentError();
        }
      }
    } catch (e) {
      print('Error checking job assignment: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.green.withOpacity(0.2),
        centerTitle: true,
        title: const Text(
          "Job Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Image
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.location,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date
                  if (widget.date != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Posted on: ${widget.date!.day}/${widget.date!.month}/${widget.date!.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    "Description",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  if (_isJobAssigned) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToJob(),
                            icon: const Icon(
                              Icons.navigation,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Get Direction",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Text(
                        "This job is not assigned to you. Please contact admin for more information.",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToJob() async {
    try {
      // Get job coordinates from the job data
      final jobDoc =
          await FirebaseFirestore.instance
              .collection('Job')
              .doc(widget.jobId)
              .get();

      if (jobDoc.exists) {
        final jobData = jobDoc.data()!;
        final lat = jobData['latitude'] as double? ?? 0.0;
        final lng = jobData['longitude'] as double? ?? 0.0;

        if (lat != 0.0 && lng != 0.0) {
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
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job location coordinates not available'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error navigating to job: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
