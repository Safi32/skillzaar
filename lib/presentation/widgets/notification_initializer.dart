import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class NotificationInitializer extends StatefulWidget {
  final Widget child;

  const NotificationInitializer({super.key, required this.child});

  @override
  State<NotificationInitializer> createState() =>
      _NotificationInitializerState();
}

class _NotificationInitializerState extends State<NotificationInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    // Wait a bit for the app to fully load
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      await notificationProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
