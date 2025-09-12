import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SkilledWorkerRequestsScreen extends StatelessWidget {
  const SkilledWorkerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    String skilledWorkerId;

    if (user != null) {
      skilledWorkerId = user.uid;
    } else {
      skilledWorkerId = 'TEST_SKILLED_WORKER_ID';
    }

    return Container(
      color: Colors.grey.shade50,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('JobRequests')
                .where('skilledWorkerId', isEqualTo: skilledWorkerId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Requests Yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you submit job requests,\nthey will appear here.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                        horizontal: 0,
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
                        horizontal: 0,
                        vertical: 8,
                      ),
                      child: const ListTile(
                        title: Text('Job not found'),
                        subtitle: Text('This job may have been deleted'),
                      ),
                    );
                  }

                  final jobData =
                      jobSnapshot.data!.data() as Map<String, dynamic>;
                  return _buildRequestCard(context, req, jobData);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    Map<String, dynamic> request,
    Map<String, dynamic> jobData,
  ) {
    final status = request['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    jobData['title'] ?? 'Job Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              jobData['description'] ?? 'No description available',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    jobData['location'] ?? 'Location not specified',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${jobData['budget'] ?? '0'} PKR',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Requested on: ${_formatDate(request['timestamp'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown date';

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Unknown date';
    } catch (e) {
      return 'Unknown date';
    }
  }
}
