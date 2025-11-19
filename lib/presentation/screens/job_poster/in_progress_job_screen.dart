import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/in_progress_job_provider.dart';
import '../../../presentation/widgets/job_summary_card.dart';
import '../../../presentation/widgets/skilled_worker_card.dart';
import '../../../presentation/widgets/status_indicator.dart';
import '../../../presentation/widgets/job_action_button.dart';

class InProgressJobScreen extends StatelessWidget {
  const InProgressJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => InProgressJobProvider()..load(),
      child: Consumer<InProgressJobProvider>(
        builder: (context, provider, _) {
          final request = provider.request;
          final job = provider.job;
          final loading = provider.loading;
          return WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('Active Job'),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                centerTitle: true,
              ),
              body: loading
                  ? const Center(child: CircularProgressIndicator())
                  : (request == null)
                      ? const Center(child: Text('No active job'))
                      : ((job?['status'] != null && job?['status'] != 'approved')
                          ? const Center(
                              child: Text('Your job is awaiting admin approval.'),
                            )
                          : Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  JobSummaryCard(job: job),
                                  const SizedBox(height: 16),
                                  SkilledWorkerCard(request: request),
                                  const SizedBox(height: 16),
                                  StatusIndicator(status: request['status']),
                                  const Spacer(),
                                  JobActionButton(
                                    isAccepted: request['status'] == 'accepted',
                                    onPressed: () async {
                                      final ok = request['status'] == 'accepted'
                                          ? await provider.startWork()
                                          : await provider.markCompleted();
                                      if (ok && context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            )),
            ),
          );
        },
      ),
    );
  }
}
