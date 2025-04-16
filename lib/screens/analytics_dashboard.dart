// screens/analytics_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../widgets/analytics_charts.dart';
import '../widgets/pomodoro_breakdown_widget.dart';
import '../models/task_model.dart';

class AnalyticsDashboard extends StatelessWidget {
  const AnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final allTasks = taskProvider.tasks;

    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAnalyticsData(taskProvider, allTasks),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Error loading analytics: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        final data = snapshot.data!;
        final completedTasks = data['completedTasks'] as List<Task>;
        final pendingTasks = data['pendingTasks'] as List<Task>;
        final totalFocusTime = data['totalFocusTime'] as int;
        final productivityScore = data['productivityScore'] as int;
        final totalSessions = data['totalSessions'] as int;
        final mostProductiveDay = data['mostProductiveDay'] as String;
        final currentStreak = data['currentStreak'] as int;
        final longestStreak = data['longestStreak'] as int;
        final todayFocusTime = data['todayFocusTime'] as int;
        final avgTimePerSession = data['avgTimePerSession'] as double;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Productivity Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing16),

              // Today's stats
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Focus",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacing12),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacing16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${todayFocusTime}min',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          Text('Focus Time',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.orange,
                                size: 20,
                              ),
                              Text(
                                '$currentStreak',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                              ),
                            ],
                          ),
                          Text('Day Streak',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Stats cards
              Text(
                'Overall Stats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing12),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: AppConstants.spacing12,
                mainAxisSpacing: AppConstants.spacing12,
                children: [
                  _buildStatCard(
                    context,
                    title: 'Total Focus Time',
                    value: '${totalFocusTime}min',
                    icon: Icons.timer,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Productivity Score',
                    value: '$productivityScore%',
                    icon: Icons.trending_up,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Total Sessions',
                    value: '$totalSessions',
                    icon: Icons.repeat,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Avg. per Session',
                    value: '${avgTimePerSession.toStringAsFixed(1)}min',
                    icon: Icons.av_timer,
                    color: Colors.purple,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Best Day',
                    value: mostProductiveDay,
                    icon: Icons.emoji_events,
                    color: Colors.teal,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Longest Streak',
                    value: '$longestStreak days',
                    icon: Icons.local_fire_department,
                    color: Colors.deepOrange,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Completion Status
              Text(
                'Productivity Trend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing16),
              ProductivityLineChart(tasks: allTasks),

              const SizedBox(height: AppConstants.spacing24),

              // Weekly chart
              Text(
                'Weekly Progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacing16),
                  child: WeeklyProgressChart(tasks: completedTasks),
                ),
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Weekly progress
              Text(
                'Weekly Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing16),
              StreakProgressChart(tasks: allTasks),

              const SizedBox(height: AppConstants.spacing24),

              // Pomodoro time breakdown
              Text(
                'Task Distribution',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.spacing16),
              SizedBox(
                height: 200,
                child: PomodoroBarChart(tasks: completedTasks),
              ),

              const SizedBox(height: AppConstants.spacing24),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadAnalyticsData(
      TaskProvider taskProvider, List<Task> allTasks) async {
    final completedTasks = await taskProvider.getCompletedTasks();
    final pendingTasks = await taskProvider.getPendingTasks();

    final analyticsService = AnalyticsService();
    final totalFocusTime = analyticsService.getTotalFocusTime(completedTasks);
    final productivityScore = analyticsService.getProductivityScore(allTasks);
    final totalSessions =
        analyticsService.getTotalPomodoroSessions(completedTasks);
    final mostProductiveDay =
        analyticsService.getMostProductiveDay(completedTasks);
    final currentStreak = analyticsService.getCurrentStreak(completedTasks);
    final longestStreak = analyticsService.getLongestStreak(completedTasks);
    final todayFocusTime = analyticsService.getTodayFocusTime(completedTasks);
    final avgTimePerSession =
        analyticsService.getAverageFocusTimePerSession(completedTasks);

    return {
      'completedTasks': completedTasks,
      'pendingTasks': pendingTasks,
      'totalFocusTime': totalFocusTime,
      'productivityScore': productivityScore,
      'totalSessions': totalSessions,
      'mostProductiveDay': mostProductiveDay,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'todayFocusTime': todayFocusTime,
      'avgTimePerSession': avgTimePerSession,
    };
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
