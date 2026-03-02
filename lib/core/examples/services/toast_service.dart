import 'package:flutter/material.dart';
import 'package:skillzaar/core/widgets/animated_toast.dart';


class ToastService {
  static final ToastService _instance = ToastService._internal();
  factory ToastService() => _instance;
  ToastService._internal();

  static ToastService get instance => _instance;

  void showToast({
    required BuildContext context,
    required String title,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    bool isDismissible = true,
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: _buildToastContent(title, message, type),
      backgroundColor: _getBackgroundColor(type),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      dismissDirection: isDismissible ? DismissDirection.horizontal : null,
      action: action,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildToastContent(String title, String message, ToastType type) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _buildIcon(type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(ToastType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case ToastType.success:
        iconData = Icons.check_circle;
        iconColor = Colors.white;
        break;
      case ToastType.error:
        iconData = Icons.error;
        iconColor = Colors.white;
        break;
      case ToastType.warning:
        iconData = Icons.warning;
        iconColor = Colors.white;
        break;
      case ToastType.info:
        iconData = Icons.info;
        iconColor = Colors.white;
        break;
      case ToastType.location:
        iconData = Icons.location_on;
        iconColor = Colors.white;
        break;
      case ToastType.jobRequest:
        iconData = Icons.work;
        iconColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Color _getBackgroundColor(ToastType type) {
    switch (type) {
      case ToastType.success:
        return const Color(0xFF4CAF50);
      case ToastType.error:
        return const Color(0xFFF44336);
      case ToastType.warning:
        return const Color(0xFFFF9800);
      case ToastType.info:
        return const Color(0xFF2196F3);
      case ToastType.location:
        return const Color(0xFF9C27B0);
      case ToastType.jobRequest:
        return const Color(0xFF607D8B);
    }
  }

  // Convenience methods for specific toast types
  void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.success,
      duration: duration,
    );
  }

  void showError({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.error,
      duration: duration,
    );
  }

  void showLocationToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(
      context: context,
      title: 'Location',
      message: message,
      type: ToastType.location,
      duration: duration,
    );
  }

  void showJobRequestToast({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showToast(
      context: context,
      title: 'Job Request',
      message: message,
      type: ToastType.jobRequest,
      duration: duration,
    );
  }

  void showWarning({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.warning,
      duration: duration,
    );
  }

  void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.info,
      duration: duration,
    );
  }
}
