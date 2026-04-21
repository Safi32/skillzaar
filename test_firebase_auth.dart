import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// Simple test to verify Firebase Auth configuration
// Run this after updating google-services.json with SHA-1
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Test Firebase Auth instance
    final auth = FirebaseAuth.instance;
    print('✅ Firebase Auth instance created');
    print('📱 Current user: ${auth.currentUser?.uid ?? 'none'}');

    // Test phone verification (this should not hang if SHA-1 is configured)
    print('🚀 Testing phone verification setup...');

    // This will fail quickly if SHA-1 is not configured
    auth.verifyPhoneNumber(
      phoneNumber: '+923001234567', // Test number
      verificationCompleted: (credential) {
        print('✅ verificationCompleted callback works');
      },
      verificationFailed: (error) {
        print('❌ verificationFailed: ${error.code} - ${error.message}');
        if (error.code == 'app-not-authorized') {
          print('🔧 SHA-1 fingerprint not configured in Firebase Console');
        }
      },
      codeSent: (verificationId, resendToken) {
        print(
          '✅ codeSent callback works - Firebase Auth is properly configured',
        );
      },
      codeAutoRetrievalTimeout: (verificationId) {
        print('⏰ codeAutoRetrievalTimeout callback works');
      },
    );
  } catch (e) {
    print('❌ Firebase setup error: $e');
  }
}
