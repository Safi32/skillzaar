import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../skilled_worker/navigate_to_job_screen.dart';
import 'worker_tracking_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/skilled_worker_drawer_header.dart';
import '../../widgets/contact_us_dialog.dart';

class AssignedJobDetailScreen extends StatefulWidget {
  final String assignedJobId;
  final String userType;

  const AssignedJobDetailScreen({
    super.key,
    required this.assignedJobId,
    this.userType = 'skilled_worker',
  });

  @override
  State<AssignedJobDetailScreen> createState() =>
      _AssignedJobDetailScreenState();
}

class _AssignedJobDetailScreenState extends State<AssignedJobDetailScreen> {
  String? _cachedBudget;

  @override
  void initState() {
    super.initState();
    _loadCachedBudget();
  }

  Future<void> _loadCachedBudget() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _cachedBudget = prefs.getString('budget_${widget.assignedJobId}');
      });
    }
  }

  Future<void> _cacheBudget(String value) async {
    if (value == '0' ||
        value == 'Not Specified' ||
        value.isEmpty ||
        value == 'null') {
      return;
    }
    if (_cachedBudget == value) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('budget_${widget.assignedJobId}', value);
    if (mounted) {
      setState(() {
        _cachedBudget = value;
      });
    }
  }

  Future<void> _clearCachedBudget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('budget_${widget.assignedJobId}');
    if (mounted) {
      setState(() {
        _cachedBudget = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.green.withOpacity(0.2),
        centerTitle: true,
        title: const Text(
          "Assigned Job Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      drawer:
          widget.userType == 'skilled_worker'
              ? _buildSkilledWorkerDrawer(context)
              : null,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream:
            FirebaseFirestore.instance
                .collection('AssignedJobs')
                .doc(widget.assignedJobId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading job details: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data();
          if (data == null) {
            return const Center(child: Text('Job details not found'));
          }

          // Map AssignedJobs fields to our expected structure
          final jobDetails = {
            'jobName': data['jobTitle'] ?? 'No Title',
            'jobLocation': data['jobLocation'] ?? 'No Location',
            'budget':
                data['budget']?.toString() ??
                data['jobPrice']?.toString() ??
                'Not Specified',
            'jobDescription': data['jobDescription'] ?? 'No Description',
            'createdAt': data['jobCreatedAt'],
            'urgency': 'Normal',
            'estimatedDuration': 'Not Specified',
            'serviceType': data['jobServiceType'] ?? 'Not Specified',
            'jobImage': data['jobImage'] ?? '',
          };

          // Try to cache the budget from the main document if valid
          final mainDocBudget = jobDetails['budget']!;
          if (mainDocBudget != 'Not Specified' &&
              mainDocBudget != '0' &&
              mainDocBudget != 'null') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _cacheBudget(mainDocBudget);
            });
          }

          final skilledWorkerDetails = {
            'skilledWorkerName': data['workerName'] ?? 'Unknown',
            'phoneNumber': data['workerPhone'] ?? 'Not Available',
            'skilledWorkerCity': data['workerCity'] ?? 'Not Specified',
            'averageRating': data['workerRating']?.toString() ?? 'No Rating',
            'skilledWorkerExperience':
                data['workerExperience'] ?? 'Not Specified',
            'hourlyRate': 'Not Specified',
            'skilledWorkerDescription': 'Skilled Worker',
            'profileImage': data['workerProfileImage'] ?? '',
          };

          final jobPosterDetails = {
            'name': data['jobPosterName'] ?? 'Unknown',
            'phoneNumber': data['jobPosterPhone'] ?? 'Not Available',
            'email': 'Not Available',
            'address': data['jobLocation'] ?? 'Not Specified',
          };

          final status = data['assignmentStatus'] as String? ?? 'unknown';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildGlassCard(
                  title: "Job Details",
                  children: [
                    _buildInfoRow(
                      "📌 Job Title",
                      jobDetails['jobName'] ?? 'No Title',
                    ),
                    _buildInfoRow(
                      "📍 Location",
                      jobDetails['jobLocation'] ?? 'No Location',
                    ),
                    _buildBudgetStreamRow(
                      "💰 Budget",
                      jobDetails['budget']!,
                      widget.assignedJobId,
                    ),
                    _buildInfoRow(
                      "📝 Description",
                      jobDetails['jobDescription'] ?? 'No Description',
                    ),
                    _buildInfoRow(
                      "📅 Created",
                      _formatDate(jobDetails['createdAt']),
                    ),
                    _buildInfoRow(
                      "⚡ Urgency",
                      jobDetails['urgency'] ?? 'Normal',
                    ),
                    _buildInfoRow(
                      "⏱️ Duration",
                      jobDetails['estimatedDuration'] ?? 'Not Specified',
                    ),
                    _buildInfoRow("📊 Status", status.toUpperCase()),
                  ],
                ),

                const SizedBox(height: 20),

                // Skilled Worker Details Card
                _buildGlassCard(
                  title: "Skilled Worker Details",
                  children: [
                    _buildInfoRow(
                      "👤 Name",
                      skilledWorkerDetails['skilledWorkerName'] ?? 'Unknown',
                    ),
                    _buildInfoRow(
                      "📞 Phone",
                      skilledWorkerDetails['phoneNumber'] ?? 'Not Available',
                    ),
                    _buildInfoRow(
                      "🏙️ City",
                      skilledWorkerDetails['skilledWorkerCity'] ??
                          'Not Specified',
                    ),
                    _buildInfoRow(
                      "⭐ Rating",
                      skilledWorkerDetails['averageRating']?.toString() ??
                          'No Rating',
                    ),
                    _buildInfoRow(
                      "💼 Experience",
                      skilledWorkerDetails['skilledWorkerExperience'] ??
                          'Not Specified',
                    ),
                    _buildInfoRow(
                      "💰 Rate",
                      skilledWorkerDetails['hourlyRate']?.toString() ??
                          'Not Specified',
                    ),
                    _buildInfoRow(
                      "📋 Description",
                      skilledWorkerDetails['skilledWorkerDescription'] ??
                          'No Description',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Job Poster Details Card (if available)
                if (jobPosterDetails.isNotEmpty)
                  _buildGlassCard(
                    title: "Job Poster Details",
                    children: [
                      _buildInfoRow(
                        "👤 Name",
                        jobPosterDetails['name'] ?? 'Unknown',
                      ),
                      _buildInfoRow(
                        "📞 Phone",
                        jobPosterDetails['phoneNumber'] ?? 'Not Available',
                      ),
                      _buildInfoRow(
                        "📧 Email",
                        jobPosterDetails['email'] ?? 'Not Available',
                      ),
                      _buildInfoRow(
                        "📍 Address",
                        jobPosterDetails['address'] ?? 'Not Specified',
                      ),
                    ],
                  ),

                const SizedBox(height: 30),

                // Action Buttons - Different for each user type
                if (widget.userType == 'skilled_worker') ...[
                  // Skilled Worker Buttons
                  _neonButton(
                    text: "Job Approval",
                    color: Colors.blue,
                    onTap: () {
                      _requestJobApproval(context, data);
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _neonButton(
                          text: "Call",
                          color: Colors.green,
                          onTap: () {
                            _makePhoneCall(
                              context,
                              jobPosterDetails['phoneNumber'],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _neonButton(
                          text: "Navigate",
                          color: Colors.blue,
                          onTap: () {
                            _navigateToJobDetail(context, data['jobId']);
                          },
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Job Poster Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _neonButton(
                          text: "Track Worker",
                          color: Colors.green,
                          onTap: () {
                            _trackWorker(context, data);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _neonButton(
                          text: "Complete Job",
                          color: Colors.green,
                          onTap: () {
                            _completeJob(context, widget.assignedJobId);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _neonButton(
                          text: "Cancel Job",
                          color: Colors.red,
                          onTap: () {
                            _cancelJob(context, widget.assignedJobId);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Glassmorphic Card
  Widget _buildGlassCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _neonButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetStreamRow(
    String label,
    String originalBudget,
    String assignedJobId,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('JobPayments')
                      .where('assignedJobId', isEqualTo: assignedJobId)
                      .snapshots(),
              builder: (context, snapshot) {
                // If waiting, try to show cached budget if available
                if (snapshot.connectionState == ConnectionState.waiting) {
                  if (_cachedBudget != null) {
                    return Text(
                      "Rs. $_cachedBudget (Cached)",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    );
                  }
                  return const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                String displayAmount = originalBudget;
                Color textColor = Colors.black54;
                FontWeight fontWeight = FontWeight.normal;
                bool isPending = false;

                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final docs = snapshot.data!.docs;
                  final validDocs =
                      docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final a = data['amount']?.toString() ?? '0';
                        return a != '0' &&
                            a != 'Not Specified' &&
                            a != 'null' &&
                            a.isNotEmpty;
                      }).toList();

                  final validDoc =
                      validDocs.isNotEmpty ? validDocs.first : docs.first;
                  final data = validDoc.data() as Map<String, dynamic>;
                  final status = data['status'] as String? ?? '';
                  final amount = data['amount']?.toString() ?? '0';

                  if (amount != '0' &&
                      amount != 'Not Specified' &&
                      amount != 'null' &&
                      amount.isNotEmpty) {
                    displayAmount = amount;
                  }

                  if (status == 'pending_admin_approval') {
                    isPending = true;
                  } else if ([
                    'payment_approved',
                    'approved',
                    'completed',
                  ].contains(status)) {
                    textColor = Colors.green;
                    fontWeight = FontWeight.bold;
                  }
                }

                // If displayAmount is still default/zero, try cache
                if ((displayAmount == '0' ||
                        displayAmount == 'Not Specified' ||
                        displayAmount == 'null') &&
                    _cachedBudget != null) {
                  displayAmount = _cachedBudget!;
                }

                // Cache the value if we found a good one from stream/original
                if (displayAmount != '0' &&
                    displayAmount != 'Not Specified' &&
                    displayAmount != 'null' &&
                    displayAmount != _cachedBudget) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _cacheBudget(displayAmount);
                  });
                }

                if (isPending &&
                    displayAmount != '0' &&
                    displayAmount != 'Not Specified') {
                  return Text(
                    "Rs. $displayAmount (Pending)",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rs. $displayAmount",
                      style: TextStyle(
                        fontSize: 16,
                        color: textColor,
                        fontWeight: fontWeight,
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not Available';
    try {
      if (date is Timestamp) {
        return '${date.toDate().day}/${date.toDate().month}/${date.toDate().year}';
      }
      return date.toString();
    } catch (e) {
      return 'Date not available';
    }
  }

  void _makePhoneCall(BuildContext context, String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $phoneNumber...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _updateJobStatus(
    BuildContext context,
    String assignedJobId,
    String currentStatus,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Job status update functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _completeJob(BuildContext context, String assignedJobId) {
    Navigator.pushNamed(
      context,
      '/rate-skilled-worker',
      arguments: {'assignedJobId': assignedJobId, 'isJobCompletion': true},
    );
  }

  void _cancelJob(BuildContext context, String assignedJobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Job'),
            content: const Text(
              'Are you sure you want to cancel this job? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('AssignedJobs')
            .doc(assignedJobId)
            .update({
              'assignmentStatus': 'cancelled',
              'isActive': false,
              'cancelledAt': FieldValue.serverTimestamp(),
            });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job cancelled successfully'),
              backgroundColor: Colors.red,
            ),
          );

          Navigator.pushNamedAndRemoveUntil(
            context,
            widget.userType == 'skilled_worker'
                ? '/skilled-worker-home'
                : '/job-poster-home',
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error cancelling job: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _trackWorker(
    BuildContext context,
    Map<String, dynamic> assignedJobData,
  ) {
    final workerId = assignedJobData['workerId'] as String?;
    final jobTitle = assignedJobData['jobTitle'] ?? 'Job';
    final jobLocation = assignedJobData['jobLocation'] ?? 'Job Location';

    final jobLocationCoordinates =
        assignedJobData['jobLocationCoordinates'] as Map<String, dynamic>?;
    final jobLat = jobLocationCoordinates?['latitude'] as double? ?? 0.0;
    final jobLng = jobLocationCoordinates?['longitude'] as double? ?? 0.0;

    if (workerId != null && workerId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WorkerTrackingScreen(
                workerId: workerId,
                jobTitle: jobTitle,
                jobLocation: jobLocation,
                jobLatitude: jobLat,
                jobLongitude: jobLng,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Worker ID not available for tracking'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToJobDetail(BuildContext context, String? jobId) async {
    try {
      final assignedJobDoc =
          await FirebaseFirestore.instance
              .collection('AssignedJobs')
              .doc(widget.assignedJobId)
              .get();

      if (assignedJobDoc.exists) {
        final assignedJobData = assignedJobDoc.data()!;

        final jobTitle = assignedJobData['jobTitle'] ?? 'Job';
        final jobLocation = assignedJobData['jobLocation'] ?? 'Job Location';
        final jobIdFromAssigned = assignedJobData['jobId'] as String?;

        final jobLocationCoordinates =
            assignedJobData['jobLocationCoordinates'] as Map<String, dynamic>?;
        final lat = jobLocationCoordinates?['latitude'] as double? ?? 0.0;
        final lng = jobLocationCoordinates?['longitude'] as double? ?? 0.0;

        print('🔍 Coordinates from AssignedJobs - Lat: $lat, Lng: $lng');

        if (lat != 0.0 && lng != 0.0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => NavigateToJobScreen(
                    jobId: jobIdFromAssigned ?? 'unknown',
                    jobTitle: jobTitle,
                    jobAddress: jobLocation,
                    jobLatitude: lat,
                    jobLongitude: lng,
                  ),
            ),
          );
        } else {
          print('❌ Invalid coordinates: lat=$lat, lng=$lng');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Job location coordinates not available in assigned job',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Assigned job not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error navigating to job: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSkilledWorkerDrawer(BuildContext context) {
    return Drawer(
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
            leading: const Icon(Icons.star_rate, color: Colors.amber),
            title: const Text('Rate Job Poster'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/skilled-worker-rate-poster');
            },
          ),
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
    );
  }

  void _showContactUsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const ContactUsDialog());
  }

  Future<void> _requestJobApproval(
    BuildContext context,
    Map<String, dynamic>? data,
  ) async {
    if (data == null) return;

    final String? assignedJobId = data['assignedJobId'] ?? widget.assignedJobId;
    final String? jobId = data['jobId'];
    final String? workerId = data['workerId'];
    final String? posterId = data['jobPosterId'];
    final String? jobTitle = data['jobTitle'];

    if (assignedJobId == null || jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Missing job information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final existingQuery =
          await FirebaseFirestore.instance
              .collection('JobPayments')
              .where('assignedJobId', isEqualTo: assignedJobId)
              .where('status', isEqualTo: 'pending_admin_approval')
              .get();

      if (existingQuery.docs.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Approval request is already pending review by Admin.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await FirebaseFirestore.instance.collection('JobPayments').add({
        'assignedJobId': assignedJobId,
        'jobId': jobId,
        'workerId': workerId,
        'posterId': posterId,
        'jobTitle': jobTitle,
        'status': 'pending_admin_approval',
        'requestedBy': 'skilled_worker',
        'requestedAt': FieldValue.serverTimestamp(),
        'amount': data['budget'] ?? data['jobPrice'],
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Job Approval Sent! Admin will review and add payment.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('role');
        await prefs.remove('userId');
        await prefs.remove('phoneNumber');
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/role-selection', (route) => false);
      }
    }
  }
}
