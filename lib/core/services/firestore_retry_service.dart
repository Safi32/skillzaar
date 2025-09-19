import 'package:cloud_firestore/cloud_firestore.dart';

/// A service class for handling Firestore operations with automatic retry logic
///
/// This service implements exponential backoff retry for Firestore operations
/// to handle transient errors like 'unavailable' or 'deadline-exceeded'.
class FirestoreRetryService {
  static const int _maxRetries = 5;
  static const Duration _baseDelay = Duration(seconds: 1);

  /// Retry Firestore operations with exponential backoff
  ///
  /// This method implements exponential backoff retry logic for Firestore operations.
  /// It retries up to 5 times with delays of 1s, 2s, 4s, 8s, 16s.
  ///
  /// Parameters:
  /// - [operation]: The Firestore operation to retry
  /// - [operationName]: Human-readable name for logging
  ///
  /// Returns: The result of the operation if successful
  ///
  /// Throws: The last exception if all retries fail
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    required String operationName,
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        print(
          '🔄 Attempting Firestore operation: $operationName (attempt ${attempt + 1}/$_maxRetries)',
        );
        return await operation();
      } on FirebaseException catch (e) {
        lastException = e;

        // Check if this is a retryable error
        if (_isRetryableError(e.code)) {
          if (attempt < _maxRetries - 1) {
            final delay = _calculateExponentialDelay(attempt);
            print('⚠️ Firestore error (${e.code}): ${e.message}');
            print(
              '🔄 Retrying in ${delay.inSeconds}s... (attempt ${attempt + 1}/$_maxRetries)',
            );
            await Future.delayed(delay);
            continue;
          }
        }

        // Non-retryable error or max retries reached
        print('❌ Firestore operation failed: ${e.code} - ${e.message}');
        rethrow;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempt < _maxRetries - 1) {
          final delay = _calculateExponentialDelay(attempt);
          print('⚠️ General error: $e');
          print(
            '🔄 Retrying in ${delay.inSeconds}s... (attempt ${attempt + 1}/$_maxRetries)',
          );
          await Future.delayed(delay);
          continue;
        }

        print('❌ Firestore operation failed after $_maxRetries attempts: $e');
        rethrow;
      }
    }

    // This should never be reached, but just in case
    throw lastException ?? Exception('Max retries exceeded for $operationName');
  }

  /// Check if a Firebase error code is retryable
  static bool _isRetryableError(String errorCode) {
    const retryableErrors = {
      'unavailable',
      'deadline-exceeded',
      'internal',
      'resource-exhausted',
      'aborted',
    };
    return retryableErrors.contains(errorCode);
  }

  /// Calculate exponential backoff delay
  ///
  /// Returns delays of: 1s, 2s, 4s, 8s, 16s
  static Duration _calculateExponentialDelay(int attempt) {
    final delayMs = _baseDelay.inMilliseconds * (1 << attempt); // 2^attempt
    return Duration(milliseconds: delayMs);
  }

  /// Get a user-friendly error message for Firestore exceptions
  static String getUserFriendlyErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please check your internet connection and try again.';
      case 'permission-denied':
        return 'Permission denied. Please contact support.';
      case 'not-found':
        return 'Service not found. Please contact support.';
      case 'resource-exhausted':
        return 'Service is busy. Please try again in a few moments.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'internal':
        return 'Internal server error. Please try again later.';
      default:
        return 'Database error: ${e.message ?? e.code}';
    }
  }

  /// Get a user-friendly error message for general exceptions
  static String getUserFriendlyErrorMessageForException(Exception e) {
    if (e is FirebaseException) {
      return getUserFriendlyErrorMessage(e);
    }
    return 'An unexpected error occurred. Please try again later.';
  }
}
