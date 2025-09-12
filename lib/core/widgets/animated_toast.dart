import 'package:flutter/material.dart';

enum ToastType { success, error, warning, info, location, jobRequest }

class AnimatedToast extends StatefulWidget {
  final String title;
  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final bool showCloseButton;

  const AnimatedToast({
    super.key,
    required this.title,
    required this.message,
    this.type = ToastType.info,
    this.duration = const Duration(seconds: 3),
    this.onDismiss,
    this.showIcon = true,
    this.showCloseButton = true,
  });

  @override
  State<AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<AnimatedToast>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _startAnimation();
    _startAutoDismiss();
  }

  void _startAnimation() {
    _slideController.forward();
    _fadeController.forward();
  }

  void _startAutoDismiss() {
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _fadeController.reverse().then((_) {
      _slideController.reverse().then((_) {
        if (mounted) {
          widget.onDismiss?.call();
        }
      });
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.showIcon) ...[
                    _buildIcon(),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showCloseButton) ...[
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;

    switch (widget.type) {
      case ToastType.success:
        iconData = Icons.check_circle;
        break;
      case ToastType.error:
        iconData = Icons.error;
        break;
      case ToastType.warning:
        iconData = Icons.warning;
        break;
      case ToastType.info:
        iconData = Icons.info;
        break;
      case ToastType.location:
        iconData = Icons.location_on;
        break;
      case ToastType.jobRequest:
        iconData = Icons.work;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: Colors.white, size: 24),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
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
}

class ToastOverlay {
  static final ToastOverlay _instance = ToastOverlay._internal();
  factory ToastOverlay() => _instance;
  ToastOverlay._internal();

  static ToastOverlay get instance => _instance;

  OverlayEntry? _currentToast;

  void showToast({
    required BuildContext context,
    required String title,
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    bool showIcon = true,
    bool showCloseButton = true,
  }) {
    _hideCurrentToast();

    _currentToast = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: AnimatedToast(
              title: title,
              message: message,
              type: type,
              duration: duration,
              showIcon: showIcon,
              showCloseButton: showCloseButton,
              onDismiss: () {
                _hideCurrentToast();
              },
            ),
          ),
    );

    Overlay.of(context).insert(_currentToast!);
  }

  void _hideCurrentToast() {
    _currentToast?.remove();
    _currentToast = null;
  }

  void hideToast() {
    _hideCurrentToast();
  }

  // Convenience methods
  void showSuccess(BuildContext context, String title, String message) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.success,
    );
  }

  void showError(BuildContext context, String title, String message) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.error,
    );
  }

  void showLocationToast(BuildContext context, String message) {
    showToast(
      context: context,
      title: 'Location',
      message: message,
      type: ToastType.location,
    );
  }

  void showJobRequestToast(BuildContext context, String message) {
    showToast(
      context: context,
      title: 'Job Request',
      message: message,
      type: ToastType.jobRequest,
    );
  }

  void showWarning(BuildContext context, String title, String message) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.warning,
    );
  }

  void showInfo(BuildContext context, String title, String message) {
    showToast(
      context: context,
      title: title,
      message: message,
      type: ToastType.info,
    );
  }
}
