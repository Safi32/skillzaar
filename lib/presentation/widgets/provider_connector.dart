import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/notification_provider.dart';

class ProviderConnector extends StatefulWidget {
  final Widget child;

  const ProviderConnector({super.key, required this.child});

  @override
  State<ProviderConnector> createState() => _ProviderConnectorState();
}

class _ProviderConnectorState extends State<ProviderConnector> {
  @override
  void initState() {
    super.initState();
    _connectProviders();
  }

  void _connectProviders() {
    // Connect JobProvider with NotificationProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobProvider = Provider.of<JobProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      jobProvider.setNotificationProvider(notificationProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
