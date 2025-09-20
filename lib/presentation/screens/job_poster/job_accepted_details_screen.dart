import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
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
              .collection('JobRequests')
              .doc(widget.requestId)
              .get();

      if (requestDoc.exists) {
        final requestData = requestDoc.data();
        setState(() {
          _skilledWorkerId = requestData?['skilledWorkerId'];
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
              .collection('JobRequests')
              .doc(widget.requestId)
              .get();

      final requestData = requestDoc.data();

      String applicantName = requestData?['skilledWorkerName'] ?? 'Unknown';
      String applicantPhone = requestData?['skilledWorkerPhone'] ?? 'Unknown';
      String applicantEmail = 'Not available';
      String skilledWorkerId = requestData?['skilledWorkerId'] ?? '';

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => JobPosterRateWorkerScreen(
                  skilledWorkerDetails: {
                    'name': applicantName,
                    'phone': applicantPhone,
                    'email': applicantEmail,
                    'id': skilledWorkerId,
                    'skilledWorkerId': skilledWorkerId,
                    'uid': skilledWorkerId,
                  },
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
              stream: JobRequestService.streamJobDoc(widget.jobId),
              builder: (context, jobSnap) {
                final jobData = jobSnap.data?.data();

                String jobTitle =
                    jobData?['title_en'] ?? jobData?['title_ur'] ?? "No Title";
                String jobDescription =
                    jobData?['description_en'] ??
                    jobData?['description_ur'] ??
                    "No Description";
                String jobLocation =
                    jobData?['Location'] ??
                    jobData?['Address'] ??
                    "No Location";
                String jobSalary =
                    jobData?['budget']?.toString() ?? "Not Specified";

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildGlassCard(
                        title: "Job Details",
                        children: [
                          _buildInfoRow("📌 Title", jobTitle),
                          _buildInfoRow("📝 Description", jobDescription),
                          _buildInfoRow("📍 Location", jobLocation),
                          _buildInfoRow("💰 Budget", jobSalary),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildGlassCard(
                        title: "Applicant Details",
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('JobRequests')
                                    .doc(widget.requestId)
                                    .get(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final req =
                                  snap.data?.data() as Map<String, dynamic>?;
                              String name =
                                  req?['skilledWorkerName'] ?? "Unknown";
                              String phone =
                                  req?['skilledWorkerPhone'] ?? "Unknown";
                              String email = "Not Available";

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow("👤 Name", name),
                                  _buildInfoRow("📞 Phone", phone),
                                  _buildInfoRow("📧 Email", email),
                                ],
                              );
                            },
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
                              text: "✅ Complete Job",
                              color: Colors.green,
                              onTap: _onJobCompleted,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _neonButton(
                              text: "❌ Cancel Job",
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
