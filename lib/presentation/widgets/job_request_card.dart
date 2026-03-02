import 'package:flutter/material.dart';
import 'request_item.dart';
class JobRequestCard extends StatelessWidget {
  final String jobTitle;
  final String jobId;
  final List<Map<String, dynamic>> requests;
  final List<String> requestIds;
  final void Function(Map<String, dynamic> req, String requestId)? onPortfolioTap;
  const JobRequestCard({Key? key, required this.jobTitle, required this.jobId, required this.requests, required this.requestIds, this.onPortfolioTap}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job: $jobTitle', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('${requests.length} request${requests.length == 1 ? '' : 's'}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            ...List.generate(requests.length, (i) => RequestItem(
              req: requests[i],
              jobId: jobId,
              requestId: requestIds[i],
              onPortfolioTap: onPortfolioTap != null ? () => onPortfolioTap!(requests[i], requestIds[i]) : null,
              showAcceptedToast: true,
            )),
          ],
        ),
      ),
    );
  }
}
