// screens/auth_screen.dart (improved animations)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../screens/welcome_screen.dart';
import '../screens/sign_in_screen.dart';
import '../screens/sign_up_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/spash.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top illustration section
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App name
                    Text(
                      'HELLO',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 40,
                              ),
                    )
                        .animate(
                            onPlay: (controller) => controller.repeat(
                                reverse: true, period: 3.seconds))
                        .fadeIn(duration: 1.seconds, curve: Curves.easeOutQuad)
                        .slide(
                            begin: const Offset(0, -0.1),
                            end: Offset.zero,
                            duration: 1.seconds,
                            curve: Curves.easeOutQuad)
                        .then()
                        .moveY(
                            begin: 0,
                            end: 5,
                            duration: 3.seconds,
                            curve: Curves.easeInOut),

                    // Subtitle
                    Text(
                      'Focus better with Pomodoro',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    )
                        .animate()
                        .fadeIn(
                            duration: 800.ms,
                            delay: 400.ms,
                            curve: Curves.easeOut)
                        .slideY(
                            begin: -0.2, end: 0, curve: Curves.easeOutCubic),

                    // Removing the city skyline illustration
                  ],
                ),
              ),

              // Bottom authentication buttons
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.spacing24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Sign In button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SignInScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeOutCubic;
                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(
                                    position: offsetAnimation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 500),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacing16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: 600.ms,
                              delay: 400.ms,
                              curve: Curves.easeOut)
                          .slideY(
                              begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: AppConstants.spacing16),

                      // Sign Up button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SignUpScreen(),
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                const begin = Offset(1.0, 0.0);
                                const end = Offset.zero;
                                const curve = Curves.easeOutCubic;
                                var tween = Tween(begin: begin, end: end)
                                    .chain(CurveTween(curve: curve));
                                var offsetAnimation = animation.drive(tween);
                                return SlideTransition(
                                    position: offsetAnimation, child: child);
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 500),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppConstants.spacing16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: 600.ms,
                              delay: 600.ms,
                              curve: Curves.easeOut)
                          .slideY(
                              begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: AppConstants.spacing24),

                      // Skip button
                      TextButton(
                        onPressed: () async {
                          final authService = AuthService();
                          await authService.skipAuthentication();

                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        const WelcomeScreen(),
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  const begin = 0.0;
                                  const end = 1.0;
                                  const curve = Curves.easeInOut;
                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));
                                  var opacityAnimation = animation.drive(tween);
                                  return FadeTransition(
                                      opacity: opacityAnimation, child: child);
                                },
                                transitionDuration:
                                    const Duration(milliseconds: 500),
                              ),
                            );
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.9),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          backgroundColor: Colors.black.withOpacity(0.3),
                        ),
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(
                              duration: 600.ms,
                              delay: 800.ms,
                              curve: Curves.easeOut)
                          .animate(
                              onPlay: (controller) => controller.repeat(
                                  reverse: true, period: 3.seconds))
                          .fadeOut(duration: 1.5.seconds),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
