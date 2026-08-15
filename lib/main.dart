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

  String? initError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppConfig.initialize(isDemoMode: false);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    initError = e.toString();
    AppConfig.initialize(isDemoMode: false);
  }

  runApp(ProviderScope(child: BmiTrackerApp(initError: initError)));
}

class BmiTrackerApp extends StatelessWidget {
  final String? initError;
  const BmiTrackerApp({super.key, this.initError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI Tracker',
      debugShowCheckedModeBanner: false,
      theme: getAppTheme(),
      home: initError != null
          ? FirebaseErrorScreen(error: initError!)
          : const AuthWrapper(),
    );
  }
}

class FirebaseErrorScreen extends StatelessWidget {
  final String error;
  const FirebaseErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.overweight),
              const SizedBox(height: 24),
              const Text(
                'Firebase Initialization Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The release app requires a valid Firebase backend connection to function properly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  error,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  main();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      ),
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
