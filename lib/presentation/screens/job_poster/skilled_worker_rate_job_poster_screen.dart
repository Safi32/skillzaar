import 'package:flutter/material.dart';
import 'package:skillzaar/core/services/job_request_service.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class SkilledWorkerRateJobPosterScreen extends StatefulWidget {
  final Map<String, dynamic> jobPosterDetails;
  final String? requestId;
  const SkilledWorkerRateJobPosterScreen({
    Key? key,
    required this.jobPosterDetails,
    this.requestId,
  }) : super(key: key);

  @override
  State<SkilledWorkerRateJobPosterScreen> createState() =>
      _SkilledWorkerRateJobPosterScreenState();
}

class _SkilledWorkerRateJobPosterScreenState
    extends State<SkilledWorkerRateJobPosterScreen> {
  double rating = 4.0;
  List<String> _getDefaultTexts(AppLocalizations l10n) => [
    l10n.feedbackExcellent,
    l10n.feedbackVeryGood,
    l10n.feedbackGood,
    l10n.feedbackAverage,
    l10n.feedbackPoor,
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
      // Submit rating to backend
      final success = await JobRequestService.submitJobPosterRating(
        jobPosterId:
            widget.jobPosterDetails['id'] ??
            widget.jobPosterDetails['jobPosterId'],
        rating: rating,
        feedback: selectedText ?? _customController.text,
        requestId: widget.requestId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rating submitted successfully! (${rating.toStringAsFixed(1)} stars)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back to skilled worker home screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/skilled-worker-home',
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToSubmitRating),
            backgroundColor: Colors.red,
          ),
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
    final l10n = AppLocalizations.of(context)!;
    final defaultTexts = _getDefaultTexts(l10n);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.rateJobPoster),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Poster Info Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green.shade100,
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.jobPosterDetails,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.rateExperienceJobPoster,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          Icons.person,
                          l10n.nameLabel,
                          widget.jobPosterDetails['name'] ?? '-',
                        ),
                        _buildInfoRow(
                          Icons.phone,
                          l10n.phoneLabel,
                          widget.jobPosterDetails['phone'] ?? '-',
                        ),
                        _buildInfoRow(
                          Icons.email,
                          l10n.emailLabel,
                          widget.jobPosterDetails['email'] ?? '-',
                        ),
                        _buildInfoRow(
                          Icons.location_on,
                          l10n.addressLabel,
                          widget.jobPosterDetails['address'] ?? '-',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Rating Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.howWasExperience,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(child: _buildRatingBar()),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getRatingText(rating),
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Feedback Section
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.selectFeedback,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              defaultTexts.map((text) {
                                final isSelected = selectedText == text;
                                return ChoiceChip(
                                  label: Text(text),
                                  selected: isSelected,
                                  selectedColor: Colors.green.shade100,
                                  checkmarkColor: Colors.green.shade700,
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
                          l10n.writeOwnFeedback,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _customController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: l10n.enterDetailedFeedback,
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && selectedText != null) {
                              setState(() {
                                selectedText = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child:
                        _isSubmitting
                            ? Row(
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
                                SizedBox(width: 12),
                                Text(
                                  l10n.submittingText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                            : Text(
                              l10n.submitRating,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        return GestureDetector(
          onTap: () => _onRatingChanged(starIndex.toDouble()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Icon(
              starIndex <= rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 40,
            ),
          ),
        );
      }),
    );
  }

  String _getRatingText(double rating) {
    final l10n = AppLocalizations.of(context)!;
    if (rating >= 4.5) return l10n.excellent;
    if (rating >= 3.5) return l10n.veryGoodExcl;
    if (rating >= 2.5) return l10n.goodExcl;
    if (rating >= 1.5) return l10n.feedbackAverage;
    return l10n.feedbackPoor;
  }
}
