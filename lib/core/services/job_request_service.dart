import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

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

      await _firestore.collection('JobRequests').add(requestData);
      return true;
    } catch (e) {
      print('Error creating job request: $e');
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
      final jobDoc = await _firestore.collection('Job').doc(jobId).get();
      if (jobDoc.exists) {
        return jobDoc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting job details: $e');
      return null;
    }
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
      await _firestore.collection('JobRequests').doc(requestId).update({
        'status': 'in_progress',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error marking request in progress: $e');
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

  /// Mark a job request as completed (poster action)
  static Future<bool> markRequestCompleted(String requestId) async {
    try {
      await _firestore.collection('JobRequests').doc(requestId).update({
        'status': 'completed',
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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
