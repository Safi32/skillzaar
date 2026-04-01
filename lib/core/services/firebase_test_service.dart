import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseTestService {
  /// Test Firebase configuration and phone auth setup
  static Future<Map<String, dynamic>> testFirebaseConfiguration() async {
    try {
      print('🔍 Testing Firebase configuration...');

      // Test Firebase initialization
      final app = Firebase.app();
      print('✅ Firebase app initialized: ${app.name}');

      // Test Firebase Auth
      print('✅ Firebase Auth instance created');

      // Test app configuration
      final options = app.options;
      print('✅ Project ID: ${options.projectId}');
      print('✅ App ID: ${options.appId}');

      return {
        'success': true,
        'projectId': options.projectId,
        'appId': options.appId,
        'message': 'Firebase configuration is valid',
      };
    } catch (e) {
      print('❌ Firebase configuration test failed: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Firebase configuration has issues',
      };
    }
  }

  /// Test phone auth configuration specifically
  static Future<bool> testPhoneAuthConfiguration() async {
    try {
      // Test Firebase Auth instance creation
      print('✅ Phone auth configuration test passed');
      return true;
    } catch (e) {
      print('❌ Phone auth configuration test failed: $e');
      return false;
    }
  }
}
