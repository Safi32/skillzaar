import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:skillzaar/presentation/providers/skilled_worker_provider.dart';
import 'presentation/screens/role_selection_screen.dart';
import 'core/theme/app_theme.dart';
import 'presentation/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'presentation/providers/cnic_provider.dart';
import 'presentation/providers/profile_provider.dart';
import 'presentation/providers/home_profile_provider.dart';
import 'presentation/providers/auth_state_provider.dart';
import 'presentation/providers/phone_auth_provider.dart';
import 'presentation/providers/job_provider.dart';
import 'presentation/providers/ui_state_provider.dart';
import 'presentation/providers/location_state_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/screens/skilled_worker/skilled_worker_home_screen.dart';
import 'presentation/widgets/notification_initializer.dart';
import 'presentation/widgets/provider_connector.dart';
import 'core/services/notification_handler_service.dart';
import 'package:skillzaar/presentation/providers/locale_provider.dart';
import 'package:skillzaar/l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CnicProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PhoneAuthProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => SkilledWorkerProvider()),
        ChangeNotifierProvider(create: (_) => UIStateProvider()),
        ChangeNotifierProvider(create: (_) => LocationStateProvider()),
        ChangeNotifierProvider(create: (_) => HomeProfileProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AuthStateProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const NotificationInitializer(
        child: ProviderConnector(child: MyApp()),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    NotificationHandlerService.initialize(navigatorKey);

    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.themeData,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en', ''), Locale('ur', '')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthWrapper(),
          routes: {
            '/role-selection': (context) => const RoleSelectionScreen(),
            ...AppRoutes.routes,
          },
          onGenerateRoute: AppRoutes.onGenerateRoute,
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);

    switch (auth.status) {
      case AuthStatus.uninitialized:
      case AuthStatus.checkingSession:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AuthStatus.notLoggedIn:
        return const RoleSelectionScreen();

      case AuthStatus.loggingIn:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));

      case AuthStatus.loggedIn:
        if (auth.role == 'skilled_worker') {
          return const SkilledWorkerHomeScreen();
        }
        if (auth.role == 'job_poster') return const JobPosterSessionRouter();
        return const RoleSelectionScreen();
    }
  }
}

class JobPosterSessionRouter extends StatefulWidget {
  const JobPosterSessionRouter({super.key});

  @override
  State<JobPosterSessionRouter> createState() => _JobPosterSessionRouterState();
}

class _JobPosterSessionRouterState extends State<JobPosterSessionRouter> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_navigated) {
      _navigated = true;
      _handleRouting();
    }
  }

  Future<void> _handleRouting() async {
    final auth = Provider.of<AuthStateProvider>(context, listen: false);

    if (auth.status != AuthStatus.loggedIn || auth.role != 'job_poster') {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/role-selection',
          (route) => false,
        );
      }
      return;
    }

    final next = await auth.determineNextScreen();
    if (!mounted) return;

    switch (next) {
      case NextScreen.activeJobJobPoster:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-home',
          (route) => false,
        );
        break;
      case NextScreen.completeProfile:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-profile',
          (route) => false,
        );
        break;
      case NextScreen.homeJobPoster:
      case NextScreen.login:
      case NextScreen.homeSkilledWorker:
      case NextScreen.activeJobSkilledWorker:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/job-poster-home',
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
