import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/presentation/widgets/job_ad_card.dart';
import 'package:skillzaar/presentation/widgets/job_ads_empty_state.dart';

class JobPosterAdsScreen extends StatelessWidget {
  final bool myAdsOnly;
  final bool isGuest;

  const JobPosterAdsScreen({
    super.key,
    this.myAdsOnly = false,
    this.isGuest = false,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    String? jobPosterId = user?.uid;

    print('🔍 Job Poster Ads Screen - User ID: $jobPosterId');
    print('🔍 Job Poster Ads Screen - My Ads Only: $myAdsOnly');

    if ((myAdsOnly && jobPosterId == null) || isGuest) {
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
            ],
          ),
        ),
      );
    }

    final Query<Map<String, dynamic>> query =
        myAdsOnly && jobPosterId != null
            ? FirebaseFirestore.instance
                .collection('Job')
                .where('jobPosterId', isEqualTo: jobPosterId)
            : FirebaseFirestore.instance.collection('Job');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const JobAdsEmptyState();
        }
        // Client-side sort by createdAt desc to avoid composite index
        final docs = [...snapshot.data!.docs];
        docs.sort((a, b) {
          final aTs =
              (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          final bTs =
              (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
          if (aTs == null && bTs == null) return 0;
          if (aTs == null) return 1;
          if (bTs == null) return -1;
          return bTs.compareTo(aTs);
        });
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
