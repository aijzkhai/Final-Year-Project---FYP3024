// widgets/task_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/task_model.dart';
import '../utils/constants.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final Function(String taskId)? onDelete;
  final VoidCallback? onStart;

  const TaskItem({super.key, required this.task, this.onDelete, this.onStart});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  task.isCompleted
                      ? FontAwesomeIcons.circleCheck
                      : FontAwesomeIcons.stopwatch,
                  color: task.isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                  size: 18,
                ),
                const SizedBox(width: AppConstants.spacing8),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                  onPressed: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Task'),
                        content: const Text(
                            'Are you sure you want to delete this task?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (onDelete != null) {
                                onDelete!(task.id);
                              }
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: AppConstants.spacing8),
              Padding(
                padding: const EdgeInsets.only(left: AppConstants.spacing32),
                child: Text(
                  task.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: AppConstants.spacing12),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: AppConstants.spacing32,
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.clock,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.pomodoroTime} min × ${task.pomodoroCount}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                        const SizedBox(width: AppConstants.spacing8),
                        if (task.isCompleted && task.completedAt != null)
                          Text(
                            'Completed on ${DateFormat('MMM d').format(task.completedAt!)}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (!task.isCompleted && onStart != null)
                  ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const FaIcon(FontAwesomeIcons.play, size: 12),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing16,
                        vertical: AppConstants.spacing8,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
