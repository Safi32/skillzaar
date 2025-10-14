import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillzaar/presentation/screens/job_poster/home_screen.dart';
import 'package:skillzaar/presentation/widgets/bottom_bar_widget.dart';
import '../../providers/ui_state_provider.dart';
import 'job_poster_ads_screen.dart';
// import 'job_requests_screen.dart'; // Requests removed
import 'job_poster_profile_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:skillzaar/presentation/widgets/job_poster_drawer.dart';
import 'package:skillzaar/presentation/widgets/location_permission_dialog.dart';
import 'package:skillzaar/presentation/widgets/location_settings_dialog.dart';
import 'package:skillzaar/presentation/widgets/logout_dialog.dart';
import '../../providers/phone_auth_provider.dart';
import '../../../core/services/job_request_service.dart';
// import 'job_requests_screen.dart'; // Requests removed

class JobPosterHomeScreen extends StatelessWidget {
  const JobPosterHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UIStateProvider>(
      builder: (context, uiProvider, child) {
        return _JobPosterHomeContent(uiProvider: uiProvider);
      },
    );
  }
}

class _JobPosterHomeContent extends StatefulWidget {
  final UIStateProvider uiProvider;

  const _JobPosterHomeContent({required this.uiProvider});

  @override
  State<_JobPosterHomeContent> createState() => _JobPosterHomeContentState();
}

class _JobPosterHomeContentState extends State<_JobPosterHomeContent> {
  int _selectedIndex = 0;
  bool _hasShownLocationPrompt = false;

  late List<Widget> _pages;
  bool _showMyAdsOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLocationPermissionPrompt();
      _maybeRedirectToActiveJob();
    });
    _pages = [
      HomeScreen(),
      JobPosterAdsScreen(
        myAdsOnly: _showMyAdsOnly,
        isGuest:
            Provider.of<PhoneAuthProvider>(
                      context,
                      listen: false,
                    ).loggedInUserId ==
                    null
                ? true
                : false,
      ),
      const JobPosterProfileScreen(),
    ];

    log(
      Provider.of<PhoneAuthProvider>(
        context,
        listen: false,
      ).loggedInUserId.toString(),
    );
  }

  Future<void> _maybeRedirectToActiveJob() async {
    try {
      // Get job poster ID from provider
      final phoneAuthProvider = Provider.of<PhoneAuthProvider>(
        context,
        listen: false,
      );
      final jobPosterId = phoneAuthProvider.loggedInUserId;
      final jobPosterPhone = phoneAuthProvider.loggedInPhoneNumber;

      if (jobPosterId == null || jobPosterId.isEmpty) return;

      print(
        '[JobPosterHome] Checking for active job - JobPosterId: $jobPosterId',
      );

      // Check for active job
      final active = await JobRequestService.getActiveRequestForPoster(
        jobPosterId,
        posterPhone: jobPosterPhone,
      );

      if (!mounted || active == null) return;

      final jobId = active['jobId'] as String?;
      final requestId = active['requestId'] as String?;
      final status = active['status'] as String?;

      if (jobId == null || jobId.isEmpty) return;

      print(
        '[JobPosterHome] Found active job - JobId: $jobId, Status: $status',
      );

      // Redirect based on job status
      if (status == 'in_progress') {
        // In progress jobs go to job detail screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-job-detail',
          (route) => false,
          arguments: {'jobId': jobId, 'requestId': requestId},
        );
      } else if (status == 'accepted') {
        // Accepted jobs go to accepted details screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-accepted-details',
          (route) => false,
          arguments: {'jobId': jobId, 'requestId': requestId},
        );
      }
    } catch (e) {
      print('[JobPosterHome] Error checking for active job: $e');
    }
  }

  // Reserved for future: redirect to accepted/in-progress job if needed
  /* Future<void> _maybeRedirectToAccepted() async {
    final currentPosterId =
        JobRequestService.getCurrentUserId() ?? 'TEST_POSTER_ID';
    Map<String, dynamic>? req =
        await JobRequestService.getAcceptedRequestForPoster(currentPosterId);
    if (!mounted) return;
    if (req != null && req['status'] == 'accepted') {
      final request = req;  
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => JobAcceptedDetailsScreen(
                jobId: (request['jobId'] ?? '').toString(),
                requestId: (request['requestId'] ?? '').toString(),
              ),
        ),
      );
      return;
    }
    // If not accepted, check for in-progress
    req = await JobRequestService.getInProgressRequestForPoster(
      currentPosterId,
    );
    if (!mounted) return;
    // No in-progress screen in current flow. Keep user on home if not accepted.
  } */

  Future<void> _showLocationPermissionPrompt() async {
    if (_hasShownLocationPrompt) return;

    setState(() {
      _hasShownLocationPrompt = true;
    });

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      _showLocationDialog();
    } else if (permission == LocationPermission.deniedForever) {
      _showLocationSettingsDialog();
    }
  }

  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LocationPermissionDialog(
          onTurnOnLocation: _requestLocationPermission,
        );
      },
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LocationSettingsDialog(
          onOpenSettings: () async {
            await Geolocator.openAppSettings();
          },
        );
      },
    );
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      await Future.delayed(const Duration(milliseconds: 500));

      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location access granted! You can now post jobs with precise locations.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location access denied. You can still post jobs but location features will be limited.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error requesting location permission: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _switchAdsView({required bool myAds}) {
    setState(() {
      _showMyAdsOnly = myAds;
      _pages[1] = JobPosterAdsScreen(
        myAdsOnly: _showMyAdsOnly,
        isGuest:
            Provider.of<PhoneAuthProvider>(
                      context,
                      listen: false,
                    ).loggedInUserId ==
                    null
                ? true
                : false,
      );
      _selectedIndex = 1;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: JobPosterDrawer(
        onPostJob: () {
          Navigator.pop(context);
          Provider.of<PhoneAuthProvider>(
                    context,
                    listen: false,
                  ).loggedInUserId ==
                  null
              ? ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please login first to post a job.'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 4),
                ),
              )
              : Navigator.pushNamed(context, '/job-poster-post-job');
        },
        onAllAds: () => _switchAdsView(myAds: false),
        onMyAds: () => _switchAdsView(myAds: true),
        onLogout: () => _showLogoutDialog(context),
      ),
      body: Column(
        children: [
          // 🔹 Custom App Bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: Row(
                children: [
                  // Drawer icon
                  Builder(
                    builder:
                        (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.green),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                  ),

                  // Search bar in center
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Notification icon at the end
                  IconButton(
                    icon: const Icon(Icons.notifications, color: Colors.green),
                    onPressed: () {
                      // Handle notifications
                    },
                  ),
                ],
              ),
            ),
          ),

          // 🔹 Main page content
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingIslandNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return LogoutDialog(
          onLogout: () {
            Navigator.of(context).pushReplacementNamed('/role-selection');
          },
        );
      },
    );
  }
}
