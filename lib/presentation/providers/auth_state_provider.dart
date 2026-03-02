import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';

enum AuthStatus {
  uninitialized,
  checkingSession,
  notLoggedIn,
  loggingIn,
  loggedIn,
}

enum NextScreen {
  login,
  homeSkilledWorker,
  homeJobPoster,
  activeJobSkilledWorker,
  activeJobJobPoster,
  completeProfile,
}

/// Lightweight user model for provider memory
class AuthUser {
  final String id;
  final String role;
  final String? name;
  final String? phone;
  final String? email;

  AuthUser({
    required this.id,
    required this.role,
    this.name,
    this.phone,
    this.email,
  });

  @override
  String toString() {
    return 'AuthUser(id: $id, role: $role, name: $name, phone: $phone, email: $email)';
  }
}

class AuthStateProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _name;

  // public getters
  AuthStatus _status = AuthStatus.uninitialized;
  AuthStatus get status => _status;

  AuthUser? _currentUser;
  AuthUser? get currentUser => _currentUser;

  String? get role => _currentUser?.role;
  String? get userId => _currentUser?.id;
  String? get name => _name;

  // verificationId storage & completer used to notify callers when codeSent
  String? _verificationId;
  String? get verificationId => _verificationId;

  Completer<String?>? _codeSentCompleter;

  AuthStateProvider() {
    _restoreSession();
  }

  // ---------------------------
  // Session restore / persistence
  // ---------------------------
  Future<void> _restoreSession() async {
    _status = AuthStatus.checkingSession;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString("role");
      final savedUserId = prefs.getString("userId");
      final savedName = prefs.getString("name");

      log("Restoring session: role=$savedRole, userId=$savedUserId");

      if (savedRole != null && savedUserId != null) {
        _currentUser = AuthUser(
          id: savedUserId,
          role: savedRole,
          name: savedName,
        );
        _status = AuthStatus.loggedIn;
        notifyListeners();
        // optionally refresh profile data (non-blocking)
        _refreshProfileData().catchError(
          (e) => log("refresh profile error: $e"),
        );
        return;
      }

      _status = AuthStatus.notLoggedIn;
      notifyListeners();
    } catch (e) {
      log("restoreSession error: $e");
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
    }
  }

  Future<void> _saveSession() async {
    if (_currentUser == null) return;
    log(
      "Restoring session:- role=${_currentUser!.role}, userId=${_currentUser!.id}",
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("role", _currentUser!.role);
    await prefs.setString("userId", _currentUser!.id);
    await prefs.setString("name", name ?? "");
  }

  Future<void> _clearSession() async {
    log("Restoring session:--");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("role");
    await prefs.remove("userId");
    await prefs.remove("name");
  }

  // Refresh name/phone from Firestore (best-effort)
  Future<void> _refreshProfileData() async {
    if (_currentUser == null) return;
    try {
      if (_currentUser!.role == "skilled_worker") {
        final doc =
            await _db.collection("SkilledWorkers").doc(_currentUser!.id).get();
        if (doc.exists) {
          _currentUser = AuthUser(
            id: _currentUser!.id,
            role: _currentUser!.role,
            name: doc.data()?['Name'] as String?,
            phone: doc.data()?['phoneNumber'] as String?,
          );
          notifyListeners();
        }
      } else if (_currentUser!.role == "job_poster") {
        log("Refreshing profile data for job poster ${_currentUser!.id}");
        final doc =
            await _db.collection("JobPosters").doc(_currentUser!.id).get();
        if (doc.exists) {
          final data = doc.data();
          _currentUser = AuthUser(
            id: _currentUser!.id,
            role: _currentUser!.role,
            name: data?['displayName'] as String?,
            phone: data?['phoneNumber'] as String?,
            email: data?['email'] as String?,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      log("refreshProfileData error: $e");
    }
  }

  /// Public helper: mark a job poster as signed in.
  Future<void> setJobPosterSignedIn({
    required String id,
    String? name,
    String? phone,
    String? email,
  }) async {
    _currentUser = AuthUser(
      id: id,
      role: "job_poster",
      name: name,
      phone: phone,
      email: email,
    );
    _status = AuthStatus.loggedIn;
    await _saveSession();
    notifyListeners();
  }

  /// Public helper: mark a skilled worker as signed in using Firestore-only identity.
  /// This does not rely on a FirebaseAuth [User] and can be used after a successful
  /// skilled worker OTP flow that creates/updates the `SkilledWorkers` document.
  Future<void> setSkilledWorkerSignedIn({
    required String id,
    String? name,
    String? phone,
  }) async {
    _currentUser = AuthUser(
      id: id,
      role: "skilled_worker",
      name: name,
      phone: phone,
    );
    _status = AuthStatus.loggedIn;
    await _saveSession();
    notifyListeners();
  }

  // ---------------------------
  // Skilled Worker login (admin created accounts)
  // ---------------------------
  /// Returns null on success, or error string on failure.
  Future<String?> loginSkilledWorker(String phone, String password) async {
    _status = AuthStatus.loggingIn;
    notifyListeners();

    try {
      final query =
          await _db
              .collection("SkilledWorkers")
              .where("phoneNumber", isEqualTo: phone)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "No skilled worker found with this phone.";
      }

      final doc = query.docs.first;
      final data = doc.data();
      final id = doc.id;
      _name = data['Name'] as String? ?? data['displayName'] as String?;

      final storedPassword = (data['password'] as String?) ?? '';

      if (storedPassword.isEmpty) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Password is not set for this account. Please contact support.";
      }

      if (storedPassword != password) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Incorrect password.";
      }

      _currentUser = AuthUser(
        id: id,
        role: "skilled_worker",
        name: name,
        phone: phone,
      );

      log("Login successful: ${_currentUser.toString()}");
      await _saveSession();

      _status = AuthStatus.loggedIn;
      notifyListeners();
      return null;
    } catch (e) {
      log("loginSkilledWorker error: $e");
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
      return "Login error: ${e.toString()}";
    }
  }

  /// ---------------------------
  /// Job Poster login with phone/password
  /// ---------------------------
  /// Returns null on success, or error string on failure.
  Future<String?> loginJobPosterWithPhonePassword(
    String phone,
    String password,
  ) async {
    _status = AuthStatus.loggingIn;
    notifyListeners();

    try {
      final query = await _db
          .collection("JobPosters")
          .where("phoneNumber", isEqualTo: phone)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "No job poster found with this phone.";
      }

      final doc = query.docs.first;
      final data = doc.data();

      final storedPassword = (data['password'] as String?) ?? '';
      final email = data['email'] as String? ?? '';

      if (storedPassword.isEmpty) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Password is not set for this account. Please contact support.";
      }

      if (storedPassword != password) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Incorrect password.";
      }

      User? fbUser;

      if (email.isNotEmpty) {
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: storedPassword,
          );
          fbUser = userCredential.user;
        } on FirebaseAuthException catch (e) {
          String msg;
          switch (e.code) {
            case 'invalid-email':
              msg = "Invalid email address.";
              break;
            case 'user-not-found':
              msg = "No job poster found for this phone.";
              break;
            case 'wrong-password':
              msg = "Incorrect password.";
              break;
            case 'user-disabled':
              msg = "This account has been disabled.";
              break;
            default:
              msg = "Login error: ${e.message ?? e.code}";
          }
          _status = AuthStatus.notLoggedIn;
          notifyListeners();
          return msg;
        }
      }

      final userId = fbUser?.uid ?? doc.id;

      _currentUser = AuthUser(
        id: userId,
        role: "job_poster",
        name: data['displayName'] as String? ?? fbUser?.displayName,
        phone: data['phoneNumber'] as String? ?? fbUser?.phoneNumber,
        email: data['email'] as String? ?? fbUser?.email,
      );

      await _saveSession();

      _status = AuthStatus.loggedIn;
      notifyListeners();
      return null;
    } catch (e) {
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
      return "Login error: ${e.toString()}";
    }
  }

  /// ---------------------------
  /// Job Poster login with email/password
  /// ---------------------------
  /// Returns null on success, or error string on failure.
  Future<String?> loginJobPosterWithEmailPassword(
    String email,
    String password,
  ) async {
    _status = AuthStatus.loggingIn;
    notifyListeners();

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final fbUser = userCredential.user;

      if (fbUser == null) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Firebase sign-in failed.";
      }

      final posterDocRef = _db.collection("JobPosters").doc(fbUser.uid);
      final snapshot = await posterDocRef.get();

      if (!snapshot.exists) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Job poster profile not found.";
      }

      final data = snapshot.data();

      _currentUser = AuthUser(
        id: fbUser.uid,
        role: "job_poster",
        name: data?['displayName'] as String? ?? fbUser.displayName,
        phone: data?['phoneNumber'] as String? ?? fbUser.phoneNumber,
        email: data?['email'] as String? ?? fbUser.email,
      );

      await _saveSession();

      _status = AuthStatus.loggedIn;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = "Invalid email address.";
          break;
        case 'user-not-found':
          msg = "No job poster found with this email.";
          break;
        case 'wrong-password':
          msg = "Incorrect password.";
          break;
        case 'user-disabled':
          msg = "This account has been disabled.";
          break;
        default:
          msg = "Login error: ${e.message ?? e.code}";
      }
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
      return msg;
    } catch (e) {
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
      return "Login error: ${e.toString()}";
    }
  }

  // ---------------------------
  // Job Poster OTP flow
  // ---------------------------

  /// Sends OTP and completes when Firebase `codeSent` is called.
  /// Returns null on success (codeSent received), or error string.
  Future<String?> sendOtpToPhone(
    String phone, {
    Duration waitForCodeSent = const Duration(seconds: 10),
  }) async {
    // ensure not re-used completer
    if (_codeSentCompleter != null && !(_codeSentCompleter!.isCompleted)) {
      _codeSentCompleter!.complete(null);
    }
    _codeSentCompleter = Completer<String?>();

    try {
      // First check if a JobPoster exists with this phone.
      final exists = await UserDataService.userExistsByPhone(
        phoneNumber: phone,
        userType: 'job_poster',
      );

      if (!exists) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return 'No job poster account found for this phone. Please sign up first.';
      }

      // set temporary status while waiting for codeSent
      _status = AuthStatus.loggingIn;
      notifyListeners();

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential cred) async {
          // Auto verification (instant)
          await _completeOtpLogin(cred);
        },
        verificationFailed: (FirebaseAuthException e) {
          log("verifyPhoneNumber failed: ${e.code} ${e.message}");
          if (!(_codeSentCompleter?.isCompleted ?? true)) {
            _codeSentCompleter?.complete("Failed to send OTP: ${e.message}");
          }
          _status = AuthStatus.notLoggedIn;
          notifyListeners();
        },
        codeSent: (String verificationId, int? forceResendingToken) {
          _verificationId = verificationId;
          // complete the completer successfully
          if (!(_codeSentCompleter?.isCompleted ?? true)) {
            _codeSentCompleter?.complete(null);
          }
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          // don't complete as error — code might still be delivered manually
          notifyListeners();
        },
      );

      // Wait for completer to be completed (codeSent or failure). Fail after timeout.
      // String? res;
      // try {
      //   res = await _codeSentCompleter!.future.timeout(waitForCodeSent);
      // } on TimeoutException {
      //   res = "Timeout waiting for SMS. Please try again.";
      //   // leave _verificationId as is if codeAutoRetrievalTimeout filled it later
      // }

      // if (res != null) {
      //   // res contains error
      //   _status = AuthStatus.notLoggedIn;
      //   notifyListeners();
      //   return res;
      // }

      // If we are not logged in (e.g. auto-verify didn't happen), reset status to notLoggedIn
      // so the UI doesn't show a loading spinner indefinitely.
      if (_status != AuthStatus.loggedIn) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
      }

      return null;
    } catch (e) {
      log("sendOtpToPhone error: $e");
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
      return "Error sending OTP: ${e.toString()}";
    } finally {
      // Do not clear _verificationId here; OTP verify needs it.
      // Leave status as notLoggedIn until verifyOtpCode sets loggingIn.
    }
  }

  /// Verify OTP code (smsCode) and sign in. Returns null on success or error string.
  Future<String?> verifyOtpCode(String smsCode, String phone) async {
    _status = AuthStatus.loggingIn;
    notifyListeners();

    try {
      if (_verificationId == null) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Verification ID missing. Please resend OTP.";
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      return await _completeOtpLogin(credential, phone: phone);
    } catch (e) {
      log("verifyOtpCode error: $e");
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
      return "Invalid OTP";
    }
  }

  /// Internal: completes OTP login (called by verificationCompleted or manual verify)
  Future<String?> _completeOtpLogin(
    PhoneAuthCredential credential, {
    String? phone,
  }) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final fbUser = userCredential.user ?? _auth.currentUser;

      if (fbUser == null) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Firebase sign-in failed.";
      }

      // Ensure JobPosters doc exists for this uid.
      final posterDocRef = _db.collection("JobPosters").doc(fbUser.uid);
      final posterSnapshot = await posterDocRef.get();

      if (!posterSnapshot.exists) {
        _status = AuthStatus.notLoggedIn;
        notifyListeners();
        return "Job poster profile not found.";
      }

      // read doc to get profile fields
      final doc = await posterDocRef.get();
      final data = doc.data();

      _currentUser = AuthUser(
        id: fbUser.uid,
        role: "job_poster",
        name: data?['displayName'] as String? ?? fbUser.displayName,
        phone: data?['phoneNumber'] as String? ?? fbUser.phoneNumber,
        email: data?['email'] as String?,
      );

      await _saveSession();

      _status = AuthStatus.loggedIn;
      notifyListeners();

      return null;
    } catch (e) {
      log("_completeOtpLogin error: $e");
      _status = AuthStatus.notLoggedIn;
      notifyListeners();
      return "OTP Login Error: ${e.toString()}";
    }
  }

  // ---------------------------
  // Logout
  // ---------------------------
  Future<void> logout() async {
    try {
      if (_currentUser?.role == "job_poster") {
        await _auth.signOut();
      }
    } catch (e) {
      log("logout firebase signout error: $e");
    }

    await _clearSession();
    _currentUser = null;
    _verificationId = null;
    _status = AuthStatus.notLoggedIn;
    notifyListeners();
  }

  // ---------------------------
  // Determine next screen (based on role & active job)
  // UI can call this to decide where to navigate next.
  // ---------------------------
  Future<NextScreen> determineNextScreen() async {
    if (_status != AuthStatus.loggedIn || _currentUser == null) {
      return NextScreen.login;
    }

    try {
      final id = _currentUser!.id;
      final r = _currentUser!.role;

      log("determineNextScreen for user $id with role $r");

      if (r == "skilled_worker") {
        // Mirror _checkForActiveJobSkilledWorker logic at a high level:
        // 1) Active assigned job
        // 2) Completed job needing rating
        // 3) Otherwise go to skilled worker home

        // 1) Check for active assigned job
        final assignedJob =
            await JobRequestService.getActiveAssignedJobForWorker(id);
        if (assignedJob != null) {
          return NextScreen.activeJobSkilledWorker;
        }

        // 2) Check for completed job that needs worker rating
        final completedJob =
            await JobRequestService.getCompletedJobNeedingWorkerRating(id);
        if (completedJob != null) {
          // For now we reuse the same enum; UI can route to rating screen
          // when it sees this for a skilled worker.
          return NextScreen.activeJobSkilledWorker;
        }

        // 3) Default to skilled worker home
        return NextScreen.homeSkilledWorker;
      }

      if (r == "job_poster") {
        final doc = await _db.collection("JobPosters").doc(id).get();
        if (!doc.exists) return NextScreen.login;

        final data = doc.data() ?? {};
        final profileCompleted = data['profileCompleted'] as bool? ?? true;
        final hasActiveJob = data['isActive'] as bool? ?? false;
        log('determineNextScreen: profileCompleted=$profileCompleted, hasActiveJob=$hasActiveJob , for job poster $id');
        
        if( hasActiveJob) {
          return NextScreen.activeJobJobPoster;
        }
        if (!profileCompleted) {
          return NextScreen.completeProfile;
        }


        return NextScreen.homeJobPoster;
      }

      return NextScreen.login;
    } catch (e) {
      log("determineNextScreen error: $e");
      return NextScreen.login;
    }
  }
}
