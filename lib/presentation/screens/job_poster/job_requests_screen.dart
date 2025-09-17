import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/widgets/job_request_card.dart';
import 'package:skillzaar/presentation/widgets/job_requests_empty_state.dart';

import '../../../core/services/job_request_service.dart';
import '../../providers/phone_auth_provider.dart';
import 'portfolio_view_screen.dart';

class JobRequestsScreen extends StatelessWidget {
  const JobRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneAuthProvider = Provider.of<PhoneAuthProvider>(
      context,
      listen: false,
    );

    String? jobPosterId;

    if (phoneAuthProvider.isLoggedIn &&
        phoneAuthProvider.loggedInUserId != null) {
      jobPosterId = phoneAuthProvider.loggedInUserId!;
    } else {
      jobPosterId = null;
    }

    print('🔍 Job Requests Screen - Job Poster ID: $jobPosterId');
    print(
      '🔍 Job Requests Screen - Is Logged In: ${phoneAuthProvider.isLoggedIn}',
    );

    if (jobPosterId == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Please log in to view your job requests.',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/job-poster-home',
                      (route) => false,
                    );
                  },
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final String posterId = jobPosterId;

    // Normalize legacy requests on first build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await JobRequestService.normalizeJobRequestsForPoster(
        jobPosterId: posterId,
        posterPhone: phoneAuthProvider.loggedInPhoneNumber,
      );
    });

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // Fetch requests directly by jobPosterId, independent of job list
        stream: JobRequestService.getJobRequestsForPoster(posterId),
        builder: (context, reqSnapshot) {
          if (reqSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reqSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error loading requests',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${reqSnapshot.error}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!reqSnapshot.hasData || reqSnapshot.data!.docs.isEmpty) {
            return const JobRequestsEmptyState();
          }

          // Group requests by jobId
          final byJob = <String, List<QueryDocumentSnapshot>>{};
          for (final doc in reqSnapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final jobId = (data['jobId'] as String? ?? '').trim();
            if (jobId.isEmpty) continue;
            byJob.putIfAbsent(jobId, () => <QueryDocumentSnapshot>[]).add(doc);
          }

          final jobIds = byJob.keys.toList();

          return ListView.builder(
            itemCount: jobIds.length,
            itemBuilder: (context, index) {
              final jobId = jobIds[index];
              final requests = byJob[jobId]!;

              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('Jobs')
                        .doc(jobId)
                        .get(),
                builder: (context, jobSnap) {
                  final jobTitle = () {
                    if (jobSnap.hasData && jobSnap.data!.exists) {
                      final d = jobSnap.data!.data() as Map<String, dynamic>;
                      return d['title_en'] ??
                          d['title_ur'] ??
                          d['Name'] ??
                          'No Title';
                    }
                    return 'Job';
                  }();

                  final sorted =
                      requests.toList()..sort((a, b) {
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
                      sorted
                          .map((doc) => doc.data() as Map<String, dynamic>)
                          .toList();
                  final requestIds = sorted.map((doc) => doc.id).toList();

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
