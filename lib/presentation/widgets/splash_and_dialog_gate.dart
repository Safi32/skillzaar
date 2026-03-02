import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/screens/splash_screen.dart';
import 'package:skillzaar/presentation/widgets/active_work_gate.dart';
import 'package:skillzaar/presentation/screens/role_selection_screen.dart';

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
        MaterialPageRoute(
          builder: (_) => const ActiveWorkGate(child: RoleSelectionScreen()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
