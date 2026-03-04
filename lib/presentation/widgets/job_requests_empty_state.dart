import 'package:flutter/material.dart';
import 'package:skillzaar/l10n/app_localizations.dart';

class JobRequestsEmptyState extends StatelessWidget {
  const JobRequestsEmptyState({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noJobsFound,
            style: const TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.jobsAppearHereMsg,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
