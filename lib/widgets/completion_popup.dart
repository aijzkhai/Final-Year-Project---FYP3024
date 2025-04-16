// widgets/completion_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../models/task_model.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class CompletionPopup extends StatelessWidget {
  final Task task;
  final VoidCallback onClose;

  const CompletionPopup({
    super.key,
    required this.task,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Choose colors based on theme
    final backgroundColor = isDarkMode ? const Color(0xFF262640) : Colors.white;
    final shadowColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
    final dividerColor = isDarkMode ? Colors.grey[700] : Colors.grey[300];
    final highlightBgColor = isDarkMode
        ? Colors.green.withOpacity(0.2)
        : Colors.green.withOpacity(0.1);
    final highlightBorderColor = isDarkMode
        ? Colors.green.withOpacity(0.5)
        : Colors.green.withOpacity(0.3);
    final highlightTextColor =
        isDarkMode ? Colors.green[400] : Colors.green[700];
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
      ),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.green,
                size: 40,
              ),
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: AppConstants.spacing16),

            // Congratulations text
            Text(
              'Congratulations!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: const Duration(milliseconds: 300)),

            const SizedBox(height: AppConstants.spacing8),

            // Task completed text
            Text(
              'You have successfully completed:',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: const Duration(milliseconds: 400)),

            const SizedBox(height: AppConstants.spacing16),

            // Task name
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacing16,
                vertical: AppConstants.spacing8,
              ),
              decoration: BoxDecoration(
                color: highlightBgColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                border: Border.all(color: highlightBorderColor),
              ),
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: highlightTextColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 500)).slideY(
                  begin: 0.5,
                  end: 0,
                  delay: const Duration(milliseconds: 500),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: AppConstants.spacing16),

            // Task stats
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.timer,
                  value: '${task.pomodoroTime} min',
                  label: 'Per Session',
                  highlightColor: highlightTextColor,
                  secondaryColor: secondaryTextColor,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: dividerColor,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing12,
                  ),
                ),
                _buildStatItem(
                  context,
                  icon: Icons.repeat,
                  value: '${task.pomodoroCount}',
                  label: 'Sessions',
                  highlightColor: highlightTextColor,
                  secondaryColor: secondaryTextColor,
                ),
              ],
            ).animate().fadeIn(delay: const Duration(milliseconds: 600)),

            const SizedBox(height: AppConstants.spacing24),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                ),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 700)).slideY(
                  begin: 0.5,
                  end: 0,
                  delay: const Duration(milliseconds: 700),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color? highlightColor,
    required Color? secondaryColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: highlightColor,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: highlightColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: secondaryColor,
              ),
        ),
      ],
    );
  }
}
