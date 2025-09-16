import 'package:flutter/material.dart';
import 'package:skillzaar/core/services/job_request_service.dart';

class JobPosterRateWorkerScreen extends StatefulWidget {
  final Map<String, dynamic> skilledWorkerDetails;
  final String? requestId;
  const JobPosterRateWorkerScreen({
    Key? key,
    required this.skilledWorkerDetails,
    this.requestId,
  }) : super(key: key);

  @override
  State<JobPosterRateWorkerScreen> createState() =>
      _JobPosterRateWorkerScreenState();
}

class _JobPosterRateWorkerScreenState extends State<JobPosterRateWorkerScreen> {
  double rating = 4.0;
  final List<String> defaultTexts = [
    'Excellent work',
    'Very Good',
    'Good',
    'Average',
    'Poor',
  ];
  String? selectedText;
  final TextEditingController _customController = TextEditingController();
  bool _isSubmitting = false;

  void _onRatingChanged(double value) {
    setState(() {
      rating = value;
    });
  }

  Future<void> _submitRating() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // If requestId is provided, mark the job as completed
      if (widget.requestId != null && widget.requestId!.isNotEmpty) {
        final success = await JobRequestService.markRequestCompleted(
          widget.requestId!,
        );
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to home screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/job-poster-home',
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to complete job. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Just show success message if no requestId
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-home',
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Skilled Worker')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Skilled Worker:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Name: ${widget.skilledWorkerDetails['name'] ?? '-'}'),
              Text('Phone: ${widget.skilledWorkerDetails['phone'] ?? '-'}'),
              Text('Email: ${widget.skilledWorkerDetails['email'] ?? '-'}'),
              const SizedBox(height: 32),
              Text(
                'Give a rating:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              _buildRatingBar(),
              const SizedBox(height: 16),
              Text(
                'Select a feedback:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children:
                    defaultTexts.map((text) {
                      final isSelected = selectedText == text;
                      return ChoiceChip(
                        label: Text(text),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            selectedText = text;
                            _customController.clear();
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                'Or write your own feedback:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your feedback',
                ),
                onChanged: (val) {
                  if (val.isNotEmpty && selectedText != null) {
                    setState(() {
                      selectedText = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  child:
                      _isSubmitting
                          ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Submitting...'),
                            ],
                          )
                          : const Text('Submit Rating & Complete Job'),
                ),
              ),
            ],
          ),
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
          onPressed: () => _onRatingChanged(starIndex.toDouble()),
        );
      }),
    );
  }
}
