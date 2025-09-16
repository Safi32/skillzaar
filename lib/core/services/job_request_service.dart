import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class JobRequestService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's ID (job poster or skilled worker)
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Get job poster ID from job document
  static Future<String?> getJobPosterId(String jobId) async {
    try {
      final jobDoc = await _firestore.collection('Job').doc(jobId).get();
      if (jobDoc.exists) {
        final jobData = jobDoc.data() as Map<String, dynamic>;
        return jobData['jobPosterId'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting job poster ID: $e');
      return null;
    }
  }

  /// Get skilled worker ID for current user
  static Future<String?> getSkilledWorkerId() async {
    final user = _auth.currentUser;
    if (user == null) {
      // For testing: return a default skilled worker ID
      return 'TEST_SKILLED_WORKER_ID';
    }

    try {
      final workerDoc =
          await _firestore.collection('SkilledWorkers').doc(user.uid).get();

      if (workerDoc.exists) {
        return user.uid;
      }
      return null;
    } catch (e) {
      print('Error getting skilled worker ID: $e');
      return null;
    }
  }

  /// Check if user has already requested a job
  static Future<bool> hasRequestedJob(
    String jobId,
    String skilledWorkerId,
  ) async {
    try {
      final existingRequest =
          await _firestore
              .collection('JobRequests')
              .where('jobId', isEqualTo: jobId)
              .where('skilledWorkerId', isEqualTo: skilledWorkerId)
              .get();

      return existingRequest.docs.isNotEmpty;
    } catch (e) {
      print('Error checking existing request: $e');
      return false;
    }
  }

  /// Create a job request
  static Future<bool> createJobRequest({
    required String jobId,
    required String jobPosterId,
    required String skilledWorkerId,
    required String skilledWorkerName,
    required String skilledWorkerPhone,
  }) async {
    try {
      print('🔍 Creating Job Request:');
      print('  Job ID: $jobId');
      print('  Job Poster ID: $jobPosterId');
      print('  Skilled Worker ID: $skilledWorkerId');
      print('  Skilled Worker Name: $skilledWorkerName');
      print('  Skilled Worker Phone: $skilledWorkerPhone');

      final requestData = {
        'jobId': jobId,
        'jobPosterId': jobPosterId,
        'skilledWorkerId': skilledWorkerId,
        'skilledWorkerName': skilledWorkerName,
        'skilledWorkerPhone': skilledWorkerPhone,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      final docRef = await _firestore
          .collection('JobRequests')
          .add(requestData);
      print('✅ Job request created with ID: ${docRef.id}');
      return true;
    } catch (e) {
      print('❌ Error creating job request: $e');
      return false;
    }
  }

  /// Update job request status
  static Future<bool> updateRequestStatus(
    String requestId,
    String status,
  ) async {
    try {
      await _firestore.collection('JobRequests').doc(requestId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating request status: $e');
      return false;
    }
  }

  /// Get job requests for a job poster
  static Stream<QuerySnapshot> getJobRequestsForPoster(String jobPosterId) {
    return _firestore
        .collection('JobRequests')
        .where('jobPosterId', isEqualTo: jobPosterId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Best-effort normalization to rewrite legacy JobRequests with a
  /// placeholder jobPosterId to the currently logged-in poster's ID, based on
  /// ownership of jobs by user id or phone number.
  static Future<void> normalizeJobRequestsForPoster({
    required String jobPosterId,
    String? posterPhone,
  }) async {
    try {
      if (jobPosterId.isEmpty) return;

      // Collect jobs by this poster via user id
      final byUser =
          await _firestore
              .collection('Job')
              .where('jobPosterId', isEqualTo: jobPosterId)
              .get();

      // Compute job ids owned by poster: by user id + multiple phone variants
      final jobIds = <String>{...byUser.docs.map((d) => d.id)};

      if (posterPhone != null && posterPhone.isNotEmpty) {
        final phoneCandidates = <String>{posterPhone};
        if (posterPhone.startsWith('0') && posterPhone.length == 11) {
          phoneCandidates.add('+92${posterPhone.substring(1)}');
        }
        if (posterPhone.startsWith('+92') && posterPhone.length == 13) {
          phoneCandidates.add('0${posterPhone.substring(3)}');
        }
        if (posterPhone.length == 10 && posterPhone.startsWith('3')) {
          phoneCandidates.add('+92$posterPhone');
          phoneCandidates.add('0$posterPhone');
        }

        for (final ph in phoneCandidates) {
          final snap =
              await _firestore
                  .collection('Job')
                  .where('posterPhone', isEqualTo: ph)
                  .get();
          jobIds.addAll(snap.docs.map((d) => d.id));
        }
      }

      if (jobIds.isEmpty) return;

      for (final jobId in jobIds) {
        final reqs =
            await _firestore
                .collection('JobRequests')
                .where('jobId', isEqualTo: jobId)
                .get();

        for (final req in reqs.docs) {
          final data = req.data();
          final current = data['jobPosterId'] as String?;
          if (current != jobPosterId) {
            await req.reference.update({'jobPosterId': jobPosterId});
          }
        }
      }
    } catch (_) {
      // ignore normalization failures
    }
  }

  /// Get job requests for a skilled worker
  static Stream<QuerySnapshot> getJobRequestsForWorker(String skilledWorkerId) {
    return _firestore
        .collection('JobRequests')
        .where('skilledWorkerId', isEqualTo: skilledWorkerId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Get jobs for a job poster
  static Stream<QuerySnapshot> getJobsForPoster(String jobPosterId) {
    return _firestore
        .collection('Job')
        .where('jobPosterId', isEqualTo: jobPosterId)
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Get approved jobs for skilled workers to browse
  static Stream<QuerySnapshot> getApprovedJobs() {
    return _firestore
        .collection('Job')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Get pending jobs for admin approval
  static Stream<QuerySnapshot> getPendingJobs() {
    return _firestore
        .collection('Job')
        .where('status', isEqualTo: 'pending')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// Approve a pending job (admin function)
  static Future<bool> approveJob(String jobId) async {
    try {
      await _firestore.collection('Job').doc(jobId).update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error approving job: $e');
      return false;
    }
  }

  /// Reject a pending job (admin function)
  static Future<bool> rejectJob(String jobId, String reason) async {
    try {
      await _firestore.collection('Job').doc(jobId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });
      return true;
    } catch (e) {
      print('Error rejecting job: $e');
      return false;
    }
  }

  /// Get job details by ID
  static Future<Map<String, dynamic>?> getJobDetails(String jobId) async {
    try {
      print('🔍 getJobDetails: Looking for jobId: $jobId');

      // Try legacy collection 'Job' first
      final jobDoc = await _firestore.collection('Job').doc(jobId).get();
      print('🔍 Job collection result: exists=${jobDoc.exists}');
      if (jobDoc.exists) {
        final data = jobDoc.data() as Map<String, dynamic>;
        print('✅ Found job in Job collection: $data');
        return data;
      }

      // Fallback to new collection 'jobs'
      final newDoc = await _firestore.collection('jobs').doc(jobId).get();
      print('🔍 jobs collection result: exists=${newDoc.exists}');
      if (newDoc.exists) {
        final data = newDoc.data() as Map<String, dynamic>;
        // Optionally flatten some common fields for UI compatibility
        final details = (data['details'] as Map<String, dynamic>?) ?? {};
        return {
          ...data,
          // Provide best-effort compatibility keys used across UI
          'title_en': details['title'] ?? data['title_en'] ?? data['title'],
          'description_en':
              details['description'] ??
              data['description_en'] ??
              data['description'],
          'Address':
              details['address'] ??
              data['Address'] ??
              data['Location'] ??
              details['location'],
          'Location':
              details['location'] ?? data['Location'] ?? data['Address'],
          'Image': details['imageUrl'] ?? data['Image'] ?? data['imageUrl'],
          'createdAt': data['createdAt'] ?? details['createdAt'],
        };
        print('✅ Found job in jobs collection: $data');
        final result = {
          ...data,
          // Provide best-effort compatibility keys used across UI
          'title_en': details['title'] ?? data['title_en'] ?? data['title'],
          'description_en':
              details['description'] ??
              data['description_en'] ??
              data['description'],
          'Address':
              details['address'] ??
              data['Address'] ??
              data['Location'] ??
              details['location'],
          'Location':
              details['location'] ?? data['Location'] ?? data['Address'],
          'Image': details['imageUrl'] ?? data['Image'] ?? data['imageUrl'],
          'createdAt': data['createdAt'] ?? details['createdAt'],
        };
        print('✅ Returning processed job data: $result');
        return result;
      }
      print('❌ Job not found in any collection');
      return null;
    } catch (e) {
      print('❌ Error getting job details: $e');
      return null;
    }
  }

  /// Stream job status updates from unified collections
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamJobDoc(
    String jobId,
  ) {
    // Prefer new 'jobs' collection; consumer should handle non-existence
    return _firestore.collection('jobs').doc(jobId).snapshots();
  }

  /// Get first accepted request for a skilled worker (if any)
  static Future<Map<String, dynamic>?> getAcceptedRequestForWorker(
    String skilledWorkerId,
  ) async {
    try {
      final snap =
          await _firestore
              .collection('JobRequests')
              .where('skilledWorkerId', isEqualTo: skilledWorkerId)
              .where('status', isEqualTo: 'accepted')
              .limit(1)
              .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final Map<String, dynamic> data = doc.data();
      return {...data, 'requestId': doc.id};
    } catch (e) {
      print('Error fetching accepted request for worker: $e');
      return null;
    }
  }

  /// Get active (in_progress or accepted) request for worker
  static Future<Map<String, dynamic>?> getActiveRequestForWorker(
    String skilledWorkerId, {
    String? skilledWorkerPhone,
  }) async {
    // Try in_progress first
    final inProg =
        await _firestore
            .collection('JobRequests')
            .where('skilledWorkerId', isEqualTo: skilledWorkerId)
            .where('status', isEqualTo: 'in_progress')
            .limit(1)
            .get();
    if (inProg.docs.isNotEmpty) {
      final d = inProg.docs.first;
      final data = d.data();
      return {...data, 'requestId': d.id};
    }
    // Then accepted (treat as active regardless of legacy isActive flag)
    final acc =
        await _firestore
            .collection('JobRequests')
            .where('skilledWorkerId', isEqualTo: skilledWorkerId)
            .where('status', isEqualTo: 'accepted')
            .limit(1)
            .get();
    if (acc.docs.isNotEmpty) {
      final d = acc.docs.first;
      final data = d.data();
      return {...data, 'requestId': d.id};
    }
    // Fallback by phone if id-based lookup fails (legacy TEST ids)
    if (skilledWorkerPhone != null && skilledWorkerPhone.isNotEmpty) {
      final phones = <String>{skilledWorkerPhone};
      if (skilledWorkerPhone.startsWith('0') &&
          skilledWorkerPhone.length == 11) {
        phones.add('+92${skilledWorkerPhone.substring(1)}');
      }
      if (skilledWorkerPhone.startsWith('+92') &&
          skilledWorkerPhone.length == 13) {
        phones.add('0${skilledWorkerPhone.substring(3)}');
      }
      if (skilledWorkerPhone.length == 10 &&
          skilledWorkerPhone.startsWith('3')) {
        phones.add('+92$skilledWorkerPhone');
        phones.add('0$skilledWorkerPhone');
      }
      for (final ph in phones) {
        final snap =
            await _firestore
                .collection('JobRequests')
                .where('skilledWorkerPhone', isEqualTo: ph)
                .where('status', whereIn: ['in_progress', 'accepted'])
                .limit(1)
                .get();
        if (snap.docs.isNotEmpty) {
          final d = snap.docs.first;
          final data = d.data();
          // normalize id for next time
          if (data['skilledWorkerId'] != skilledWorkerId) {
            await d.reference.update({'skilledWorkerId': skilledWorkerId});
          }
          return {...data, 'requestId': d.id};
        }
      }
    }
    return null;
  }

  /// Get this worker's request for a specific job (returns status and id)
  static Future<Map<String, dynamic>?> getWorkerRequestForJob({
    required String skilledWorkerId,
    required String jobId,
  }) async {
    try {
      final snap =
          await _firestore
              .collection('JobRequests')
              .where('skilledWorkerId', isEqualTo: skilledWorkerId)
              .where('jobId', isEqualTo: jobId)
              .limit(1)
              .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final Map<String, dynamic> data = doc.data();
      return {...data, 'requestId': doc.id};
    } catch (e) {
      print('Error fetching worker request for job: $e');
      return null;
    }
  }

  /// Mark a job request as in progress
  static Future<bool> markRequestInProgress(String requestId) async {
    try {
      final reqRef = _firestore.collection('JobRequests').doc(requestId);
      final reqSnap = await reqRef.get();
      if (!reqSnap.exists) return false;
      final data = reqSnap.data() as Map<String, dynamic>;

      await reqRef.update({
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final skilledWorkerId = data['skilledWorkerId'] as String?;
      final jobId = data['jobId'] as String?;

      // Best-effort: set active job on SkilledWorkers and status/availability
      if (skilledWorkerId != null && skilledWorkerId.isNotEmpty) {
        if (jobId != null && jobId.isNotEmpty) {
          await _firestore
              .collection('SkilledWorkers')
              .doc(skilledWorkerId)
              .set({'activeJobId': jobId}, SetOptions(merge: true));
          // Set SharedPreferences flag for immediate redirect
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('active_job_$skilledWorkerId', true);
          await prefs.setString('active_job_${skilledWorkerId}_jobId', jobId);
          print(
            '✅ Set SharedPrefs: active_job_$skilledWorkerId = true, jobId = $jobId',
          );
        }
        await _firestore.collection('SkilledWorkers').doc(skilledWorkerId).set({
          'status': 'in_progress',
          'availability': true,
        }, SetOptions(merge: true));
      }
      return true;
    } catch (e) {
      print('Error marking request in progress: $e');
      return false;
    }
  }

  /// Mark a job request as accepted (poster action)
  static Future<bool> markRequestAccepted(String requestId) async {
    try {
      final reqRef = _firestore.collection('JobRequests').doc(requestId);
      final reqSnap = await reqRef.get();
      if (!reqSnap.exists) return false;
      final data = reqSnap.data() as Map<String, dynamic>;

      await reqRef.update({
        'status': 'accepted',
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final skilledWorkerId = data['skilledWorkerId'] as String?;
      final jobPosterId = data['jobPosterId'] as String?;
      final jobId = data['jobId'] as String?;

      // Set active job for skilled worker
      if (skilledWorkerId != null && skilledWorkerId.isNotEmpty) {
        if (jobId != null && jobId.isNotEmpty) {
          await _firestore
              .collection('SkilledWorkers')
              .doc(skilledWorkerId)
              .set({'activeJobId': jobId}, SetOptions(merge: true));
          // Set SharedPreferences flag for immediate redirect
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('active_job_$skilledWorkerId', true);
          await prefs.setString('active_job_${skilledWorkerId}_jobId', jobId);
          print(
            '✅ Set SharedPrefs for worker: active_job_$skilledWorkerId = true, jobId = $jobId',
          );
        }
        await _firestore.collection('SkilledWorkers').doc(skilledWorkerId).set({
          'status': 'accepted',
          'availability': true,
        }, SetOptions(merge: true));
      }

      // Set active job for job poster
      if (jobPosterId != null && jobPosterId.isNotEmpty) {
        if (jobId != null && jobId.isNotEmpty) {
          await _firestore.collection('JobPosters').doc(jobPosterId).set({
            'activeJobId': jobId,
          }, SetOptions(merge: true));
          // Set SharedPreferences flag for immediate redirect
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('active_job_$jobPosterId', true);
          await prefs.setString('active_job_${jobPosterId}_jobId', jobId);
          print(
            '✅ Set SharedPrefs for poster: active_job_$jobPosterId = true, jobId = $jobId',
          );
        }
      }

      return true;
    } catch (e) {
      print('Error marking request accepted: $e');
      return false;
    }
  }

  /// For job poster: get an in-progress request (worker currently active)
  static Future<Map<String, dynamic>?> getInProgressRequestForPoster(
    String jobPosterId,
  ) async {
    try {
      final snap =
          await _firestore
              .collection('JobRequests')
              .where('jobPosterId', isEqualTo: jobPosterId)
              .where('status', isEqualTo: 'in_progress')
              .limit(1)
              .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final Map<String, dynamic> data = doc.data();
      return {...data, 'requestId': doc.id};
    } catch (e) {
      print('Error fetching in-progress request for poster: $e');
      return null;
    }
  }

  /// For job poster: get an accepted request (worker accepted but not yet started)
  static Future<Map<String, dynamic>?> getAcceptedRequestForPoster(
    String jobPosterId,
  ) async {
    try {
      final snap =
          await _firestore
              .collection('JobRequests')
              .where('jobPosterId', isEqualTo: jobPosterId)
              .where('status', isEqualTo: 'accepted')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      final Map<String, dynamic> data = doc.data();
      return {...data, 'requestId': doc.id};
    } catch (e) {
      print('Error fetching accepted request for poster: $e');
      return null;
    }
  }

  /// Get active (in_progress or accepted) request for poster
  static Future<Map<String, dynamic>?> getActiveRequestForPoster(
    String jobPosterId, {
    String? posterPhone,
  }) async {
    print(
      '[JobRequestService] getActiveRequestForPoster called with jobPosterId: $jobPosterId',
    );
    print(
      '[JobRequestService] getActiveRequestForPoster called with posterPhone: $posterPhone',
    );

    final inProg =
        await _firestore
            .collection('JobRequests')
            .where('jobPosterId', isEqualTo: jobPosterId)
            .where('status', isEqualTo: 'in_progress')
            .limit(1)
            .get();
    print(
      '[JobRequestService] In-progress requests found: ${inProg.docs.length}',
    );
    if (inProg.docs.isNotEmpty) {
      final d = inProg.docs.first;
      final data = d.data();
      print('[JobRequestService] Found in-progress request: ${d.id} = $data');
      return {...data, 'requestId': d.id};
    }

    final acc =
        await _firestore
            .collection('JobRequests')
            .where('jobPosterId', isEqualTo: jobPosterId)
            .where('status', isEqualTo: 'accepted')
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();
    print('[JobRequestService] Accepted requests found: ${acc.docs.length}');
    if (acc.docs.isNotEmpty) {
      final d = acc.docs.first;
      final data = d.data();
      print('[JobRequestService] Found accepted request: ${d.id} = $data');
      return {...data, 'requestId': d.id};
    }
    // Fallback by phone: look for active requests whose job's posterPhone matches
    if (posterPhone != null && posterPhone.isNotEmpty) {
      final phones = <String>{posterPhone};
      if (posterPhone.startsWith('0') && posterPhone.length == 11) {
        phones.add('+92${posterPhone.substring(1)}');
      }
      if (posterPhone.startsWith('+92') && posterPhone.length == 13) {
        phones.add('0${posterPhone.substring(3)}');
      }
      if (posterPhone.length == 10 && posterPhone.startsWith('3')) {
        phones.add('+92$posterPhone');
        phones.add('0$posterPhone');
      }
      // Query recent active requests then verify against Job.posterPhone
      final activeSnap =
          await _firestore
              .collection('JobRequests')
              .where('isActive', isEqualTo: true)
              .where('status', whereIn: ['in_progress', 'accepted'])
              .limit(25)
              .get();
      for (final doc in activeSnap.docs) {
        final data = doc.data();
        final jobId = data['jobId'] as String?;
        if (jobId == null) continue;
        final job = await _firestore.collection('Job').doc(jobId).get();
        if (!job.exists) continue;
        final jd = job.data() as Map<String, dynamic>;
        final jobPhone = jd['posterPhone'] as String?;
        if (jobPhone != null && phones.contains(jobPhone)) {
          // normalize id for next time
          if (data['jobPosterId'] != jobPosterId) {
            await doc.reference.update({'jobPosterId': jobPosterId});
          }
          return {...data, 'requestId': doc.id};
        }
      }
    }
    return null;
  }

  /// Mark a job request as completed (poster action)
  static Future<bool> markRequestCompleted(String requestId) async {
    try {
      final reqRef = _firestore.collection('JobRequests').doc(requestId);
      final reqSnap = await reqRef.get();
      if (!reqSnap.exists) return false;
      final data = reqSnap.data() as Map<String, dynamic>;

      await reqRef.update({
        'status': 'completed',
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final skilledWorkerId = data['skilledWorkerId'] as String?;
      final jobPosterId = data['jobPosterId'] as String?;
      final jobId = data['jobId'] as String?;

      // Clear active job for skilled worker
      if (skilledWorkerId != null && skilledWorkerId.isNotEmpty) {
        await _firestore.collection('SkilledWorkers').doc(skilledWorkerId).set({
          'activeJobId': FieldValue.delete(),
        }, SetOptions(merge: true));
        // Clear SharedPreferences flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('active_job_$skilledWorkerId', false);
        await prefs.remove('active_job_${skilledWorkerId}_jobId');
        print(
          '✅ Cleared SharedPrefs for worker: active_job_$skilledWorkerId = false',
        );
        await _firestore.collection('SkilledWorkers').doc(skilledWorkerId).set({
          'status': 'available',
          'availability': false,
        }, SetOptions(merge: true));
      }

      // Clear active job for job poster
      if (jobPosterId != null && jobPosterId.isNotEmpty) {
        await _firestore.collection('JobPosters').doc(jobPosterId).set({
          'activeJobId': FieldValue.delete(),
        }, SetOptions(merge: true));
        // Clear SharedPreferences flag
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('active_job_$jobPosterId', false);
        await prefs.remove('active_job_${jobPosterId}_jobId');
        print(
          '✅ Cleared SharedPrefs for poster: active_job_$jobPosterId = false',
        );
      }

      // Optional: also mark job document inactive if using unified 'jobs'
      if (jobId != null && jobId.isNotEmpty) {
        try {
          await _firestore.collection('jobs').doc(jobId).set({
            'active': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {
          // ignore if unified jobs collection not in use
        }
      }
      return true;
    } catch (e) {
      print('Error marking request completed: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getSkilledWorkerDetails(
    String skilledWorkerId,
  ) async {
    try {
      final workerDoc =
          await _firestore
              .collection('SkilledWorkers')
              .doc(skilledWorkerId)
              .get();

      if (workerDoc.exists) {
        return workerDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting skilled worker details: $e');
      return null;
    }
  }

  /// Get job poster details by ID
  static Future<Map<String, dynamic>?> getJobPosterDetails(
    String jobPosterId,
  ) async {
    try {
      final posterDoc =
          await _firestore.collection('JobPosters').doc(jobPosterId).get();
      if (posterDoc.exists) {
        return posterDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting job poster details: $e');
      return null;
    }
  }

  /// Launch navigation from skilled worker location to job location
  static Future<void> launchNavigation({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String? fromAddress,
    String? toAddress,
  }) async {
    try {
      // Try to launch Google Maps with directions
      final googleMapsUrl =
          'https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLng&destination=$toLat,$toLng&travelmode=driving';

      final uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to Apple Maps or other navigation apps
        final fallbackUrl =
            'https://maps.apple.com/?daddr=$toLat,$toLng&saddr=$fromLat,$fromLng';
        final fallbackUri = Uri.parse(fallbackUrl);
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception('No navigation app available');
        }
      }
    } catch (e) {
      print('Error launching navigation: $e');
      rethrow;
    }
  }

  /// Launch Google Maps with directions
  static Future<void> launchGoogleMapsDirections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final url =
          'https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLng&destination=$toLat,$toLng&travelmode=driving';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch Google Maps');
      }
    } catch (e) {
      print('Error launching Google Maps: $e');
      rethrow;
    }
  }

  /// Launch Apple Maps with directions (iOS)
  static Future<void> launchAppleMapsDirections({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final url =
          'https://maps.apple.com/?daddr=$toLat,$toLng&saddr=$fromLat,$fromLng';
      final uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch Apple Maps');
      }
    } catch (e) {
      print('Error launching Apple Maps: $e');
      rethrow;
    }
  }

  /// Get distance between two points in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double R = 6371; // Earth's radius in kilometers
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Get estimated travel time (rough estimate)
  static String getEstimatedTravelTime(double distanceKm) {
    // Rough estimate: 30 km/h average speed in city
    final estimatedHours = distanceKm / 30;
    if (estimatedHours < 1) {
      final minutes = (estimatedHours * 60).round();
      return '${minutes} min';
    } else {
      final hours = estimatedHours.round();
      return '${hours} hr';
    }
  }
}
