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
      print('🔍 Getting job poster ID for job: $jobId');

      // Try legacy 'Job' collection first
      final jobDoc = await _firestore.collection('Job').doc(jobId).get();
      if (jobDoc.exists) {
        final jobData = jobDoc.data() as Map<String, dynamic>;
        final jobPosterId = jobData['jobPosterId'] as String?;
        print('🔍 Found job poster ID in Job collection: $jobPosterId');
        return jobPosterId;
      }

      // Try new 'jobs' collection as fallback
      final newJobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (newJobDoc.exists) {
        final jobData = newJobDoc.data() as Map<String, dynamic>;
        final jobPosterId = jobData['jobPosterId'] as String?;
        print('🔍 Found job poster ID in jobs collection: $jobPosterId');
        return jobPosterId;
      }

      print('❌ Job not found in any collection');
      return null;
    } catch (e) {
      print('❌ Error getting job poster ID: $e');
      return null;
    }
  }

  /// Get skilled worker ID for current user
  static Future<String?> getSkilledWorkerId() async {
    final user = _auth.currentUser;
    if (user == null) {
      print('🔍 No authenticated user, returning test skilled worker ID');
      return 'TEST_SKILLED_WORKER_ID';
    }

    try {
      print('🔍 Getting skilled worker ID for user: ${user.uid}');

      final workerDoc =
          await _firestore.collection('SkilledWorkers').doc(user.uid).get();

      if (workerDoc.exists) {
        print(
          '🔍 Found skilled worker document, returning user ID: ${user.uid}',
        );
        return user.uid;
      }

      print('❌ Skilled worker document not found for user: ${user.uid}');
      return null;
    } catch (e) {
      print('❌ Error getting skilled worker ID: $e');
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

  /// Check if a job has any active requests (in_progress or accepted)
  static Future<bool> hasActiveRequests(String jobId) async {
    try {
      print('🔍 Checking for active requests for job: $jobId');

      // Check for in_progress requests
      final inProgressRequests =
          await _firestore
              .collection('JobRequests')
              .where('jobId', isEqualTo: jobId)
              .where('status', isEqualTo: 'in_progress')
              .where('isActive', isEqualTo: true)
              .get();

      if (inProgressRequests.docs.isNotEmpty) {
        print(
          '🔍 Found ${inProgressRequests.docs.length} in_progress requests',
        );
        return true;
      }

      // Check for accepted requests
      final acceptedRequests =
          await _firestore
              .collection('JobRequests')
              .where('jobId', isEqualTo: jobId)
              .where('status', isEqualTo: 'accepted')
              .where('isActive', isEqualTo: true)
              .get();

      if (acceptedRequests.docs.isNotEmpty) {
        print('🔍 Found ${acceptedRequests.docs.length} accepted requests');
        return true;
      }

      print('🔍 No active requests found for job: $jobId');
      return false;
    } catch (e) {
      print('❌ Error checking active requests: $e');
      return false;
    }
  }

  /// Get active request details for a job (if any)
  static Future<Map<String, dynamic>?> getActiveRequestForJob(
    String jobId,
  ) async {
    try {
      print('🔍 Getting active request details for job: $jobId');

      // Check for in_progress requests first
      final inProgressRequests =
          await _firestore
              .collection('JobRequests')
              .where('jobId', isEqualTo: jobId)
              .where('status', isEqualTo: 'in_progress')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (inProgressRequests.docs.isNotEmpty) {
        final doc = inProgressRequests.docs.first;
        final data = doc.data();
        print('🔍 Found in_progress request: ${doc.id}');
        return {...data, 'requestId': doc.id, 'status': 'in_progress'};
      }

      // Check for accepted requests
      final acceptedRequests =
          await _firestore
              .collection('JobRequests')
              .where('jobId', isEqualTo: jobId)
              .where('status', isEqualTo: 'accepted')
              .where('isActive', isEqualTo: true)
              .limit(1)
              .get();

      if (acceptedRequests.docs.isNotEmpty) {
        final doc = acceptedRequests.docs.first;
        final data = doc.data();
        print('🔍 Found accepted request: ${doc.id}');
        return {...data, 'requestId': doc.id, 'status': 'accepted'};
      }

      print('🔍 No active requests found for job: $jobId');
      return null;
    } catch (e) {
      print('❌ Error getting active request for job: $e');
      return null;
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
    print('🔍 JobRequestService.getJobRequestsForPoster:');
    print('👤 Job Poster ID: $jobPosterId');

    final stream =
        _firestore
            .collection('JobRequests')
            .where('jobPosterId', isEqualTo: jobPosterId)
            .where('isActive', isEqualTo: true)
            .snapshots();

    // Add listener to debug
    stream.listen((snapshot) {
      print('📊 Job Requests found: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        print('📄 Request ID: ${doc.id}');
        print('📄 Request Data: ${doc.data()}');
      }
    });

    return stream;
  }
  static Stream<QuerySnapshot> getJobRequestsForPosterByPhone(
    String phoneNumber,
  ) {
    print('🔍 JobRequestService.getJobRequestsForPosterByPhone:');
    print('📱 Phone Number: $phoneNumber');

    // Generate multiple phone number formats to search for
    final phoneVariants = <String>{phoneNumber};
    if (phoneNumber.startsWith('+92') && phoneNumber.length == 13) {
      phoneVariants.add('0${phoneNumber.substring(3)}');
      phoneVariants.add(phoneNumber.substring(3));
    } else if (phoneNumber.startsWith('0') && phoneNumber.length == 11) {
      phoneVariants.add('+92${phoneNumber.substring(1)}');
      phoneVariants.add(phoneNumber.substring(1));
    } else if (phoneNumber.length == 10 && phoneNumber.startsWith('3')) {
      phoneVariants.add('+92$phoneNumber');
      phoneVariants.add('0$phoneNumber');
    }

    print('📱 Phone variants to search: $phoneVariants');

    // First, get all jobs created by this phone number
    final jobsStream =
        _firestore
            .collection('Job')
            .where('posterPhone', whereIn: phoneVariants.toList())
            .snapshots();

    return jobsStream.asyncMap((jobsSnapshot) async {
      if (jobsSnapshot.docs.isEmpty) {
        print('📊 No jobs found for phone: $phoneNumber');
        // Return an empty QuerySnapshot by querying for non-existent data
        return await _firestore
            .collection('JobRequests')
            .where('jobId', isEqualTo: 'NON_EXISTENT_JOB_ID')
            .where('isActive', isEqualTo: true)
            .get();
      }

      final jobIds = jobsSnapshot.docs.map((doc) => doc.id).toList();
      final jobPosterIds =
          jobsSnapshot.docs
              .map((doc) {
                final data = doc.data();
                return data['jobPosterId'] as String?;
              })
              .where((id) => id != null && id.isNotEmpty)
              .toList();

      print('📊 Found ${jobIds.length} jobs for phone: $phoneNumber');
      print('📊 Job IDs: $jobIds');
      print('📊 Job Poster IDs: $jobPosterIds');

      // Debug: Print job details to see what phone numbers are stored
      for (var doc in jobsSnapshot.docs) {
        final data = doc.data();
        print(
          '📊 Job ${doc.id} - posterPhone: ${data['posterPhone']}, jobPosterId: ${data['jobPosterId']}',
        );
      }

      // Get all requests for these jobs
      final requestsSnapshot =
          await _firestore
              .collection('JobRequests')
              .where('jobId', whereIn: jobIds)
              .where('isActive', isEqualTo: true)
              .get();

      print('📊 Found ${requestsSnapshot.docs.length} requests for these jobs');
      for (var doc in requestsSnapshot.docs) {
        print('📄 Request ID: ${doc.id}');
        print('📄 Request Data: ${doc.data()}');
      }

      return requestsSnapshot;
    }).asBroadcastStream();
  }

  /// Get job requests for a job poster by jobPosterId from job documents (fallback)
  static Stream<QuerySnapshot> getJobRequestsForPosterByJobPosterId(
    String phoneNumber,
  ) {
    print('🔍 JobRequestService.getJobRequestsForPosterByJobPosterId:');
    print('📱 Phone Number: $phoneNumber');

    // Generate multiple phone number formats to search for
    final phoneVariants = <String>{phoneNumber};
    if (phoneNumber.startsWith('+92') && phoneNumber.length == 13) {
      phoneVariants.add('0${phoneNumber.substring(3)}');
      phoneVariants.add(phoneNumber.substring(3));
    } else if (phoneNumber.startsWith('0') && phoneNumber.length == 11) {
      phoneVariants.add('+92${phoneNumber.substring(1)}');
      phoneVariants.add(phoneNumber.substring(1));
    } else if (phoneNumber.length == 10 && phoneNumber.startsWith('3')) {
      phoneVariants.add('+92$phoneNumber');
      phoneVariants.add('0$phoneNumber');
    }

    print('📱 Phone variants to search: $phoneVariants');

    // First, get all jobs created by this phone number and extract their jobPosterIds
    final jobsStream =
        _firestore
            .collection('Job')
            .where('posterPhone', whereIn: phoneVariants.toList())
            .snapshots();

    return jobsStream.asyncMap((jobsSnapshot) async {
      if (jobsSnapshot.docs.isEmpty) {
        print('📊 No jobs found for phone: $phoneNumber');
        // Return an empty QuerySnapshot by querying for non-existent data
        return await _firestore
            .collection('JobRequests')
            .where('jobId', isEqualTo: 'NON_EXISTENT_JOB_ID')
            .where('isActive', isEqualTo: true)
            .get();
      }

      // Extract jobPosterIds from job documents
      final jobPosterIds =
          jobsSnapshot.docs
              .map((doc) {
                final data = doc.data();
                return data['jobPosterId'] as String?;
              })
              .where((id) => id != null && id.isNotEmpty)
              .toList();

      print(
        '📊 Found ${jobPosterIds.length} unique job poster IDs for phone: $phoneNumber',
      );
      print('📊 Job Poster IDs: $jobPosterIds');

      // Debug: Print job details to see what phone numbers are stored
      for (var doc in jobsSnapshot.docs) {
        final data = doc.data();
        print(
          '📊 Job ${doc.id} - posterPhone: ${data['posterPhone']}, jobPosterId: ${data['jobPosterId']}',
        );
      }

      if (jobPosterIds.isEmpty) {
        print('📊 No job poster IDs found in job documents');
        return await _firestore
            .collection('JobRequests')
            .where('jobId', isEqualTo: 'NON_EXISTENT_JOB_ID')
            .where('isActive', isEqualTo: true)
            .get();
      }

      // Get all requests for these job poster IDs
      final requestsSnapshot =
          await _firestore
              .collection('JobRequests')
              .where('jobPosterId', whereIn: jobPosterIds)
              .where('isActive', isEqualTo: true)
              .get();

      print(
        '📊 Found ${requestsSnapshot.docs.length} requests for these job poster IDs',
      );
      for (var doc in requestsSnapshot.docs) {
        print('📄 Request ID: ${doc.id}');
        print('📄 Request Data: ${doc.data()}');
      }

      return requestsSnapshot;
    }).asBroadcastStream();
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

      // Snapshot essential job fields into the JobRequests doc for reliable display
      if (jobId != null && jobId.isNotEmpty) {
        try {
          final jobData = await getJobDetails(jobId);
          if (jobData != null) {
            await reqRef.set({
              'jobTitle':
                  jobData['title_en'] ??
                  jobData['title_ur'] ??
                  jobData['title'],
              'jobDescription':
                  jobData['description_en'] ??
                  jobData['description_ur'] ??
                  jobData['description'],
              'jobLocation': jobData['Location'] ?? jobData['Address'],
              'jobBudget': jobData['budget'],
            }, SetOptions(merge: true));
          }
        } catch (e) {
          // Non-fatal: continue even if job snapshot fails
          print('warn: could not snapshot job details on accept: $e');
        }
      }

      if (jobId != null &&
          jobId.isNotEmpty &&
          skilledWorkerId != null &&
          skilledWorkerId.isNotEmpty) {
        try {
          await _createAcceptedJobEntry(
            jobId: jobId,
            skilledWorkerId: skilledWorkerId,
            jobPosterId: jobPosterId,
            requestId: requestId,
          );
        } catch (e) {
          print('❌ Error creating AcceptedJobs entry: $e');
          // Don't fail the entire operation if AcceptedJobs creation fails
        }
      }

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

      // Mark job as inactive when completed
      if (jobId != null && jobId.isNotEmpty) {
        await markJobAsInactive(jobId);
      }
      return true;
    } catch (e) {
      print('Error marking request completed: $e');
      return false;
    }
  }

  /// Mark a job as inactive (completed or no longer available)
  static Future<bool> markJobAsInactive(String jobId) async {
    try {
      print('🔍 Marking job as inactive: $jobId');

      // Mark job as inactive in legacy Job collection
      await _firestore.collection('Job').doc(jobId).update({
        'isActive': false,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Mark job as inactive in new jobs collection
      await _firestore.collection('jobs').doc(jobId).set({
        'active': false,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Job marked as inactive: $jobId');
      return true;
    } catch (e) {
      print('❌ Error marking job as inactive: $e');
      return false;
    }
  }

  /// Check if a job is still active (not completed or cancelled)
  static Future<bool> isJobActive(String jobId) async {
    try {
      print('🔍 Checking if job is active: $jobId');

      // Check legacy Job collection first
      final jobDoc = await _firestore.collection('Job').doc(jobId).get();
      if (jobDoc.exists) {
        final data = jobDoc.data();
        final isActive = data?['isActive'] as bool? ?? true;
        final status = data?['status'] as String? ?? 'approved';

        print('🔍 Job collection - isActive: $isActive, status: $status');
        return isActive && status != 'completed' && status != 'cancelled';
      }

      // Check new jobs collection as fallback
      final newJobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (newJobDoc.exists) {
        final data = newJobDoc.data();
        final isActive = data?['active'] as bool? ?? true;
        final status = data?['status'] as String? ?? 'approved';

        print('🔍 Jobs collection - isActive: $isActive, status: $status');
        return isActive && status != 'completed' && status != 'cancelled';
      }

      print('❌ Job not found in any collection: $jobId');
      return false;
    } catch (e) {
      print('❌ Error checking if job is active: $e');
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

  /// Create an entry in AcceptedJobs collection with job and skilled worker details
  static Future<void> _createAcceptedJobEntry({
    required String jobId,
    required String skilledWorkerId,
    String? jobPosterId,
    required String requestId,
  }) async {
    try {
      print(
        '🔍 Creating AcceptedJobs entry for job: $jobId, worker: $skilledWorkerId',
      );

      // Get complete job details
      final jobData = await getJobDetails(jobId);
      if (jobData == null) {
        print('❌ Job data not found for jobId: $jobId');
        return;
      }

      // Get complete skilled worker details
      final skilledWorkerData = await getSkilledWorkerDetails(skilledWorkerId);
      if (skilledWorkerData == null) {
        print('❌ Skilled worker data not found for workerId: $skilledWorkerId');
        return;
      }

      // Get job poster details if available
      Map<String, dynamic>? jobPosterData;
      if (jobPosterId != null && jobPosterId.isNotEmpty) {
        jobPosterData = await getJobPosterDetails(jobPosterId);
      }

      // Create the AcceptedJobs entry
      final acceptedJobData = {
        // Basic info
        'requestId': requestId,
        'jobId': jobId,
        'skilledWorkerId': skilledWorkerId,
        'jobPosterId': jobPosterId,
        'acceptedAt': FieldValue.serverTimestamp(),
        'status': 'accepted',
        'isActive': true,

        // Complete job details
        'jobDetails': {
          'jobName':
              jobData['title_en'] ??
              jobData['title_ur'] ??
              jobData['title'] ??
              'Job Title',
          'jobLocation':
              jobData['Location'] ??
              jobData['Address'] ??
              'Location not specified',
          'jobImage':
              jobData['ImageUrl'] ?? jobData['imageUrl'] ?? jobData['Image'],
          'jobDescription':
              jobData['description_en'] ??
              jobData['description_ur'] ??
              jobData['description'] ??
              'No description',
          // Additional job fields
          'latitude': jobData['Latitude'],
          'longitude': jobData['Longitude'],
          'budget': jobData['budget'],
          'createdAt': jobData['createdAt'],
          'category': jobData['category'],
          'urgency': jobData['urgency'],
          'estimatedDuration': jobData['estimatedDuration'],
        },

        // Complete skilled worker details
        'skilledWorkerDetails': {
          'skilledWorkerName':
              skilledWorkerData['Name'] ??
              skilledWorkerData['name'] ??
              'Skilled Worker',
          'skilledWorkerCity':
              skilledWorkerData['City'] ?? skilledWorkerData['city'],
          'skilledWorkerDescription':
              skilledWorkerData['description'] ??
              skilledWorkerData['Description'] ??
              skilledWorkerData['bio'] ??
              skilledWorkerData['Bio'] ??
              'No description available',
          'skilledWorkerImage':
              skilledWorkerData['ProfilePicture'] ??
              skilledWorkerData['profilePicture'] ??
              skilledWorkerData['image'] ??
              skilledWorkerData['Image'],
          'skilledWorkerExperience':
              skilledWorkerData['experience'] ??
              skilledWorkerData['Experience'] ??
              skilledWorkerData['yearsOfExperience'] ??
              skilledWorkerData['YearsOfExperience'] ??
              'Experience not specified',
          // Additional skilled worker fields
          'age': skilledWorkerData['Age'] ?? skilledWorkerData['age'],
          'phoneNumber':
              skilledWorkerData['phoneNumber'] ?? skilledWorkerData['phone'],
          'displayName':
              skilledWorkerData['displayName'] ?? skilledWorkerData['name'],
          'cnicFront':
              skilledWorkerData['CNICFront'] ?? skilledWorkerData['cnicFront'],
          'cnicBack':
              skilledWorkerData['CNICBack'] ?? skilledWorkerData['cnicBack'],
          'currentLatitude': skilledWorkerData['currentLatitude'],
          'currentLongitude': skilledWorkerData['currentLongitude'],
          'currentAddress': skilledWorkerData['currentAddress'],
          'locationUpdatedAt': skilledWorkerData['locationUpdatedAt'],
          'createdAt': skilledWorkerData['createdAt'],
          'isActive': skilledWorkerData['isActive'],
        },

        // Job poster details (if available)
        'jobPosterDetails':
            jobPosterData != null
                ? {
                  'name':
                      jobPosterData['name'] ??
                      jobPosterData['Name'] ??
                      'Job Poster',
                  'phoneNumber':
                      jobPosterData['phoneNumber'] ?? jobPosterData['phone'],
                  'email': jobPosterData['email'],
                  'address': jobPosterData['address'],
                  'createdAt': jobPosterData['createdAt'],
                }
                : null,
      };

      // Save to AcceptedJobs collection
      final docRef = await _firestore
          .collection('AcceptedJobs')
          .add(acceptedJobData);
      print('✅ AcceptedJobs entry created successfully with ID: ${docRef.id}');
      print('🔍 AcceptedJobs data saved: $acceptedJobData');
    } catch (e) {
      print('❌ Error creating AcceptedJobs entry: $e');
      rethrow;
    }
  }

  /// Get all accepted jobs for a skilled worker
  static Stream<QuerySnapshot> getAcceptedJobsForWorker(
    String skilledWorkerId,
  ) {
    return _firestore
        .collection('AcceptedJobs')
        .where('skilledWorkerId', isEqualTo: skilledWorkerId)
        .where('isActive', isEqualTo: true)
        .orderBy('acceptedAt', descending: true)
        .snapshots();
  }

  /// Get all accepted jobs for a job poster
  static Stream<QuerySnapshot> getAcceptedJobsForPoster(String jobPosterId) {
    return _firestore
        .collection('AcceptedJobs')
        .where('jobPosterId', isEqualTo: jobPosterId)
        .where('isActive', isEqualTo: true)
        .orderBy('acceptedAt', descending: true)
        .snapshots();
  }

  /// Get all accepted jobs (admin function)
  static Stream<QuerySnapshot> getAllAcceptedJobs() {
    return _firestore
        .collection('AcceptedJobs')
        .where('isActive', isEqualTo: true)
        .orderBy('acceptedAt', descending: true)
        .snapshots();
  }

  /// Mark an accepted job as completed
  static Future<bool> markAcceptedJobCompleted(String acceptedJobId) async {
    try {
      await _firestore.collection('AcceptedJobs').doc(acceptedJobId).update({
        'status': 'completed',
        'isActive': false,
        'completedAt': FieldValue.serverTimestamp(),
      });
      print('✅ Accepted job marked as completed: $acceptedJobId');
      return true;
    } catch (e) {
      print('❌ Error marking accepted job as completed: $e');
      return false;
    }
  }

  /// Mark an accepted job as in progress
  static Future<bool> markAcceptedJobInProgress(String acceptedJobId) async {
    try {
      await _firestore.collection('AcceptedJobs').doc(acceptedJobId).update({
        'status': 'in_progress',
        'inProgressAt': FieldValue.serverTimestamp(),
      });
      print('✅ Accepted job marked as in progress: $acceptedJobId');
      return true;
    } catch (e) {
      print('❌ Error marking accepted job as in progress: $e');
      return false;
    }
  }

  /// Cancel a job and clean up all related data
  static Future<bool> cancelJob({
    required String jobId,
    required String requestId,
    required String jobPosterId,
    required String skilledWorkerId,
  }) async {
    try {
      print('🔍 Cancelling job - JobId: $jobId, RequestId: $requestId');
      print('🔍 JobPosterId: $jobPosterId, SkilledWorkerId: $skilledWorkerId');

      // 1. Update job status to cancelled in both collections
      print('🔄 Step 1: Updating job status to cancelled...');
      await _updateJobStatus(jobId, 'cancelled');

      // 2. Update job request status to cancelled
      print('🔄 Step 2: Updating job request status to cancelled...');
      await _firestore.collection('JobRequests').doc(requestId).update({
        'status': 'cancelled',
        'isActive': false,
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // 3. Update AcceptedJobs collection if exists
      print('🔄 Step 3: Cancelling AcceptedJobs entries...');
      await _cancelAcceptedJobEntry(jobId, skilledWorkerId);

      // 4. Clear active job flags for both users
      print('🔄 Step 4: Clearing active job flags...');
      await _clearActiveJobFlags(jobPosterId, skilledWorkerId);

      // 5. Update user statuses
      print('🔄 Step 5: Updating user statuses to available...');
      await _updateUserStatuses(jobPosterId, skilledWorkerId);

      print(
        '✅ Job cancelled successfully - both users will be redirected to home',
      );
      return true;
    } catch (e) {
      print('❌ Error cancelling job: $e');
      return false;
    }
  }

  /// Update job status in both legacy and new collections
  static Future<void> _updateJobStatus(String jobId, String status) async {
    try {
      // Update legacy Job collection
      await _firestore.collection('Job').doc(jobId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('⚠️ Could not update legacy Job collection: $e');
    }

    try {
      // Update new jobs collection
      await _firestore.collection('jobs').doc(jobId).set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('⚠️ Could not update jobs collection: $e');
    }
  }

  /// Cancel AcceptedJobs entry if it exists
  static Future<void> _cancelAcceptedJobEntry(
    String jobId,
    String skilledWorkerId,
  ) async {
    try {
      final acceptedJobs =
          await _firestore
              .collection('AcceptedJobs')
              .where('jobId', isEqualTo: jobId)
              .where('skilledWorkerId', isEqualTo: skilledWorkerId)
              .where('isActive', isEqualTo: true)
              .get();

      for (final doc in acceptedJobs.docs) {
        await doc.reference.update({
          'status': 'cancelled',
          'isActive': false,
          'cancelledAt': FieldValue.serverTimestamp(),
        });
        print('✅ Cancelled AcceptedJobs entry: ${doc.id}');
      }
    } catch (e) {
      print('⚠️ Could not cancel AcceptedJobs entries: $e');
    }
  }

  /// Clear active job flags for both users
  static Future<void> _clearActiveJobFlags(
    String jobPosterId,
    String skilledWorkerId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear job poster flags
      await prefs.setBool('active_job_$jobPosterId', false);
      await prefs.remove('active_job_${jobPosterId}_jobId');
      await prefs.remove('active_job_${jobPosterId}_requestId');

      // Clear skilled worker flags
      await prefs.setBool('active_job_$skilledWorkerId', false);
      await prefs.remove('active_job_${skilledWorkerId}_jobId');
      await prefs.remove('active_job_${skilledWorkerId}_requestId');

      print('✅ Cleared active job flags for both users');
    } catch (e) {
      print('⚠️ Could not clear SharedPreferences flags: $e');
    }
  }

  /// Update user statuses to available
  static Future<void> _updateUserStatuses(
    String jobPosterId,
    String skilledWorkerId,
  ) async {
    try {
      // Update job poster status
      await _firestore.collection('JobPosters').doc(jobPosterId).set({
        'activeJobId': FieldValue.delete(),
        'status': 'available',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update skilled worker status
      await _firestore.collection('SkilledWorkers').doc(skilledWorkerId).set({
        'activeJobId': FieldValue.delete(),
        'status': 'available',
        'availability': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Updated user statuses to available');
    } catch (e) {
      print('⚠️ Could not update user statuses: $e');
    }
  }

  /// Submit rating for job poster by skilled worker
  static Future<bool> submitJobPosterRating({
    required String jobPosterId,
    required double rating,
    required String feedback,
    String? requestId,
  }) async {
    try {
      print('🔍 Submitting job poster rating:');
      print('  Job Poster ID: $jobPosterId');
      print('  Rating: $rating');
      print('  Feedback: $feedback');
      print('  Request ID: $requestId');

      final ratingData = {
        'jobPosterId': jobPosterId,
        'skilledWorkerId': getCurrentUserId(),
        'rating': rating,
        'feedback': feedback,
        'ratedAt': FieldValue.serverTimestamp(),
        'requestId': requestId,
      };

      // Save rating to JobPosterRatings collection
      await _firestore.collection('JobPosterRatings').add(ratingData);

      // Update job poster's average rating
      await _updateJobPosterAverageRating(jobPosterId);

      print('✅ Job poster rating submitted successfully');
      return true;
    } catch (e) {
      print('❌ Error submitting job poster rating: $e');
      return false;
    }
  }

  /// Update job poster's average rating
  static Future<void> _updateJobPosterAverageRating(String jobPosterId) async {
    try {
      // Get all ratings for this job poster
      final ratingsSnapshot =
          await _firestore
              .collection('JobPosterRatings')
              .where('jobPosterId', isEqualTo: jobPosterId)
              .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      // Calculate average rating
      double totalRating = 0;
      int ratingCount = 0;

      for (final doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final rating = data['rating'] as double?;
        if (rating != null) {
          totalRating += rating;
          ratingCount++;
        }
      }

      if (ratingCount > 0) {
        final averageRating = totalRating / ratingCount;

        // Update job poster's average rating
        await _firestore.collection('JobPosters').doc(jobPosterId).update({
          'averageRating': averageRating,
          'ratingCount': ratingCount,
          'lastRatedAt': FieldValue.serverTimestamp(),
        });

        print(
          '✅ Updated job poster average rating: $averageRating ($ratingCount ratings)',
        );
      }
    } catch (e) {
      print('❌ Error updating job poster average rating: $e');
    }
  }

  /// Submit rating for skilled worker by job poster
  static Future<bool> submitSkilledWorkerRating({
    required String skilledWorkerId,
    required double rating,
    required String feedback,
    String? requestId,
  }) async {
    try {
      print('🔍 Submitting skilled worker rating:');
      print('  Skilled Worker ID: $skilledWorkerId');
      print('  Rating: $rating');
      print('  Feedback: $feedback');
      print('  Request ID: $requestId');

      final ratingData = {
        'skilledWorkerId': skilledWorkerId,
        'jobPosterId': getCurrentUserId(),
        'rating': rating,
        'feedback': feedback,
        'ratedAt': FieldValue.serverTimestamp(),
        'requestId': requestId,
      };

      // Save rating to SkilledWorkerRatings collection
      await _firestore.collection('SkilledWorkerRatings').add(ratingData);

      // Update skilled worker's average rating
      await _updateSkilledWorkerAverageRating(skilledWorkerId);

      print('✅ Skilled worker rating submitted successfully');
      return true;
    } catch (e) {
      print('❌ Error submitting skilled worker rating: $e');
      return false;
    }
  }

  /// Update skilled worker's average rating
  static Future<void> _updateSkilledWorkerAverageRating(
    String skilledWorkerId,
  ) async {
    try {
      // Get all ratings for this skilled worker
      final ratingsSnapshot =
          await _firestore
              .collection('SkilledWorkerRatings')
              .where('skilledWorkerId', isEqualTo: skilledWorkerId)
              .get();

      if (ratingsSnapshot.docs.isEmpty) return;

      double totalRating = 0;
      int ratingCount = 0;

      for (final doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final r = data['rating'];
        if (r is num) {
          totalRating += r.toDouble();
          ratingCount++;
        }
      }

      if (ratingCount > 0) {
        final averageRating = totalRating / ratingCount;

        await _firestore.collection('SkilledWorkers').doc(skilledWorkerId).set({
          'averageRating': averageRating,
          'ratingCount': ratingCount,
          'lastRatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print(
          '✅ Updated skilled worker average rating: $averageRating ($ratingCount ratings)',
        );
      }
    } catch (e) {
      print('❌ Error updating skilled worker average rating: $e');
    }
  }

  /// Test method to create a sample AcceptedJobs entry (for debugging)
  static Future<void> createTestAcceptedJobEntry() async {
    try {
      final testData = {
        'requestId': 'TEST_REQUEST_ID',
        'jobId': 'TEST_JOB_ID',
        'skilledWorkerId': 'TEST_SKILLED_WORKER_ID',
        'jobPosterId': 'TEST_JOB_POSTER_ID',
        'acceptedAt': FieldValue.serverTimestamp(),
        'status': 'accepted',
        'isActive': true,
        'jobDetails': {
          'title': 'Test Job Title',
          'description': 'Test Job Description',
          'location': 'Test Location',
          'budget': '1000',
        },
        'skilledWorkerDetails': {
          'name': 'Test Worker',
          'phoneNumber': '+923115798273',
          'city': 'Test City',
        },
        'jobPosterDetails': {
          'name': 'Test Poster',
          'phoneNumber': '+923115798273',
        },
      };

      final docRef = await _firestore.collection('AcceptedJobs').add(testData);
      print('✅ Test AcceptedJobs entry created with ID: ${docRef.id}');
    } catch (e) {
      print('❌ Error creating test AcceptedJobs entry: $e');
    }
  }
}
