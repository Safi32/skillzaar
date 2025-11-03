import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHandlerService {
  static final NotificationHandlerService _instance =
      NotificationHandlerService._internal();
  factory NotificationHandlerService() => _instance;
  NotificationHandlerService._internal();

  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the notification handler with navigator key
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Handle notification tap and navigate to appropriate screen
  static void handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    final assignedJobId = data['assignedJobId'] as String?;
    final userType = data['userType'] as String?;
    final action = data['action'] as String?;

    print('🔔 Handling notification tap: $type');

    if (_navigatorKey?.currentState == null) {
      print('❌ Navigator not available');
      return;
    }

    final context = _navigatorKey!.currentState!.context;

    switch (type) {
      case 'job_assigned':
        if (assignedJobId != null && userType != null) {
          _navigateToAssignedJobDetail(context, assignedJobId, userType);
        }
        break;
      case 'job_completed':
        if (assignedJobId != null && action == 'rate_client') {
          _navigateToRateJobPoster(context, assignedJobId);
        }
        break;
      case 'worker_rating_completed':
        _navigateToHome(context);
        break;
      case 'job_cancelled':
        _navigateToHome(context);
        break;
      case 'job_posting':
        _navigateToJobsScreen(context);
        break;
      default:
        print('⚠️ Unknown notification type: $type');
    }
  }

  /// Navigate to assigned job detail screen
  static void _navigateToAssignedJobDetail(
    BuildContext context,
    String assignedJobId,
    String userType,
  ) {
    print(
      '🧭 Navigating to assigned job detail: $assignedJobId, userType: $userType',
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/assigned-job-detail',
      (route) => false,
      arguments: {'assignedJobId': assignedJobId, 'userType': userType},
    );
  }

  /// Navigate to rate job poster screen
  static void _navigateToRateJobPoster(
    BuildContext context,
    String assignedJobId,
  ) {
    print('🧭 Navigating to rate job poster: $assignedJobId');

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/rate-job-poster',
      (route) => false,
      arguments: {'assignedJobId': assignedJobId, 'isJobCompletion': true},
    );
  }

  /// Navigate to home screen
  static void _navigateToHome(BuildContext context) {
    print('🧭 Navigating to home screen');

    // Determine which home screen based on user type
    // This is a simplified approach - you might want to check user type from provider
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/skilled-worker-home', // Default to skilled worker home
      (route) => false,
    );
  }

  /// Navigate to jobs screen
  static void _navigateToJobsScreen(BuildContext context) {
    print('🧭 Navigating to jobs screen');

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/skilled-worker-jobs',
      (route) => false,
    );
  }
}
