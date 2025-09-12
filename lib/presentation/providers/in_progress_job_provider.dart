import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/job_request_service.dart';

class InProgressJobProvider extends ChangeNotifier {
  Map<String, dynamic>? request;
  Map<String, dynamic>? job;
  bool loading = true;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    final posterId = FirebaseAuth.instance.currentUser?.uid ?? 'TEST_POSTER_ID';
    Map<String, dynamic>? req =
        await JobRequestService.getAcceptedRequestForPoster(posterId);
    if (req == null) {
      req = await JobRequestService.getInProgressRequestForPoster(posterId);
    }
    Map<String, dynamic>? jobData;
    if (req != null) {
      jobData = await JobRequestService.getJobDetails(req['jobId'] as String);
    }
    request = req;
    job = jobData ?? {};
    loading = false;
    notifyListeners();
  }

  Future<bool> markCompleted() async {
    if (request == null) return false;
    final ok = await JobRequestService.markRequestCompleted(
      request!['requestId'] as String,
    );
    if (ok) await load();
    return ok;
  }

  Future<bool> startWork() async {
    if (request == null) return false;
    final ok = await JobRequestService.markRequestInProgress(
      request!['requestId'] as String,
    );
    if (ok) await load();
    return ok;
  }
}
