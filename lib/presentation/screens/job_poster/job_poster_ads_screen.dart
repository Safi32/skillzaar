import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/presentation/widgets/job_ad_card.dart';
import 'package:skillzaar/presentation/widgets/job_ads_empty_state.dart';

class JobPosterAdsScreen extends StatelessWidget {
  final bool myAdsOnly;

  const JobPosterAdsScreen({super.key, this.myAdsOnly = false});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String? jobPosterId = user?.uid;

    if (myAdsOnly && jobPosterId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Please log in to view your ads.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/job-poster-home',
                    (route) => false,
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
        .collection('Job')
        .orderBy('createdAt', descending: true);

    final Query<Map<String, dynamic>> query =
        myAdsOnly && jobPosterId != null
            ? baseQuery.where('jobPosterId', isEqualTo: jobPosterId)
            : baseQuery;

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const JobAdsEmptyState();
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return AdCard(adId: docs[index].id, ad: data);
          },
        );
      },
    );
  }
}
