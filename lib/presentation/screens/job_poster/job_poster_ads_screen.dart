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
    final jobPosterId = user?.uid ?? 'TEST_JOB_POSTER_ID';

    final Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
        .collection('Job')
        .orderBy('createdAt', descending: true);

    final Query<Map<String, dynamic>> query = myAdsOnly
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
