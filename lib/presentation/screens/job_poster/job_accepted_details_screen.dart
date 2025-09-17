import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import 'job_poster_rate_worker_screen.dart';

class JobAcceptedDetailsScreen extends StatefulWidget {
  final String jobId;
  final String requestId;

  const JobAcceptedDetailsScreen({
    super.key,
    required this.jobId,
    required this.requestId,
  });

  @override
  State<JobAcceptedDetailsScreen> createState() =>
      _JobAcceptedDetailsScreenState();
}

class _JobAcceptedDetailsScreenState extends State<JobAcceptedDetailsScreen> {
  bool jobCompleted = false;
  bool jobCancelled = false;

  @override
  void initState() {
    super.initState();
  }

  void _onJobCompleted() async {
    // Get skilled worker details from Firebase
    try {
      final requestDoc =
          await FirebaseFirestore.instance
              .collection('JobRequests')
              .doc(widget.requestId)
              .get();

      final requestData = requestDoc.data();

      String applicantName = 'Unknown';
      String applicantPhone = 'Unknown';
      String applicantEmail = 'Not available';

      if (requestData != null) {
        applicantName = requestData['skilledWorkerName'] ?? 'Unknown';
        applicantPhone = requestData['skilledWorkerPhone'] ?? 'Unknown';
        applicantEmail = 'Not available'; // Email not stored in current schema
      }

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => JobPosterRateWorkerScreen(
                  skilledWorkerDetails: {
                    'name': applicantName,
                    'phone': applicantPhone,
                    'email': applicantEmail,
                  },
                  requestId: widget.requestId,
                ),
          ),
        );
      }
    } catch (e) {
      print('Error getting skilled worker details: $e');
      // Fallback with default values
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => JobPosterRateWorkerScreen(
                  skilledWorkerDetails: {
                    'name': 'Unknown',
                    'phone': 'Unknown',
                    'email': 'Not available',
                  },
                  requestId: widget.requestId,
                ),
          ),
        );
      }
    }
  }

  void _onCancelJob() {
    setState(() {
      jobCancelled = true;
    });
    // TODO: Add logic to cancel job in backend
  }

  @override
  Widget build(BuildContext context) {
    // Validate that we have valid IDs
    if (widget.jobId.isEmpty || widget.requestId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Invalid Job Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Job ID or Request ID is missing. Please try again.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (jobCancelled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Cancelled')),
        body: const Center(child: Text('This job has been cancelled.')),
      );
    }

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async => false, // Block back while active
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance
                  .collection('JobRequests')
                  .doc(widget.requestId)
                  .snapshots(),
          builder: (context, snapshot) {
            final status = snapshot.data?.data()?['status'] as String?;
            final isActive = snapshot.data?.data()?['isActive'] as bool?;

            if (status == 'completed' || isActive == false) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!Navigator.of(context).canPop()) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/job-poster-home',
                    (route) => false,
                  );
                }
              });
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Job & Applicant Details'),
                centerTitle: true,
              ),
              body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: JobRequestService.streamJobDoc(widget.jobId),
                builder: (context, jobSnap) {
                  final jobStatus = jobSnap.data?.data()?['status'] as String?;
                  if (jobStatus == 'completed') {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!Navigator.of(context).canPop()) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/job-poster-home',
                          (route) => false,
                        );
                      }
                    });
                  }

                  // Get job data from Firebase
                  final jobData = jobSnap.data?.data();
                  String jobTitle = "Loading...";
                  String jobDescription = "Loading...";
                  String jobLocation = "Loading...";
                  String jobSalary = "Loading...";

                  if (jobData != null) {
                    jobTitle =
                        jobData['title_en'] ??
                        jobData['title_ur'] ??
                        'No Title';
                    jobDescription =
                        jobData['description_en'] ??
                        jobData['description_ur'] ??
                        'No Description';
                    jobLocation =
                        jobData['Location'] ??
                        jobData['Address'] ??
                        'No Location';
                    jobSalary =
                        jobData['budget']?.toString() ?? 'Not specified';
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Job Details
                        const Text(
                          'Job Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Title: $jobTitle",
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Description: $jobDescription",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Location: $jobLocation",
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Budget: $jobSalary",
                          style: const TextStyle(fontSize: 16),
                        ),

                        const Divider(height: 30, thickness: 1),

                        const Text(
                          'Applicant Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Fetch applicant details from JobRequests collection
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('JobRequests')
                                  .doc(widget.requestId)
                                  .get(),
                          builder: (context, requestSnap) {
                            if (requestSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final requestData =
                                requestSnap.data?.data()
                                    as Map<String, dynamic>?;

                            String applicantName = "Loading...";
                            String applicantPhone = "Loading...";
                            String applicantEmail = "Loading...";

                            if (requestData != null) {
                              applicantName =
                                  requestData['skilledWorkerName'] ?? 'Unknown';
                              applicantPhone =
                                  requestData['skilledWorkerPhone'] ??
                                  'Unknown';
                              applicantEmail =
                                  'Not available'; // Email not stored in current schema
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Name: $applicantName",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Phone: $applicantPhone",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Email: $applicantEmail",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _onJobCompleted,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Complete Job',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _onCancelJob,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel Job',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
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
              ),
            );
          },
        ),
      ),
    );
  }
}
