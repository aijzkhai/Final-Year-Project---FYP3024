// screens/timer_screen.dart (updated for resume functionality)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/timer_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/timer_widget.dart';
import '../widgets/completion_popup.dart';
import '../utils/constants.dart';
import '../screens/home_screen.dart';

class TimerScreen extends StatefulWidget {
  final Task task;

  const TimerScreen({
    super.key,
    required this.task,
  });

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  late DateTime _backgroundTime;
  late TimerProvider _timerProvider;
  bool _showingCompletionPopup = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Get the TaskProvider first
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Initialize TimerProvider with TaskProvider
    _timerProvider = TimerProvider(taskProvider: taskProvider);

    // Set up the task - this will be done after checking for an in-progress task
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimer();
    });
  }

  Future<void> _initializeTimer() async {
    if (_isInitialized) return;

    // Check if we're resuming this task
    final inProgressTask = await _timerProvider.hasInProgressTask();

    if (inProgressTask) {
      // Let the provider load the in-progress task
      // It will set the correct state from SharedPreferences
    } else {
      // Set a new task
      _timerProvider.setTask(widget.task);
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // We don't dispose the _timerProvider here because it needs to save state
    // when the user leaves the screen
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundTime = DateTime.now();
      // Pause the timer when the app goes to background
      if (_timerProvider.timerState == TimerState.running) {
        _timerProvider.pause();
      }
    }

    if (state == AppLifecycleState.resumed) {
      if (_timerProvider.timerState == TimerState.running) {
        final elapsedSeconds =
            DateTime.now().difference(_backgroundTime).inSeconds;
        // Adjust timer if needed
        // This is simplified - you might want a more complex logic
        // to handle background time based on your requirements
      }
    }
  }

  void _showCompletionDialog() {
    if (_showingCompletionPopup) return; // Prevent multiple dialogs
    setState(() => _showingCompletionPopup = true);

    // Show the completion dialog
    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to dismiss
      builder: (BuildContext context) {
        return CompletionPopup(
          task: widget.task,
          onClose: () {
            Navigator.of(context).pop(); // Close the dialog
            _timerProvider.acknowledgeCompletion(); // Mark as acknowledged

            // Navigate back to home screen
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false, // Remove all previous routes
            );
          },
        );
      },
    ).then((_) {
      // Dialog closed
      setState(() => _showingCompletionPopup = false);
    });
  }

  Future<bool> _onWillPop() async {
    // If a task is in progress, we want to save its state but let the user leave
    if (_timerProvider.timerState == TimerState.running) {
      _timerProvider.pause(); // Pause the timer

      // Show a message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timer paused. You can resume from the home screen.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }

    return true; // Allow the navigation
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: ChangeNotifierProvider.value(
            value: _timerProvider,
            child: Consumer<TimerProvider>(
              builder: (context, timerProvider, _) {
                final timerId = widget.task.id.substring(0, 8);
                final timerTypeText =
                    _getTimerTypeText(timerProvider.timerType);
                return Text('$timerTypeText - #$timerId');
              },
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _onWillPop().then((canPop) {
                if (canPop) {
                  Navigator.pop(context);
                }
              });
            },
          ),
        ),
        body: ChangeNotifierProvider.value(
          value: _timerProvider,
          child: Consumer<TimerProvider>(
            builder: (context, timerProvider, _) {
              // Check if we should show the completion popup
              if (timerProvider.completionState == CompletionState.completed &&
                  timerProvider.longBreakCompleted &&
                  !_showingCompletionPopup) {
                // Use a post-frame callback to avoid build issues
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _showCompletionDialog();
                });
              }

              return Column(
                children: [
                  // Task info
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spacing16),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.spacing16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.task.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                if (timerProvider.taskCompleted ||
                                    widget.task.isCompleted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppConstants.spacing8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.radiusSmall),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Completed',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (widget.task.description.isNotEmpty) ...[
                              const SizedBox(height: AppConstants.spacing8),
                              Text(
                                widget.task.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            const SizedBox(height: AppConstants.spacing12),
                            Row(
                              children: [
                                const Icon(Icons.repeat, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Pomodoro ${timerProvider.currentPomodoro}/${widget.task.pomodoroCount}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const Spacer(),
                                if (!timerProvider.taskCompleted &&
                                    !widget.task.isCompleted)
                                  Text(
                                    'Task will auto-complete after all sessions',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey[600],
                                        ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade().slideY(begin: -0.1, end: 0),
                  ),

                  // Timer widget
                  Expanded(
                    child: Center(
                      child: TimerWidget(
                        timerProvider: timerProvider,
                      ),
                    ),
                  ),

                  // Timer controls
                  Padding(
                    padding: const EdgeInsets.all(AppConstants.spacing24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(
                          icon: Icons.refresh,
                          label: 'Reset',
                          onPressed: timerProvider.timerState != TimerState.idle
                              ? timerProvider.reset
                              : null,
                        ),
                        _buildControlButton(
                          icon: timerProvider.timerState == TimerState.running
                              ? Icons.pause
                              : Icons.play_arrow,
                          label: timerProvider.timerState == TimerState.running
                              ? 'Pause'
                              : 'Start',
                          primary: true,
                          onPressed:
                              timerProvider.timerState == TimerState.running
                                  ? timerProvider.pause
                                  : timerProvider.start,
                        ),
                        _buildControlButton(
                          icon: Icons.skip_next,
                          label: 'Skip',
                          onPressed: timerProvider.timerState != TimerState.idle
                              ? timerProvider.skipCurrent
                              : null,
                        ),
                      ],
                    ).animate().fade().slideY(begin: 0.1, end: 0),
                  ),

                  // Bottom padding for consistent spacing
                  const SizedBox(height: AppConstants.spacing24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(AppConstants.spacing16),
            backgroundColor: primary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            foregroundColor:
                primary ? Colors.white : Theme.of(context).colorScheme.primary,
            elevation: 3,
            shadowColor: primary
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Colors.black12,
          ),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: AppConstants.spacing8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getTimerTypeText(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return 'Focus';
      case TimerType.shortBreak:
        return 'Short Break';
      case TimerType.longBreak:
        return 'Long Break';
    }
  }
}
