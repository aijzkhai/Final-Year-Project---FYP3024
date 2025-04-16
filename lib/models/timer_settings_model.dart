class TimerSettings {
  final int defaultPomodoroTime; // in minutes
  final int defaultShortBreak; // in minutes
  final int defaultLongBreak; // in minutes
  final int defaultPomodoroCount;
  final bool autoStartBreaks;
  final bool autoStartPomodoros;
  final bool vibrationEnabled;
  final bool soundEnabled;

  TimerSettings({
    this.defaultPomodoroTime = 25,
    this.defaultShortBreak = 5,
    this.defaultLongBreak = 15,
    this.defaultPomodoroCount = 4,
    this.autoStartBreaks = false,
    this.autoStartPomodoros = false,
    this.vibrationEnabled = true,
    this.soundEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'defaultPomodoroTime': defaultPomodoroTime,
      'defaultShortBreak': defaultShortBreak,
      'defaultLongBreak': defaultLongBreak,
      'defaultPomodoroCount': defaultPomodoroCount,
      'autoStartBreaks': autoStartBreaks,
      'autoStartPomodoros': autoStartPomodoros,
      'vibrationEnabled': vibrationEnabled,
      'soundEnabled': soundEnabled,
    };
  }

  factory TimerSettings.fromJson(Map<String, dynamic> json) {
    return TimerSettings(
      defaultPomodoroTime: json['defaultPomodoroTime'] ?? 25,
      defaultShortBreak: json['defaultShortBreak'] ?? 5,
      defaultLongBreak: json['defaultLongBreak'] ?? 15,
      defaultPomodoroCount: json['defaultPomodoroCount'] ?? 4,
      autoStartBreaks: json['autoStartBreaks'] ?? false,
      autoStartPomodoros: json['autoStartPomodoros'] ?? false,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
    );
  }

  TimerSettings copyWith({
    int? defaultPomodoroTime,
    int? defaultShortBreak,
    int? defaultLongBreak,
    int? defaultPomodoroCount,
    bool? autoStartBreaks,
    bool? autoStartPomodoros,
    bool? vibrationEnabled,
    bool? soundEnabled,
  }) {
    return TimerSettings(
      defaultPomodoroTime: defaultPomodoroTime ?? this.defaultPomodoroTime,
      defaultShortBreak: defaultShortBreak ?? this.defaultShortBreak,
      defaultLongBreak: defaultLongBreak ?? this.defaultLongBreak,
      defaultPomodoroCount: defaultPomodoroCount ?? this.defaultPomodoroCount,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartPomodoros: autoStartPomodoros ?? this.autoStartPomodoros,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}