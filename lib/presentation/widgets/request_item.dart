import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'request_status_indicator.dart';

class RequestItem extends StatelessWidget {
  final Map<String, dynamic> req;
  final String jobId;
  final String requestId;
  final VoidCallback? onPortfolioTap;
  final bool showAcceptedToast;
  const RequestItem({
    Key? key,
    required this.req,
    required this.jobId,
    required this.requestId,
    this.onPortfolioTap,
    this.showAcceptedToast = false,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Worker: ${req['skilledWorkerName'] ?? req['skilledWorkerId'] ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.phone, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('Phone: ${req['skilledWorkerPhone'] ?? 'N/A'}'),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              req['requestedAt'] != null
                  ? 'Requested: ${req['requestedAt'] is Timestamp 
                      ? (req['requestedAt'] as Timestamp).toDate().toString().split(' ').first
                      : req['requestedAt'].toString().split(' ').first}'
                  : 'Unknown date',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RequestStatusIndicator(status: req['status']),
        if (showAcceptedToast && req['status'] == 'accepted')
          Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job request accepted!')),
                );
              });
              return const SizedBox.shrink();
            },
          ),
        const SizedBox(height: 12),
        if (req['status'] == 'pending')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (req['portfolioViewed'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 14,
                        color: Colors.blue.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Portfolio Viewed',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: onPortfolioTap,
                  child: const Text(
                    'Check Portfolio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        if (req['status'] == 'accepted')
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/job-poster-job-detail',
                      arguments: {'jobId': jobId, 'requestId': requestId},
                    );
                  },
                  child: const Text(
                    'View Job Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        const Divider(),
      ],
    );
  }
}
