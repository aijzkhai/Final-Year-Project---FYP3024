import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/constants.dart';
import '../screens/home_screen.dart';
import '../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final StorageService _storageService = StorageService();
  int _currentPage = 0;
  final int _totalPages = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markOnboardingComplete() async {
    await _storageService.saveOnboardingComplete(true);
  }

  void _onNextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _markOnboardingComplete();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _onSkip() {
    _markOnboardingComplete();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _onSkip,
                child: const Text('Skip'),
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage(
                    icon: FontAwesomeIcons.clock,
                    title: 'Welcome to FocusMate',
                    description:
                        'Your personal productivity companion that helps you stay focused and accomplish more with the Pomodoro technique.',
                    color: Colors.blue,
                  ),
                  _buildPage(
                    icon: FontAwesomeIcons.listCheck,
                    title: 'Manage Tasks',
                    description:
                        'Create and organize your tasks. Set specific Pomodoro timer settings for each task based on its complexity.',
                    color: Colors.green,
                  ),
                  _buildPage(
                    icon: FontAwesomeIcons.fire,
                    title: 'Build Streaks',
                    description:
                        'Complete tasks daily to build streaks. Track your progress and stay motivated with our gamification features.',
                    color: Colors.orange,
                  ),
                  _buildPage(
                    icon: FontAwesomeIcons.chartLine,
                    title: 'Track Progress',
                    description:
                        'Visualize your productivity with detailed analytics. See when you are most productive and how you spend your focus time.',
                    color: Colors.purple,
                  ),
                  _buildPage(
                    icon: FontAwesomeIcons.robot,
                    title: 'Meet FocusMate AI',
                    description:
                        'Get personalized productivity tips and task recommendations from your AI assistant. Just tap the pen icon and select "Chat with FocusMate AI".',
                    color: Colors.teal,
                  ),
                ],
              ),
            ),

            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Next button
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              child: ElevatedButton(
                onPressed: _onNextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                ),
                child: Text(
                  _currentPage == _totalPages - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon,
            size: 100,
            color: color,
          )
              .animate()
              .scale(
                duration: 600.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0.5, 0.5),
                end: const Offset(1.0, 1.0),
              )
              .fadeIn(duration: 600.ms),
          const SizedBox(height: AppConstants.spacing32),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 400.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}
