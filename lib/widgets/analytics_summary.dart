import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';

class AnalyticsSummary extends StatelessWidget {
  final List<Task> tasks;
  final bool isCompact;

  const AnalyticsSummary({
    Key? key,
    required this.tasks,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analyticsService = AnalyticsService();
    final todayFocusTime = analyticsService.getTodayFocusTime(tasks);
    final currentStreak = analyticsService.getCurrentStreak(tasks);
    final productivityScore = analyticsService.getProductivityScore(tasks);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(
            isCompact ? AppConstants.spacing12 : AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today's Overview",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getProductivityColor(productivityScore)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getProductivityIcon(productivityScore),
                        size: 16,
                        color: _getProductivityColor(productivityScore),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${productivityScore.toInt()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getProductivityColor(productivityScore),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Today's Focus Time
                _buildMetricItem(
                  context,
                  value: '$todayFocusTime',
                  unit: 'min',
                  label: 'Focus Time',
                  icon: Icons.timer,
                  color: Theme.of(context).colorScheme.primary,
                ),

                // Streak
                _buildMetricItem(
                  context,
                  value: '$currentStreak',
                  unit: 'days',
                  label: 'Current Streak',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String value,
    required String unit,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final TextStyle? valueStyle = isCompact
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            )
        : Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            );

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: valueStyle,
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: color.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Color _getProductivityColor(double score) {
    if (score >= 75) return Colors.green;
    if (score >= 50) return Colors.amber;
    if (score >= 25) return Colors.orange;
    return Colors.red;
  }

  IconData _getProductivityIcon(double score) {
    if (score >= 75) return Icons.sentiment_very_satisfied;
    if (score >= 50) return Icons.sentiment_satisfied;
    if (score >= 25) return Icons.sentiment_neutral;
    return Icons.sentiment_dissatisfied;
  }
}
