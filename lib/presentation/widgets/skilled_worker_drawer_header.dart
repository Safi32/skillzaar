import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/providers/auth_state_provider.dart';
class SkilledWorkerDrawerHeader extends StatelessWidget {

  

  const SkilledWorkerDrawerHeader({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    AuthStateProvider authStateProvider = Provider.of<AuthStateProvider>(context);
    return DrawerHeader(
      decoration: const BoxDecoration(color: Colors.green),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 35, color: Colors.green),
          ),
          const SizedBox(height: 10),
           Text(
            authStateProvider.name?? 'Skilled Worker',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Welcome to Skillzaar',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
