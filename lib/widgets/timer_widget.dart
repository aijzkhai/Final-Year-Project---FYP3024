// widgets/timer_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/timer_provider.dart';
import '../utils/constants.dart';

class TimerWidget extends StatelessWidget {
  final TimerProvider timerProvider;

  const TimerWidget({super.key, required this.timerProvider});

  @override
  Widget build(BuildContext context) {
    final Color timerColor = _getTimerColor(timerProvider.timerType);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer circle
        Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: timerColor.withOpacity(0.1),
          ),
        ),

        // Progress ring
        SizedBox(
          width: 260,
          height: 260,
          child: CircularProgressIndicator(
            value: 1 - timerProvider.progress,
            strokeWidth: 12,
            backgroundColor: timerColor.withOpacity(0.2),
            color: timerColor,
          ),
        ),

        // Time text
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                  timerProvider.getFormattedTime(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: timerColor,
                  ),
                )
                .animate(
                  target:
                      timerProvider.timerState == TimerState.running ? 1 : 0,
                )
                .shimmer(
                  duration: const Duration(seconds: 2),
                  color: timerColor.withOpacity(0.5),
                ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              _getTimerTypeText(timerProvider.timerType),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: timerColor),
            ),
          ],
        ),
      ],
    );
  }

  Color _getTimerColor(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return AppColors.pomodoro;
      case TimerType.shortBreak:
        return AppColors.shortBreak;
      case TimerType.longBreak:
        return AppColors.longBreak;
    }
  }

  String _getTimerTypeText(TimerType type) {
    switch (type) {
      case TimerType.pomodoro:
        return 'Focus Time';
      case TimerType.shortBreak:
        return 'Short Break';
      case TimerType.longBreak:
        return 'Long Break';
    }
  }
}
