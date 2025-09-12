import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/lang.dart';
import '../../../core/services/job_request_service.dart';
import '../../widgets/location_status_widget.dart';
import 'job_detail_screen.dart';

class SkilledWorkerJobsScreen extends StatefulWidget {
  const SkilledWorkerJobsScreen({super.key});

  @override
  State<SkilledWorkerJobsScreen> createState() =>
      _SkilledWorkerJobsScreenState();
}

class _SkilledWorkerJobsScreenState extends State<SkilledWorkerJobsScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize location services when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SkilledWorkerProvider>(
        context,
        listen: false,
      );
      provider.initializeLocationServices();
    });
  }

  void _launchDialer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SkilledWorkerProvider>(
      builder: (context, skilledWorkerProvider, child) {
        return Container(
          color: Colors.grey.shade50,
          child: Column(
            children: [
              // Location Status Widget
              const LocationStatusWidget(),

              // Jobs List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: JobRequestService.getApprovedJobs(),
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
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.work_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No approved jobs available',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Jobs are being reviewed by admin.\nCheck back later for approved opportunities.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final job = snapshot.data!.docs[index];
                        final jobData = job.data() as Map<String, dynamic>;

                        return _buildJobCard(context, jobData, job.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
  ) {
    final title =
        job['title_en'] ?? job['title_ur'] ?? job['Name'] ?? 'No Title';
    final description =
        job['description_en'] ??
        job['description_ur'] ??
        job['Description'] ??
        '';
    final imageUrl =
        (job['images'] != null &&
                job['images'] is List &&
                job['images'].isNotEmpty)
            ? job['images'][0]
            : (job['Image'] ?? 'https://via.placeholder.com/120x80?text=Job');
    final postedDate =
        job['createdAt'] != null
            ? (job['createdAt'] as Timestamp).toDate()
            : null;
    final posterPhone = job['posterPhone'] ?? '';
    final lat =
        job['Latitude'] is double
            ? job['Latitude']
            : (job['Latitude'] as num?)?.toDouble();
    final lng =
        job['Longitude'] is double
            ? job['Longitude']
            : (job['Longitude'] as num?)?.toDouble();
    final distance =
        lat != null &&
                lng != null &&
                Provider.of<SkilledWorkerProvider>(
                      context,
                      listen: false,
                    ).currentLatitude !=
                    null
            ? JobRequestService.calculateDistance(
              Provider.of<SkilledWorkerProvider>(
                context,
                listen: false,
              ).currentLatitude!,
              Provider.of<SkilledWorkerProvider>(
                context,
                listen: false,
              ).currentLongitude!,
              lat,
              lng,
            )
            : null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => JobDetailScreen(
                    imageUrl: imageUrl,
                    title: title,
                    location: job['Address'] ?? '',
                    date: postedDate,
                    description: description,
                    jobId: jobId,
                    jobPosterId: job['jobPosterId'] ?? job['userId'] ?? '',
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.work,
                          color: Colors.green,
                          size: 36,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          postedDate != null
                              ? '${postedDate.day}/${postedDate.month}/${postedDate.year}'
                              : tr(context, 'calendar'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    if (distance != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Tap for more details.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Column(
                children: [
                  if (posterPhone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () => _launchDialer(posterPhone),
                      tooltip: 'Call job poster',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
