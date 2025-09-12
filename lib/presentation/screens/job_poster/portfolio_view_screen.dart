import 'package:flutter/material.dart';
import '../../widgets/portfolio_professional_header.dart';
import '../../widgets/portfolio_worker_details.dart';
import '../../widgets/portfolio_skills.dart';
import '../../widgets/portfolio_experience.dart';
import '../../widgets/portfolio_bio.dart';
import '../../widgets/portfolio_images.dart';
import '../../widgets/portfolio_action_buttons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
    final doc = await FirebaseFirestore.instance.collection('SkilledWorkers').doc(skilledWorkerId).get();
    return doc.data();
  }

  Future<Map<String, dynamic>?> _fetchRequestData() async {
    final doc = await FirebaseFirestore.instance.collection('JobRequests').doc(requestId).get();
    return doc.data();
  }

  void _updateRequestStatus(BuildContext context, String status) async {
    await FirebaseFirestore.instance.collection('JobRequests').doc(requestId).update({'status': status, 'isActive': false});
    Navigator.of(context).pop();
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
                    PortfolioProfessionalHeader(skilledWorkerName: skilledWorkerName),
                    const SizedBox(height: 20),
                    PortfolioWorkerDetails(
                      phone: portfolio['userPhone']?.toString() ?? 'Not provided',
                      rate: portfolio['rate']?.toString() ?? 'Not specified',
                      availability: portfolio['availability']?.toString() ?? 'Not specified',
                    ),
                    const SizedBox(height: 20),
                    PortfolioSkills(
                      skills: (portfolio['skills'] as List<dynamic>?) ?? [],
                    ),
                    const SizedBox(height: 20),
                    PortfolioExperience(
                      experience: portfolio['experience']?.toString() ?? '',
                    ),
                    const SizedBox(height: 20),
                    PortfolioBio(
                      bio: portfolio['bio']?.toString() ?? '',
                    ),
                    const SizedBox(height: 20),
                    PortfolioImages(
                      images: (portfolio['portfolioImages'] as List<dynamic>?) ?? [],
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


