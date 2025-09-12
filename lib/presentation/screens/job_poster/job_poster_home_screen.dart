import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ui_state_provider.dart';
import 'job_poster_ads_screen.dart';
import 'job_requests_screen.dart';
import 'job_poster_profile_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/job_request_service.dart';
import 'in_progress_job_screen.dart';
import 'job_accepted_details_screen.dart';
import 'package:skillzaar/presentation/widgets/job_poster_drawer.dart';
import 'package:skillzaar/presentation/widgets/location_permission_dialog.dart';
import 'package:skillzaar/presentation/widgets/location_settings_dialog.dart';
import 'package:skillzaar/presentation/widgets/logout_dialog.dart';

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
      _maybeRedirectToAccepted();
    });
    _pages = [
      JobPosterAdsScreen(myAdsOnly: _showMyAdsOnly),
      const JobRequestsScreen(),
      const JobPosterProfileScreen(),
    ];
  }

  Future<void> _maybeRedirectToAccepted() async {
    final currentPosterId = JobRequestService.getCurrentUserId() ?? 'TEST_POSTER_ID';
    Map<String, dynamic>? req = await JobRequestService.getAcceptedRequestForPoster(currentPosterId);
    if (!mounted) return;
    if (req != null && req['status'] == 'accepted') {
      // Fetch job details
      final jobDetails = await JobRequestService.getJobDetails(req['jobId'] as String);
      // Fetch skilled worker details
      final skilledWorkerDetails = await JobRequestService.getSkilledWorkerDetails(req['skilledWorkerId'] as String);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => JobAcceptedDetailsScreen(
            jobDetails: jobDetails ?? {},
            skilledWorkerDetails: skilledWorkerDetails ?? {
              'name': req?['skilledWorkerName'] ?? '-',
              'phone': req?['skilledWorkerPhone'] ?? '-',
              'email': req?['skilledWorkerEmail'] ?? '-',
            },
            isJobCompleted: false,
          ),
        ),
      );
      return;
    }
    // If not accepted, check for in-progress
    req = await JobRequestService.getInProgressRequestForPoster(currentPosterId);
    if (!mounted) return;
    if (req != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const InProgressJobScreen()),
      );
    }
  }

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
    widget.uiProvider.setLoading(true);
    _selectedIndex = index;
    widget.uiProvider.setLoading(false);
  }

  void _switchAdsView({required bool myAds}) {
    setState(() {
      _showMyAdsOnly = myAds;
      _pages[0] = JobPosterAdsScreen(myAdsOnly: _showMyAdsOnly);
      _selectedIndex = 0; 
    });
    Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? (_showMyAdsOnly ? 'My Ads' : 'All Ads')
              : _selectedIndex == 1
              ? 'Requests'
              : 'Profile',
        ),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: JobPosterDrawer(
        onPostJob: () => Navigator.pushNamed(context, '/job-poster-post-job'),
        onAllAds: () => _switchAdsView(myAds: false),
        onMyAds: () => _switchAdsView(myAds: true),
        onLogout: () => _showLogoutDialog(context),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
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
