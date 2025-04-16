// widgets/analytics_charts.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../utils/constants.dart';
import '../services/analytics_service.dart';
import '../utils/analytics_helpers.dart';

// Define the PomodoroSession model needed for the FocusDurationByTimeChart
class PomodoroSession {
  final DateTime startTime;
  final int duration; // in minutes

  PomodoroSession({
    required this.startTime,
    required this.duration,
  });
}

class PomodoroBarChart extends StatelessWidget {
  final List<Task> tasks;

  const PomodoroBarChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;

    // Calculate total pomodoro time
    int totalPomodoroMinutes = 0;
    for (final task in tasks) {
      totalPomodoroMinutes += task.pomodoroCount * task.pomodoroTime;
    }

    // Create bar chart data - limit to 5 bars on narrow screens
    final showTaskCount =
        isNarrowScreen ? math.min(5, tasks.length) : tasks.length;
    final displayTasks =
        tasks.length > showTaskCount ? tasks.sublist(0, showTaskCount) : tasks;

    final List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < displayTasks.length; i++) {
      final taskMinutes =
          displayTasks[i].pomodoroCount * displayTasks[i].pomodoroTime;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: taskMinutes.toDouble(),
              color: Theme.of(context).colorScheme.primary,
              width: isNarrowScreen ? 10 : 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.radiusSmall),
                topRight: Radius.circular(AppConstants.radiusSmall),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Total Focus Time: ${totalPomodoroMinutes} minutes',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
            height: isNarrowScreen
                ? AppConstants.spacing8
                : AppConstants.spacing16),
        if (tasks.length > showTaskCount && isNarrowScreen)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              'Showing top $showTaskCount tasks',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: barGroups.isEmpty
              ? const Center(child: Text('No data to display'))
              : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (barGroups.isNotEmpty
                            ? barGroups
                                .map((group) => group.barRods.first.toY)
                                .reduce((a, b) => a > b ? a : b)
                            : 0) *
                        1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < displayTasks.length) {
                              String title = displayTasks[value.toInt()].title;
                              // Get just first word or truncate
                              if (title.contains(" ")) {
                                title = title.split(" ")[0];
                              }
                              if (isNarrowScreen && title.length > 3) {
                                title = title.substring(0, 3) + "...";
                              } else if (title.length > 5) {
                                title = title.substring(0, 5) + "...";
                              }

                              return SizedBox(
                                width: isNarrowScreen
                                    ? 30
                                    : 40, // Fixed width for title, smaller on narrow screens
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: isNarrowScreen ? 4.0 : 8.0),
                                  child: Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontSize: isNarrowScreen ? 9.0 : null,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isNarrowScreen ? 24 : 30,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: isNarrowScreen ? 9.0 : null,
                                  ),
                            );
                          },
                        ),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: 20,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.1),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    barGroups: barGroups,
                  ),
                ),
        ),
      ],
    );
  }
}

class WeeklyProgressChart extends StatelessWidget {
  final List<Task> tasks;

  const WeeklyProgressChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;

    // Group tasks by day of week
    final Map<int, int> minutesByDay = {};
    for (final task in tasks) {
      if (task.completedAt != null) {
        final dayOfWeek = task.completedAt!.weekday;
        final minutes = task.pomodoroCount * task.pomodoroTime;

        minutesByDay[dayOfWeek] = (minutesByDay[dayOfWeek] ?? 0) + minutes;
      }
    }

    // Create line chart data
    final List<FlSpot> spots = [];
    for (int i = 1; i <= 7; i++) {
      spots.add(FlSpot(i.toDouble(), (minutesByDay[i] ?? 0).toDouble()));
    }

