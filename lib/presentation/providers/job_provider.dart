import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class JobProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _success;
  String _address = '';
  double? _latitude;
  double? _longitude;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get success => _success;
  String get address => _address;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  void setAddress(String value) {
    _address = value;
    notifyListeners();
  }

  void setLatLng(double? lat, double? lng) {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  Future<void> postJob({
    required String name_en,
    required String name_ur,
    required String description_en,
    required String description_ur,
    required File? image,
    required String location,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    String jobPosterId;
    String posterPhone;

    if (user != null) {
      jobPosterId = user.uid;
      posterPhone = user.phoneNumber ?? '0000000000';

      // Check if job poster exists, if not create one
      try {
        final jobPosterDoc =
            await FirebaseFirestore.instance
                .collection('JobPosters')
                .doc(user.uid)
                .get();

        if (!jobPosterDoc.exists) {
          // Create job poster document
          await FirebaseFirestore.instance
              .collection('JobPosters')
              .doc(user.uid)
              .set({
                'userId': user.uid,
                'phoneNumber': user.phoneNumber ?? '0000000000',
                'displayName': user.displayName ?? 'Job Poster',
                'createdAt': FieldValue.serverTimestamp(),
                'isActive': true,
              });
        }
      } catch (e) {
        _error = 'Failed to create job poster profile: $e';
        _isLoading = false;
        notifyListeners();
        return;
      }
    } else {
      // For testing: use a default job poster ID
      jobPosterId = 'TEST_JOB_POSTER_ID';
      posterPhone = '+923115798273';
    }

    String imageUrl = "https://via.placeholder.com/150";

    final jobData = {
      'title_en': name_en,
      'title_ur': name_ur,
      'description_en': description_en,
      'description_ur': description_ur,
      'Image': imageUrl,
      'Location': location,
      'Address': address,
      'Latitude': latitude,
      'Longitude': longitude,
      'jobPosterId': jobPosterId,
      'posterPhone': posterPhone,
      'createdAt': FieldValue.serverTimestamp(),
      'status':
          'pending', // Jobs require admin approval before being visible to skilled workers
      'isActive': true,
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('Job')
          .add(jobData);
      _success =
          'Job posted successfully! Your job is pending admin approval and will be visible to skilled workers once approved.';
      _isLoading = false;
      notifyListeners();

      _address = '';
      _latitude = null;
      _longitude = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to post job: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearStatus() {
    _error = null;
    _success = null;
    notifyListeners();
  }
}
