import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/core/examples/services/toast_service.dart';
import '../../presentation/providers/ui_state_provider.dart';

import '../widgets/animated_toast.dart';

class ToastUsageExamples extends StatelessWidget {
  const ToastUsageExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Toast Examples'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Toast Notification Examples',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Regular Toast Service Examples
            const Text(
              'Regular Toast Service:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _showRegularSuccessToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Success Toast'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _showRegularErrorToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Error Toast'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _showRegularLocationToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Location Toast'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _showRegularJobRequestToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Job Request Toast'),
            ),

            const SizedBox(height: 20),

            // Animated Toast Examples
            const Text(
              'Animated Toast (GetX-like):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _showAnimatedSuccessToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Animated Success Toast'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _showAnimatedErrorToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Animated Error Toast'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _showAnimatedLocationToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Animated Location Toast'),
            ),
            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () => _showAnimatedJobRequestToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Animated Job Request Toast'),
            ),

            const SizedBox(height: 20),

            // Direct ToastOverlay Examples
            const Text(
              'Direct ToastOverlay:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _showDirectToast(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Show Direct Toast'),
            ),
          ],
        ),
      ),
    );
  }

  // Regular Toast Service Methods
  void _showRegularSuccessToast(BuildContext context) {
    ToastService.instance.showSuccess(
      context: context,
      title: 'Success!',
      message: 'Operation completed successfully.',
    );
  }

  void _showRegularErrorToast(BuildContext context) {
    ToastService.instance.showError(
      context: context,
      title: 'Error!',
      message: 'Something went wrong. Please try again.',
    );
  }

  void _showRegularLocationToast(BuildContext context) {
    ToastService.instance.showLocationToast(
      context: context,
      message: 'Location services are now enabled.',
    );
  }

  void _showRegularJobRequestToast(BuildContext context) {
    ToastService.instance.showJobRequestToast(
      context: context,
      message: 'Your job request has been accepted! You can now navigate.',
    );
  }

  // Animated Toast Methods (via Provider)
  void _showAnimatedSuccessToast(BuildContext context) {
    context.read<UIStateProvider>().showAnimatedSuccessToast(
      context,
      'Success!',
      'Operation completed with beautiful animation!',
    );
  }

  void _showAnimatedErrorToast(BuildContext context) {
    context.read<UIStateProvider>().showAnimatedErrorToast(
      context,
      'Error!',
      'Something went wrong with animation!',
    );
  }

  void _showAnimatedLocationToast(BuildContext context) {
    context.read<UIStateProvider>().showAnimatedLocationToast(
      context,
      'Location services are now enabled with smooth animation!',
    );
  }

  void _showAnimatedJobRequestToast(BuildContext context) {
    context.read<UIStateProvider>().showAnimatedJobRequestToast(
      context,
      'Job request accepted! You can now navigate with style!',
    );
  }

  // Direct ToastOverlay Method
  void _showDirectToast(BuildContext context) {
    ToastOverlay.instance.showToast(
      context: context,
      title: 'Custom Toast',
      message: 'This is a custom toast with your own settings!',
      type: ToastType.warning,
      duration: const Duration(seconds: 5),
      showIcon: true,
      showCloseButton: true,
    );
  }
}
