// screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';
import '../utils/app_info.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Add a slight delay for the splash screen to be visible
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      // For web, we'll use a simpler authentication check
      bool isAuthenticated = false;
      bool isOnboardingComplete = false;

      final authService = AuthService();

      try {
        isAuthenticated = await authService.isAuthenticated();
        print('Authentication check result: $isAuthenticated');
      } catch (e) {
        print('Authentication check failed: $e');
        isAuthenticated = false;
      }

      try {
        isOnboardingComplete = await _storageService.isOnboardingComplete();
        print('Onboarding check result: $isOnboardingComplete');
      } catch (e) {
        print('Onboarding check failed: $e');
        isOnboardingComplete = kIsWeb ? true : false; // Assume completed on web
      }

      if (!mounted) return;

      // If we're in web mode and getting errors, default to auth screen
      if (kIsWeb && (_errorMessage != null)) {
        print('Web mode with error, navigating to auth screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
        return;
      }

      // If user is authenticated but hasn't completed onboarding, show onboarding
      if (isAuthenticated && !isOnboardingComplete) {
        print('User authenticated but needs onboarding');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        // Otherwise, show home screen or auth screen based on authentication status
        print('Navigating to ${isAuthenticated ? 'home' : 'auth'} screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                isAuthenticated ? const HomeScreen() : const AuthScreen(),
          ),
        );
      }
    } catch (e) {
      print('Navigation error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });

        // After error, show auth screen after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            print('Error occurred, navigating to auth screen');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthScreen()),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Icon(
                Icons.timer,
                size: 80,
                color: AppColors.primary,
              ),
            ).animate().fade(duration: 500.ms).scale(delay: 300.ms),

            const SizedBox(height: AppConstants.spacing24),

            // App name
            Text(
              AppInfo.appName,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fade(delay: 500.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppConstants.spacing8),

            // Tagline
            Text(
              AppInfo.appTagline,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
            ).animate().fade(delay: 700.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppConstants.spacing32),

            // Error message if any
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.red[100],
                    ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 900.ms),

            if (_errorMessage == null)
              // Loading indicator
              const CircularProgressIndicator(
                color: Colors.white,
              ).animate().fade(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}
