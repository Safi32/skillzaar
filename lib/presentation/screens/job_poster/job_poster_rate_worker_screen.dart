import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/job_request_service.dart';

class JobPosterRateWorkerScreen extends StatefulWidget {
  final Map<String, dynamic> skilledWorkerDetails;
  final String? requestId;

  const JobPosterRateWorkerScreen({
    super.key,
    required this.skilledWorkerDetails,
    this.requestId,
  });

  @override
  State<JobPosterRateWorkerScreen> createState() =>
      _JobPosterRateWorkerScreenState();
}

class _JobPosterRateWorkerScreenState extends State<JobPosterRateWorkerScreen> {
  double rating = 4.0;
  String? selectedFeedback;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> feedbackOptions = [
    'Excellent work',
    'Very Good',
    'Good',
    'Average',
    'Poor',
  ];

  String _extractWorkerDocId() {
    final details = widget.skilledWorkerDetails;
    final dynamic direct =
        details['docId'] ??
        details['id'] ??
        details['skilledWorkerId'] ??
        details['uid'] ??
        details['workerId'] ??
        details['userId'];
    return (direct?.toString() ?? '').trim();
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final workerDocId = _extractWorkerDocId();
      if (workerDocId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Skilled worker not identified."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final submitted = await JobRequestService.submitSkilledWorkerRating(
        skilledWorkerId: workerDocId,
        rating: rating,
        feedback: selectedFeedback ?? _feedbackController.text,
        requestId: widget.requestId,
      );

      if (!submitted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to submit rating."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Mark AssignedJobs as completed and open worker rating flow
      if (widget.requestId != null && widget.requestId!.isNotEmpty) {
        try {
          final assignedRef = FirebaseFirestore.instance
              .collection('AssignedJobs')
              .doc(widget.requestId!);
          final assignedSnap = await assignedRef.get();

          await assignedRef.set({
            'assignmentStatus': 'completed',
            'isActive': false,
            'completedAt': FieldValue.serverTimestamp(),
            'rating': rating,
            'ratingComment': selectedFeedback ?? _feedbackController.text,
            'ratedBy': JobRequestService.getCurrentUserId(),
            'ratedAt': FieldValue.serverTimestamp(),
            'workerRatingCompleted': false, // worker must now rate poster
          }, SetOptions(merge: true));

          // Best-effort: clear worker activeJobId and poster activeJobId
          final data = assignedSnap.data() as Map<String, dynamic>?;
          final workerId = data?['workerId']?.toString();
          final posterId = data?['jobPosterId']?.toString();
          if (workerId != null && workerId.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('SkilledWorkers')
                .doc(workerId)
                .set({
                  'activeJobId': FieldValue.delete(),
                }, SetOptions(merge: true));
          }
          if (posterId != null && posterId.isNotEmpty) {
            await FirebaseFirestore.instance
                .collection('JobPosters')
                .doc(posterId)
                .set({
                  'activeJobId': FieldValue.delete(),
                }, SetOptions(merge: true));
          }
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Rating submitted! (${rating.toStringAsFixed(1)} stars)",
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/job-poster-home',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workerDocId = _extractWorkerDocId();

    return Scaffold(
      appBar: AppBar(title: const Text("Rate Skilled Worker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Worker Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (workerDocId.isNotEmpty)
                FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future:
                      FirebaseFirestore.instance
                          .collection('SkilledWorkers')
                          .doc(workerDocId)
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text("Worker not found.");
                    }

                    final data = snapshot.data!.data();
                    final String name =
                        (data?['Name'] ??
                                data?['displayName'] ??
                                data?['name'] ??
                                data?['FullName'] ??
                                '-')
                            .toString();
                    final String phone =
                        (data?['phoneNumber'] ??
                                data?['userPhone'] ??
                                data?['phone'] ??
                                data?['skilledWorkerPhone'] ??
                                data?['Phone'] ??
                                '-')
                            .toString();
                    final String city =
                        (data?['City'] ?? data?['city'] ?? '').toString();
                    final String? profileUrl =
                        (data?['ProfilePicture'] ??
                                data?['profileImage'] ??
                                data?['photoURL'] ??
                                data?['imageUrl'] ??
                                data?['skilledWorkerProfileImage'])
                            ?.toString();
                    return _buildWorkerCard(
                      name: name,
                      phone: phone,
                      city: city.isEmpty ? '-' : city,
                      profileUrl:
                          (profileUrl != null && profileUrl.isNotEmpty)
                              ? profileUrl
                              : null,
                    );
                  },
                )
              else
                const Text("Worker ID missing"),

              const SizedBox(height: 24),
              const Text(
                "Give a rating:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              _buildRatingBar(),
              const SizedBox(height: 16),

              const Text(
                "Select a feedback:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Wrap(
                spacing: 8,
                children:
                    feedbackOptions.map((text) {
                      final isSelected = selectedFeedback == text;
                      return ChoiceChip(
                        label: Text(text),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedFeedback = text;
                            _feedbackController.clear();
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),

              const Text(
                "Or write your feedback:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _feedbackController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Enter your feedback",
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && selectedFeedback != null) {
                    setState(() => selectedFeedback = null);
                  }
                },
              ),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                          : const Text("Submit Rating & Complete Job"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerCard({
    required String name,
    required String phone,
    required String city,
    String? profileUrl,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
          child: profileUrl == null ? const Icon(Icons.person, size: 32) : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text("Phone: $phone"), Text("City: $city")],
        ),
      ),
    );
  }

  Widget _buildRatingBar() {
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return IconButton(
          icon: Icon(
            starIndex <= rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 32,
          ),
          onPressed: () => setState(() => rating = starIndex.toDouble()),
        );
      }),
    );
  }
}
