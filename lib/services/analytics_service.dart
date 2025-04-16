// services/analytics_service.dart
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/task_model.dart';

class AnalyticsService {
  // Get total completed pomodoro sessions
  int getTotalPomodoroSessions(List<Task> tasks) {
    return tasks
        .where((task) => task.isCompleted)
        .map((task) => task.pomodoroCount)
        .fold(0, (previous, count) => previous + count);
  }

  // Get total pomodoro minutes
  int getTotalFocusTime(List<Task> tasks) {
    return tasks
        .where((task) => task.isCompleted)
        .map((task) => task.pomodoroCount * task.pomodoroTime)
        .fold(0, (previous, minutes) => previous + minutes);
  }

  // Get average focus time per session
  double getAverageFocusTimePerSession(List<Task> tasks) {
    final totalSessions = getTotalPomodoroSessions(tasks);
    if (totalSessions == 0) return 0.0;

    final totalMinutes = getTotalFocusTime(tasks);
    return totalMinutes / totalSessions;
  }

  // Get focus hours for today
  int getTodayFocusTime(List<Task> tasks) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .where((task) {
          final taskDate = DateTime(
            task.completedAt!.year,
            task.completedAt!.month,
            task.completedAt!.day,
          );
          return taskDate.isAtSameMomentAs(todayDate);
        })
        .map((task) => task.pomodoroCount * task.pomodoroTime)
        .fold(0, (previous, minutes) => previous + minutes);
  }

  // Get focus time streak (consecutive days with completed pomodoros)
  int getCurrentStreak(List<Task> tasks) {
    if (tasks.isEmpty) return 0;

    // Get all days with completed tasks
    final Set<String> daysWithCompletedTasks = tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .map((task) => DateFormat('yyyy-MM-dd').format(task.completedAt!))
        .toSet();

    if (daysWithCompletedTasks.isEmpty) return 0;

    // Sort dates
    final sortedDates = daysWithCompletedTasks.toList()..sort();

    // Check if today has tasks
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hasTasksToday = daysWithCompletedTasks.contains(today);

    // Calculate streak
    int streak = hasTasksToday ? 1 : 0;
    if (streak == 0) return 0;

    // Work backwards from yesterday
    var currentDate = DateTime.now().subtract(const Duration(days: 1));

    while (true) {
      final dateStr = DateFormat('yyyy-MM-dd').format(currentDate);
      if (daysWithCompletedTasks.contains(dateStr)) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // Get longest streak
  int getLongestStreak(List<Task> tasks) {
    if (tasks.isEmpty) return 0;

    // Get all days with completed tasks
    final List<DateTime> datesWithTasks = tasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .map((task) => DateTime(
              task.completedAt!.year,
              task.completedAt!.month,
              task.completedAt!.day,
            ))
        .toList();

    if (datesWithTasks.isEmpty) return 0;

    // Sort dates
    datesWithTasks.sort();

    int currentStreak = 1;
    int longestStreak = 1;

    for (int i = 1; i < datesWithTasks.length; i++) {
      final difference =
          datesWithTasks[i].difference(datesWithTasks[i - 1]).inDays;

      if (difference == 1) {
        // Consecutive day
        currentStreak++;
        longestStreak =
            currentStreak > longestStreak ? currentStreak : longestStreak;
      } else if (difference > 1) {
        // Streak broken
        currentStreak = 1;
      }
    }

    return longestStreak;
  }

  // Get tasks grouped by day
  Map<DateTime, List<Task>> getTasksByDay(List<Task> tasks) {
    final Map<DateTime, List<Task>> result = {};

    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final date = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );

        if (!result.containsKey(date)) {
          result[date] = [];
        }

        result[date]!.add(task);
      }
    }

    return result;
  }

  // Get tasks grouped by week
  Map<int, List<Task>> getTasksByWeek(List<Task> tasks) {
    final Map<int, List<Task>> result = {};

    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final weekNumber = _getWeekNumber(task.completedAt!);

        if (!result.containsKey(weekNumber)) {
          result[weekNumber] = [];
        }

        result[weekNumber]!.add(task);
      }
    }

    return result;
  }

  // Get tasks grouped by month
  Map<String, List<Task>> getTasksByMonth(List<Task> tasks) {
    final Map<String, List<Task>> result = {};

    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final monthKey = DateFormat('yyyy-MM').format(task.completedAt!);

        if (!result.containsKey(monthKey)) {
          result[monthKey] = [];
        }

        result[monthKey]!.add(task);
      }
    }

    return result;
  }

  // Get productivity score (0-100)
  double getProductivityScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0;

    // Calculate completion percentage
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final completionPercentage = (completedTasks.length / tasks.length) * 100;

    // Calculate focus time percentage - how much of the scheduled pomodoro time was actually completed
    double focusTimePercentage = 0;
    if (tasks.isNotEmpty) {
      final totalScheduledMinutes = tasks.fold<int>(
          0, (sum, task) => sum + task.pomodoroTime * task.pomodoroCount);

      final totalCompletedMinutes = completedTasks.fold<int>(
          0, (sum, task) => sum + task.pomodoroTime * task.pomodoroCount);

      if (totalScheduledMinutes > 0) {
        focusTimePercentage =
            (totalCompletedMinutes / totalScheduledMinutes) * 100;
      }
    }

    // Calculate weekly consistency score
    final consistencyPercentage = _getWeeklyConsistencyScore(tasks);

    // Calculate weighted average
    final weightedScore = (completionPercentage * 0.4) +
        (focusTimePercentage * 0.4) +
        (consistencyPercentage * 0.2);

    return min(100, max(0, weightedScore));
  }

  Map<String, double> getProductivityScoreComponents(List<Task> tasks) {
    if (tasks.isEmpty) {
      return {
        'completionPercentage': 0,
        'focusTimePercentage': 0,
        'consistencyPercentage': 0,
      };
    }

    // Calculate completion percentage
    final completedTasks = tasks.where((task) => task.isCompleted).toList();
    final completionPercentage = (completedTasks.length / tasks.length) * 100;

    // Calculate focus time percentage
    double focusTimePercentage = 0;
    final totalScheduledMinutes = tasks.fold<int>(
        0, (sum, task) => sum + task.pomodoroTime * task.pomodoroCount);

    final totalCompletedMinutes = completedTasks.fold<int>(
        0, (sum, task) => sum + task.pomodoroTime * task.pomodoroCount);

    if (totalScheduledMinutes > 0) {
      focusTimePercentage =
          (totalCompletedMinutes / totalScheduledMinutes) * 100;
    }

    // Calculate weekly consistency score
    final consistencyPercentage = _getWeeklyConsistencyScore(tasks);

    return {
      'completionPercentage': min(100, max(0, completionPercentage)),
      'focusTimePercentage': min(100, max(0, focusTimePercentage)),
      'consistencyPercentage': min(100, max(0, consistencyPercentage)),
    };
  }

  // Calculate weekly consistency score (percentage of days in last week with activity)
  double _getWeeklyConsistencyScore(List<Task> tasks) {
    if (tasks.isEmpty) return 0;

    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));

    // Get dates with completed tasks in the last week
    final Set<String> daysWithTasksLastWeek = tasks
        .where((task) =>
            task.isCompleted &&
            task.completedAt != null &&
            task.completedAt!.isAfter(oneWeekAgo))
        .map((task) => DateFormat('yyyy-MM-dd').format(task.completedAt!))
        .toSet();

    // Calculate percentage (out of 7 days)
    return (daysWithTasksLastWeek.length / 7) * 100;
  }

  // Get daily average pomodoro sessions
  double getDailyAveragePomodoroSessions(List<Task> tasks) {
    final tasksByDay = getTasksByDay(tasks);
    if (tasksByDay.isEmpty) return 0;

    final totalSessions = getTotalPomodoroSessions(tasks);
    return totalSessions / tasksByDay.length;
  }

  // Get most productive day of week
  String getMostProductiveDay(List<Task> tasks) {
    if (tasks.isEmpty) return 'N/A';

    final Map<int, int> minutesByDayOfWeek = {
      1: 0, // Monday
      2: 0, // Tuesday
      3: 0, // Wednesday
      4: 0, // Thursday
      5: 0, // Friday
      6: 0, // Saturday
      7: 0, // Sunday
    };

    for (final task in tasks) {
      if (task.isCompleted && task.completedAt != null) {
        final dayOfWeek = task.completedAt!.weekday;
        final minutes = task.pomodoroCount * task.pomodoroTime;
        minutesByDayOfWeek[dayOfWeek] =
            (minutesByDayOfWeek[dayOfWeek] ?? 0) + minutes;
      }
    }

    if (minutesByDayOfWeek.values.every((minutes) => minutes == 0)) {
      return 'N/A';
    }

    int mostProductiveDayNumber = 1;
    int maxMinutes = 0;

    minutesByDayOfWeek.forEach((day, minutes) {
      if (minutes > maxMinutes) {
        maxMinutes = minutes;
        mostProductiveDayNumber = day;
      }
    });

    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return daysOfWeek[mostProductiveDayNumber - 1];
  }

  // Helper method to get week number
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }
}
