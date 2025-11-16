import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AuthStateProvider centralizes session state so UI can reactively
/// show the correct initial screen without manually calling setState.
class AuthStateProvider with ChangeNotifier {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  fb_auth.User? _user;
  String? _role; // 'skilled_worker' | 'job_poster'
  String? _persistedUserId;
  bool _loading = true;

  AuthStateProvider() {
    _init();
  }

  fb_auth.User? get user => _user;
  String? get role => _role;
  bool get loading => _loading;
  bool get isSignedIn => _user != null;

  Future<void> _init() async {
    try {
      _user = _auth.currentUser;

      // Check SharedPreferences for persisted role first (fast, local)
      final prefs = await SharedPreferences.getInstance();
      final persistedRole = prefs.getString('role');
      final persistedUserId = prefs.getString('userId');
      if (persistedRole != null) {
        _role = persistedRole;
        _persistedUserId = persistedUserId;
      }

      // If user exists and role not in prefs, do a Firestore lookup
      if (_user != null && _role == null) {
        final uid = _user!.uid;
        try {
          final skDoc =
              await FirebaseFirestore.instance
                  .collection('SkilledWorkers')
                  .doc(uid)
                  .get();
          if (skDoc.exists) {
            _role = 'skilled_worker';
            await prefs.setString('role', _role!);
            await prefs.setString('userId', uid);
            _persistedUserId = uid;
          } else {
            final jpDoc =
                await FirebaseFirestore.instance
                    .collection('JobPosters')
                    .doc(uid)
                    .get();
            if (jpDoc.exists) {
              _role = 'job_poster';
              await prefs.setString('role', _role!);
              await prefs.setString('userId', uid);
              _persistedUserId = uid;
            }
          }
        } catch (_) {
          // Firestore lookup failed; leave role null
        }
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Call this after a successful login to persist role and user
  Future<void> setSignedIn({
    required fb_auth.User user,
    required String role,
  }) async {
    _user = user;
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('role', role);
    if (user.uid.isNotEmpty) {
      await prefs.setString('userId', user.uid);
      _persistedUserId = user.uid;
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } finally {
      _user = null;
      _role = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('role');
      await prefs.remove('userId');
      _persistedUserId = null;
      notifyListeners();
    }
  }

  /// Consider session present if Firebase user exists OR we have persisted role+userId.
  bool get isSessionPersisted =>
      _user != null || (_role != null && _persistedUserId != null);
}
