import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/screens/splash_screen.dart';
import 'package:skillzaar/presentation/widgets/fee_dialog.dart';

class SplashAndDialogGate extends StatefulWidget {
  const SplashAndDialogGate({super.key});

  @override
  State<SplashAndDialogGate> createState() => _SplashAndDialogGateState();
}

class _SplashAndDialogGateState extends State<SplashAndDialogGate> {
  final bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkActive());
  }

  Future<void> _checkActive() async {    
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || _navigated) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FeeDialogScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

class FeeDialogScreen extends StatefulWidget {
  const FeeDialogScreen({super.key});

  @override
  State<FeeDialogScreen> createState() => _FeeDialogScreenState();
}

class _FeeDialogScreenState extends State<FeeDialogScreen> {
  bool _dialogsShown = false;

  @override
  Widget build(BuildContext context) {
    if (!_dialogsShown) {
      _dialogsShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await showDialog(
          context: context,
          barrierDismissible: true,
          builder:
              (context) =>
                  FeeDialog(onAccept: () => Navigator.of(context).pop()),
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/role-selection');
        }
      });
    }

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: SizedBox.shrink()),
    );
  }
}
