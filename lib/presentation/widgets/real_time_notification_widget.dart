import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RealTimeNotificationWidget extends StatefulWidget {
  final String userId;
  final String userType; // 'skilled_worker' or 'job_poster'

  const RealTimeNotificationWidget({
    super.key,
    required this.userId,
    required this.userType,
  });

  @override
  State<RealTimeNotificationWidget> createState() =>
      _RealTimeNotificationWidgetState();
}

class _RealTimeNotificationWidgetState extends State<RealTimeNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _listenToNotifications();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _listenToNotifications() {
    // Listen to AssignedJobs collection for real-time updates
    FirebaseFirestore.instance
        .collection('AssignedJobs')
        .where(
          widget.userType == 'skilled_worker' ? 'workerId' : 'jobPosterId',
          isEqualTo: widget.userId,
        )
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            final newNotifications =
                snapshot.docs
                    .map(
                      (doc) => {
                        'id': doc.id,
                        'title': doc.data()['jobTitle'] ?? 'Unknown Job',
                        'body':
                            widget.userType == 'skilled_worker'
                                ? 'You have been assigned a new job!'
                                : 'A worker has been assigned to your job!',
                        'status': doc.data()['assignmentStatus'] ?? 'unknown',
                        'assignedAt': doc.data()['assignedAt'],
                        'timestamp': DateTime.now(),
                        'isRead': false,
                      },
                    )
                    .toList();

            // Check if there are new notifications
            if (newNotifications.isNotEmpty && _notifications.isNotEmpty) {
              final latestNotification = newNotifications.first;
              final previousLatest = _notifications.first;

              // If this is a new notification (different ID or newer timestamp)
              if (latestNotification['id'] != previousLatest['id'] ||
                  latestNotification['assignedAt'] !=
                      previousLatest['assignedAt']) {
                _showNotification(latestNotification);
              }
            }

            setState(() {
              _notifications = newNotifications;
              _unreadCount = newNotifications.where((n) => !n['isRead']).length;
            });
          }
        });
  }

  void _showNotification(Map<String, dynamic> notification) {
    setState(() {
      _isVisible = true;
    });

    _slideController.forward();

    // Auto-hide after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _slideController.reverse().then((_) {
          setState(() {
            _isVisible = false;
          });
        });
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Slide-in Notification (only show when there's a new notification)
        if (_isVisible)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.work, color: Colors.white, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '🎉 New Job Assignment!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _notifications.isNotEmpty
                                ? _notifications.first['title']
                                : 'You have a new job!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _slideController.reverse().then((_) {
                          setState(() {
                            _isVisible = false;
                          });
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
