import 'dart:async';
import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/widgets/banner.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/services/job_request_service.dart';
import 'job_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreenSkilled extends StatefulWidget {
  const HomeScreenSkilled({super.key});

  @override
  State<HomeScreenSkilled> createState() => _HomeScreenSkilledState();
}

class _HomeScreenSkilledState extends State<HomeScreenSkilled> {
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeRedirectToActiveJob(),
    );
  }

  Future<void> _maybeRedirectToActiveJob() async {
    try {
      final provider = Provider.of<SkilledWorkerProvider>(
        context,
        listen: false,
      );
      String? workerId =
          provider.loggedInUserId ?? FirebaseAuth.instance.currentUser?.uid;
      final workerPhone = provider.loggedInPhoneNumber;

      if ((workerId == null || workerId.isEmpty) &&
          workerPhone != null &&
          workerPhone.isNotEmpty) {
        workerId = 'SKILLED_WORKER_${workerPhone.replaceAll('0', '')}';
      }
      if (workerId == null || workerId.isEmpty) return;

      final active = await JobRequestService.getActiveRequestForWorker(
        workerId,
        skilledWorkerPhone: workerPhone,
      );
      if (!mounted || active == null) return;
      final jobId = active['jobId'] as String?;
      if (jobId == null || jobId.isEmpty) return;
      final job = await JobRequestService.getJobDetails(jobId);
      if (!mounted || job == null) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/skilled-worker-job-detail',
        (route) => false,
        arguments: {
          'imageUrl': job['Image'] ?? job['imageUrl'] ?? '',
          'title': job['title_en'] ?? job['title_ur'] ?? job['title'] ?? '',
          'location': job['Address'] ?? job['Location'] ?? '',
          'date': job['createdAt'],
          'description': job['description_en'] ?? job['description'] ?? '',
          'jobId': jobId,
          'jobPosterId': active['jobPosterId'] ?? '',
          'requestId': active['requestId'],
        },
      );
    } catch (_) {}
  }

  Future<void> _navigateToJobDetailWithAssignmentCheck(
    BuildContext context,
    String jobId,
    String imageUrl,
    String title,
    String location,
    DateTime? date,
    String description,
    String jobPosterId,
  ) async {
    try {
      final skilledWorkerId = await JobRequestService.getSkilledWorkerId();
      if (skilledWorkerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This job is not assigned to you. Please contact admin for more information.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final isAssigned = await JobRequestService.isSkilledWorkerAssignedToJob(
        jobId: jobId,
        skilledWorkerId: skilledWorkerId,
      );
      if (!isAssigned) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This job is not assigned to you. Please contact admin for more information.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => JobDetailScreen(
                imageUrl: imageUrl,
                title: title,
                location: location,
                date: date,
                description: description,
                jobId: jobId,
                jobPosterId: jobPosterId,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error navigating to job detail: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getLocalizedCategoryName(String label, AppLocalizations l10n) {
    switch (label) {
      case 'All':
        return l10n.all;
      case 'Plumbing':
        return l10n.plumbing;
      case 'Painting':
        return l10n.painting;
      case 'Cleaning':
        return l10n.cleaning;
      case 'Gardening':
        return l10n.gardening;
      case 'Masonry':
        return l10n.masonry;
      case 'Electric Work':
        return l10n.electricWork;
      default:
        return label;
    }
  }

  Widget _buildChip(String label, String assetPath, AppLocalizations l10n) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color:
              isSelected ? Colors.green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.green, width: 2) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(assetPath, width: 40, height: 40, fit: BoxFit.contain),
            const SizedBox(height: 6),
            Text(
              _getLocalizedCategoryName(label, l10n),
              style: TextStyle(
                color: isSelected ? Colors.green : Colors.black87,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const HireBanner(),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _buildChip("All", 'assets/workers.png', l10n),
              _buildChip("Plumbing", 'assets/plumber.png', l10n),
              _buildChip("Painting", 'assets/painter.png', l10n),
              _buildChip("Cleaning", 'assets/broom.png', l10n),
              _buildChip("Gardening", 'assets/gardener.png', l10n),
              _buildChip("Masonry", 'assets/brickwork.png', l10n),
              _buildChip("Electric Work", 'assets/electrician.png', l10n),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: JobRequestService.getApprovedJobsByCategory(
              _selectedCategory,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.work_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedCategory == 'All'
                            ? l10n.noJobsAvailable
                            : l10n.noCategoryJobs.replaceFirst(
                              '{category}',
                              _getLocalizedCategoryName(
                                _selectedCategory,
                                l10n,
                              ),
                            ),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.checkBackLater,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final jobId = doc.id;
                  final title =
                      data['title_en'] ??
                      data['title_ur'] ??
                      data['Name'] ??
                      'No Title';
                  final description =
                      data['description_en'] ??
                      data['description_ur'] ??
                      data['Description'] ??
                      '';
                  final imageUrl =
                      (data['images'] != null &&
                              data['images'] is List &&
                              data['images'].isNotEmpty)
                          ? data['images'][0]
                          : (data['Image'] ??
                              'https://via.placeholder.com/120x80?text=Job');
                  final postedDate =
                      data['createdAt'] != null
                          ? (data['createdAt'] as Timestamp).toDate()
                          : null;
                  final lat =
                      data['Latitude'] is double
                          ? data['Latitude']
                          : (data['Latitude'] as num?)?.toDouble();
                  final lng =
                      data['Longitude'] is double
                          ? data['Longitude']
                          : (data['Longitude'] as num?)?.toDouble();
                  double? distanceKm;
                  final provider = Provider.of<SkilledWorkerProvider>(
                    context,
                    listen: false,
                  );
                  if (lat != null &&
                      lng != null &&
                      provider.currentLatitude != null &&
                      provider.currentLongitude != null) {
                    distanceKm = JobRequestService.calculateDistance(
                      provider.currentLatitude!,
                      provider.currentLongitude!,
                      lat,
                      lng,
                    );
                  }
                  return JobCard(
                    onTap:
                        () => _navigateToJobDetailWithAssignmentCheck(
                          context,
                          jobId,
                          imageUrl,
                          title,
                          data['Address'] ?? data['Location'] ?? '',
                          postedDate,
                          description,
                          data['jobPosterId'] ?? data['userId'] ?? '',
                        ),
                    title: title,
                    company:
                        (data['jobPosterName'] ?? l10n.jobPoster).toString(),
                    location: data['Address'] ?? data['Location'] ?? '—',
                    salary:
                        (() {
                          final dynamic price =
                              data['price'] ?? data['Budget'] ?? data['budget'];
                          if (price != null &&
                              price.toString().trim().isNotEmpty) {
                            final currency =
                                (data['currency'] ?? 'PKR').toString();
                            return '$currency ${price.toString()}';
                          }
                          if (distanceKm != null)
                            return '${distanceKm.toStringAsFixed(0)} km';
                          return '';
                        })(),
                    rating: 4.7,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final String salary;
  final double rating;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.title,
    required this.company,
    required this.location,
    required this.salary,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.green.withOpacity(0.2),
              child: const Icon(Icons.work, color: Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    company,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  salary,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
