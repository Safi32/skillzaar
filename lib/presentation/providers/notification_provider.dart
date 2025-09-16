import 'package:flutter/material.dart';
import '../../core/services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  NotificationService get notificationService => _notificationService;

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _fcmToken;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get fcmToken => _fcmToken;
  String? get error => _error;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    _clearError();

    try {
      await _notificationService.initialize();
      _fcmToken = _notificationService.fcmToken;
      _isInitialized = true;
      print('✅ Notification provider initialized');
    } catch (e) {
      _setError('Failed to initialize notifications: $e');
      print('❌ Notification provider initialization failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send job notification to all skilled workers
  Future<void> sendJobNotification({
    required String jobTitle,
    required String jobDescription,
    required String jobId,
    required String location,
    required double budget,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.sendJobNotificationToAllWorkers(
        jobTitle: jobTitle,
        jobDescription: jobDescription,
        jobId: jobId,
        location: location,
        budget: budget,
      );
      print('✅ Job notification sent successfully');
    } catch (e) {
      _setError('Failed to send job notification: $e');
      print('❌ Failed to send job notification: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh FCM token
  Future<void> refreshToken() async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.refreshToken();
      _fcmToken = _notificationService.fcmToken;
      print('✅ FCM token refreshed');
    } catch (e) {
      _setError('Failed to refresh token: $e');
      print('❌ Failed to refresh FCM token: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Unsubscribe from job notifications
  Future<void> unsubscribeFromJobNotifications() async {
    _setLoading(true);
    _clearError();

    try {
      await _notificationService.unsubscribeFromJobNotifications();
      print('✅ Unsubscribed from job notifications');
    } catch (e) {
      _setError('Failed to unsubscribe: $e');
      print('❌ Failed to unsubscribe from job notifications: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all state
  void clear() {
    _isInitialized = false;
    _isLoading = false;
    _fcmToken = null;
    _error = null;
    notifyListeners();
  }
}
