import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';

import '../providers/skilled_worker_provider.dart';
import '../screens/skilled_worker/approval_waiting_screen.dart';

class ApprovalGate extends StatelessWidget {
  final Widget child;

  const ApprovalGate({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<SkilledWorkerProvider>(
      builder: (context, skilledWorkerProvider, _) {
        final userId = skilledWorkerProvider.loggedInUserId;

        if (userId == null || userId.isEmpty) {
          // No user logged in, show child
          return child;
        }

        return FutureBuilder<bool>(
          future: UserDataService.isSkilledWorkerApproved(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error checking approval status',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Retry by rebuilding
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final isApproved = snapshot.data ?? false;

            if (isApproved) {
              // User is approved, show the main content
              return child;
            } else {
              // User is not approved, show approval waiting screen
              return ApprovalWaitingScreen(
                userId: userId,
                phoneNumber: skilledWorkerProvider.loggedInPhoneNumber ?? '',
              );
            }
          },
        );
      },
    );
  }
}
