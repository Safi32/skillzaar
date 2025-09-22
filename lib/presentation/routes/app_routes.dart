import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/screens/auth/job_poster_signup_screen.dart';
import 'package:skillzaar/presentation/screens/auth/login_screen.dart';

import '../screens/job_poster/otp_screen.dart'
    as job_poster_otp; // Restored OTP for job posters
import '../screens/job_poster/post_job_screen.dart';
import '../screens/job_poster/job_poster_home_screen.dart';
// import '../screens/job_poster/job_requests_screen.dart'; // Requests removed
import '../screens/job_poster/job_poster_profile_screen.dart';
import '../screens/job_poster/job_poster_detail_screen.dart';
import '../screens/job_poster/job_poster_ads_screen.dart';
import '../screens/job_poster/contact_us_screen.dart';
// import '../screens/skilled_worker/signup_screen.dart'; // Removed - skilled worker signup disabled
// import '../screens/skilled_worker/otp_screen.dart' as skilled_worker_otp; // OTP removed for skilled workers
import '../screens/skilled_worker/cnic_screen.dart';
import '../screens/skilled_worker/profile_screen.dart';
import '../screens/skilled_worker/home_screen_skilled.dart';
import '../screens/skilled_worker/home_profile_screen.dart';
import '../screens/skilled_worker/jobs_screen.dart';
// import '../screens/skilled_worker/accepted_requests_screen.dart'; // Requests removed
import '../screens/skilled_worker/job_detail_screen.dart' as skilled_worker;
import '../screens/skilled_worker/job_detail_screen_from_id.dart';
import '../screens/job_poster/job_detail_screen.dart';
import '../screens/job_poster/job_accepted_details_screen.dart';
import '../screens/skilled_worker/navigate_to_job_screen.dart';
import '../screens/skilled_worker/portfolio_overview_screen.dart';
import '../screens/skilled_worker/rate_job_poster_screen.dart';
import '../screens/shared/assigned_job_rating_screen.dart';
import '../screens/job_poster/skilled_worker_rate_job_poster_screen.dart';
import '../screens/test_notification_screen.dart';
import '../screens/admin/worker_approval_screen.dart';
// import '../screens/skilled_worker/approval_waiting_screen.dart'; // Removed - no approval needed for admin-created accounts
import '../screens/job_poster/worker_tracking_screen.dart';
import '../screens/shared/assigned_job_detail_screen.dart';
import '../providers/skilled_worker_provider.dart';
import '../providers/ui_state_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper function to safely convert Timestamp to DateTime
DateTime? _safeConvertToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/job-poster-login': (context) => LoginScreen(),
    '/job-poster-quick-register': (context) => LoginScreen(),
    '/job-poster-signup': (context) => const JobPosterSignUpScreen(),
    '/job-poster-otp': (context) => const job_poster_otp.JobPosterOTPScreen(),
    '/job-poster-post-job': (context) => const PostJobScreen(),
    '/job-poster-home': (context) => const JobPosterHomeScreen(),
    // '/job-poster-requests': (context) => const JobRequestsScreen(), // Removed
    '/job-poster-profile': (context) => const JobPosterProfileScreen(),
    '/job-poster-ads': (context) => const JobPosterAdsScreen(),
    '/job-poster-contact': (context) => const ContactUsScreen(),
    '/job-poster-detail': (context) => const JobPosterDetailScreen(),
    // '/skilled-worker-signup': (context) => const SkilledWorkerSignUpScreen(), // Disabled - skilled worker accounts are created by admin
    '/skilled-worker-login': (context) => LoginScreen(),
    // '/skilled-worker-otp': (context) => const skilled_worker_otp.SkilledWorkerOTPScreen(), // OTP removed for skilled workers
    '/skilled-worker-cnic': (context) => const CnicScreen(),
    '/skilled-worker-home': (context) => const HomeScreenSkilled(),
    '/skilled-worker-jobs': (context) => const SkilledWorkerJobsScreen(),
    // '/skilled-worker-accepted-requests':
    //     (context) => const AcceptedRequestsScreen(), // Removed
    '/test-notifications': (context) => const TestNotificationScreen(),
    '/admin-worker-approval': (context) => const WorkerApprovalScreen(),
    // '/skilled-worker-approval-waiting': (context) { // Removed - no approval needed for admin-created accounts
    //   final args =
    //       ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    //   return ApprovalWaitingScreen(
    //     userId: args?['userId'] ?? '',
    //     phoneNumber: args?['phoneNumber'] ?? '',
    //   );
    // },
    '/worker-tracking': (context) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return WorkerTrackingScreen(
        jobId: args?['jobId'] ?? '',
        workerId: args?['workerId'],
      );
    },
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
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder:
              (context) => JobDetailScreen(
                jobId: (args?['jobId'] ?? '').toString(),
                requestId: (args?['requestId'] ?? '').toString(),
              ),
        );
      case '/job-poster-accepted-details':
        final args = settings.arguments as Map<String, dynamic>?;
        final jobId = (args?['jobId'] ?? '').toString().trim();
        final requestId = (args?['requestId'] ?? '').toString().trim();

        // Debug logging
        print(
          '🔍 JobAcceptedDetailsScreen - JobId: "$jobId", RequestId: "$requestId"',
        );

        return MaterialPageRoute(
          builder:
              (context) =>
                  JobAcceptedDetailsScreen(jobId: jobId, requestId: requestId),
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
                  date: _safeConvertToDateTime(args['date']),
                  description: args['description'] ?? '',
                  jobId: args['jobId'] ?? '',
                  jobPosterId: args['jobPosterId'] ?? '',
                  requestId: args['requestId'] ?? '',
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
      case '/skilled-worker-rate-job-poster':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => SkilledWorkerRateJobPosterScreen(
                  jobPosterDetails: args['jobPosterDetails'] ?? {},
                  requestId: args['requestId'],
                ),
          );
        }
        break;
      case '/skilled-worker-rate-poster':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => RateJobPosterScreen(
                  assignedJobId: args['assignedJobId'] ?? '',
                  isJobCompletion: args['isJobCompletion'] ?? false,
                ),
          );
        }
        break;
      case '/job-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => JobDetailScreenFromId(jobId: args['jobId'] ?? ''),
          );
        }
        break;
      case '/assigned-job-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => AssignedJobDetailScreen(
                  assignedJobId: args['assignedJobId'] ?? '',
                  userType: args['userType'] ?? 'skilled_worker',
                ),
          );
        }
        break;
      case '/rate-skilled-worker':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => AssignedJobRatingScreen(
                  assignedJobId: args['assignedJobId'] ?? '',
                  isJobCompletion: args['isJobCompletion'] ?? false,
                ),
          );
        }
        break;
      case '/rate-job-poster':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return MaterialPageRoute(
            builder:
                (context) => RateJobPosterScreen(
                  assignedJobId: args['assignedJobId'] ?? '',
                  isJobCompletion: args['isJobCompletion'] ?? false,
                ),
          );
        }
        break;
    }
    return null;
  }
}
