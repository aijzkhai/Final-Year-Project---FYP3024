// providers/timer_provider.dart (updated with completion handling)
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/timer_settings_model.dart';
import '../services/storage_service.dart';
import '../services/timer_service.dart';
import '../providers/task_provider.dart';

enum TimerType { pomodoro, shortBreak, longBreak }

enum TimerState { idle, running, paused, finished }

enum CompletionState { notCompleted, completed, acknowledged }

class TimerProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final TimerService _timerService = TimerService();
  final TaskProvider? _taskProvider;

  TimerSettings _settings = TimerSettings();
  Task? _currentTask;

  Timer? _timer;
  int _timeLeft = 0; // in seconds
  int _totalTime = 0; // in seconds
  int _currentPomodoro = 1;

  TimerType _timerType = TimerType.pomodoro;
  TimerState _timerState = TimerState.idle;
  CompletionState _completionState = CompletionState.notCompleted;

  bool _taskCompleted = false;
  bool _longBreakCompleted = false;

  // Getters
  TimerSettings get settings => _settings;
  Task? get currentTask => _currentTask;
  int get timeLeft => _timeLeft;
  int get totalTime => _totalTime;
  int get currentPomodoro => _currentPomodoro;
  TimerType get timerType => _timerType;
  TimerState get timerState => _timerState;
  CompletionState get completionState => _completionState;
  double get progress =>
      _totalTime > 0 ? (_totalTime - _timeLeft) / _totalTime : 0;
  bool get taskCompleted => _taskCompleted;
  bool get longBreakCompleted => _longBreakCompleted;

  TimerProvider({TaskProvider? taskProvider}) : _taskProvider = taskProvider {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settings = await _storageService.getTimerSettings();
    notifyListeners();
  }

  Future<void> updateSettings(TimerSettings settings) async {
    await _storageService.saveTimerSettings(settings);
    await _loadSettings();
  }

  void setTask(Task task) {
    _currentTask = task;
    _currentPomodoro = 1;
    _taskCompleted = false;
    _longBreakCompleted = false;
    _completionState = CompletionState.notCompleted;
    _setTimerType(TimerType.pomodoro);
    notifyListeners();
  }

  void _setTimerType(TimerType type) {
    _timerType = type;

    switch (type) {
      case TimerType.pomodoro:
        _totalTime =
            (_currentTask?.pomodoroTime ?? _settings.defaultPomodoroTime) * 60;
        break;
      case TimerType.shortBreak:
        _totalTime =
            (_currentTask?.shortBreak ?? _settings.defaultShortBreak) * 60;
        break;
      case TimerType.longBreak:
        _totalTime =
            (_currentTask?.longBreak ?? _settings.defaultLongBreak) * 60;
        break;
    }

    _timeLeft = _totalTime;
    notifyListeners();
  }

  void start() {
    if (_timerState == TimerState.running) return;

    _timerState = TimerState.running;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        _timeLeft--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });

    notifyListeners();
  }

  void pause() {
    if (_timerState != TimerState.running) return;

    _timer?.cancel();
    _timerState = TimerState.paused;

    // Save current task state to storage for resuming later
    if (_currentTask != null) {
      _storageService.saveInProgressTask(
        _currentTask!,
        _currentPomodoro,
        _timerType.index,
        _timeLeft,
        _totalTime,
        DateTime.now(),
      );
    }

    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timeLeft = _totalTime;
    _timerState = TimerState.idle;
    notifyListeners();
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    _timerState = TimerState.finished;

    // Send notifications based on timer type
    String notificationTitle;
    String notificationBody;

    if (_timerType == TimerType.pomodoro) {
      notificationTitle = 'Pomodoro Complete!';
      notificationBody = 'Time for a break.';
    } else {
      notificationTitle = 'Break Complete!';
      notificationBody = 'Ready to focus again?';
    }

    await _timerService.handleTimerCompletion(
      settings: _settings,
      notificationTitle: notificationTitle,
      notificationBody: notificationBody,
    );

    // Determine next timer type
    if (_timerType == TimerType.pomodoro) {
      final maxPomodoros =
          _currentTask?.pomodoroCount ?? _settings.defaultPomodoroCount;

      if (_currentPomodoro < maxPomodoros) {
        _currentPomodoro++;

        if (_settings.autoStartBreaks) {
          _setTimerType(TimerType.shortBreak);
          start();
        } else {
          _setTimerType(TimerType.shortBreak);
        }
      } else {
        // Last pomodoro completed - auto-complete the task
        await _completeTask();

        // Start the long break
        if (_settings.autoStartBreaks) {
          _setTimerType(TimerType.longBreak);
          start();
        } else {
          _setTimerType(TimerType.longBreak);
        }
      }
    } else if (_timerType == TimerType.longBreak && _taskCompleted) {
      // Long break after task completion is finished - show celebration
      _longBreakCompleted = true;
      _completionState = CompletionState.completed;

      // No auto-start of next timer since the task is complete
      _setTimerType(TimerType.pomodoro); // Reset to pomodoro for UI clarity
      _timerState = TimerState.idle;
    } else {
      // Short break timer finished
      if (_settings.autoStartPomodoros && !_taskCompleted) {
        _setTimerType(TimerType.pomodoro);
        start();
      } else {
        _setTimerType(TimerType.pomodoro);
      }
    }

    notifyListeners();
  }

  Future<void> _completeTask() async {
    if (_currentTask != null && !_taskCompleted && _taskProvider != null) {
      // Set the task as completed
      await _taskProvider!.completeTask(_currentTask!.id);
      _taskCompleted = true;

      // Get the updated task from storage
      final tasks = await _storageService.getTasks();
      final updatedTask = tasks.firstWhere(
        (task) => task.id == _currentTask!.id,
        orElse: () => _currentTask!,
      );
      _currentTask = updatedTask;
    }
  }

  void skipCurrent() {
    _onTimerComplete();
  }

  void acknowledgeCompletion() {
    _completionState = CompletionState.acknowledged;
    notifyListeners();
  }

  Future<bool> hasInProgressTask() async {
    // Check storage for any in-progress timer task
    final inProgressTask = await _storageService.getInProgressTask();
    if (inProgressTask != null) {
      // Load the saved task state
      _currentTask = inProgressTask.task;
      _timerType = TimerType.values[inProgressTask.timerType];
      _timeLeft = inProgressTask.timeLeft;
      _totalTime = inProgressTask.totalTime;
      _currentPomodoro = inProgressTask.currentPomodoro;
      _timerState = TimerState.paused;
      _taskCompleted = false; // Reset task completed state
      notifyListeners();
      return true;
    }
    return false;
  }

  String getFormattedTime() {
    final minutes = (_timeLeft / 60).floor();
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<String> getElapsedTimeSincePaused() async {
    // Get the in-progress task to check pausedTime
    final inProgressTask = await _storageService.getInProgressTask();
    if (inProgressTask == null || inProgressTask.pausedTime == null) {
      return '';
    }

    // Calculate the time difference
    final now = DateTime.now();
    final difference = now.difference(inProgressTask.pausedTime!);

    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'just now';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
