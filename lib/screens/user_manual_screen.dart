import 'package:flutter/material.dart';
import '../utils/constants.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Manual'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        children: [
          _buildSection(
            context,
            title: 'Getting Started',
            content:
                'Welcome to FocusMate! This manual will help you understand how to use the app effectively for your productivity needs.',
            image: Image.asset(
              'assets/images/manual_1.png',
              fit: BoxFit.none,
            ),
          ),
          _buildSection(
            context,
            title: 'Creating Tasks',
            content:
                'Tap the pencil button on the home screen to create a new task. Fill in the task details including title, description, and Pomodoro settings (focus time, break duration, and number of pomodoros).',
            image: Image.asset(
              'assets/images/manual_2.png',
              fit: BoxFit.none,
            ),
          ),
          _buildSection(
            context,
            title: 'Pomodoro Timer',
            content:
                'The Pomodoro technique uses time blocks to improve focus:\n\n• Focus Session: Default 25 minutes of concentrated work\n• Short Break: Default 5 minutes to rest\n• Long Break: Default 15 minutes after completing 4 focus sessions',
            image: Image.asset(
              'assets/images/manual_8.png',
              fit: BoxFit.none,
            ),
          ),
          _buildSection(
            context,
            title: 'Chat with FocusMate AI',
            content:
                'Need help with your tasks or productivity tips? Chat with our FocusMate AI assistant by tapping the "+" button and selecting "Chat with DeepSeek AI". The AI can help you create optimized tasks and provide personalized productivity advice.',
            image: Image.asset(
              'assets/images/manual_3.png',
              fit: BoxFit.none,
            ),
          ),
          _buildSection(
            context,
            title: 'Task Management',
            content:
                'You can view your pending tasks on the home screen. Completed tasks are moved to the "Completed Tasks" section which can be accessed from the side menu. To start working on a task, tap the "Start" button on any task card.',
            image: Image.asset(
              'assets/images/manual_4.png',
              fit: BoxFit.none,
            ),
          ),
          _buildSection(
            context,
            title: 'Analytics & Progress Tracking',
            content:
                'The app provides detailed analytics to help you understand your productivity patterns. View charts of your completed tasks, focus time, and more in the Analytics section accessible from the side menu.',
            image: Image.asset(
              'assets/images/manual_5.png',
              fit: BoxFit.none,
            ),
          ),
          _buildSection(
            context,
            title: 'Streak System',
            content:
                'Maintain your productivity streak by completing at least one task each day. Your current streak is displayed on the home screen. The longer your streak, the more motivated you\'ll stay!',
            image: Image.asset(
              'assets/images/manual_6.png',
              fit: BoxFit.none,
            ),
          ),
          _buildSection(
            context,
            title: 'Settings & Customization',
            content:
                'Customize your experience in the Settings screen:\n\n• Timer settings: Adjust focus and break durations\n• Auto-start options for breaks and pomodoros\n• Notifications: Enable/disable sounds and vibrations\n• Theme: Toggle between light and dark modes\n• Profile: Manage your account details',
            image: Image.asset(
              'assets/images/manual_7.png',
              fit: BoxFit.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    bool imagePlaceholder = false,
    Widget? image,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacing12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (image != null) ...[
            const SizedBox(height: AppConstants.spacing16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppConstants.radiusMedium - 1),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: image,
                  ),
                ),
              ),
            ),
          ] else if (imagePlaceholder) ...[
            const SizedBox(height: AppConstants.spacing16),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: Colors.grey.withOpacity(0.7),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    'Screenshot placeholder for ${title}',
                    style: TextStyle(color: Colors.grey.withOpacity(0.7)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacing4),
                  Text(
                    'Tap to add screenshot',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppConstants.spacing16),
          const Divider(),
        ],
      ),
    );
  }
}
