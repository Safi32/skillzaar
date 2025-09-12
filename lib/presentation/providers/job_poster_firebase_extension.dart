import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

extension JobPosterFirebase on dynamic {
  Future<void> createJobPosterInFirebase(BuildContext context) async {
    final phoneAuthProvider = this;
    final phone = phoneAuthProvider._currentPhoneNumber ?? '';
    final userId = phone; // Use phone as userId for test/demo
    final jobPosterDoc = FirebaseFirestore.instance.collection('JobPosters').doc(userId);
    final doc = await jobPosterDoc.get();
    if (!doc.exists) {
      await jobPosterDoc.set({
        'userId': userId,
        'phoneNumber': phone,
        'displayName': 'Job Poster',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    }
  }
}
