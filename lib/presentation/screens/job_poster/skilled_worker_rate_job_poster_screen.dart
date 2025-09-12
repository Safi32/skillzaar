import 'package:flutter/material.dart';

class SkilledWorkerRateJobPosterScreen extends StatefulWidget {
  final Map<String, dynamic> jobPosterDetails;
  const SkilledWorkerRateJobPosterScreen({Key? key, required this.jobPosterDetails}) : super(key: key);

  @override
  State<SkilledWorkerRateJobPosterScreen> createState() => _SkilledWorkerRateJobPosterScreenState();
}

class _SkilledWorkerRateJobPosterScreenState extends State<SkilledWorkerRateJobPosterScreen> {
  double rating = 4.0;

  void _onRatingChanged(double value) {
    setState(() {
      rating = value;
    });
    // TODO: Send rating to backend
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate Job Poster')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Poster:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Name: ${widget.jobPosterDetails['name'] ?? '-'}'),
            Text('Phone: ${widget.jobPosterDetails['phone'] ?? '-'}'),
            Text('Email: ${widget.jobPosterDetails['email'] ?? '-'}'),
            const SizedBox(height: 32),
            Text('Give a rating:', style: Theme.of(context).textTheme.titleMedium),
            _buildRatingBar(),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Submit rating
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted!')));
                },
                child: const Text('Submit'),
              ),
            ),
          ],
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
