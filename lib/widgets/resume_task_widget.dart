// widgets/resume_task_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/in_progress_task_model.dart';
import '../providers/timer_provider.dart';
import '../screens/timer_screen.dart';
import '../utils/constants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ResumeTaskWidget extends StatefulWidget {
  final InProgressTask inProgressTask;
  final TimerProvider timerProvider;
  final VoidCallback onDiscard;

  const ResumeTaskWidget({
    super.key,
    required this.inProgressTask,
    required this.timerProvider,
    required this.onDiscard,
  });

  @override
  State<ResumeTaskWidget> createState() => _ResumeTaskWidgetState();
}

class _ResumeTaskWidgetState extends State<ResumeTaskWidget> {
  String pausedTimeAgo = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPausedTime();
  }

  Future<void> _loadPausedTime() async {
    setState(() {
      isLoading = true;
    });

    final elapsed = await widget.timerProvider.getElapsedTimeSincePaused();

    if (mounted) {
      setState(() {
        pausedTimeAgo = elapsed;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.inProgressTask.task;
    final timerType = TimerType.values[widget.inProgressTask.timerType];
    final timerTypeText = _getTimerTypeText(timerType);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing16,
        vertical: AppConstants.spacing8,
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to timer screen with this task
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TimerScreen(task: task)),
          );
        },
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with paused badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusSmall,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.circlePause,
                          size: 16,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PAUSED',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  )
                      .animate(
                        onPlay: (controller) => controller.repeat(
                          reverse: true,
                          period: 2.seconds,
                        ),
                      )
                      .fadeOut(begin: 1.0),
                  const Spacer(),
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
                    onPressed: widget.onDiscard,
                    tooltip: 'Discard',
                    iconSize: 18,
                    color: Colors.grey,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing8),

              // Task title
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.spacing8),

              // Timer info
              Row(
                children: [
                  _buildInfoTag(
                    context,
                    '$timerTypeText',
                    _getTimerTypeIcon(timerType),
                    _getTimerTypeColor(timerType),
                  ),
                  const SizedBox(width: AppConstants.spacing8),
                  _buildInfoTag(
                    context,
                    '${widget.inProgressTask.timeLeft ~/ 60}:${(widget.inProgressTask.timeLeft % 60).toString().padLeft(2, '0')} left',
                    FontAwesomeIcons.clock,
                    Colors.blue,
                  ),
                  const SizedBox(width: AppConstants.spacing8),
                  _buildInfoTag(
                    context,
                    'Pomodoro ${widget.inProgressTask.currentPomodoro}/${task.pomodoroCount}',
                    FontAwesomeIcons.repeat,
                    Colors.purple,
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing16),

              // Resume button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TimerScreen(task: task),
                      ),
                    );
                  },
                  icon: const FaIcon(FontAwesomeIcons.play),
                  label: const Text('Resume'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing16,
                      vertical: AppConstants.spacing8,
                    ),
                  ),
                ),
              ),

              if (pausedTimeAgo.isNotEmpty) ...[
                const SizedBox(height: AppConstants.spacing8),

                // Paused time info
                Align(
                  alignment: Alignment.centerRight,
                  child: isLoading
                      ? SizedBox(
                          height: 10,
                          width: 80,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        )
                      : Text(
                          'Paused $pausedTimeAgo',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.2,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildInfoTag(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacing8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
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

  IconData _getTimerTypeIcon(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return FontAwesomeIcons.stopwatch;
      case TimerType.shortBreak:
        return FontAwesomeIcons.mugHot;
      case TimerType.longBreak:
        return FontAwesomeIcons.couch;
    }
  }

  Color _getTimerTypeColor(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return Colors.red;
      case TimerType.shortBreak:
        return Colors.green;
      case TimerType.longBreak:
        return Colors.blue;
    }
  }
}
