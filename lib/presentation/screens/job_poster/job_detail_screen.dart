import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/screens/job_poster/job_poster_rate_worker_screen.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const jobTitle = "Flutter Developer";
    const jobDescription =
        "Build cross-platform mobile apps using Flutter and Dart.";
    const jobLocation = "San Francisco, USA";
    const jobSalary = "\$80,000 - \$100,000";

    const applicantName = "John Doe";
    const applicantEmail = "john.doe@example.com";
    const applicantPhone = "+1 123 456 7890";

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job & Applicant Details'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Job Details
              const Text(
                'Job Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text("Title: $jobTitle", style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                "Description: $jobDescription",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "Location: $jobLocation",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text("Salary: $jobSalary", style: const TextStyle(fontSize: 16)),

              const Divider(height: 30, thickness: 1),

              const Text(
                'Applicant Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "Name: $applicantName",
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text(
                "Email: $applicantEmail",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                "Phone: $applicantPhone",
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 30),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => JobPosterRateWorkerScreen(
                            skilledWorkerDetails: const {
                              'name': applicantName,
                              'email': applicantEmail,
                              'phone': applicantPhone,
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Complete Job',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement cancel job logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel Job',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
