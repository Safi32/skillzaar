import 'package:flutter/material.dart';
class JobRequestsEmptyState extends StatelessWidget {
  const JobRequestsEmptyState({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.work_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No jobs found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Jobs you post will appear here with requests.', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
