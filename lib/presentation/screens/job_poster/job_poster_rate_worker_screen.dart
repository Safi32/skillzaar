import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

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
  double _currentWorkerRating = 0.0;
  int _currentRatingCount = 0;

  List<String> _getFeedbackOptions(AppLocalizations l10n) => [
    l10n.feedbackExcellent,
    l10n.feedbackVeryGood,
    l10n.feedbackGood,
    l10n.feedbackAverage,
    l10n.feedbackPoor,
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.workerNotIdentified),
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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSubmitRating),
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
          String? workerId;
          String? posterId;
          String? jobId;
          String? jobRequestId;

          await FirebaseFirestore.instance.runTransaction((txn) async {
            final assignedSnap = await txn.get(assignedRef);
            if (!assignedSnap.exists) {
              throw Exception('Assigned job not found');
            }

            final data = assignedSnap.data() as Map<String, dynamic>;
            workerId = data['workerId']?.toString();
            posterId = data['jobPosterId']?.toString();
            jobId = data['jobId']?.toString();
            jobRequestId = data['requestId']?.toString();

            final alreadyPosterRated =
                (data['posterRatingCompleted'] as bool?) ??
                data['rating'] != null;
            if (alreadyPosterRated) {
              throw Exception(
                'You have already submitted a rating for this job.',
              );
            }

            final workerAlreadyRatedPoster =
                (data['workerRatingCompleted'] as bool?) ?? false;

            txn.set(assignedRef, {
              'assignmentStatus': 'completed',
              'isActive': false,
              'completedAt': FieldValue.serverTimestamp(),
              'rating': rating,
              'ratingComment': selectedFeedback ?? _feedbackController.text,
              'ratedBy': JobRequestService.getCurrentUserId(),
              'ratedAt': FieldValue.serverTimestamp(),
              'posterRatingCompleted': true,
              'workerRatingCompleted': workerAlreadyRatedPoster,
              'fullyCompleted': workerAlreadyRatedPoster,
              'fullyCompletedAt':
                  workerAlreadyRatedPoster
                      ? FieldValue.serverTimestamp()
                      : FieldValue.delete(),
            }, SetOptions(merge: true));
          });

          // Best-effort: mark JobRequests completed so worker listeners fire
          if (jobRequestId != null && jobRequestId!.trim().isNotEmpty) {
            try {
              await JobRequestService.markRequestCompleted(
                jobRequestId!.trim(),
              );
            } catch (_) {}
          }

          // Update Job collection status to completed
          if (jobId?.isNotEmpty == true) {
            await FirebaseFirestore.instance
                .collection('Job')
                .doc(jobId)
                .update({
                  'status': 'completed',
                  'completedAt': FieldValue.serverTimestamp(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          }

          if (workerId?.isNotEmpty == true) {
            await FirebaseFirestore.instance
                .collection('SkilledWorkers')
                .doc(workerId)
                .set({
                  'activeJobId': FieldValue.delete(),
                  'jobAssigned': false,
                  'assignedJobId': FieldValue.delete(),
                  'currentJobId': FieldValue.delete(),
                  'currentJob': FieldValue.delete(),
                }, SetOptions(merge: true));
          }
          if (posterId?.isNotEmpty == true) {
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

    final l10n = AppLocalizations.of(context)!;
    final feedbackOptions = _getFeedbackOptions(l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rateSkilledWorker),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future:
                    FirebaseFirestore.instance
                        .collection('AssignedJobs')
                        .doc(widget.requestId ?? '')
                        .get(),
                builder: (context, assignedSnap) {
                  final assignedData = assignedSnap.data?.data();
                  final jobTitle =
                      assignedData?['jobTitle'] ??
                      assignedData?['jobDetails']?['jobName'] ??
                      l10n.jobLabel;
                  final workerName =
                      assignedData?['workerName'] ??
                      assignedData?['skilledWorkerName'] ??
                      assignedData?['skilledWorkerDetails']?['skilledWorkerName'];

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.jobCompleted,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${l10n.jobLabel}: $jobTitle',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${l10n.workerLabel}: ${workerName ?? l10n.skilledWorkerText}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '${l10n.currentRating}: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < _currentWorkerRating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                );
                              }),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_currentWorkerRating.toStringAsFixed(1)}/5.0',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($_currentRatingCount ${_currentRatingCount == 1 ? l10n.ratingLabel : l10n.ratingsLabel})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

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
                      return Text(l10n.workerNotFound);
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

                    final nextAvg =
                        (data?['averageRating'] as num?)?.toDouble() ?? 0.0;
                    final nextCount =
                        (data?['ratingCount'] as num?)?.toInt() ?? 0;
                    if (_currentWorkerRating != nextAvg ||
                        _currentRatingCount != nextCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() {
                          _currentWorkerRating = nextAvg;
                          _currentRatingCount = nextCount;
                        });
                      });
                    }

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
                Text(l10n.workerIdMissing),

              const SizedBox(height: 30),

              Text(
                l10n.howWasExperienceWorker,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap:
                          () => setState(() => rating = (index + 1).toDouble()),
                      child: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 50,
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  feedbackOptions[rating.toInt() - 1],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                l10n.quickFeedback,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    feedbackOptions.map((text) {
                      final isSelected = selectedFeedback == text;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedFeedback = isSelected ? null : text;
                            if (selectedFeedback != null) {
                              _feedbackController.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.green
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.green
                                      : Colors.grey.shade300,
                            ),
                          ),
                          child: Text(
                            text,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),

              const SizedBox(height: 20),

              Text(
                l10n.customFeedback,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10n.feedbackHintWorker,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      selectedFeedback = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                            l10n.submitRatingCompleteJob,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
          children: [
            Text("${AppLocalizations.of(context)!.phoneLabel}: $phone"),
            Text("${AppLocalizations.of(context)!.cityLabel}: $city"),
          ],
        ),
      ),
    );
  }
}
