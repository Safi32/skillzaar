import 'package:flutter/material.dart';
import '../../widgets/portfolio_professional_header.dart';
import '../../widgets/portfolio_worker_details.dart';
import '../../widgets/portfolio_skills.dart';
import '../../widgets/portfolio_experience.dart';
import '../../widgets/portfolio_bio.dart';
import '../../widgets/portfolio_images.dart';
import '../../widgets/portfolio_action_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/job_request_service.dart';

class PortfolioViewScreen extends StatelessWidget {
  final String skilledWorkerId;
  final String skilledWorkerName;
  final String jobId;
  final String requestId;

  const PortfolioViewScreen({
    Key? key,
    required this.skilledWorkerId,
    required this.skilledWorkerName,
    required this.jobId,
    required this.requestId,
  }) : super(key: key);

  Future<Map<String, dynamic>?> _fetchPortfolioData() async {
    // Try by document id first
    final doc =
        await FirebaseFirestore.instance
            .collection('SkilledWorkers')
            .doc(skilledWorkerId)
            .get();
    if (doc.exists) return doc.data();

    // Fallbacks: search by phone or legacy fields from request
    final req =
        await FirebaseFirestore.instance
            .collection('JobRequests')
            .doc(requestId)
            .get();
    if (req.exists) {
      final data = req.data() as Map<String, dynamic>;
      final phone = data['skilledWorkerPhone'] as String?;
      if (phone != null && phone.isNotEmpty) {
        // normalize variants
        final candidates = <String>{phone};
        if (phone.startsWith('0') && phone.length == 11) {
          candidates.add('+92${phone.substring(1)}');
        }
        if (phone.startsWith('+92') && phone.length == 13) {
          candidates.add('0${phone.substring(3)}');
        }
        if (phone.length == 10 && phone.startsWith('3')) {
          candidates.add('+92$phone');
          candidates.add('0$phone');
        }
        for (final ph in candidates) {
          final snap =
              await FirebaseFirestore.instance
                  .collection('SkilledWorkers')
                  .where('userPhone', isEqualTo: ph)
                  .limit(1)
                  .get();
          if (snap.docs.isNotEmpty) {
            return snap.docs.first.data();
          }
        }
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchRequestData() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('JobRequests')
            .doc(requestId)
            .get();
    return doc.data();
  }

  void _updateRequestStatus(BuildContext context, String status) async {
    try {
      if (status == 'accepted') {
        // Use the proper method that creates AcceptedJobs entry
        final success = await JobRequestService.markRequestAccepted(requestId);
        if (success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Job request accepted successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            // Redirect to job poster accepted details screen for accepted jobs
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/job-poster-accepted-details',
              (route) => false,
              arguments: {'jobId': jobId, 'requestId': requestId},
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to accept job request. Please try again.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // For rejected status, just update the JobRequests collection
        await FirebaseFirestore.instance
            .collection('JobRequests')
            .doc(requestId)
            .update({'status': status, 'isActive': false});
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job request rejected.'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchPortfolioData(),
        builder: (context, portfolioSnapshot) {
          if (portfolioSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!portfolioSnapshot.hasData || portfolioSnapshot.data == null) {
            return const Center(child: Text('Portfolio not found'));
          }
          final portfolio = portfolioSnapshot.data!;
          return FutureBuilder<Map<String, dynamic>?>(
            future: _fetchRequestData(),
            builder: (context, requestSnapshot) {
              if (requestSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!requestSnapshot.hasData || requestSnapshot.data == null) {
                return const Center(child: Text('Request not found'));
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PortfolioProfessionalHeader(
                      skilledWorkerName: skilledWorkerName,
                    ),
                    const SizedBox(height: 20),
                    PortfolioWorkerDetails(
                      phone:
                          portfolio['userPhone']?.toString() ?? 'Not provided',
                      rate: portfolio['rate']?.toString() ?? 'Not specified',
                      availability:
                          portfolio['availability']?.toString() ??
                          'Not specified',
                    ),
                    const SizedBox(height: 20),
                    PortfolioSkills(
                      skills:
                          (portfolio['skills'] as List<dynamic>?) ??
                          (portfolio['categories'] as List<dynamic>?) ??
                          const [],
                    ),
                    const SizedBox(height: 20),
                    PortfolioExperience(
                      experience: portfolio['experience']?.toString() ?? '',
                    ),
                    const SizedBox(height: 20),
                    PortfolioBio(
                      bio:
                          (portfolio['bio'] ?? portfolio['description'])
                              ?.toString() ??
                          '',
                    ),
                    const SizedBox(height: 20),
                    PortfolioImages(
                      images:
                          (portfolio['portfolioImages'] as List<dynamic>?) ??
                          (portfolio['images'] as List<dynamic>?) ??
                          const [],
                    ),
                    const SizedBox(height: 32),
                    PortfolioActionButtons(
                      onAccept: () => _updateRequestStatus(context, 'accepted'),
                      onReject: () => _updateRequestStatus(context, 'rejected'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
