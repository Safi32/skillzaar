import 'package:flutter/material.dart';
import 'job_poster_rate_worker_screen.dart';

class JobAcceptedDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> jobDetails;
  final Map<String, dynamic> skilledWorkerDetails;
  final bool isJobCompleted;

  const JobAcceptedDetailsScreen({
    Key? key,
    required this.jobDetails,
    required this.skilledWorkerDetails,
    this.isJobCompleted = false,
  }) : super(key: key);

  @override
  State<JobAcceptedDetailsScreen> createState() => _JobAcceptedDetailsScreenState();
}

class _JobAcceptedDetailsScreenState extends State<JobAcceptedDetailsScreen> {
  bool jobCompleted = false;
  bool jobCancelled = false;

  @override
  void initState() {
    super.initState();
    jobCompleted = widget.isJobCompleted;
  }

  void _onJobCompleted() {
    // TODO: Add logic to update job status in backend
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobPosterRateWorkerScreen(
          skilledWorkerDetails: widget.skilledWorkerDetails,
        ),
      ),
    );
  }

  void _onCancelJob() {
    setState(() {
      jobCancelled = true;
    });
    // TODO: Add logic to cancel job in backend
  }

  @override
  Widget build(BuildContext context) {
    if (jobCancelled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Cancelled')),
        body: const Center(child: Text('This job has been cancelled.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Title: 	${widget.jobDetails['title'] ?? '-'}'),
            Text('Description: ${widget.jobDetails['description'] ?? '-'}'),
            Text('Location: ${widget.jobDetails['location'] ?? '-'}'),
            const Divider(height: 32),
            Text('Skilled Worker Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Name: ${widget.skilledWorkerDetails['name'] ?? '-'}'),
            Text('Phone: ${widget.skilledWorkerDetails['phone'] ?? '-'}'),
            Text('Email: ${widget.skilledWorkerDetails['email'] ?? '-'}'),
            const Spacer(),
            if (!jobCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onJobCompleted,
                      child: const Text('Job Completed'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onCancelJob,
                      child: const Text('Cancel Job'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Center(child: Text('Job marked as completed.')),
            ],
          ],
        ),
      ),
    );
  }
}
