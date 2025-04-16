import 'package:uuid/uuid.dart';

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final int pomodoroTime; // in minutes
  final int shortBreak; // in minutes
  final int longBreak; // in minutes
  final int pomodoroCount;
  bool isCompleted;
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.description = '',
    required this.pomodoroTime,
    required this.shortBreak,
    required this.longBreak,
    required this.pomodoroCount,
    this.isCompleted = false,
    this.completedAt,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'pomodoroTime': pomodoroTime,
      'shortBreak': shortBreak,
      'longBreak': longBreak,
      'pomodoroCount': pomodoroCount,
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      pomodoroTime: json['pomodoroTime'],
      shortBreak: json['shortBreak'],
      longBreak: json['longBreak'],
      pomodoroCount: json['pomodoroCount'],
      isCompleted: json['isCompleted'],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    int? pomodoroTime,
    int? shortBreak,
    int? longBreak,
    int? pomodoroCount,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      pomodoroTime: pomodoroTime ?? this.pomodoroTime,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
