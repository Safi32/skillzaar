import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/job_request_service.dart';

class JobDetailScreen extends StatelessWidget {
  final String jobId;
  final String requestId;

  const JobDetailScreen({
    super.key,
    required this.jobId,
    required this.requestId,
  });

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
            // Decorative background
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

            // Stream for job details
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: JobRequestService.streamJobDoc(jobId),
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
                                    .doc(requestId)
                                    .get(),
                            builder: (context, snap) {
                              if (!snap.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final req =
                                  snap.data?.data() as Map<String, dynamic>?;

                              final fallbackName =
                                  (req?['skilledWorkerName'] ?? 'Unknown')
                                      .toString();
                              final fallbackPhone =
                                  (req?['skilledWorkerPhone'] ?? 'Unknown')
                                      .toString();
                              final skilledWorkerId =
                                  (req?['skilledWorkerId'] ??
                                          req?['workerId'] ??
                                          req?['uid'] ??
                                          req?['userId'])
                                      ?.toString();

                              if (skilledWorkerId == null ||
                                  skilledWorkerId.isEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow("👤 Name", fallbackName),
                                    _buildInfoRow("📞 Phone", fallbackPhone),
                                  ],
                                );
                              }

                              return FutureBuilder<
                                DocumentSnapshot<Map<String, dynamic>>
                              >(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('SkilledWorkers')
                                        .doc(skilledWorkerId)
                                        .get(),
                                builder: (context, workerSnap) {
                                  final data = workerSnap.data?.data();
                                  final name =
                                      (data?['Name'] ??
                                              data?['displayName'] ??
                                              data?['name'] ??
                                              data?['FullName'] ??
                                              fallbackName)
                                          .toString();
                                  final phone =
                                      (data?['phoneNumber'] ??
                                              data?['userPhone'] ??
                                              data?['phone'] ??
                                              data?['skilledWorkerPhone'] ??
                                              data?['Phone'] ??
                                              fallbackPhone)
                                          .toString();

                                  if (workerSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildInfoRow("👤 Name", name),
                                      _buildInfoRow("📞 Phone", phone),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: _neonButton(
                              text: "✅ Complete Job",
                              color: Colors.green,
                              onTap: () {
                                // Navigate to rate worker
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _neonButton(
                              text: "❌ Cancel Job",
                              color: Colors.redAccent,
                              onTap: () {},
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

  // Decorative Circles
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
}
