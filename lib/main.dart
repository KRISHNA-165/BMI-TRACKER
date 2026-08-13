import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/home_screen.dart';
import 'screens/onboarding/user_details_screen.dart';
import 'services/storage_service.dart';
import 'utils/app_config.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  // Attempt real Firebase initialization.
  // If it fails (e.g. no network, misconfigured), fall back to Demo Mode.
  bool isDemoMode;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isDemoMode = false;
  } catch (e) {
    debugPrint('Firebase initialization failed — switching to Demo Mode: $e');
    isDemoMode = true;
  }

  AppConfig.initialize(isDemoMode: isDemoMode);

  runApp(const ProviderScope(child: BmiTrackerApp()));
}

class BmiTrackerApp extends StatelessWidget {
  const BmiTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Tracker',
      debugShowCheckedModeBanner: false,
      theme: getAppTheme(),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        final profileState = ref.watch(profileNotifierProvider);

        if (profileState.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // No profiles yet → mandatory User Details onboarding
        if (profileState.activeProfile == null) {
          return const UserDetailsScreen();
        }

        return const HomeScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, stack) => const LoginScreen(),
    );
  }
}
