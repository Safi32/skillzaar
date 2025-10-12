import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/widgets/banner.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../../core/services/job_request_service.dart';
import 'job_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skillzaar/presentation/widgets/bottom_bar_widget.dart';
import '../../widgets/contact_us_dialog.dart';
import '../../widgets/filter_dialog.dart';
import '../../widgets/skilled_worker_drawer_header.dart';
// import '../../widgets/approval_gate.dart'; // Removed - no approval needed for admin-created accounts
import 'jobs_screen.dart';
import 'home_profile_screen.dart';
// import 'requests_screen.dart'; // Requests removed
// import '../../widgets/real_time_notification_widget.dart';

/// Helper function to safely convert Timestamp to DateTime
DateTime? _safeConvertToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class HomeScreenSkilled extends StatefulWidget {
  const HomeScreenSkilled({super.key});

  @override
  State<HomeScreenSkilled> createState() => _HomeScreenSkilledState();
}

class _HomeScreenSkilledState extends State<HomeScreenSkilled> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String _selectedJobType = 'All';
  double _selectedRadius = 50.0;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRedirectToActiveJob();
      _setupRequestStatusListener();
      // Retry once shortly after initial build to handle late provider init
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _maybeRedirectToActiveJob();
        }
      });
    });
  }

  void _setupRequestStatusListener() {
    final provider = Provider.of<SkilledWorkerProvider>(context, listen: false);
    if (provider.loggedInUserId != null) {
      FirebaseFirestore.instance
          .collection('JobRequests')
          .where('skilledWorkerId', isEqualTo: provider.loggedInUserId)
          .where('status', isEqualTo: 'accepted')
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.docs.isNotEmpty && mounted) {
              final requestData = snapshot.docs.first.data();
              final jobId = requestData['jobId'] as String?;
              if (jobId != null) {
                _redirectToJobDetail(
                  jobId,
                  requestData['requestId'] as String?,
                );
              }
            }
          });
    }
  }

  Future<void> _redirectToJobDetail(String jobId, String? requestId) async {
    try {
      final job = await JobRequestService.getJobDetails(jobId);
      if (job != null && mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/skilled-worker-job-detail',
          (route) => false,
          arguments: {
            'imageUrl': job['Image'] ?? '',
            'title': job['title_en'] ?? job['title_ur'] ?? '',
            'location': job['Address'] ?? job['Location'] ?? '',
            'date': _safeConvertToDateTime(job['createdAt']),
            'description': job['description_en'] ?? job['description_ur'] ?? '',
            'jobId': jobId,
            'jobPosterId': job['jobPosterId'] ?? '',
            'requestId': requestId,
          },
        );
      }
    } catch (e) {
      print('Error redirecting to job detail: $e');
    }
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
      // Check if the skilled worker is assigned to this job before navigating
      final skilledWorkerId = await JobRequestService.getSkilledWorkerId();
      if (skilledWorkerId == null) {
        _showAssignmentError(context);
        return;
      }

      final isAssigned = await JobRequestService.isSkilledWorkerAssignedToJob(
        jobId: jobId,
        skilledWorkerId: skilledWorkerId,
      );

      if (!isAssigned) {
        _showAssignmentError(context);
        return;
      }

      // If assigned, navigate to job detail screen
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
      print('Error navigating to job detail: $e');
      _showAssignmentError(context);
    }
  }

  void _showAssignmentError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This job is not assigned to you. Please contact admin for more information.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(top: 50, left: 16, right: 16),
      ),
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

      // If workerId not available yet, derive it from phone used in test auth
      if ((workerId == null || workerId.isEmpty) &&
          workerPhone != null &&
          workerPhone.isNotEmpty) {
        final derived = 'SKILLED_WORKER_${workerPhone.replaceAll('0', '')}';
        workerId = derived;
      }

      if (workerId == null || workerId.isEmpty) return;

      // Force rating flow BEFORE anything else. If there's a completed job
      // where the worker hasn't rated the client yet, open the rating screen
      // and block access to other screens until it's submitted.
      final completedNeedingRating =
          await JobRequestService.getCompletedJobNeedingWorkerRating(workerId);
      if (mounted &&
          completedNeedingRating != null &&
          (completedNeedingRating['assignedJobId'] as String?)?.isNotEmpty ==
              true) {
        final assignedJobId = completedNeedingRating['assignedJobId'] as String;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/rate-job-poster',
          (route) => false,
          arguments: {'assignedJobId': assignedJobId, 'isJobCompletion': true},
        );
        return;
      }
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

  @override
  Widget build(BuildContext context) {
    return _buildMainContent(
      context,
    ); // Removed ApprovalGate - admin-created accounts are auto-approved
  }

  Widget _buildMainContent(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeBody(),
      const SkilledWorkerJobsScreen(),
      const HomeProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        centerTitle: true,
        elevation: 5,
        title: Text(
          _getTitle(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SkilledWorkerDrawerHeader(),
            ListTile(
              leading: const Icon(Icons.contact_support, color: Colors.green),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.pop(context);
                _showContactUsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.red),
              title: const Text('Deactivate Account'),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text('Deactivate Account'),
                        content: const Text(
                          'This will permanently delete your account and data. Continue?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                );

                if (confirm == true) {
                  final success = await Provider.of<SkilledWorkerProvider>(
                    context,
                    listen: false,
                  ).deactivateAndDeleteCurrentUser(context);
                  if (!mounted) return;
                  if (success) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/skilled-worker-login',
                      (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not delete account. Re-login may be required.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            // Rate Job Poster functionality removed from drawer but kept for automatic opening
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: FloatingIslandNavBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildChip(String label, String assetPath) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
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
              label,
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

  Widget _buildHomeBody() {
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
              _buildChip("All", 'assets/workers.png'),
              _buildChip("Plumbing", 'assets/plumber.png'),
              _buildChip("Painting", 'assets/painter.png'),
              _buildChip("Cleaning", 'assets/broom.png'),
              _buildChip("Gardening", 'assets/gardener.png'),
              _buildChip("Masonry", 'assets/brickwork.png'),
              _buildChip("Electric Work", 'assets/electrician.png'),
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
                            ? 'No approved jobs available yet'
                            : 'No $_selectedCategory jobs available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new opportunities',
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
                    company: (data['jobPosterName'] ?? 'Job Poster').toString(),
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
                          if (distanceKm != null) {
                            return '${distanceKm.toStringAsFixed(1)} km';
                          }
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

  void _showContactUsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const ContactUsDialog());
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            selectedJobType: _selectedJobType,
            selectedRadius: _selectedRadius,
            onJobTypeChanged: (type) => setState(() => _selectedJobType = type),
            onRadiusChanged: (value) => setState(() => _selectedRadius = value),
            onReset: () {
              setState(() {
                _selectedJobType = 'All';
                _selectedRadius = 50.0;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filters reset to default'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onApply: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Filters applied: \${_selectedJobType} jobs within \${_selectedRadius.round()} km',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
    );
  }

  Future<void> _openRateJobPosterFromDrawer(BuildContext context) async {
    try {
      final provider = Provider.of<SkilledWorkerProvider>(
        context,
        listen: false,
      );
      final skilledWorkerId = provider.loggedInUserId;

      if (skilledWorkerId == null || skilledWorkerId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Look for a completed job that still needs the worker's rating
      final completedJob =
          await JobRequestService.getCompletedJobNeedingWorkerRating(
            skilledWorkerId,
          );

      if (completedJob != null &&
          (completedJob['assignedJobId'] as String?)?.isNotEmpty == true) {
        final assignedJobId = completedJob['assignedJobId'] as String;
        Navigator.pushNamed(
          context,
          '/rate-job-poster',
          arguments: {'assignedJobId': assignedJobId, 'isJobCompletion': true},
        );
        return;
      }

      // If nothing pending, inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending ratings found.'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open rating page: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    if (shouldLogout == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/role-selection');
      }
    }
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'All Ads';
      case 2:
        return 'Profile';
      default:
        return 'All Jobs';
    }
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
