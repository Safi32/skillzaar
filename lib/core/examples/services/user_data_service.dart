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
    try {
      print('📝 Creating job poster in Firestore: $phoneNumber');

      // Create document in Firestore only (no Firebase Auth)
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
    } catch (e) {
      print('❌ Error creating job poster: $e');
      rethrow;
    }
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
          'isVerified': false, // Changed to false - requires admin approval
          'isApproved': false, // New field for admin approval
          'approvalStatus': 'pending', // New field: pending, approved, rejected
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

  /// Check if user exists by phone number
  static Future<bool> userExistsByPhone({
    required String phoneNumber,
    required String userType,
  }) async {
    try {
      print('🔍 UserDataService.userExistsByPhone:');
      print('📱 Phone: $phoneNumber');
      print('👤 Type: $userType');

      // Check Firestore for actual user existence
      final collection =
          userType == 'job_poster'
              ? _jobPostersCollection
              : _skilledWorkersCollection;

      print('📂 Checking Firestore collection: $collection');

      final querySnapshot = await FirestoreRetryService.retryOperation(
        () async {
          return await FirebaseFirestore.instance
              .collection(collection)
              .where('phoneNumber', isEqualTo: phoneNumber)
              .limit(1)
              .get()
              .timeout(const Duration(seconds: 10));
        },
        operationName: 'userExistsByPhone',
      );

      print('📊 Query result: ${querySnapshot.docs.length} documents found');
      for (var doc in querySnapshot.docs) {
        print('📄 Document ID: ${doc.id}');
        print('📄 Data: ${doc.data()}');
        print('📄 Phone in doc: ${doc.data()['phoneNumber']}');
        print('📄 Searching for: $phoneNumber');
        print('📄 Phone match: ${doc.data()['phoneNumber'] == phoneNumber}');
      }

      final exists = querySnapshot.docs.isNotEmpty;
      print('✅ User exists: $exists');
      return exists;
    } catch (e) {
      print('❌ Error checking user existence by phone: $e');
      return false;
    }
  }

  /// Get user data by phone number
  static Future<DocumentSnapshot?> getUserDataByPhone({
    required String phoneNumber,
    required String userType,
  }) async {
    try {
      final collection =
          userType == 'job_poster'
              ? _jobPostersCollection
              : _skilledWorkersCollection;

      final querySnapshot = await FirestoreRetryService.retryOperation(
        () async {
          return await FirebaseFirestore.instance
              .collection(collection)
              .where('phoneNumber', isEqualTo: phoneNumber)
              .limit(1)
              .get();
        },
        operationName: 'getUserDataByPhone',
      );

      return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first : null;
    } catch (e) {
      print('❌ Error getting user data by phone: $e');
      return null;
    }
  }

  /// Get all job posters
  static Future<QuerySnapshot> getAllJobPosters() async {
    return await FirestoreRetryService.retryOperation(() async {
      final snap =
          await FirebaseFirestore.instance
              .collection(_jobPostersCollection)
              .where('isActive', isEqualTo: true)
              .get();
      return snap;
    }, operationName: 'getAllJobPosters');
  }

  /// Get all skilled workers
  static Future<QuerySnapshot> getAllSkilledWorkers() async {
    return await FirestoreRetryService.retryOperation(() async {
      final snap =
          await FirebaseFirestore.instance
              .collection(_skilledWorkersCollection)
              .where('isActive', isEqualTo: true)
              .get();
      return snap;
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

  /// Update skilled worker approval status
  static Future<void> updateSkilledWorkerApprovalStatus({
    required String userId,
    required String status, // 'pending', 'approved', 'rejected'
    String? adminNotes,
  }) async {
    await FirestoreRetryService.retryOperation(() async {
      await FirebaseFirestore.instance
          .collection(_skilledWorkersCollection)
          .doc(userId)
          .update({
            'approvalStatus': status,
            'isApproved': status == 'approved',
            'isVerified': status == 'approved',
            'adminNotes': adminNotes ?? '',
            'approvedAt':
                status == 'approved' ? FieldValue.serverTimestamp() : null,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      print('✅ Skilled worker approval status updated to: $status');
    }, operationName: 'updateSkilledWorkerApprovalStatus');
  }

  /// Get skilled workers by approval status
  static Future<QuerySnapshot> getSkilledWorkersByApprovalStatus({
    required String status, // 'pending', 'approved', 'rejected'
  }) async {
    return await FirestoreRetryService.retryOperation(() async {
      final snap =
          await FirebaseFirestore.instance
              .collection(_skilledWorkersCollection)
              .where('approvalStatus', isEqualTo: status)
              .get();
      return snap;
    }, operationName: 'getSkilledWorkersByApprovalStatus');
  }

  /// Get only approved skilled workers (for job poster display)
  static Future<QuerySnapshot> getApprovedSkilledWorkers() async {
    return await FirestoreRetryService.retryOperation(() async {
      return await FirebaseFirestore.instance
          .collection(_skilledWorkersCollection)
          .where('isActive', isEqualTo: true)
          .where('isApproved', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
    }, operationName: 'getApprovedSkilledWorkers');
  }

  /// Get approved skilled workers by service type
  static Future<QuerySnapshot> getApprovedSkilledWorkersByService(
    String serviceType,
  ) async {
    print('🔍 Getting skilled workers for service: $serviceType');

    // Always return all approved workers for "All" category
    if (serviceType == 'All' || serviceType.isEmpty) {
      print('📋 Fetching ALL approved skilled workers');
      return await FirestoreRetryService.retryOperation(() async {
        final result =
            await FirebaseFirestore.instance
                .collection(_skilledWorkersCollection)
                .where('isActive', isEqualTo: true)
                .where('isApproved', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .get();
        print('✅ Found ${result.docs.length} approved skilled workers');
        return result;
      }, operationName: 'getApprovedSkilledWorkersByService');
    }

    // For specific service types, filter by categories array
    print('🔍 Fetching skilled workers for specific service: $serviceType');
    return await FirestoreRetryService.retryOperation(() async {
      final result =
          await FirebaseFirestore.instance
              .collection(_skilledWorkersCollection)
              .where('isActive', isEqualTo: true)
              .where('isApproved', isEqualTo: true)
              .where('categories', arrayContains: serviceType)
              .orderBy('createdAt', descending: true)
              .get();
      print('✅ Found ${result.docs.length} skilled workers for $serviceType');
      return result;
    }, operationName: 'getApprovedSkilledWorkersByService');
  }

  /// Check if a skilled worker is approved
  static Future<bool> isSkilledWorkerApproved(String userId) async {
    try {
      final doc = await getUserData(userId: userId, userType: 'skilled_worker');
      if (doc?.exists == true) {
        final data = doc!.data() as Map<String, dynamic>;
        return data['approvalStatus'] == 'approved';
      }
      return false;
    } catch (e) {
      print('❌ Error checking approval status: $e');
      return false;
    }
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
