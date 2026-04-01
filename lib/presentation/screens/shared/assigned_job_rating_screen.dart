import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/services/job_request_service.dart';

class AssignedJobRatingScreen extends StatefulWidget {
  final String assignedJobId;
  final bool isJobCompletion;

  const AssignedJobRatingScreen({
    super.key,
    required this.assignedJobId,
    required this.isJobCompletion,
  });

  @override
  State<AssignedJobRatingScreen> createState() =>
      _AssignedJobRatingScreenState();
}

class _AssignedJobRatingScreenState extends State<AssignedJobRatingScreen> {
  double rating = 4.0;
  // Map 1 star -> Poor, 5 stars -> Excellent (poster rates worker)
  final List<String> defaultTexts = [
    'Poor',
    'Average',
    'Good',
    'Very Good',
    'Excellent work',
  ];
  String? selectedText;
  final TextEditingController _customController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _assignedJobData;
  bool _isLoading = true;
  double _currentWorkerRating = 0.0;
  int _currentRatingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAssignedJobData();
  }

  Future<void> _loadAssignedJobData() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('AssignedJobs')
              .doc(widget.assignedJobId)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _assignedJobData = data;
          _isLoading = false;
        });

        // Load skilled worker's current rating
        await _loadSkilledWorkerRating(data['workerId'] as String?);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assigned job not found'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading job data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadSkilledWorkerRating(String? workerId) async {
    if (workerId == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('SkilledWorkers')
              .doc(workerId)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _currentWorkerRating =
              (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          _currentRatingCount = (data['ratingCount'] as int?) ?? 0;
        });
      }
    } catch (e) {
      print('Error loading skilled worker rating: $e');
    }
  }

  void _onRatingChanged(double value) {
    setState(() {
      rating = value;
    });
  }

  Future<void> _submitRating() async {
    if (_isSubmitting || _assignedJobData == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final skilledWorkerId = _assignedJobData!['workerId'] as String?;
      final jobPosterId = _assignedJobData!['jobPosterId'] as String?;
      final jobId = _assignedJobData!['jobId'] as String?;

      if (skilledWorkerId == null || jobPosterId == null || jobId == null) {
        throw Exception('Missing required IDs');
      }

      String? jobRequestId;

      // 1) Update the assigned job status to completed (transactional, prevents duplicates)
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final assignedRef = FirebaseFirestore.instance
            .collection('AssignedJobs')
            .doc(widget.assignedJobId);
        final assignedSnap = await txn.get(assignedRef);
        if (!assignedSnap.exists) {
          throw Exception('Assigned job not found');
        }

        final assignedData = assignedSnap.data() as Map<String, dynamic>;
        jobRequestId = (assignedData['requestId'] as String?)?.toString();

        final alreadyPosterRated =
            (assignedData['posterRatingCompleted'] as bool?) ??
            assignedData['rating'] != null;
        if (alreadyPosterRated) {
          throw Exception('You have already submitted a rating for this job.');
        }

        final workerAlreadyRatedPoster =
            (assignedData['workerRatingCompleted'] as bool?) ?? false;

        txn.update(assignedRef, {
          'assignmentStatus': 'completed',
          'isActive': false,
          'completedAt': FieldValue.serverTimestamp(),
          'rating': rating,
          'ratingComment': selectedText ?? _customController.text,
          'ratedBy': jobPosterId,
          'ratedAt': FieldValue.serverTimestamp(),
          'posterRatingCompleted': true,
          'workerRatingCompleted': workerAlreadyRatedPoster,
          'fullyCompleted': workerAlreadyRatedPoster,
          'fullyCompletedAt': workerAlreadyRatedPoster
              ? FieldValue.serverTimestamp()
              : FieldValue.delete(),
        });
      });

      // 2) Update skilled worker's rating
      await _updateSkilledWorkerRating(skilledWorkerId, rating);

      // 3) Update job status
      await FirebaseFirestore.instance.collection('Job').doc(jobId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      // 4) Mark JobRequests completed (best-effort) so worker-side completion listeners fire
      try {
        final reqId =
            (jobRequestId != null && jobRequestId!.trim().isNotEmpty)
                ? jobRequestId!.trim()
                : widget.assignedJobId;
        await JobRequestService.markRequestCompleted(reqId);
      } catch (_) {}

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rating submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home screen after job poster rates the worker
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/job-poster-home',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting rating: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _updateSkilledWorkerRating(
    String skilledWorkerId,
    double newRating,
  ) async {
    try {
      // Use the current rating data we already have
      final currentRating = _currentWorkerRating;
      final ratingCount = _currentRatingCount;

      // Calculate new average rating using proper formula
      // New Average = (Current Average × Current Count + New Rating) / (Current Count + 1)
      final newAverageRating =
          ((currentRating * ratingCount) + newRating) / (ratingCount + 1);

      // Update worker's rating
      await FirebaseFirestore.instance
          .collection('SkilledWorkers')
          .doc(skilledWorkerId)
          .update({
            'averageRating': newAverageRating,
            'ratingCount': ratingCount + 1,
            'lastRatingAt': FieldValue.serverTimestamp(),
          });

      // Update local state
      setState(() {
        _currentWorkerRating = newAverageRating;
        _currentRatingCount = ratingCount + 1;
      });
    } catch (e) {
      print('Error updating skilled worker rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_assignedJobData == null) {
      return const Scaffold(
        body: Center(child: Text('Job data not available')),
      );
    }

    final workerName = _assignedJobData!['workerName'] ?? 'Worker';
    final jobTitle = _assignedJobData!['jobTitle'] ?? 'Job';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isJobCompletion ? 'Rate Worker' : 'Rate Worker'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Info Card
            Container(
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
                    'Job Completed!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Job: $jobTitle', style: const TextStyle(fontSize: 16)),
                  Text(
                    'Worker: $workerName',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  // Current Rating Display
                  Row(
                    children: [
                      const Text(
                        'Current Rating: ',
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
                        '(${_currentRatingCount} ${_currentRatingCount == 1 ? 'rating' : 'ratings'})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Rating Section
            const Text(
              'How was your experience?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 20),

            // Star Rating
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => _onRatingChanged((index + 1).toDouble()),
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

            // Rating Text
            Center(
              child: Text(
                defaultTexts[rating.toInt() - 1],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Quick Feedback Options
            const Text(
              'Quick Feedback (Optional)',
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
                  defaultTexts.map((text) {
                    final isSelected = selectedText == text;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedText = isSelected ? null : text;
                          if (selectedText != null) {
                            _customController.clear();
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
                              isSelected ? Colors.green : Colors.grey.shade200,
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

            // Custom Feedback
            const Text(
              'Custom Feedback (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: _customController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your detailed feedback...',
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
                    selectedText = null;
                  });
                }
              },
            ),

            const SizedBox(height: 40),

            // Submit Button
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
                        : const Text(
                          'Submit Rating',
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
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }
}
