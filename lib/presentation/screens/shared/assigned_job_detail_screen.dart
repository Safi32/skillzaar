import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/location_tracking_service.dart';
import '../job_poster/job_poster_rate_worker_screen.dart';
import '../skilled_worker/navigate_to_job_screen.dart';
import 'worker_tracking_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/skilled_worker_drawer_header.dart';
import '../../widgets/contact_us_dialog.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

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
  Timer? _locationUpdateTimer;
  String? _locationWorkerId;
  bool _navigatedToPosterRating = false;

  @override
  void initState() {
    super.initState();
    _loadCachedBudget();
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
    super.dispose();
  }

  Future<void> _loadCachedBudget() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _cachedBudget = prefs.getString('budget_${widget.assignedJobId}');
      });
    }
  }

  void _startPeriodicLocationUpdatesForWorker(String workerId) {
    // Avoid restarting timer if already tracking same worker
    if (_locationWorkerId == workerId && _locationUpdateTimer != null) {
      return;
    }

    _locationWorkerId = workerId;
    _locationUpdateTimer?.cancel();

    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (
      _,
    ) async {
      if (!mounted) return;

      try {
        final position = await LocationTrackingService().getCurrentLocation();
        if (position == null) return;

        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(workerId)
            .update({
              'currentLatitude': position.latitude,
              'currentLongitude': position.longitude,
              'lastLocationUpdate': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        log('Error updating worker lat/lng for $workerId: $e');
      }
    });
  }

  Future<void> _cacheBudget(String value) async {
    log('Caching budget: $value for job: ${widget.assignedJobId}');
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.green.withOpacity(0.2),
        centerTitle: true,
        title: Text(
          l10n.assignedJobDetails,
          style: const TextStyle(
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

          // For skilled workers viewing their assigned job, start periodic
          // location updates to SkilledWorkers.currentLatitude/currentLongitude.
          if (widget.userType == 'skilled_worker') {
            final workerId = data['workerId'] as String?;
            if (workerId != null && workerId.isNotEmpty) {
              _startPeriodicLocationUpdatesForWorker(workerId);
            }
          }

          // Map AssignedJobs fields to our expected structure
          final jobDetails = {
            'jobName': _localizeValue(data['jobTitle'], l10n, l10n.noTitle),
            'jobLocation': _localizeValue(
              data['jobLocation'],
              l10n,
              l10n.noLocation,
            ),
            'budget': _localizeValue(
              data['budget']?.toString() ?? data['jobPrice']?.toString(),
              l10n,
              l10n.notSpecified,
            ),
            'jobDescription': _localizeValue(
              data['jobDescription'],
              l10n,
              l10n.noDescription,
            ),
            'createdAt': data['jobCreatedAt'],
            'urgency': _localizeValue(
              data['urgency'],
              l10n,
              l10n.normalUrgency,
            ),
            'estimatedDuration': _localizeValue(
              data['estimatedDuration'],
              l10n,
              l10n.notSpecified,
            ),
            'serviceType': _localizeValue(
              data['jobServiceType'],
              l10n,
              l10n.notSpecified,
            ),
            'jobImage': data['jobImage'] ?? '',
          };

          // Try to cache the budget from the main document if valid
          final mainDocBudget = jobDetails['budget']!;
          if (mainDocBudget != l10n.notSpecified &&
              mainDocBudget != '0' &&
              mainDocBudget != 'null') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _cacheBudget(mainDocBudget);
            });
          }

          final skilledWorkerDetails = {
            'skilledWorkerName': _localizeValue(
              data['workerName'],
              l10n,
              l10n.unknown,
            ),
            'phoneNumber': _localizeValue(
              data['workerPhone'],
              l10n,
              l10n.notAvailable,
            ),
            'skilledWorkerCity': _localizeValue(
              data['workerCity'],
              l10n,
              l10n.notSpecified,
            ),
            'averageRating':
                (data['workerRating'] is num)
                    ? (data['workerRating'] as num).toDouble().toStringAsFixed(
                      1,
                    )
                    : _localizeValue(
                      data['workerRating']?.toString(),
                      l10n,
                      l10n.noRating,
                    ),
            'skilledWorkerExperience': _localizeValue(
              data['workerExperience'],
              l10n,
              l10n.notSpecified,
            ),
            'hourlyRate': _localizeValue(
              data['hourlyRate']?.toString(),
              l10n,
              l10n.notSpecified,
            ),
            'skilledWorkerDescription': _localizeValue(
              data['workerDescription'],
              l10n,
              l10n.skilledWorkerText,
            ),
            'profileImage': data['workerProfileImage'] ?? '',
          };

          String? _formatRating(dynamic value) {
            if (value == null) return null;
            if (value is num) return value.toDouble().toStringAsFixed(1);
            final s = value.toString().trim();
            final d = double.tryParse(s);
            if (d == null) return s;
            return d.toStringAsFixed(1);
          }

          final jobPosterDetails = {
            'name': _localizeValue(data['jobPosterName'], l10n, l10n.unknown),
            'phoneNumber': _localizeValue(
              data['jobPosterPhone'],
              l10n,
              l10n.notAvailable,
            ),
            'email': _localizeValue(
              data['jobPosterEmail'],
              l10n,
              l10n.notAvailable,
            ),
            'address': _localizeValue(
              data['jobLocation'],
              l10n,
              l10n.notSpecified,
            ),
            'averageRating': _formatRating(
              data['jobPosterRating'] ??
                  data['jobPosterAverageRating'] ??
                  data['jobPosterDetails']?['averageRating'] ??
                  data['jobPosterDetails']?['rating'],
            ),
          };

          final status = data['assignmentStatus'] as String? ?? 'unknown';

          final workerRatingCompleted =
              (data['workerRatingCompleted'] as bool?) ?? false;

          if (widget.userType == 'skilled_worker' &&
              status == 'completed' &&
              !workerRatingCompleted &&
              !_navigatedToPosterRating) {
            _navigatedToPosterRating = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.pushNamed(
                context,
                '/rate-job-poster',
                arguments: {
                  'assignedJobId': widget.assignedJobId,
                  'isJobCompletion': true,
                },
              );
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildGlassCard(
                  title: l10n.jobDetailsText,
                  children: [
                    _buildInfoRow(
                      "📌 ${l10n.jobTitleText}",
                      jobDetails['jobName'] ?? l10n.noTitle,
                    ),
                    _buildInfoRow(
                      "📍 ${l10n.locationText}",
                      jobDetails['jobLocation'] ?? l10n.noLocation,
                    ),
                    _buildBudgetStreamRow(
                      "💰 ${l10n.budgetText}",
                      jobDetails['budget']! == '0'
                          ? (_cachedBudget ?? '0')
                          : jobDetails['budget']!,
                      widget.assignedJobId,
                      l10n,
                    ),
                    _buildInfoRow(
                      "📝 ${l10n.descriptionText}",
                      jobDetails['jobDescription'] ?? l10n.noDescription,
                    ),
                    _buildInfoRow(
                      "📅 ${l10n.createdText}",
                      _formatDate(jobDetails['createdAt']),
                    ),
                    _buildInfoRow(
                      "⚡ ${l10n.urgencyText}",
                      jobDetails['urgency'] ?? l10n.normalUrgency,
                    ),
                    _buildInfoRow(
                      "⏱️ ${l10n.durationText}",
                      jobDetails['estimatedDuration'] ?? l10n.notSpecified,
                    ),
                    _buildInfoRow(
                      "📊 ${l10n.statusText}",
                      _getLocalizedStatus(status, l10n).toUpperCase(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Skilled Worker Details Card
                _buildGlassCard(
                  title: l10n.skilledWorkerDetailsText,
                  children: [
                    _buildInfoRow(
                      "👤 ${l10n.nameText}",
                      skilledWorkerDetails['skilledWorkerName'] ?? l10n.unknown,
                    ),
                    _buildInfoRow(
                      "📞 ${l10n.phoneText}",
                      skilledWorkerDetails['phoneNumber'] ?? l10n.notAvailable,
                    ),
                    _buildInfoRow(
                      "🏙️ ${l10n.cityText}",
                      skilledWorkerDetails['skilledWorkerCity'] ??
                          l10n.notSpecified,
                    ),
                    _buildInfoRow(
                      "⭐ ${l10n.ratingText}",
                      skilledWorkerDetails['averageRating']?.toString() ??
                          l10n.noRating,
                    ),
                    _buildInfoRow(
                      "💼 ${l10n.experienceLabel}",
                      skilledWorkerDetails['skilledWorkerExperience'] ??
                          l10n.notSpecified,
                    ),
                    _buildInfoRow(
                      "💰 ${l10n.rateText}",
                      skilledWorkerDetails['hourlyRate']?.toString() ??
                          l10n.notSpecified,
                    ),
                    _buildInfoRow(
                      "📋 ${l10n.descriptionText}",
                      skilledWorkerDetails['skilledWorkerDescription'] ??
                          l10n.noDescription,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Job Poster Details Card (if available)
                if (jobPosterDetails.isNotEmpty)
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future:
                        FirebaseFirestore.instance
                            .collection('JobPosters')
                            .doc(data['jobPosterId'] ?? '')
                            .get(),
                    builder: (context, posterSnap) {
                      final posterData = posterSnap.data?.data();
                      final posterRating = _formatRating(
                        posterData?['averageRating'] ??
                            posterData?['rating'] ??
                            data['jobPosterRating'] ??
                            data['jobPosterAverageRating'],
                      );

                      return _buildGlassCard(
                        title: l10n.jobPosterDetailsText,
                        children: [
                          _buildInfoRow(
                            "👤 ${l10n.nameText}",
                            jobPosterDetails['name'] ?? l10n.unknown,
                          ),
                          _buildInfoRow(
                            "📞 ${l10n.phoneText}",
                            jobPosterDetails['phoneNumber'] ??
                                l10n.notAvailable,
                          ),
                          _buildInfoRow(
                            "⭐ ${l10n.ratingText}",
                            posterRating?.toString() ?? l10n.noRating,
                          ),
                          _buildInfoRow(
                            "📧 ${l10n.emailText}",
                            jobPosterDetails['email'] ?? l10n.notAvailable,
                          ),
                          _buildInfoRow(
                            "📍 ${l10n.addressText}",
                            jobPosterDetails['address'] ?? l10n.notSpecified,
                          ),
                        ],
                      );
                    },
                  ),

                const SizedBox(height: 30),

                // Action Buttons - Different for each user type
                if (widget.userType == 'skilled_worker') ...[
                  // Skilled Worker Buttons
                  if (status == 'completed' && !workerRatingCompleted) ...[
                    _neonButton(
                      text: l10n.rateJobPoster,
                      color: Colors.green,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/rate-job-poster',
                          arguments: {
                            'assignedJobId': widget.assignedJobId,
                            'isJobCompletion': true,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildJobApprovalButton(context, data),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _neonButton(
                          text: l10n.callText,
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
                          text: l10n.navigateText,
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
                          text: l10n.trackWorker,
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
                          text: l10n.completeJob,
                          color: Colors.green,
                          onTap: () {
                            final workerId =
                                (data['workerId'] ?? data['skilledWorkerId'])
                                    ?.toString();
                            if (workerId == null || workerId.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Worker information missing. Cannot complete job.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => JobPosterRateWorkerScreen(
                                      skilledWorkerDetails: {
                                        'docId': workerId.trim(),
                                      },
                                      requestId: widget.assignedJobId,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _neonButton(
                          text: l10n.cancelJobText,
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

  Widget _buildJobApprovalButton(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('JobPayments')
              .where('assignedJobId', isEqualTo: widget.assignedJobId)
              .snapshots(),
      builder: (context, snapshot) {
        String buttonText = l10n.jobApproval;
        Color buttonColor = Colors.blue;
        VoidCallback onTap;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final docs = snapshot.data!.docs;
          final latest = docs.first;
          final paymentData = latest.data() as Map<String, dynamic>;
          final status = paymentData['status'] as String? ?? '';

          if (status == 'pending_admin_approval') {
            buttonText = l10n.approvalPendingText;
            buttonColor = Colors.grey;
            onTap = () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Approval already sent. Waiting for admin to add budget.',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            };
          } else if ([
            'payment_approved',
            'approved',
            'completed',
          ].contains(status)) {
            buttonText = l10n.paymentApprovedText;
            buttonColor = Colors.green;
            onTap = () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment already approved for this job.'),
                  backgroundColor: Colors.green,
                ),
              );
            };
          } else {
            buttonText = l10n.approvalPendingText;
            buttonColor = Colors.grey;
            onTap = () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Approval already requested (status: $status).',
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            };
          }
        } else {
          onTap = () {
            _requestJobApproval(context, data);
          };
        }

        return _neonButton(text: buttonText, color: buttonColor, onTap: onTap);
      },
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
    AppLocalizations l10n,
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
                            a != l10n.notSpecified &&
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
                      amount != l10n.notSpecified &&
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
                        displayAmount == l10n.notSpecified ||
                        displayAmount == 'Not Specified' ||
                        displayAmount == 'null') &&
                    _cachedBudget != null) {
                  displayAmount = _cachedBudget!;
                }

                // Cache the value if we found a good one from stream/original
                if (displayAmount != '0' &&
                    displayAmount != l10n.notSpecified &&
                    displayAmount != 'Not Specified' &&
                    displayAmount != 'null' &&
                    displayAmount != _cachedBudget) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _cacheBudget(displayAmount);
                  });
                }

                if (isPending &&
                    displayAmount != '0' &&
                    displayAmount != l10n.notSpecified &&
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

  void _cancelJob(BuildContext context, String assignedJobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.cancelJobText),
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
    final l10n = AppLocalizations.of(context)!;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SkilledWorkerDrawerHeader(),
          ListTile(
            leading: const Icon(Icons.contact_support, color: Colors.green),
            title: Text(l10n.contactUs),
            onTap: () {
              Navigator.pop(context);
              _showContactUsDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rate, color: Colors.amber),
            title: Text(l10n.rateJobPoster),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/skilled-worker-rate-poster');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n.logout),
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
              .limit(1)
              .get();

      if (existingQuery.docs.isNotEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'An approval/payment record already exists for this job.',
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

  String _getLocalizedStatus(String status, AppLocalizations l10n) {
    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.statusPending;
      case 'completed':
        return l10n.statusCompleted;
      case 'active':
        return l10n.statusActive;
      case 'inactive':
        return l10n.statusInactive;
      case 'assigned':
        return l10n.statusAssigned;
      case 'approved':
        return l10n.statusApproved;
      case 'cancelled':
        return l10n.statusCancelled;
      default:
        return status;
    }
  }

  String _localizeValue(String? value, AppLocalizations l10n, String fallback) {
    if (value == null || value.trim().isEmpty || value == 'null')
      return fallback;
    final lower = value.toLowerCase().trim();
    bool isUrdu = l10n.contactUs == 'ہم سے رابطہ کریں';
    if (lower == 'not specified') return l10n.notSpecified;
    if (lower == 'normal') return l10n.normalUrgency;
    if (lower == 'unknown') return l10n.unknown;
    if (lower == 'not available') return l10n.notAvailable;
    if (lower == 'no rating') return l10n.noRating;
    if (lower == 'skilled worker') return l10n.skilledWorkerText;
    if (lower == 'no title') return l10n.noTitle;
    if (lower == 'no location') return l10n.noLocation;
    if (lower == 'no description') return l10n.noDescription;
    if (lower == 'cleaning services') return l10n.cleaningServices;
    if (lower == 'plumbing services') return l10n.plumbingServices;
    if (lower == 'roofing services') return l10n.roofingServices;
    if (lower == 'electrical services') return l10n.electricalServices;
    if (lower == 'car care services') return l10n.carCareServices;
    if (lower == 'islamabad') return isUrdu ? 'اسلام آباد' : 'Islamabad';
    if (lower == 'lahore') return isUrdu ? 'لاہور' : 'Lahore';
    if (lower == 'karachi') return isUrdu ? 'کراچی' : 'Karachi';
    if (lower == 'rawalpindi') return isUrdu ? 'راولپنڈی' : 'Rawalpindi';
    if (lower == 'peshawar') return isUrdu ? 'پشاور' : 'Peshawar';
    return value;
  }
}
