import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_retry_service.dart';

/// Service for managing user data in Firestore
class UserDataService {
  static const String _jobPostersCollection = 'JobPosters';
  static const String _skilledWorkersCollection = 'SkilledWorkers';

  /// Create a job poster user document
  static Future<void> createJobPoster({
    required String userId,
    required String phoneNumber,
    String? displayName,
    String? email,
  }) async {
    await FirestoreRetryService.retryOperation(() async {
      final docRef = FirebaseFirestore.instance
          .collection(_jobPostersCollection)
          .doc(userId);

      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'userId': userId,
          'phoneNumber': phoneNumber,
          'displayName': displayName ?? 'Job Poster',
          'email': email ?? '',
          'isActive': true,
          'isVerified': true,
          'userType': 'job_poster',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'profileCompleted': false,
          'settings': {
            'notifications': true,
            'emailNotifications': false,
            'smsNotifications': true,
          },
          'stats': {'jobsPosted': 0, 'jobsCompleted': 0, 'totalSpent': 0.0},
        });
        print('✅ Job poster document created successfully');
      } else {
        // Update last login time
        await docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('📝 Job poster document already exists, updated login time');
      }
    }, operationName: 'createJobPoster');
  }

  /// Create a skilled worker user document
  static Future<void> createSkilledWorker({
    required String userId,
    required String phoneNumber,
    String? displayName,
    String? email,
  }) async {
    await FirestoreRetryService.retryOperation(() async {
      final docRef = FirebaseFirestore.instance
          .collection(_skilledWorkersCollection)
          .doc(userId);

      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set({
          'userId': userId,
          'phoneNumber': phoneNumber,
          'displayName': displayName ?? 'Skilled Worker',
          'email': email ?? '',
          'isActive': true,
          'isVerified': true,
          'userType': 'skilled_worker',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'profileCompleted': false,
          'settings': {
            'notifications': true,
            'emailNotifications': false,
            'smsNotifications': true,
          },
          'stats': {
            'jobsApplied': 0,
            'jobsCompleted': 0,
            'totalEarned': 0.0,
            'rating': 0.0,
          },
          'skills': [],
          'experience': [],
          'portfolio': [],
        });
        print('✅ Skilled worker document created successfully');
      } else {
        // Update last login time
        await docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('📝 Skilled worker document already exists, updated login time');
      }
    }, operationName: 'createSkilledWorker');
  }

  /// Get user data by ID and type
  static Future<DocumentSnapshot?> getUserData({
    required String userId,
    required String userType,
  }) async {
    try {
      final collection =
          userType == 'job_poster'
              ? _jobPostersCollection
              : _skilledWorkersCollection;

      return await FirestoreRetryService.retryOperation(() async {
        return await FirebaseFirestore.instance
            .collection(collection)
            .doc(userId)
            .get();
      }, operationName: 'getUserData');
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  /// Update user data
  static Future<void> updateUserData({
    required String userId,
    required String userType,
    required Map<String, dynamic> data,
  }) async {
    await FirestoreRetryService.retryOperation(() async {
      final collection =
          userType == 'job_poster'
              ? _jobPostersCollection
              : _skilledWorkersCollection;

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
      print('✅ User data updated successfully');
    }, operationName: 'updateUserData');
  }

  /// Check if user exists
  static Future<bool> userExists({
    required String userId,
    required String userType,
  }) async {
    try {
      final doc = await getUserData(userId: userId, userType: userType);
      return doc?.exists ?? false;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  /// Get all job posters
  static Future<QuerySnapshot> getAllJobPosters() async {
    return await FirestoreRetryService.retryOperation(() async {
      return await FirebaseFirestore.instance
          .collection(_jobPostersCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
    }, operationName: 'getAllJobPosters');
  }

  /// Get all skilled workers
  static Future<QuerySnapshot> getAllSkilledWorkers() async {
    return await FirestoreRetryService.retryOperation(() async {
      return await FirebaseFirestore.instance
          .collection(_skilledWorkersCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
    }, operationName: 'getAllSkilledWorkers');
  }

  /// Delete user data
  static Future<void> deleteUserData({
    required String userId,
    required String userType,
  }) async {
    await FirestoreRetryService.retryOperation(() async {
      final collection =
          userType == 'job_poster'
              ? _jobPostersCollection
              : _skilledWorkersCollection;

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .delete();
      print('✅ User data deleted successfully');
    }, operationName: 'deleteUserData');
  }

  /// Test Firestore connection
  static Future<bool> testConnection() async {
    try {
      await FirestoreRetryService.retryOperation(() async {
        await FirebaseFirestore.instance
            .collection('_test')
            .doc('connection_test')
            .get()
            .timeout(const Duration(seconds: 10));
      }, operationName: 'testConnection');
      return true;
    } catch (e) {
      print('❌ Firestore connection test failed: $e');
      return false;
    }
  }
}
