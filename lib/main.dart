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
import 'presentation/providers/phone_auth_provider.dart';
import 'presentation/providers/job_provider.dart';
import 'presentation/providers/ui_state_provider.dart';
import 'presentation/providers/location_state_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/widgets/splash_and_dialog_gate.dart';
import 'presentation/widgets/notification_initializer.dart';
import 'presentation/widgets/provider_connector.dart';
import 'presentation/widgets/active_work_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Temporarily disable App Check until API is enabled
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.playIntegrity,
  //   appleProvider: AppleProvider.appAttest,
  // );
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
      ],
      child: const NotificationInitializer(
        child: ProviderConnector(child: MyApp()),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: const SplashAndDialogGate(),
      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        ...AppRoutes.routes,
      },
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
