import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'job_poster_rate_worker_screen.dart';

class JobAcceptedDetailsScreen extends StatefulWidget {
  final String jobId;
  final String requestId;

  const JobAcceptedDetailsScreen({
    super.key,
    required this.jobId,
    required this.requestId,
  });

  @override
  State<JobAcceptedDetailsScreen> createState() =>
      _JobAcceptedDetailsScreenState();
}

class _JobAcceptedDetailsScreenState extends State<JobAcceptedDetailsScreen> {
  bool jobCancelled = false;
  String? _skilledWorkerId;

  @override
  void initState() {
    super.initState();
    _loadWorkerId();
  }

  Future<void> _loadWorkerId() async {
    try {
      final requestDoc =
          await FirebaseFirestore.instance
              .collection('AssignedJobs')
              .doc(widget.requestId)
              .get();

      if (requestDoc.exists) {
        final requestData = requestDoc.data();
        setState(() {
          _skilledWorkerId =
              requestData?['workerId'] ?? requestData?['skilledWorkerId'];
        });
      }
    } catch (e) {
      print('Error loading worker ID: $e');
    }
  }

  void _onJobCompleted() async {
    try {
      final requestDoc =
          await FirebaseFirestore.instance
              .collection('AssignedJobs')
              .doc(widget.requestId)
              .get();

      final requestData = requestDoc.data();

      // Only pass the worker document ID; next screen fetches fresh details
      final String skilledWorkerId =
          (requestData?['skilledWorkerId'] ?? requestData?['workerId'] ?? '')
              .toString();

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => JobPosterRateWorkerScreen(
                  skilledWorkerDetails: {'docId': skilledWorkerId},
                  requestId: widget.requestId,
                ),
          ),
        );
      }
    } catch (e) {
      print('Error getting skilled worker details: $e');
    }
  }

  void _onCancelJob() {
    setState(() {
      jobCancelled = true;
    });
    // TODO: Add backend cancel logic
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jobId.isEmpty || widget.requestId.isEmpty) {
      return _buildErrorScreen(
        "Invalid Job Data",
        "Job ID or Request ID is missing. Please try again.",
      );
    }

    if (jobCancelled) {
      return _buildErrorScreen("Job Cancelled", "This job has been cancelled.");
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 6,
        shadowColor: Colors.green.withOpacity(0.2),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "Job & Applicant Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Decorative circles
            Positioned(
              top: -80,
              left: -60,
              child: _buildCircle(180, Colors.green.withOpacity(0.15)),
            ),
            Positioned(
              bottom: -100,
              right: -80,
              child: _buildCircle(220, Colors.greenAccent.withOpacity(0.1)),
            ),

            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance
                      .collection('AssignedJobs')
                      .doc(widget.requestId)
                      .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final d = snap.data!.data() ?? <String, dynamic>{};

                String jobTitle =
                    (d['jobTitle'] ?? d['title'] ?? '').toString().trim();
                if (jobTitle.isEmpty) jobTitle = 'No Title';
                final jobDescription =
                    (d['jobDescription'] ?? '').toString().trim().isNotEmpty
                        ? d['jobDescription'].toString()
                        : 'No Description';
                final jobLocation =
                    (d['jobLocationAddress'] ??
                            d['jobLocation'] ??
                            'No Location')
                        .toString();
                final jobCurrency = (d['jobCurrency'] ?? 'PKR').toString();
                final jobPrice = d['jobPrice']?.toString() ?? 'Not Specified';
                final jobServiceType = (d['jobServiceType'] ?? '').toString();
                final jobStatus = (d['jobStatus'] ?? '').toString();
                final posterPhone = (d['jobPosterPhone'] ?? '').toString();
                final workerName =
                    (d['workerName'] ?? d['skilledWorkerName'] ?? '')
                        .toString();
                final workerPhone =
                    (d['workerPhone'] ?? d['skilledWorkerPhone'] ?? '')
                        .toString();
                final jobImageUrl = (d['jobImage'] ?? '').toString();
                final workerImageUrl =
                    (d['workerProfileImage'] ??
                            d['skilledWorkerProfileImage'] ??
                            '')
                        .toString();
                final workerCity = (d['workerCity'] ?? '').toString();
                final workerSkills =
                    (d['workerSkills'] is List)
                        ? (d['workerSkills'] as List)
                            .whereType<String>()
                            .toList()
                        : <String>[];
                // Assignment status/timestamps removed from UI per request

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildGlassCard(
                        title: "Job Details",
                        children: [
                          if (jobImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                jobImageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const SizedBox(),
                              ),
                            ),
                          if (jobImageUrl.isNotEmpty)
                            const SizedBox(height: 12),
                          _buildInfoRow("📌 Title", jobTitle),
                          _buildInfoRow("📝 Description", jobDescription),
                          _buildInfoRow("📍 Location", jobLocation),
                          _buildInfoRow(
                            "🧰 Service Type",
                            jobServiceType.isEmpty ? '-' : jobServiceType,
                          ),
                          _buildInfoRow(
                            "💰 Budget",
                            jobPrice == 'Not Specified'
                                ? jobPrice
                                : '$jobCurrency $jobPrice',
                          ),
                          _buildInfoRow(
                            "📄 Job Status",
                            jobStatus.isEmpty ? '-' : jobStatus,
                          ),
                          _buildInfoRow(
                            "📞 Poster Phone",
                            posterPhone.isEmpty ? '-' : posterPhone,
                          ),
                          // Removed: Assignment Status, Assigned At, Created At
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGlassCard(
                        title: "Skilled Worker",
                        children: [
                          if (workerImageUrl.isNotEmpty)
                            Center(
                              child: CircleAvatar(
                                radius: 36,
                                backgroundImage: NetworkImage(workerImageUrl),
                              ),
                            ),
                          if (workerImageUrl.isNotEmpty)
                            const SizedBox(height: 12),
                          _buildInfoRow(
                            "👷 Name",
                            workerName.isEmpty ? '-' : workerName,
                          ),
                          _buildInfoRow(
                            "📞 Phone",
                            workerPhone.isEmpty ? '-' : workerPhone,
                          ),
                          if (workerCity.isNotEmpty)
                            _buildInfoRow("🏙️ City", workerCity),
                          if (workerSkills.isNotEmpty)
                            _buildInfoRow(
                              "🛠️ Skills",
                              workerSkills.join(', '),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (_skilledWorkerId != null)
                        _neonButton(
                          text: "📍 Track Worker Location",
                          color: Colors.blueAccent,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/worker-tracking',
                              arguments: {
                                'jobId': widget.jobId,
                                'workerId': _skilledWorkerId,
                              },
                            );
                          },
                        ),
                      const SizedBox(height: 30),

                      Row(
                        children: [
                          Expanded(
                            child: _neonButton(
                              text: "Complete Job",
                              color: Colors.green,
                              onTap: _onJobCompleted,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _neonButton(
                              text: "Cancel Job",
                              color: Colors.redAccent,
                              onTap: _onCancelJob,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Error screen
  Widget _buildErrorScreen(String title, String message) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Decorative Circle
  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
    );
  }

  // Glass card
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

  // Info Row
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

  // Neon Button
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
        margin: const EdgeInsets.only(bottom: 12),
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
}
