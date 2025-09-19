import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/lang.dart';
import '../../../core/services/job_request_service.dart';
import '../../../core/services/performance_service.dart';
import '../../../core/services/performance_monitor.dart';
import '../../widgets/location_status_widget.dart';
import '../../widgets/approval_gate.dart';
import 'job_detail_screen.dart';

class SkilledWorkerJobsScreen extends StatefulWidget {
  const SkilledWorkerJobsScreen({super.key});

  @override
  State<SkilledWorkerJobsScreen> createState() =>
      _SkilledWorkerJobsScreenState();
}

class _SkilledWorkerJobsScreenState extends State<SkilledWorkerJobsScreen>
    with PerformanceMonitoringMixin {
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
    return ApprovalGate(
      child: Consumer<SkilledWorkerProvider>(
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
                              Icon(
                                Icons.work_off,
                                size: 64,
                                color: Colors.grey,
                              ),
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

                      return PerformanceListView(
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
      ),
    );
  }

  Widget _buildJobCard(
    BuildContext context,
    Map<String, dynamic> job,
    String jobId,
  ) {
    return RepaintBoundary(
      child: _JobCardWidget(
        job: job,
        jobId: jobId,
        onTap: () => _launchDialer(job['posterPhone'] ?? ''),
      ),
    );
  }
}

class _JobCardWidget extends StatefulWidget {
  final Map<String, dynamic> job;
  final String jobId;
  final VoidCallback onTap;

  const _JobCardWidget({
    required this.job,
    required this.jobId,
    required this.onTap,
  });

  @override
  State<_JobCardWidget> createState() => _JobCardWidgetState();
}

class _JobCardWidgetState extends State<_JobCardWidget>
    with PerformanceMonitoringMixin {
  double? _distance;
  bool _isCalculatingDistance = false;

  @override
  void initState() {
    super.initState();
    _calculateDistance();
  }

  Future<void> _calculateDistance() async {
    final lat =
        widget.job['Latitude'] is double
            ? widget.job['Latitude']
            : (widget.job['Latitude'] as num?)?.toDouble();
    final lng =
        widget.job['Longitude'] is double
            ? widget.job['Longitude']
            : (widget.job['Longitude'] as num?)?.toDouble();

    if (lat == null || lng == null) return;

    final provider = Provider.of<SkilledWorkerProvider>(context, listen: false);
    if (provider.currentLatitude == null || provider.currentLongitude == null) {
      return;
    }

    setState(() {
      _isCalculatingDistance = true;
    });

    try {
      final distance = await monitorMethod('distance_calculation', () async {
        return await PerformanceService.calculateDistanceInIsolate(
          lat1: provider.currentLatitude!,
          lon1: provider.currentLongitude!,
          lat2: lat,
          lon2: lng,
        );
      });

      if (mounted) {
        setState(() {
          _distance = distance;
          _isCalculatingDistance = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCalculatingDistance = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.job['title_en'] ??
        widget.job['title_ur'] ??
        widget.job['Name'] ??
        'No Title';
    final description =
        widget.job['description_en'] ??
        widget.job['description_ur'] ??
        widget.job['Description'] ??
        '';
    final imageUrl =
        (widget.job['images'] != null &&
                widget.job['images'] is List &&
                widget.job['images'].isNotEmpty)
            ? widget.job['images'][0]
            : (widget.job['Image'] ??
                'https://via.placeholder.com/120x80?text=Job');
    final postedDate =
        widget.job['createdAt'] != null
            ? (widget.job['createdAt'] as Timestamp).toDate()
            : null;
    final posterPhone = widget.job['posterPhone'] ?? '';

    final dynamic price =
        widget.job['price'] ?? widget.job['Budget'] ?? widget.job['budget'];
    final String salaryText =
        (price != null && price.toString().trim().isNotEmpty)
            ? '${(widget.job['currency'] ?? 'PKR').toString()} ${price.toString()}'
            : (_distance != null ? '${_distance!.toStringAsFixed(1)} km' : '');

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
                    location: widget.job['Address'] ?? '',
                    date: postedDate,
                    description: description,
                    jobId: widget.jobId,
                    jobPosterId:
                        widget.job['jobPosterId'] ?? widget.job['userId'] ?? '',
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
                    if (_distance != null) ...[
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
                            '${_distance!.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else if (_isCalculatingDistance) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Calculating distance...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          salaryText,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                  ],
                ),
              ),
              // Action buttons
              Column(
                children: [
                  if (posterPhone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: widget.onTap,
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
