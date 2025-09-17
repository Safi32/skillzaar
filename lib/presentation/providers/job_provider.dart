import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'notification_provider.dart';
import 'package:provider/provider.dart';
import 'phone_auth_provider.dart' as auth_provider;

class JobProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _success;
  String _address = '';
  double? _latitude;
  double? _longitude;
  NotificationProvider? _notificationProvider;

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

  void setNotificationProvider(NotificationProvider provider) {
    _notificationProvider = provider;
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
    required BuildContext context,
  }) async {
    _isLoading = true;
    _error = null;
    _success = null;
    notifyListeners();

    // Require authenticated job poster
    final phoneAuthProvider = Provider.of<auth_provider.PhoneAuthProvider>(
      context,
      listen: false,
    );

    if (!(phoneAuthProvider.isLoggedIn &&
        phoneAuthProvider.loggedInUserId != null)) {
      _isLoading = false;
      _error = 'Please log in and verify your phone to post a job.';
      notifyListeners();
      return;
    }

    final String jobPosterId = phoneAuthProvider.loggedInUserId!;
    final String posterPhone =
        phoneAuthProvider.loggedInPhoneNumber ?? 'unknown';

    print('🔍 Posting Job:');
    print('  Job Poster ID: $jobPosterId');
    print('  Job Poster Phone: $posterPhone');

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
      'status': 'pending',
      'isActive': true,
    };

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('Job')
          .add(jobData);

      // Send notification to all skilled workers
      if (_notificationProvider != null) {
        await _notificationProvider!.sendJobNotification(
          jobTitle: name_en,
          jobDescription: description_en,
          jobId: docRef.id,
          location: location,
          budget: 0.0, // You might want to add budget field to your job data
        );

        // Send push notification to job poster (self)
        // Get job poster's FCM token from Firestore
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(jobPosterId)
                .get();
        final posterFcmToken = userDoc.data()?['fcmToken'] as String?;
        if (posterFcmToken != null) {
          await _notificationProvider!.notificationService.sendNotificationToToken(
            fcmToken: posterFcmToken,
            title: 'Job Posted!',
            body:
                'Your job has been posted successfully and is pending admin approval.',
            data: {'jobId': docRef.id, 'type': 'job_posted'},
          );
        }
      }

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
