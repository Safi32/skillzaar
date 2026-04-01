import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/job_request_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/phone_auth_provider.dart' as poster_auth;
import '../providers/skilled_worker_provider.dart' as worker_auth;
import 'package:shared_preferences/shared_preferences.dart';

/// Helper function to safely convert Timestamp to DateTime
DateTime? _safeConvertToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Gate that redirects user to an active job screen if one exists.
/// For skilled worker: routes to '/skilled-worker-job-detail'.
/// For job poster: routes to '/job-poster-job-detail'.
class ActiveWorkGate extends StatefulWidget {
  final Widget child;
  const ActiveWorkGate({super.key, required this.child});

  @override
  State<ActiveWorkGate> createState() => _ActiveWorkGateState();
}

class _ActiveWorkGateState extends State<ActiveWorkGate> {
  bool _checked = false;

  Future<void> _clearWorkerActiveFlags({
    required SharedPreferences prefs,
    required String workerId,
  }) async {
    final spKey = 'active_job_$workerId';
    await prefs.setBool(spKey, false);
    await prefs.remove('${spKey}_jobId');
    await prefs.remove('${spKey}_requestId');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checked) return;
    _checked = true;
    // Add a small delay to ensure provider state is fully updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkActive();
        }
      });
    });
  }

  Future<void> _checkActive() async {
    print('[ActiveWorkGate] _checkActive() called');
    final poster = context.read<poster_auth.PhoneAuthProvider>();
    final worker = context.read<worker_auth.SkilledWorkerProvider>();

    print('[ActiveWorkGate] Worker logged in: ${worker.isLoggedIn}');
    print('[ActiveWorkGate] Worker ID: ${worker.loggedInUserId}');
    print('[ActiveWorkGate] Poster logged in: ${poster.isLoggedIn}');
    print('[ActiveWorkGate] Poster ID: ${poster.loggedInUserId}');

    // SharedPrefs short-circuit: if flag says active for this worker, go directly
    final prefs = await SharedPreferences.getInstance();
    if (worker.isLoggedIn && worker.loggedInUserId != null) {
      print('[ActiveWorkGate] Checking SharedPreferences for active job (worker)...');
      final spKey = 'active_job_${worker.loggedInUserId!}';
      final spActive = prefs.getBool(spKey) ?? false;
      final spJobId = prefs.getString('${spKey}_jobId');
      try {
        final keys = prefs.getKeys();
        print('[ActiveWorkGate] WorkerId=${worker.loggedInUserId!}');
        print('[ActiveWorkGate] SharedPrefs keys: ' + keys.join(', '));
        print('[ActiveWorkGate] SP[$spKey] => ' + spActive.toString());
        print('[ActiveWorkGate] SP[${spKey}_jobId] => ' + (spJobId ?? 'null'));
      } catch (e) {
        print('[ActiveWorkGate] Error reading SharedPreferences: $e');
      }
      if (spActive && spJobId != null && spJobId.isNotEmpty) {
        // Revalidate via backend: SharedPrefs flags can be stale after completion.
        final activeReq = await JobRequestService.getActiveRequestForWorker(
          worker.loggedInUserId!,
          skilledWorkerPhone: worker.loggedInPhoneNumber,
        );

        // If there is no active request (accepted/in_progress), clear stale flags.
        if (activeReq == null) {
          await _clearWorkerActiveFlags(
            prefs: prefs,
            workerId: worker.loggedInUserId!,
          );
          print(
            '[ActiveWorkGate] Cleared stale worker SharedPrefs active flags (no active request found)',
          );
        } else {
          final job = await JobRequestService.getJobDetails(spJobId);
          if (!mounted) return;

          final status = (job?['status'] ?? job?['Status'])?.toString();
          final active = job?['active'] ?? job?['isActive'];

          final bool isCompleted = status == 'completed';
          final bool isInactive = active == false;

          // If the job itself is completed/inactive/missing, clear stale flags and do not redirect.
          if (job == null || isCompleted || isInactive) {
            await _clearWorkerActiveFlags(
              prefs: prefs,
              workerId: worker.loggedInUserId!,
            );
            print(
              '[ActiveWorkGate] Cleared stale worker SharedPrefs active flags (job completed/inactive/missing)',
            );
          } else {
            print(
              '[ActiveWorkGate] Redirecting via SharedPrefs to jobId=$spJobId',
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/skilled-worker-job-detail',
              (route) => false,
              arguments: {
                'imageUrl': job['Image'] ?? '',
                'title': job['title_en'] ?? job['title_ur'] ?? '',
                'location': job['Address'] ?? job['Location'] ?? '',
                'date': _safeConvertToDateTime(job['createdAt']),
                'description':
                    job['description_en'] ?? job['description_ur'] ?? '',
                'jobId': spJobId,
                'jobPosterId': job['jobPosterId'] ?? '',
              },
            );
            return;
          }
        }
      }
    }

    // SharedPrefs short-circuit: if flag says active for this job poster, go directly
    if (poster.isLoggedIn && poster.loggedInUserId != null) {
      print(
        '[ActiveWorkGate] Checking SharedPreferences for active job (poster)...',
      );
      final spKey = 'active_job_${poster.loggedInUserId!}';
      final spActive = prefs.getBool(spKey) ?? false;
      final spJobId = prefs.getString('${spKey}_jobId');
      try {
        final keys = prefs.getKeys();
        print('[ActiveWorkGate] PosterId=${poster.loggedInUserId!}');
        print('[ActiveWorkGate] SharedPrefs keys: ' + keys.join(', '));
        print('[ActiveWorkGate] SP[$spKey] => ' + spActive.toString());
        print('[ActiveWorkGate] SP[${spKey}_jobId] => ' + (spJobId ?? 'null'));
      } catch (e) {
        print('[ActiveWorkGate] Error reading SharedPreferences: $e');
      }
      if (spActive && spJobId != null && spJobId.isNotEmpty) {
        final job = await JobRequestService.getJobDetails(spJobId);
        if (!mounted) return;
        if (job != null) {
          print(
            '[ActiveWorkGate] Redirecting poster via SharedPrefs to jobId=$spJobId',
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-job-detail',
            (route) => false,
            arguments: {
              'jobId': spJobId,
              // Add more arguments if needed
            },
          );
          return;
        }
        print(
          '[ActiveWorkGate] SharedPrefs indicated active for poster, but job details not found for jobId=$spJobId',
        );
      }
    }

    // First, use role collections: SkilledWorkers/{userId}.activeJobId for worker
    // and JobPosters/{userId}.activeJobId for poster
    // Skilled worker
    if (worker.isLoggedIn && worker.loggedInUserId != null) {
      print('[ActiveWorkGate] Checking Firebase for active job...');
      final swColl = FirebaseFirestore.instance.collection('SkilledWorkers');
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await swColl.doc(worker.loggedInUserId!).get();
      print('[ActiveWorkGate] User doc exists: ${userDoc.exists}');
      if (!userDoc.exists) {
        // Attempt resolution by stored userId field or phone
        final byUserId =
            await swColl
                .where('userId', isEqualTo: worker.loggedInUserId!)
                .limit(1)
                .get();
        if (byUserId.docs.isNotEmpty) {
          userDoc = byUserId.docs.first;
        } else if ((worker.loggedInPhoneNumber ?? '').isNotEmpty) {
          final byPhone =
              await swColl
                  .where('userPhone', isEqualTo: worker.loggedInPhoneNumber!)
                  .limit(1)
                  .get();
          if (byPhone.docs.isNotEmpty) userDoc = byPhone.docs.first;
        }
      }
      final activeJobId = userDoc.data()?['activeJobId'] as String?;
      print('[ActiveWorkGate] Active job ID: $activeJobId');
      if (!mounted) return;
      if (activeJobId != null && activeJobId.isNotEmpty) {
        print('[ActiveWorkGate] Found active job ID, getting job details...');
        final job = await JobRequestService.getJobDetails(activeJobId);
        print('[ActiveWorkGate] Job details: $job');
        if (!mounted) return;
        if (job != null) {
          print('[ActiveWorkGate] Redirecting to job detail screen...');
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/skilled-worker-job-detail',
            (route) => false,
            arguments: {
              'imageUrl': job['Image'] ?? '',
              'title': job['title_en'] ?? job['title_ur'] ?? '',
              'location': job['Address'] ?? job['Location'] ?? '',
              'date': _safeConvertToDateTime(job['createdAt']),
              'description':
                  job['description_en'] ?? job['description_ur'] ?? '',
              'jobId': activeJobId,
              'jobPosterId': job['jobPosterId'] ?? '',
            },
          );
          return;
        }
      }
      // Fallback: if activeJobId missing, resolve any active request and navigate
      print(
        '[ActiveWorkGate] No active job ID found, checking for active requests...',
      );
      final swDoc = userDoc;
      final active = await JobRequestService.getActiveRequestForWorker(
        worker.loggedInUserId!,
        skilledWorkerPhone: worker.loggedInPhoneNumber,
      );
      print('[ActiveWorkGate] Active request result: $active');
      if (!mounted) return;
      if (active != null) {
        print('[ActiveWorkGate] Found active request, getting job details...');
        final job = await JobRequestService.getJobDetails(active['jobId']);
        if (!mounted) return;
        if (job != null) {
          // Backfill activeJobId for consistency
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(swDoc.id)
              .set({'activeJobId': active['jobId']}, SetOptions(merge: true));

          Navigator.pushNamedAndRemoveUntil(
            context,
            '/skilled-worker-job-detail',
            (route) => false,
            arguments: {
              'imageUrl': job['Image'] ?? '',
              'title': job['title_en'] ?? job['title_ur'] ?? '',
              'location': job['Address'] ?? job['Location'] ?? '',
              'date': _safeConvertToDateTime(job['createdAt']),
              'description':
                  job['description_en'] ?? job['description_ur'] ?? '',
              'jobId': active['jobId'],
              'jobPosterId': active['jobPosterId'],
              'requestId': active['requestId'],
            },
          );
          return;
        }
      }
    }

    // Job poster
    if (poster.isLoggedIn && poster.loggedInUserId != null) {
      // Try by explicit doc id first
      DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('JobPosters')
              .doc(poster.loggedInUserId!)
              .get();

      // Fallback: resolve by phone number if doc doesn't exist
      if (!userDoc.exists && (poster.loggedInPhoneNumber ?? '').isNotEmpty) {
        final byPhone =
            await FirebaseFirestore.instance
                .collection('JobPosters')
                .where('userPhone', isEqualTo: poster.loggedInPhoneNumber!)
                .limit(1)
                .get();
        if (byPhone.docs.isNotEmpty) {
          userDoc = byPhone.docs.first;
        }
      }

      final activeJobId = userDoc.data()?['activeJobId'] as String?;
      if (!mounted) return;
      if (activeJobId != null && activeJobId.isNotEmpty) {
        // Check job status to determine which screen to redirect to
        try {
          final active = await JobRequestService.getActiveRequestForPoster(
            poster.loggedInUserId!,
            posterPhone: poster.loggedInPhoneNumber,
          );
          if (active != null) {
            final status = active['status'] as String?;
            if (status == 'in_progress') {
              // In progress jobs go to job detail screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/job-poster-job-detail',
                (route) => false,
                arguments: {
                  'jobId': activeJobId,
                  'requestId': active['requestId'],
                },
              );
            } else {
              // Accepted jobs go to accepted details screen
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/job-poster-accepted-details',
                (route) => false,
                arguments: {
                  'jobId': activeJobId,
                  'requestId': active['requestId'],
                },
              );
            }
            return;
          }
        } catch (e) {
          print('Error checking job status: $e');
        }

        // Fallback: redirect to accepted details screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-accepted-details',
          (route) => false,
          arguments: {
            'jobId': activeJobId,
            // requestId is optional under new schema
          },
        );
        return;
      }

      // Fallback: if no activeJobId, check AcceptedJobs directly and force navigation
      try {
        final accepted =
            await FirebaseFirestore.instance
                .collection('AcceptedJobs')
                .where('jobPosterId', isEqualTo: poster.loggedInUserId)
                .where('isActive', isEqualTo: true)
                .orderBy('acceptedAt', descending: true)
                .limit(1)
                .get();
        if (accepted.docs.isNotEmpty) {
          final doc = accepted.docs.first;
          final data = doc.data();
          final jobId = (data['jobId'] ?? '').toString();
          final requestId = (data['requestId'] ?? '').toString();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-accepted-details',
            (route) => false,
            arguments: {'jobId': jobId, 'requestId': requestId},
          );
          return;
        }
      } catch (_) {}
    }

    // Legacy flows (JobRequests) kept for backward compatibility
    // Skilled worker first
    if (worker.isLoggedIn && worker.loggedInUserId != null) {
      final active = await JobRequestService.getActiveRequestForWorker(
        worker.loggedInUserId!,
      );
      if (!mounted) return;
      if (active != null) {
        final job = await JobRequestService.getJobDetails(active['jobId']);
        if (!mounted) return;
        if (job != null) {
          Navigator.pushReplacementNamed(
            context,
            '/skilled-worker-job-detail',
            arguments: {
              'imageUrl': job['Image'] ?? '',
              'title': job['title_en'] ?? job['title_ur'] ?? '',
              'location': job['Address'] ?? job['Location'] ?? '',
              'date': _safeConvertToDateTime(job['createdAt']),
              'description':
                  job['description_en'] ?? job['description_ur'] ?? '',
              'jobId': active['jobId'],
              'jobPosterId': active['jobPosterId'],
              'requestId': active['requestId'],
            },
          );
          return;
        }
      }
    }

    // Job poster
    if (poster.isLoggedIn && poster.loggedInUserId != null) {
      final active = await JobRequestService.getActiveRequestForPoster(
        poster.loggedInUserId!,
        posterPhone: poster.loggedInPhoneNumber,
      );
      if (!mounted) return;
      if (active != null) {
        final status = active['status'] as String?;
        // For job posters, redirect based on job status
        if (status == 'in_progress') {
          // In progress jobs go to job detail screen
          Navigator.pushReplacementNamed(
            context,
            '/job-poster-job-detail',
            arguments: {
              'jobId': active['jobId'],
              'requestId': active['requestId'],
            },
          );
        } else {
          // Accepted jobs go to accepted details screen
          Navigator.pushReplacementNamed(
            context,
            '/job-poster-accepted-details',
            arguments: {
              'jobId': active['jobId'],
              'requestId': active['requestId'],
            },
          );
        }
        return;
      }
    }

    print('[ActiveWorkGate] No active job found, proceeding to normal flow');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
