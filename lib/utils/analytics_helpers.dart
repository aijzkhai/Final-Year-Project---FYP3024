// utils/analytics_helpers.dart
import 'package:flutter/material.dart';
import '../models/task_model.dart';

class AnalyticsHelpers {
  // Calculate current streak of consecutive days with completed tasks
  static int calculateStreak(List<Task> allTasks) {
    if (allTasks.isEmpty) return 0;

    // Get all completed tasks
    final completedTasks = allTasks
        .where((task) => task.isCompleted && task.completedAt != null)
        .toList();
    if (completedTasks.isEmpty) return 0;

    // Sort tasks by completion date (newest first)
    completedTasks.sort((a, b) => b.completedAt!.compareTo(a.completedAt!));

    // Get today's date without time component
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Check if there are tasks completed today
    bool hasTasksToday = false;
    for (final task in completedTasks) {
      final completionDate = DateTime(
        task.completedAt!.year,
        task.completedAt!.month,
        task.completedAt!.day,
      );

      if (completionDate.isAtSameMomentAs(today)) {
        hasTasksToday = true;
        break;
      }
    }

    // Start from today or yesterday depending on if there are tasks today
    DateTime currentDate =
        hasTasksToday ? today : today.subtract(const Duration(days: 1));
    int streak = hasTasksToday ? 1 : 0;

    // Go back day by day to find the streak
    while (true) {
      // Go to previous day
      currentDate = currentDate.subtract(const Duration(days: 1));

      // Check if there are tasks completed on this day
      bool hasTasksOnCurrentDate = false;
      for (final task in completedTasks) {
        final completionDate = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );

        if (completionDate.isAtSameMomentAs(currentDate)) {
          hasTasksOnCurrentDate = true;
          break;
        }
      }

      // If no tasks on this day, the streak is broken
      if (!hasTasksOnCurrentDate) break;

      // Otherwise, increment streak
      streak++;
    }

    return streak;
  }

  // Calculate time spent on tasks today
  static int calculateTimeSpentToday(List<Task> allTasks) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int totalMinutes = 0;

    for (final task in allTasks) {
      if (task.isCompleted && task.completedAt != null) {
        final completionDate = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );

        if (completionDate.isAtSameMomentAs(today)) {
          totalMinutes += task.pomodoroCount * task.pomodoroTime;
        }
      }
    }

    return totalMinutes;
  }

  // Get number of tasks completed today
  static int getTasksCompletedToday(List<Task> allTasks) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    int count = 0;

    for (final task in allTasks) {
      if (task.isCompleted && task.completedAt != null) {
        final completionDate = DateTime(
          task.completedAt!.year,
          task.completedAt!.month,
          task.completedAt!.day,
        );

        if (completionDate.isAtSameMomentAs(today)) {
          count++;
        }
      }
    }

    return count;
  }

  // Format minutes into hours and minutes
  static String formatTimeSpent(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;

      if (remainingMinutes == 0) {
        return '$hours hr';
      } else {
        return '$hours hr $remainingMinutes min';
      }
    }
  }
}
