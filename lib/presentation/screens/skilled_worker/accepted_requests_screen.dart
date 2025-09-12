import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'navigate_to_job_screen.dart';

class AcceptedRequestsScreen extends StatelessWidget {
  const AcceptedRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    String skilledWorkerId;

    if (user != null) {
      skilledWorkerId = user.uid;
    } else {
      skilledWorkerId = 'TEST_SKILLED_WORKER_ID';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accepted Jobs'),
        backgroundColor: Colors.green,
        centerTitle: true,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('JobRequests')
                .where('skilledWorkerId', isEqualTo: skilledWorkerId)
                .where('status', isEqualTo: 'accepted')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Accepted Jobs Yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When job posters accept your requests,\nthey will appear here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final requests = snapshot.data!.docs;
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index].data() as Map<String, dynamic>;
              return FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('Job')
                        .doc(req['jobId'])
                        .get(),
                builder: (context, jobSnapshot) {
                  if (jobSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const ListTile(
                        leading: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        title: Text('Loading job details...'),
                      ),
                    );
                  }
                  if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.error_outline, color: Colors.red),
                        title: Text('Job not found'),
                        subtitle: Text('This job may have been deleted'),
                      ),
                    );
                  }
                  final jobData =
                      jobSnapshot.data!.data() as Map<String, dynamic>;
                  final jobTitle =
                      jobData['title_en'] ??
                      jobData['title_ur'] ??
                      jobData['Name'] ??
                      'No Title';
                  final jobAddress = jobData['Address'] ?? 'No address';
                  final jobLat =
                      jobData['Latitude'] is double
                          ? jobData['Latitude']
                          : (jobData['Latitude'] as num?)?.toDouble();
                  final jobLng =
                      jobData['Longitude'] is double
                          ? jobData['Longitude']
                          : (jobData['Longitude'] as num?)?.toDouble();

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.work,
                                color: Colors.green.shade700,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  jobTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  jobAddress,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    if (jobLat != null && jobLng != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) => NavigateToJobScreen(
                                                jobId: req['jobId'],
                                                jobTitle: jobTitle,
                                                jobAddress: jobAddress,
                                                jobLatitude: jobLat,
                                                jobLongitude: jobLng,
                                              ),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Job location not available',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.directions),
                                  label: const Text('Navigate to Job'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                    side: BorderSide(color: Colors.green),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Show job details or additional actions
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Job: $jobTitle'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline),
                                  label: const Text('Job Details'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
