import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/home_screen.dart';
import '../utils/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildWelcomePage(),
                  _buildFeaturesPage(),
                  _buildGetStartedPage(),
                ],
              ),
            ),
            _buildPageIndicator(),
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: _currentPage < _totalPages - 1
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            _navigateToHomePage();
                          },
                          child: const Text('Skip'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: AppConstants.mediumAnimation,
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Next'),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToHomePage();
                        },
                        child: const Text('Get Started'),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          )
              .animate()
              .fade(duration: AppConstants.mediumAnimation)
              .scale(delay: AppConstants.shortAnimation),
          const SizedBox(height: AppConstants.spacing24),
          Text(
            'Welcome to ${AppConstants.appName}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fade(delay: AppConstants.shortAnimation)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            'Boost your productivity with a professional Pomodoro timer app',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          )
              .animate()
              .fade(delay: AppConstants.mediumAnimation)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildFeaturesPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Key Features',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacing32),
          ...AppConstants.welcomeFeatures.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spacing16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.check, color: Colors.white),
                    ),
                  ).animate().fade(
                        delay: Duration(milliseconds: 100 * entry.key),
                      ),
                  const SizedBox(width: AppConstants.spacing16),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: Theme.of(context).textTheme.bodyLarge,
                    )
                        .animate()
                        .fade(delay: Duration(milliseconds: 100 * entry.key))
                        .slideX(begin: 0.2, end: 0),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // screens/welcome_screen.dart (fixing any syntax issues)
  Widget _buildGetStartedPage() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_objects,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ).animate().fade().scale(),
          const SizedBox(height: AppConstants.spacing24),
          Text(
            'Ready to boost productivity?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ).animate().fade().slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            'Create tasks, set timers, and track your progress with our Pomodoro app',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          )
              .animate()
              .fade(delay: AppConstants.shortAnimation)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _totalPages,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  void _navigateToHomePage() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }
}
