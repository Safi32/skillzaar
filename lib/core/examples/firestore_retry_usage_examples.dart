import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_retry_service.dart';

/// Examples of how to use the FirestoreRetryService for various operations
class FirestoreRetryUsageExamples {
  
  /// Example 1: Simple document read with retry
  static Future<DocumentSnapshot> getUserDocument(String userId) async {
    return await FirestoreRetryService.retryOperation(
      () async {
        return await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
      },
      operationName: 'getUserDocument',
    );
  }

  /// Example 2: Document write with retry
  static Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    await FirestoreRetryService.retryOperation(
      () async {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      },
      operationName: 'createUserProfile',
    );
  }

  /// Example 3: Query with retry
  static Future<QuerySnapshot> getActiveJobs() async {
    return await FirestoreRetryService.retryOperation(
      () async {
        return await FirebaseFirestore.instance
            .collection('jobs')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
      },
      operationName: 'getActiveJobs',
    );
  }

  /// Example 4: Batch operation with retry
  static Future<void> updateMultipleDocuments({
    required List<String> documentIds,
    required Map<String, dynamic> updateData,
  }) async {
    await FirestoreRetryService.retryOperation(
      () async {
        final batch = FirebaseFirestore.instance.batch();
        
        for (final docId in documentIds) {
          final docRef = FirebaseFirestore.instance
              .collection('documents')
              .doc(docId);
          batch.update(docRef, updateData);
        }
        
        await batch.commit();
      },
      operationName: 'updateMultipleDocuments',
    );
  }

  /// Example 5: Error handling with user-friendly messages
  static Future<void> handleFirestoreOperation() async {
    try {
      await FirestoreRetryService.retryOperation(
        () async {
          // Your Firestore operation here
          await FirebaseFirestore.instance
              .collection('test')
              .doc('test')
              .get();
        },
        operationName: 'handleFirestoreOperation',
      );
    } on FirebaseException catch (e) {
      // Get user-friendly error message
      final userMessage = FirestoreRetryService.getUserFriendlyErrorMessage(e);
      print('User-friendly error: $userMessage');
      
      // Handle the error appropriately
      throw Exception(userMessage);
    } catch (e) {
      // Handle other exceptions
      final userMessage = FirestoreRetryService.getUserFriendlyErrorMessageForException(
        e is Exception ? e : Exception(e.toString()),
      );
      print('General error: $userMessage');
      throw Exception(userMessage);
    }
  }
}
