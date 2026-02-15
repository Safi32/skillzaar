
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skillzaar/presentation/screens/skilled_worker/home_screen_skilled.dart';
import 'package:skillzaar/presentation/widgets/bottom_bar_widget.dart';
import '../../widgets/contact_us_dialog.dart';
import '../../widgets/filter_dialog.dart';
import '../../widgets/skilled_worker_drawer_header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/skilled_worker_provider.dart';
import '../../providers/ui_state_provider.dart';
import 'jobs_screen.dart';
import 'home_profile_screen.dart';
// import 'requests_screen.dart'; // Requests removed
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/job_request_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_state_provider.dart';

class SkilledWorkerHomeScreen extends StatelessWidget {
  const SkilledWorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<SkilledWorkerProvider, UIStateProvider>(
      builder: (context, skilledWorkerProvider, uiProvider, child) {
        return _HomeContent(
          skilledWorkerProvider: skilledWorkerProvider,
          uiProvider: uiProvider,
        );
      },
    );
  }
}

class _HomeContent extends StatefulWidget {
  final SkilledWorkerProvider skilledWorkerProvider;
  final UIStateProvider uiProvider;

  const _HomeContent({
    required this.skilledWorkerProvider,
    required this.uiProvider,
  });

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  int _selectedIndex = 0;
  String _selectedJobType = 'All';
  double _selectedRadius = 50.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription<QuerySnapshot>? _assignedJobsSub;
  bool _navigatedToAssignedJob = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncAuthProvider();
      _initializeLocationServices();
      _maybeRedirectToActiveJob();
      _startAssignedJobListener();
    });
  }

  void _syncAuthProvider() {
    final skilledWorkerProvider = Provider.of<SkilledWorkerProvider>(
      context,
      listen: false,
    );
    final authProvider = Provider.of<AuthStateProvider>(context, listen: false);

    if (skilledWorkerProvider.loggedInUserId == null &&
        authProvider.status == AuthStatus.loggedIn &&
        authProvider.role == 'skilled_worker') {
      skilledWorkerProvider.setLoggedInState(
        userId: authProvider.userId!,
        phoneNumber: authProvider.currentUser?.phone ?? '',
      );
    }
  }

  void _initializeLocationServices() {
    final provider = Provider.of<SkilledWorkerProvider>(context, listen: false);
    provider.initializeLocationServices();
  }

  Future<void> _maybeRedirectToActiveJob() async {
    try {
      final provider = Provider.of<SkilledWorkerProvider>(
        context,
        listen: false,
      );

      // Build a workerId to search by; prefer provider's id
      String? workerId = provider.loggedInUserId;

      // Fallback: try FirebaseAuth uid if available
      workerId ??= FirebaseAuth.instance.currentUser?.uid;

      if (workerId == null || workerId.isEmpty) {
        return; // no identity available, skip redirect
      }

      final active = await JobRequestService.getActiveAssignedJobForWorker(
        workerId,
      );

      if (!mounted || active == null) return;

      final assignedJobId = active['assignedJobId'] as String?;
      if (assignedJobId == null || assignedJobId.isEmpty) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/assigned-job-detail',
        (route) => false,
        arguments: {
          'assignedJobId': assignedJobId,
          'userType': 'skilled_worker',
        },
      );
    } catch (_) {
      // best-effort; ignore failures
    }
  }

  void _startAssignedJobListener() async {
    try {
      final provider = Provider.of<SkilledWorkerProvider>(
        context,
        listen: false,
      );

      String? workerId =
          provider.loggedInUserId ?? FirebaseAuth.instance.currentUser?.uid;

      if (workerId == null || workerId.isEmpty) return;

      await _assignedJobsSub?.cancel();
      _assignedJobsSub = FirebaseFirestore.instance
          .collection('AssignedJobs')
          .where('workerId', isEqualTo: workerId)
          .where('assignmentStatus', whereIn: ['assigned', 'in_progress'])
          .where('isActive', isEqualTo: true)
          .snapshots()
          .listen((snapshot) {
        if (!mounted || _navigatedToAssignedJob) return;
        if (snapshot.docs.isEmpty) return;

        final doc = snapshot.docs.first;
        final assignedJobId = doc.id;
        if (assignedJobId.isEmpty) return;

        _navigatedToAssignedJob = true;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/assigned-job-detail',
          (route) => false,
          arguments: {
            'assignedJobId': assignedJobId,
            'userType': 'skilled_worker',
          },
        );
      });
    } catch (e) {
      print('[SkilledWorkerHome] Error starting assigned job listener: $e');
    }
  }

  void _onItemTapped(int index) {
    widget.uiProvider.setLoading(true);
    setState(() {
      _selectedIndex = index;
    });
    widget.uiProvider.setLoading(false);
  }

  void _showContactUsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const ContactUsDialog());
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => FilterDialog(
            selectedJobType: _selectedJobType,
            selectedRadius: _selectedRadius,
            onJobTypeChanged: (type) => setState(() => _selectedJobType = type),
            onRadiusChanged: (value) => setState(() => _selectedRadius = value),
            onReset: () {
              setState(() {
                _selectedJobType = 'All';
                _selectedRadius = 50.0;
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Filters reset to default'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onApply: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Filters applied: ${_selectedJobType} jobs within ${_selectedRadius.round()} km',
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
    );
  }

  void _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('role');
        await prefs.remove('userId');
        await prefs.remove('name');

      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/role-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreenSkilled(),
      const SkilledWorkerJobsScreen(),
      const HomeProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        centerTitle: true,
        elevation: 5,
        title: Text(
          _getTitle(_selectedIndex),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),

        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () => _showFilterDialog(context),
            ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SkilledWorkerDrawerHeader(),
            ListTile(
              leading: const Icon(Icons.contact_support, color: Colors.green),
              title: const Text('Contact Us'),
              onTap: () {
                Navigator.pop(context);
                _showContactUsDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_rate, color: Colors.amber),
              title: const Text('Rate Job Poster'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/skilled-worker-rate-poster');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
          ],
        ),
      ),
      body: pages[_selectedIndex],
      floatingActionButton: FloatingIslandNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'All Ads';
      case 2:
        return 'Requests';
      case 3:
        return 'Profile';
      default:
        return 'All Jobs';
    }
  }
}
