import 'package:flutter/material.dart';
import 'package:skillzaar/presentation/screens/job_poster/job_poster_rate_worker_screen.dart';
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
    String jobTitle = "Loading...";
    String jobDescription = "Loading...";
    String jobLocation = "Loading...";
    String jobSalary = "Loading...";

    String applicantName = "Loading...";
    String applicantEmail = "Loading...";
    String applicantPhone = "Loading...";
    String skilledWorkerId = "";

    return SafeArea(
      child: WillPopScope(
        onWillPop: () async => false,
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance
                  .collection('JobRequests')
                  .doc(requestId)
                  .snapshots(),
          builder: (context, snapshot) {
            final status = snapshot.data?.data()?['status'] as String?;
            final isActive = snapshot.data?.data()?['isActive'] as bool?;
            // Only redirect to home if job is completed or inactive, not for accepted or in_progress jobs
            if (status == 'completed' ||
                (isActive == false &&
                    status != 'accepted' &&
                    status != 'in_progress')) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!Navigator.of(context).canPop()) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/job-poster-home',
                    (route) => false,
                  );
                }
              });
            }
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: JobRequestService.streamJobDoc(jobId),
              builder: (context, jobSnap) {
                final jobStatus = jobSnap.data?.data()?['status'] as String?;
                if (jobStatus == 'completed') {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!Navigator.of(context).canPop()) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/job-poster-home',
                        (route) => false,
                      );
                    }
                  });
                }

                // Get job data from Firebase
                final jobData = jobSnap.data?.data();
                if (jobData != null) {
                  jobTitle =
                      jobData['title_en'] ?? jobData['title_ur'] ?? 'No Title';
                  jobDescription =
                      jobData['description_en'] ??
                      jobData['description_ur'] ??
                      'No Description';
                  jobLocation =
                      jobData['Location'] ??
                      jobData['Address'] ??
                      'No Location';
                  jobSalary = jobData['budget']?.toString() ?? 'Not specified';
                }

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Job & Applicant Details'),
                    centerTitle: true,
                    leading: Builder(
                      builder:
                          (context) => IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                          ),
                    ),
                  ),
                  drawer: FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('JobRequests')
                            .doc(requestId)
                            .get(),
                    builder: (context, requestSnap) {
                      String currentApplicantName = applicantName;
                      String currentApplicantPhone = applicantPhone;
                      String currentApplicantEmail = applicantEmail;
                      String currentSkilledWorkerId = skilledWorkerId;

                      if (requestSnap.hasData &&
                          requestSnap.data?.data() != null) {
                        final requestData =
                            requestSnap.data?.data() as Map<String, dynamic>;
                        currentApplicantName =
                            requestData['skilledWorkerName'] ?? 'Unknown';
                        currentApplicantPhone =
                            requestData['skilledWorkerPhone'] ?? 'Unknown';
                        currentApplicantEmail = 'Not available';
                        currentSkilledWorkerId =
                            requestData['skilledWorkerId'] ?? '';
                      }

                      return _buildDrawer(
                        context,
                        jobTitle,
                        jobDescription,
                        jobLocation,
                        jobSalary,
                        currentApplicantName,
                        currentApplicantEmail,
                        currentApplicantPhone,
                        currentSkilledWorkerId,
                      );
                    },
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Job Details
                        const Text(
                          'Job Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Title: $jobTitle",
                          style: const TextStyle(fontSize: 18),
                        ),
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
                        Text(
                          "Budget: $jobSalary",
                          style: const TextStyle(fontSize: 16),
                        ),

                        const Divider(height: 30, thickness: 1),

                        const Text(
                          'Applicant Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Fetch applicant details from JobRequests collection
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('JobRequests')
                                  .doc(requestId)
                                  .get(),
                          builder: (context, requestSnap) {
                            if (requestSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            final requestData =
                                requestSnap.data?.data()
                                    as Map<String, dynamic>?;
                            if (requestData != null) {
                              applicantName =
                                  requestData['skilledWorkerName'] ?? 'Unknown';
                              applicantPhone =
                                  requestData['skilledWorkerPhone'] ??
                                  'Unknown';
                              applicantEmail =
                                  'Not available'; // Email not stored in current schema
                              skilledWorkerId =
                                  requestData['skilledWorkerId'] ?? '';
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Name: $applicantName",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Phone: $applicantPhone",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Email: $applicantEmail",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              JobPosterRateWorkerScreen(
                                                skilledWorkerDetails: {
                                                  'name': applicantName,
                                                  'email': applicantEmail,
                                                  'phone': applicantPhone,
                                                  'id': skilledWorkerId,
                                                  'skilledWorkerId':
                                                      skilledWorkerId,
                                                  'uid': skilledWorkerId,
                                                },
                                                requestId: requestId,
                                              ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Complete Job',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement cancel job logic
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Cancel Job',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
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
        ),
      ),
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    String jobTitle,
    String jobDescription,
    String jobLocation,
    String jobSalary,
    String applicantName,
    String applicantEmail,
    String applicantPhone,
    String skilledWorkerId,
  ) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.work, size: 40, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  'Job Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View all information',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          // Job Details Section
          _buildDrawerSection(
            title: 'Job Information',
            icon: Icons.work_outline,
            children: [
              _buildDrawerItem(
                icon: Icons.title,
                title: 'Title',
                subtitle: jobTitle,
              ),
              _buildDrawerItem(
                icon: Icons.description,
                title: 'Description',
                subtitle: jobDescription,
              ),
              _buildDrawerItem(
                icon: Icons.location_on,
                title: 'Location',
                subtitle: jobLocation,
              ),
              _buildDrawerItem(
                icon: Icons.attach_money,
                title: 'Budget',
                subtitle: jobSalary,
              ),
            ],
          ),

          const Divider(),

          // Skilled Worker Details Section
          _buildDrawerSection(
            title: 'Skilled Worker',
            icon: Icons.person_outline,
            children: [
              _buildDrawerItem(
                icon: Icons.person,
                title: 'Name',
                subtitle: applicantName,
              ),
              _buildDrawerItem(
                icon: Icons.phone,
                title: 'Phone',
                subtitle: applicantPhone,
              ),
              _buildDrawerItem(
                icon: Icons.email,
                title: 'Email',
                subtitle: applicantEmail,
              ),
            ],
          ),

          const Divider(),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close drawer
                      // Navigate to rate worker screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder:
                              (context) => JobPosterRateWorkerScreen(
                                skilledWorkerDetails: {
                                  'name': applicantName,
                                  'email': applicantEmail,
                                  'phone': applicantPhone,
                                  'id': skilledWorkerId,
                                  'skilledWorkerId': skilledWorkerId,
                                  'uid': skilledWorkerId,
                                },
                                requestId: requestId,
                              ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Rate Worker'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // Close drawer
                      // TODO: Implement cancel job logic
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Job'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[600]),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
    );
  }
}
