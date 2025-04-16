import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/task_model.dart';
import '../utils/constants.dart';

class PomodoroBreakdownWidget extends StatelessWidget {
  final List<Task> tasks;

  const PomodoroBreakdownWidget({
    Key? key,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group tasks by name and calculate total pomodoro time
    final Map<String, int> timeByTask = {};
    int totalTime = 0;

    for (final task in tasks) {
      if (task.isCompleted) {
        final minutes = task.pomodoroCount * task.pomodoroTime;
        timeByTask[task.title] = (timeByTask[task.title] ?? 0) + minutes;
        totalTime += minutes;
      }
    }

    // Sort tasks by time (descending)
    final List<MapEntry<String, int>> sortedEntries =
        timeByTask.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Get top 5 tasks (or fewer if not enough)
    final List<MapEntry<String, int>> topTasks = sortedEntries.take(5).toList();

    // Calculate percentages and create pie chart sections
    final List<PieChartSectionData> sections = [];
    final List<Color> colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];

    // Create a legend data
    final List<Widget> legendItems = [];

    for (int i = 0; i < topTasks.length; i++) {
      final entry = topTasks[i];
      final percentage = totalTime > 0 ? (entry.value / totalTime) * 100 : 0;
      final color = colors[i % colors.length];

      sections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      legendItems.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(
                '${entry.value} min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    if (tasks.isEmpty || topTasks.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Not enough data to show breakdown'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pomodoro Time Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacing16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 30,
                        sections: sections,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spacing16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top Tasks',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: AppConstants.spacing8),
                      ...legendItems,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing8),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Total: $totalTime minutes',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
