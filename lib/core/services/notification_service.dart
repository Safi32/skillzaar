import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize notification service
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      await _getFCMToken();

      // Configure message handlers
      _configureMessageHandlers();

      // Subscribe to job notifications topic
      await _subscribeToJobNotifications();

      print('✅ Notification service initialized successfully');
    } catch (e) {
      print('❌ Notification service initialization failed: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission for notifications');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('⚠️ User granted provisional permission for notifications');
    } else {
      print('❌ User declined or has not accepted permission for notifications');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }
  }

  /// Create notification channel for Android
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'job_notifications',
      'Job Notifications',
      description: 'Notifications for new job postings',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Save token to Firestore for the current user
      await _saveTokenToFirestore();
    } catch (e) {
      print('❌ Failed to get FCM token: $e');
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _fcmToken != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': _fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token saved to Firestore');
      } catch (e) {
        print('❌ Failed to save FCM token to Firestore: $e');
      }
    }
  }

  /// Configure message handlers
  void _configureMessageHandlers() {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Subscribe to job notifications topic
  Future<void> _subscribeToJobNotifications() async {
    try {
      await _firebaseMessaging.subscribeToTopic('job_notifications');
      print('✅ Subscribed to job notifications topic');
    } catch (e) {
      print('❌ Failed to subscribe to job notifications: $e');
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📨 Received foreground message: ${message.messageId}');

    // Show local notification
    await _showLocalNotification(message);
  }

  /// Handle notification tap
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('👆 Notification tapped: ${message.messageId}');
    // Navigate to relevant screen based on notification data
    _navigateToJobDetails(message.data);
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'job_notifications',
          'Job Notifications',
          channelDescription: 'Notifications for new job postings',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Job Posted',
      message.notification?.body ?? 'A new job has been posted in your area',
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap from local notifications
  void _onNotificationTapped(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Navigate to job details
  void _navigateToJobDetails(Map<String, dynamic> data) {
    // This will be implemented in the UI layer
    print('🧭 Navigate to job details: $data');
  }

  /// Send notification to all skilled workers
  Future<void> sendJobNotificationToAllWorkers({
    required String jobTitle,
    required String jobDescription,
    required String jobId,
    required String location,
    required double budget,
  }) async {
    try {
      // Get all skilled workers' FCM tokens
      final workersSnapshot =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'skilled_worker')
              .where('fcmToken', isNull: false)
              .get();

      if (workersSnapshot.docs.isEmpty) {
        print('⚠️ No skilled workers found with FCM tokens');
        return;
      }

      // Send notification to each worker
      for (final doc in workersSnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'] as String?;
        if (fcmToken != null) {
          await sendNotificationToToken(
            fcmToken: fcmToken,
            title: 'New Job Posted: $jobTitle',
            body:
                '$jobDescription\nLocation: $location\nBudget: \$${budget.toStringAsFixed(0)}',
            data: {
              'jobId': jobId,
              'type': 'job_posting',
              'title': jobTitle,
              'location': location,
              'budget': budget.toString(),
            },
          );
        }
      }

      print(
        '✅ Job notification sent to ${workersSnapshot.docs.length} skilled workers',
      );
    } catch (e) {
      print('❌ Failed to send job notification: $e');
    }
  }

  /// Send notification to specific FCM token
  Future<void> sendNotificationToToken({
    required String fcmToken,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // This would typically be done from your backend server
    // For now, we'll just log the notification details
  print('📤 Would send notification to token: $fcmToken');
  print('   Title: $title');
  print('   Body: $body');
  print('   Data: $data');
  }

  /// Refresh FCM token
  Future<void> refreshToken() async {
    await _getFCMToken();
  }

  /// Unsubscribe from job notifications
  Future<void> unsubscribeFromJobNotifications() async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic('job_notifications');
      print('✅ Unsubscribed from job notifications');
    } catch (e) {
      print('❌ Failed to unsubscribe from job notifications: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Handling background message: ${message.messageId}');
  // Handle background message here
}
