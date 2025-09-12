import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/widgets/job_request_card.dart';
import 'package:skillzaar/presentation/widgets/job_requests_empty_state.dart';

import '../../../core/services/job_request_service.dart';
import 'portfolio_view_screen.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    String jobPosterId;

    if (user != null) {
      jobPosterId = user.uid;
    } else {
      jobPosterId = 'TEST_JOB_POSTER_ID';
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: JobRequestService.getJobsForPoster(jobPosterId),
        builder: (context, jobSnapshot) {
          if (jobSnapshot.hasError) {}
          if (jobSnapshot.hasData) {}
          if (jobSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (jobSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading jobs',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${jobSnapshot.error}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!jobSnapshot.hasData || jobSnapshot.data!.docs.isEmpty) {
            return const JobRequestsEmptyState();
          }
          final jobs = jobSnapshot.data!.docs;
          return ListView.builder(
            itemCount: jobs.length,
            itemBuilder: (context, jobIndex) {
              final job = jobs[jobIndex];
              final jobId = job.id;
              final jobTitle =
                  job['title_en'] ??
                  job['title_ur'] ??
                  job['Name'] ??
                  'No Title';
              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('JobRequests')
                        .where('jobId', isEqualTo: jobId)
                        .where('isActive', isEqualTo: true)
                        .snapshots(),
                builder: (context, reqSnapshot) {
                  if (reqSnapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (reqSnapshot.hasError) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Job: $jobTitle',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Error loading requests',
                              style: TextStyle(
                                color: Colors.red,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!reqSnapshot.hasData || reqSnapshot.data!.docs.isEmpty) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Job: $jobTitle',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No requests yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final requests =
                      reqSnapshot.data!.docs.toList()..sort((a, b) {
                        final aData = a.data() as Map<String, dynamic>;
                        final bData = b.data() as Map<String, dynamic>;
                        final aTime = aData['requestedAt'];
                        final bTime = bData['requestedAt'];
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return bTime.compareTo(aTime);
                      });
                  final requestMaps =
                      requests
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();
                  final requestIds = requests.map((doc) => doc.id).toList();
                  return JobRequestCard(
                    jobTitle: jobTitle,
                    jobId: jobId,
                    requests: requestMaps,
                    requestIds: requestIds,
                    onPortfolioTap: (req, requestId) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => PortfolioViewScreen(
                                skilledWorkerId: req['skilledWorkerId'] ?? '',
                                skilledWorkerName:
                                    req['skilledWorkerName'] ?? 'Worker',
                                jobId: jobId,
                                requestId: requestId,
                              ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