    return SizedBox(
      height: isNarrowScreen ? 160 : 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 30,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isNarrowScreen ? 20 : 30,
                getTitlesWidget: (value, meta) {
                  const days = [
                    '',
                    'Mon',
                    'Tue',
                    'Wed',
                    'Thu',
                    'Fri',
                    'Sat',
                    'Sun'
                  ];
                  if (value >= 1 && value <= 7) {
                    String label = days[value.toInt()];
                    if (isNarrowScreen) {
                      label = label.substring(
                          0, 1); // Just first letter on narrow screens
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: isNarrowScreen ? 9 : null,
                            ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: isNarrowScreen ? 28 : 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: isNarrowScreen ? 9 : null,
                        ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          minX: 1,
          maxX: 7,
          minY: 0,
          maxY: spots.isEmpty
              ? 60
              : (spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) *
                  1.2),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: isNarrowScreen ? 3 : 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: isNarrowScreen ? 3 : 4,
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: isNarrowScreen ? 1 : 2,
                      strokeColor: Colors.white,
                    );
                  }),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductivityLineChart extends StatelessWidget {
  final List<Task> tasks;

  const ProductivityLineChart({Key? key, required this.tasks})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analyticsService = AnalyticsService();

    // Calculate productivity score and components
    final productivityScore = analyticsService.getProductivityScore(tasks);
    final Map<String, double> scoreComponents =
        analyticsService.getProductivityScoreComponents(tasks);

    if (tasks.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No tasks to analyze yet',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Get the last 7 days for the chart
    final DateTime now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day - (6 - index));
    });

    // Group tasks by day and calculate productivity scores for each day
    final Map<String, List<Task>> tasksByDay = {};
    final Map<String, double> productivityByDay = {};

    for (final day in last7Days) {
      final dateKey = DateFormat('yyyy-MM-dd').format(day);
      // Get tasks created before or on this day
      final tasksUpToDay = tasks
          .where((task) =>
              task.createdAt.isBefore(day.add(const Duration(days: 1))))
          .toList();

      tasksByDay[dateKey] = tasksUpToDay;
      productivityByDay[dateKey] = tasksUpToDay.isEmpty
          ? 0.0
          : analyticsService.getProductivityScore(tasksUpToDay);
    }

    // Create spots for the line chart
    final List<FlSpot> productivitySpots = [];
    for (int i = 0; i < last7Days.length; i++) {
      final dateKey = DateFormat('yyyy-MM-dd').format(last7Days[i]);
      productivitySpots
          .add(FlSpot(i.toDouble(), productivityByDay[dateKey] ?? 0));
    }

    return Column(
      children: [
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                horizontalInterval: 20,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= last7Days.length) {
                        return const SizedBox();
                      }
                      final date = last7Days[value.toInt()];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('E').format(date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          value.toInt().toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                    reservedSize: 30,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
              ),
              minX: 0,
              maxX: last7Days.length - 1.0,
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: productivitySpots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Theme.of(context).colorScheme.surface,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final dateIndex = barSpot.x.toInt();
                      if (dateIndex >= 0 && dateIndex < last7Days.length) {
                        final date = last7Days[dateIndex];
                        final dateStr = DateFormat('MMM d').format(date);
                        return LineTooltipItem(
                          '$dateStr: ${barSpot.y.toInt()}%',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Score components breakdown
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Productivity: $productivityScore%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 12),

                // Completion percentage
                _buildScoreComponentRow(
                  context,
                  label: 'Completion',
                  value: scoreComponents['completionPercentage'] ?? 0,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),

                // Focus time percentage
                _buildScoreComponentRow(
                  context,
                  label: 'Focus Quality',
                  value: scoreComponents['focusTimePercentage'] ?? 0,
                  icon: Icons.timer_outlined,
                  color: Colors.blue,
                ),
                const SizedBox(height: 8),

                // Consistency score
                _buildScoreComponentRow(
                  context,
                  label: 'Consistency',
                  value: scoreComponents['consistencyPercentage'] ?? 0,
                  icon: Icons.calendar_month_outlined,
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreComponentRow(
    BuildContext context, {
    required String label,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    // Calculate the percentage (0.0 to 1.0)
    final percent = value / 100;

    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Stack(
          children: [
            // Background bar
            Container(
              width: 120,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            // Progress bar
            Container(
              width: 120 * percent,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class StreakProgressChart extends StatelessWidget {
  final List<Task> tasks;

  const StreakProgressChart({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final analyticsService = AnalyticsService();
    final currentStreak = analyticsService.getCurrentStreak(tasks);
    final longestStreak = analyticsService.getLongestStreak(tasks);

    // Get the last 7 days data for the chart
    final DateTime now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day - (6 - index));
    });

    // Get tasks completed on each day
    final Map<String, List<Task>> tasksByDay = {};
    for (final day in last7Days) {
      final dateKey = DateFormat('yyyy-MM-dd').format(day);
      tasksByDay[dateKey] = tasks.where((task) {
        return task.isCompleted &&
            task.completedAt != null &&
            DateFormat('yyyy-MM-dd').format(task.completedAt!) == dateKey;
      }).toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$currentStreak day streak',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Streak visualization
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: last7Days.map((day) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(day);
                  final tasksCompleted = tasksByDay[dateKey]?.length ?? 0;
                  final dayName = DateFormat('E').format(day);
                  final isToday =
                      DateFormat('yyyy-MM-dd').format(now) == dateKey;

                  // Calculate height percentage (max 100%)
                  final heightPercent = math.min(1.0,
                      tasksCompleted > 0 ? 0.7 + (tasksCompleted * 0.05) : 0.0);

                  return Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                                height: 70 * heightPercent,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: tasksCompleted > 0
                                      ? isToday
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.7)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: tasksCompleted > 0
                                      ? Text(
                                          '$tasksCompleted',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayName.substring(0, 1),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  context,
                  'Current',
                  '$currentStreak days',
                  Icons.local_fire_department,
                  Colors.orange,
                ),
                _buildStatItem(
                  context,
                  'Longest',
                  '$longestStreak days',
                  Icons.emoji_events,
                  Colors.amber,
                ),
                _buildStatItem(
                  context,
                  'Last 7 Days',
                  '${tasksByDay.values.fold<int>(0, (sum, list) => sum + (list.isNotEmpty ? 1 : 0))} days',
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

// Category distribution pie chart
class CategoryPieChart extends StatelessWidget {
  final List<Task> tasks;

  const CategoryPieChart({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;

    // Count tasks by category
    Map<String, int> tasksByCategory = {};

    for (final task in tasks) {
      // Extract category from description or use the task title
      final String category;
      if (task.description.toLowerCase().contains('category:')) {
        category = task.description
            .toLowerCase()
            .split('category:')[1]
            .trim()
            .split(RegExp(r'\s+'))[0];
      } else {
        category = 'Uncategorized';
      }

      tasksByCategory[category] = (tasksByCategory[category] ?? 0) + 1;
    }

    // Sort categories by count (descending)
    final sortedCategories = tasksByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // For narrow screens, only show top 3 categories plus "Others"
    final maxCategories = isNarrowScreen ? 3 : 5;
    if (sortedCategories.length > maxCategories) {
      final topCategories = sortedCategories.sublist(0, maxCategories);
      int othersCount = 0;

      for (int i = maxCategories; i < sortedCategories.length; i++) {
        othersCount += sortedCategories[i].value;
      }

      final processedCategories = Map.fromEntries(topCategories);
      if (othersCount > 0) {
        processedCategories['Others'] = othersCount;
      }
      tasksByCategory = processedCategories;
    }

    final double totalTasks =
        tasksByCategory.values.fold(0, (sum, count) => sum + count);

    // Create sections for pie chart
    final List<PieChartSectionData> sections = [];
    final colorPalette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    tasksByCategory.forEach((category, count) {
      final percentage = (count / totalTasks) * 100;
      sections.add(
        PieChartSectionData(
          color: colorPalette[colorIndex % colorPalette.length],
          value: count.toDouble(),
          title: isNarrowScreen ? '' : '${percentage.toStringAsFixed(0)}%',
          radius: isNarrowScreen ? 40 : 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Column(
      children: [
        Text(
          'Task Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: totalTasks == 0
              ? Center(child: Text('No data to display'))
              : Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: isNarrowScreen ? 0 : 20,
                          sections: sections,
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              // Optional callback for touch events
                            },
                          ),
                        ),
                      ),
                    ),

                    // Legend - Scrollable horizontal list for all screen sizes
                    Expanded(
                      flex: isNarrowScreen ? 2 : 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                List.generate(tasksByCategory.length, (index) {
                              final entry =
                                  tasksByCategory.entries.elementAt(index);
                              String categoryName = entry.key;
                              final count = entry.value;
                              final color =
                                  colorPalette[index % colorPalette.length];

                              // Truncate category name if too long
                              if (isNarrowScreen && categoryName.length > 8) {
                                categoryName =
                                    categoryName.substring(0, 8) + '...';
                              }

                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: isNarrowScreen ? 8 : 10,
                                      height: isNarrowScreen ? 8 : 10,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    SizedBox(width: isNarrowScreen ? 2 : 4),
                                    Text(
                                      '$categoryName (${(count / totalTasks * 100).toStringAsFixed(0)}%)',
                                      style: TextStyle(
                                        fontSize: isNarrowScreen ? 9 : 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// Task completion pie chart
class TaskCompletionPieChart extends StatelessWidget {
  final List<Task> tasks;

  const TaskCompletionPieChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;
    final isVeryNarrowScreen = screenWidth < 350;

    if (tasks.isEmpty) {
      return Center(
        child: Text(
          'No tasks to display',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Count completed and incomplete tasks
    final completed = tasks.where((task) => task.isCompleted).length;
    final incomplete = tasks.length - completed;

    // Calculate percentages
    final completedPercentage =
        tasks.isEmpty ? 0 : (completed / tasks.length * 100).round();
    final incompletePercentage = 100 - completedPercentage;

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Task Completion Rate',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: PieChart(
            PieChartData(
              borderData: FlBorderData(show: false),
              sectionsSpace: 0,
              centerSpaceRadius:
                  isVeryNarrowScreen ? 25 : (isNarrowScreen ? 30 : 40),
              sections: [
                if (completed > 0)
                  PieChartSectionData(
                    color: Theme.of(context).colorScheme.primary,
                    value: completed.toDouble(),
                    title: isVeryNarrowScreen
                        ? '$completedPercentage%'
                        : '$completedPercentage%\nDone',
                    radius:
                        isVeryNarrowScreen ? 40 : (isNarrowScreen ? 50 : 60),
                    titleStyle: TextStyle(
                      fontSize:
                          isVeryNarrowScreen ? 10 : (isNarrowScreen ? 12 : 16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (incomplete > 0)
                  PieChartSectionData(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.8),
                    value: incomplete.toDouble(),
                    title: isVeryNarrowScreen
                        ? '$incompletePercentage%'
                        : '$incompletePercentage%\nTodo',
                    radius:
                        isVeryNarrowScreen ? 40 : (isNarrowScreen ? 50 : 60),
                    titleStyle: TextStyle(
                      fontSize:
                          isVeryNarrowScreen ? 10 : (isNarrowScreen ? 12 : 16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (tasks.isEmpty)
                  PieChartSectionData(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.5),
                    value: 1,
                    title: 'No data',
                    radius:
                        isVeryNarrowScreen ? 40 : (isNarrowScreen ? 50 : 60),
                    titleStyle: TextStyle(
                      fontSize:
                          isVeryNarrowScreen ? 10 : (isNarrowScreen ? 12 : 14),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        SizedBox(height: isVeryNarrowScreen ? 5 : 10),
        _buildLegend(context, isVeryNarrowScreen, isNarrowScreen),
      ],
    );
  }

  Widget _buildLegend(
      BuildContext context, bool isVeryNarrowScreen, bool isNarrowScreen) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem(
            context,
            'Completed',
            Theme.of(context).colorScheme.primary,
            isVeryNarrowScreen,
            isNarrowScreen,
          ),
          SizedBox(width: isVeryNarrowScreen ? 6 : 10),
          _buildLegendItem(
            context,
            'Pending',
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
            isVeryNarrowScreen,
            isNarrowScreen,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color,
      bool isVeryNarrowScreen, bool isNarrowScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isVeryNarrowScreen ? 8 : (isNarrowScreen ? 10 : 12),
          height: isVeryNarrowScreen ? 8 : (isNarrowScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isVeryNarrowScreen ? 2 : 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: isVeryNarrowScreen ? 9 : (isNarrowScreen ? 10 : 12),
              ),
        ),
      ],
    );
  }
}

// Completion time line chart
class CompletionTimeLineChart extends StatelessWidget {
  final List<Task> tasks;

  const CompletionTimeLineChart({super.key, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 400;
    final isVeryNarrowScreen = screenWidth < 350;

    final completedTasks = tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .toList();

    if (completedTasks.isEmpty) {
      return Center(
        child: Text(
          'No completed tasks to display',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    // Group tasks by date
    final Map<DateTime, List<Task>> tasksByDate = {};
    for (final task in completedTasks) {
      final date = DateTime(task.completedAt!.year, task.completedAt!.month,
          task.completedAt!.day);

      if (!tasksByDate.containsKey(date)) {
        tasksByDate[date] = [];
      }
      tasksByDate[date]!.add(task);
    }

    // Sort dates
    final dates = tasksByDate.keys.toList()..sort();

    // Limit to last 5 dates on very narrow screens, 5 on narrow, 7 on larger screens to avoid overcrowding
    final daysToShow = isVeryNarrowScreen ? 4 : (isNarrowScreen ? 5 : 7);
    if (dates.length > daysToShow) {
      dates.removeRange(0, dates.length - daysToShow);
    }

    // Create line chart spots
    final List<FlSpot> spots = [];
    for (int i = 0; i < dates.length; i++) {
      final tasksOnDate = tasksByDate[dates[i]]!;
      spots.add(FlSpot(i.toDouble(), tasksOnDate.length.toDouble()));
    }

    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Tasks Completed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: isNarrowScreen ? false : true,
                horizontalInterval: 1,
                verticalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                    strokeWidth: 1,
                  );
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: isNarrowScreen ? 20 : 30,
                    interval: 1,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < dates.length) {
                        // Different date format based on screen width
                        final dateFormat = isVeryNarrowScreen
                            ? 'd'
                            : (isNarrowScreen ? 'dd' : 'MM/dd');
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 8.0,
                          child: Text(
                            DateFormat(dateFormat).format(dates[index]),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontSize: isVeryNarrowScreen
                                          ? 8
                                          : (isNarrowScreen ? 9 : 10),
                                    ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      return Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: isVeryNarrowScreen
                                  ? 8
                                  : (isNarrowScreen ? 9 : 10),
                            ),
                      );
                    },
                    reservedSize:
                        isVeryNarrowScreen ? 20 : (isNarrowScreen ? 24 : 42),
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3)),
              ),
              minX: 0,
              maxX: dates.length - 1.0,
              minY: 0,
              maxY: spots.map((spot) => spot.y).reduce(math.max) + 1,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Theme.of(context).colorScheme.primary,
                  barWidth: isVeryNarrowScreen ? 2 : (isNarrowScreen ? 3 : 3),
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius:
                            isVeryNarrowScreen ? 2 : (isNarrowScreen ? 3 : 4),
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth:
                            isVeryNarrowScreen ? 1 : (isNarrowScreen ? 1 : 2),
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Theme.of(context).colorScheme.surface,
                  tooltipRoundedRadius: 8,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      final dateIndex = barSpot.x.toInt();
                      if (dateIndex >= 0 && dateIndex < dates.length) {
                        final date = dates[dateIndex];
                        final dateStr =
                            DateFormat(isVeryNarrowScreen ? 'd' : 'MMM d')
                                .format(date);
                        final taskCount = barSpot.y.toInt();
                        return LineTooltipItem(
                          '$dateStr: $taskCount',
                          TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: isVeryNarrowScreen
                                ? 9
                                : (isNarrowScreen ? 10 : 12),
                          ),
                        );
                      }
                      return null;
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Focus duration distribution by time of day
class FocusDurationByTimeChart extends StatelessWidget {
  final List<PomodoroSession> sessions;

  const FocusDurationByTimeChart({Key? key, required this.sessions})
      : super(key: key);

  // Time of day labels for the x-axis
  final List<String> _timeLabels = const [
    'Morning',
    'Afternoon',
    'Evening',
    'Night'
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVeryNarrowScreen = screenWidth < 320;
    final isNarrowScreen = screenWidth < 400;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isVeryNarrowScreen ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Focus Time by Time of Day',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            SizedBox(height: 4),
            Expanded(
              child: FutureBuilder<Map<String, double>>(
                future: _calculateDurationByTimeOfDay(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text('No focus data available'),
                    );
                  }

                  Map<String, double> durationMap = snapshot.data!;
                  return _buildChart(
                      context, durationMap, isVeryNarrowScreen, isNarrowScreen);
                },
              ),
            ),
            SizedBox(height: isVeryNarrowScreen ? 4 : 8),
            _buildLegend(context, isVeryNarrowScreen, isNarrowScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, Map<String, double> durationMap,
      bool isVeryNarrowScreen, bool isNarrowScreen) {
    double maxHeight =
        durationMap.values.isEmpty ? 0 : durationMap.values.reduce(math.max);

    if (maxHeight == 0) {
      return Center(child: Text('No focus data available'));
    }

    return LayoutBuilder(builder: (context, constraints) {
      double barWidth = math.min(
        isVeryNarrowScreen ? 25 : (isNarrowScreen ? 35 : 45),
        (constraints.maxWidth - 32) / 4,
      );

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBar(
              context,
              'Morning',
              Colors.blue,
              durationMap['Morning'] ?? 0,
              maxHeight,
              barWidth,
              isVeryNarrowScreen,
              isNarrowScreen),
          _buildBar(
              context,
              'Afternoon',
              Colors.green,
              durationMap['Afternoon'] ?? 0,
              maxHeight,
              barWidth,
              isVeryNarrowScreen,
              isNarrowScreen),
          _buildBar(
              context,
              'Evening',
              Colors.orange,
              durationMap['Evening'] ?? 0,
              maxHeight,
              barWidth,
              isVeryNarrowScreen,
              isNarrowScreen),
          _buildBar(context, 'Night', Colors.purple, durationMap['Night'] ?? 0,
              maxHeight, barWidth, isVeryNarrowScreen, isNarrowScreen),
        ],
      );
    });
  }

  Widget _buildBar(
      BuildContext context,
      String label,
      Color color,
      double value,
      double maxHeight,
      double barWidth,
      bool isVeryNarrowScreen,
      bool isNarrowScreen) {
    // Scale height proportion to available space
    double heightPercent = (value / maxHeight);
    // Ensure it's at least 1 for visibility
    heightPercent =
        heightPercent.isNaN || heightPercent <= 0 ? 0.05 : heightPercent;
    // Cap max height to prevent extremely tall bars
    heightPercent = math.min(heightPercent, 1.0);

    // For very small screens, we need even smaller components
    final double maxBarHeight =
        isVeryNarrowScreen ? 70 : (isNarrowScreen ? 80 : 100);
    final double barHeight = math.max(1.0, heightPercent * maxBarHeight);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: barHeight,
            width: barWidth,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(
      BuildContext context, bool isVeryNarrowScreen, bool isNarrowScreen) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: isVeryNarrowScreen ? 9 : null,
        );

    return Padding(
      padding: EdgeInsets.only(top: isVeryNarrowScreen ? 4.0 : 8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem(
                context, 'Morning', Colors.blue, isVeryNarrowScreen, textStyle),
            SizedBox(width: isVeryNarrowScreen ? 4 : 8),
            _buildLegendItem(context, 'Afternoon', Colors.green,
                isVeryNarrowScreen, textStyle),
            SizedBox(width: isVeryNarrowScreen ? 4 : 8),
            _buildLegendItem(context, 'Evening', Colors.orange,
                isVeryNarrowScreen, textStyle),
            SizedBox(width: isVeryNarrowScreen ? 4 : 8),
            _buildLegendItem(
                context, 'Night', Colors.purple, isVeryNarrowScreen, textStyle),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String text, Color color,
      bool isVeryNarrowScreen, TextStyle? textStyle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isVeryNarrowScreen ? 8 : 12,
          height: isVeryNarrowScreen ? 8 : 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: isVeryNarrowScreen ? 2 : 4),
        Text(
          text,
          style: textStyle,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }

  Future<Map<String, double>> _calculateDurationByTimeOfDay() async {
    // Sample data for demonstration
    Map<String, double> result = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Night': 0
    };

    for (var session in sessions) {
      final hour = session.startTime.hour;

      if (hour >= 5 && hour < 12) {
        result['Morning'] = (result['Morning'] ?? 0) + session.duration;
      } else if (hour >= 12 && hour < 17) {
        result['Afternoon'] = (result['Afternoon'] ?? 0) + session.duration;
      } else if (hour >= 17 && hour < 21) {
        result['Evening'] = (result['Evening'] ?? 0) + session.duration;
      } else {
        result['Night'] = (result['Night'] ?? 0) + session.duration;
      }
    }

    return result;
  }
}
