import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:skillzaar/firebase_options.dart';
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

import 'presentation/screens/job_poster/job_poster_home_screen.dart';
import 'presentation/screens/skilled_worker/skilled_worker_home_screen.dart';

import 'presentation/widgets/notification_initializer.dart';
import 'presentation/widgets/provider_connector.dart';
import 'core/services/notification_handler_service.dart';

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

        /// NEW → Only THIS provider handles login + OTP + FirebaseAuth internally
        ChangeNotifierProvider(create: (_) => AuthStateProvider()),
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

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const AuthWrapper(),
      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        ...AppRoutes.routes,
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);

    switch (auth.status) {
      case AuthStatus.uninitialized:
      case AuthStatus.checkingSession:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case AuthStatus.notLoggedIn:
        return const RoleSelectionScreen();

      case AuthStatus.loggingIn:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );

      case AuthStatus.loggedIn:
        if (auth.role == "skilled_worker") {
          return const SkilledWorkerHomeScreen();
        }
        if (auth.role == "job_poster") {
          return const JobPosterHomeScreen();
        }

        return const RoleSelectionScreen();
    }
  }
}
