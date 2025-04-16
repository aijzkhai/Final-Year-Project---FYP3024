// models/in_progress_task_model.dart
import '../models/task_model.dart';

class InProgressTask {
  final Task task;
  final int currentPomodoro;
  final int timerType; // corresponds to TimerType enum index
  final int timeLeft;
  final int totalTime;
  final DateTime? pausedTime;

  InProgressTask({
    required this.task,
    required this.currentPomodoro,
    required this.timerType,
    required this.timeLeft,
    required this.totalTime,
    this.pausedTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'task': task.toJson(),
      'currentPomodoro': currentPomodoro,
      'timerType': timerType,
      'timeLeft': timeLeft,
      'totalTime': totalTime,
      'pausedTime': pausedTime?.toIso8601String(),
    };
  }

  factory InProgressTask.fromJson(Map<String, dynamic> json) {
    return InProgressTask(
      task: Task.fromJson(json['task']),
      currentPomodoro: json['currentPomodoro'],
      timerType: json['timerType'],
      timeLeft: json['timeLeft'],
      totalTime: json['totalTime'],
      pausedTime: json['pausedTime'] != null
          ? DateTime.parse(json['pausedTime'])
          : null,
    );
  }
}
