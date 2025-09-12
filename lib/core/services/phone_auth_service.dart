import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(PhoneAuthCredential credential) verificationCompleted,
    required Function(FirebaseAuthException e) verificationFailed,
    required Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: (verificationId, resendToken) => codeSent(verificationId),
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }
}