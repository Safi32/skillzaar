import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/screens/auth/job_poster_signup_screen.dart';
import 'package:skillzaar/presentation/screens/auth/login_screen.dart';


import '../screens/job_poster/otp_screen.dart' as job_poster_otp;
import '../screens/job_poster/post_job_screen.dart';
import '../screens/job_poster/job_poster_home_screen.dart';
import '../screens/job_poster/job_requests_screen.dart';
import '../screens/job_poster/job_poster_profile_screen.dart';
import '../screens/job_poster/job_poster_ads_screen.dart';
import '../screens/job_poster/contact_us_screen.dart';
import '../screens/skilled_worker/signup_screen.dart';
import '../screens/skilled_worker/otp_screen.dart' as skilled_worker_otp;
import '../screens/skilled_worker/cnic_screen.dart';
import '../screens/skilled_worker/profile_screen.dart';
import '../screens/skilled_worker/home_screen.dart';
import '../screens/skilled_worker/home_profile_screen.dart';
import '../screens/skilled_worker/jobs_screen.dart';
import '../screens/skilled_worker/accepted_requests_screen.dart';
import '../screens/skilled_worker/job_detail_screen.dart' as skilled_worker;
import '../screens/job_poster/job_detail_screen.dart';
import '../screens/skilled_worker/navigate_to_job_screen.dart';
import '../screens/skilled_worker/portfolio_overview_screen.dart';
import '../providers/skilled_worker_provider.dart';
import '../providers/ui_state_provider.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/job-poster-login': (context) => LoginScreen(),
    '/job-poster-quick-register': (context) => LoginScreen(),
  '/job-poster-signup':
    (context) => const JobPosterSignUpScreen(),
    '/job-poster-otp': (context) => const job_poster_otp.JobPosterOTPScreen(),
    '/job-poster-post-job': (context) => const PostJobScreen(),
    '/job-poster-home': (context) => const JobPosterHomeScreen(),
    '/job-poster-requests': (context) => const JobRequestsScreen(),
    '/job-poster-profile': (context) => const JobPosterProfileScreen(),
    '/job-poster-ads': (context) => const JobPosterAdsScreen(),
    '/job-poster-contact': (context) => const ContactUsScreen(),
  '/job-poster-job-detail': (context) => const JobDetailScreen(),
  '/skilled-worker-signup': (context) => const SkilledWorkerSignUpScreen(),
  '/skilled-worker-login': (context) => LoginScreen(),
    '/skilled-worker-otp':
        (context) => const skilled_worker_otp.SkilledWorkerOTPScreen(),
    '/skilled-worker-cnic': (context) => const CnicScreen(),
    '/skilled-worker-home': (context) => const SkilledWorkerHomeScreen(),
    '/skilled-worker-jobs': (context) => const SkilledWorkerJobsScreen(),
    '/skilled-worker-accepted-requests':
        (context) => const AcceptedRequestsScreen(),
  };
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/skilled-worker-profile':
        return MaterialPageRoute(
          builder:
              (context) => Consumer2<SkilledWorkerProvider, UIStateProvider>(
                builder: (context, skilledWorkerProvider, uiProvider, child) {
                  return ProfileScreen(
                    skilledWorkerProvider: skilledWorkerProvider,
                    uiProvider: uiProvider,
                  );
                },
              ),
        );
      case '/skilled-worker-home-profile':
        return MaterialPageRoute(
          builder: (context) => const HomeProfileScreen(),
        );
      case '/portfolio-overview':
        return MaterialPageRoute(
          builder: (context) => const PortfolioOverviewScreen(),
        );
      case '/job-poster-job-detail':
        return MaterialPageRoute(
          builder: (context) => const JobDetailScreen(),
        );
      case '/skilled-worker-job-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => skilled_worker.JobDetailScreen(
                  imageUrl: args['imageUrl'] ?? '',
                  title: args['title'] ?? '',
                  location: args['location'] ?? '',
                  date: args['date'],
                  description: args['description'] ?? '',
                  jobId: args['jobId'] ?? '',
                  jobPosterId: args['jobPosterId'] ?? '',
                ),
          );
        }
        break;
      case '/skilled-worker-navigate':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => NavigateToJobScreen(
                  jobId: args['jobId'] ?? '',
                  jobTitle: args['jobTitle'] ?? '',
                  jobAddress: args['jobAddress'] ?? '',
                  jobLatitude: args['jobLatitude'] ?? 0.0,
                  jobLongitude: args['jobLongitude'] ?? 0.0,
                ),
          );
        }
        break;
    }
    return null;
  }
}
