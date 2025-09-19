import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/core/examples/services/user_data_service.dart';
import '../../../core/theme/app_theme.dart';

class WorkerApprovalScreen extends StatefulWidget {
  const WorkerApprovalScreen({super.key});

  @override
  State<WorkerApprovalScreen> createState() => _WorkerApprovalScreenState();
}

class _WorkerApprovalScreenState extends State<WorkerApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Approval'),
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
          onTap: (index) {
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkerList('pending'),
          _buildWorkerList('approved'),
          _buildWorkerList('rejected'),
        ],
      ),
    );
  }

  Widget _buildWorkerList(String status) {
    return FutureBuilder<QuerySnapshot>(
      future: UserDataService.getSkilledWorkersByApprovalStatus(status: status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('No ${status} workers found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildWorkerCard(data, docs[index].id);
          },
        );
      },
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> data, String workerId) {
    final name = data['Name'] ?? data['displayName'] ?? 'Unknown';
    final phone = data['phoneNumber'] ?? 'N/A';
    final city = data['City'] ?? 'N/A';
    final age = data['Age'] ?? 'N/A';
    final profilePicture = data['ProfilePicture'] ?? data['profilePicture'];
    final approvalStatus = data['approvalStatus'] ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;
    final adminNotes = data['adminNotes'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      profilePicture != null
                          ? NetworkImage(profilePicture)
                          : null,
                  child:
                      profilePicture == null
                          ? const Icon(Icons.person, size: 30)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Phone: $phone'),
                      Text('City: $city'),
                      Text('Age: $age'),
                      if (createdAt != null)
                        Text(
                          'Registered: ${_formatDate(createdAt.toDate())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(approvalStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    approvalStatus.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (adminNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(adminNotes, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            if (approvalStatus == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          () => _showApprovalDialog(workerId, name, 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          () => _showApprovalDialog(workerId, name, 'reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showApprovalDialog(String workerId, String workerName, String action) {
    final TextEditingController notesController = TextEditingController();
    final bool isApprove = action == 'approve';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${isApprove ? 'Approve' : 'Reject'} Worker'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to ${action} $workerName?'),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Admin Notes (Optional)',
                    border: const OutlineInputBorder(),
                    hintText: 'Add any notes about this decision...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateWorkerStatus(
                    workerId,
                    action,
                    notesController.text,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isApprove ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(isApprove ? 'Approve' : 'Reject'),
              ),
            ],
          ),
    );
  }

  Future<void> _updateWorkerStatus(
    String workerId,
    String action,
    String notes,
  ) async {
    try {
      await UserDataService.updateSkilledWorkerApprovalStatus(
        userId: workerId,
        status: action,
        adminNotes: notes.isNotEmpty ? notes : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Worker ${action}d successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
        setState(() {}); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
