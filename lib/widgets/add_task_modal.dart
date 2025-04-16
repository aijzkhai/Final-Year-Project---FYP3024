// widgets/add_task_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../utils/constants.dart';
import '../screens/timer_screen.dart';

class AddTaskModal extends StatefulWidget {
  const AddTaskModal({super.key});

  @override
  State<AddTaskModal> createState() => _AddTaskModalState();
}

class _AddTaskModalState extends State<AddTaskModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _pomodoroTime = 25;
  int _shortBreak = 5;
  int _longBreak = 15;
  int _pomodoroCount = 4;
  bool _startImmediately = false;

  @override
  void initState() {
    super.initState();
    // Load default settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      setState(() {
        _pomodoroTime = timerProvider.settings.defaultPomodoroTime;
        _shortBreak = timerProvider.settings.defaultShortBreak;
        _longBreak = timerProvider.settings.defaultLongBreak;
        _pomodoroCount = timerProvider.settings.defaultPomodoroCount;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(bottom: keyboardHeight + AppConstants.spacing16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusLarge),
          topRight: Radius.circular(AppConstants.radiusLarge),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusSmall,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spacing16),
              Text(
                'Add New Task',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.spacing16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task title',
                  prefixIcon: Icon(Icons.title),
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.spacing16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppConstants.spacing24),
              _buildTimerSettings(),
              const SizedBox(height: AppConstants.spacing16),
              SwitchListTile(
                title: const Text('Start immediately'),
                subtitle: const Text('Open timer screen after adding task'),
                value: _startImmediately,
                onChanged: (value) {
                  setState(() {
                    _startImmediately = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppConstants.spacing24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveTask,
                      child: const Text('Add Task'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timer Settings',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppConstants.spacing12),
        _buildSliderSetting(
          title: 'Pomodoro Duration',
          value: _pomodoroTime.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          suffix: 'min',
          onChanged: (value) {
            setState(() {
              _pomodoroTime = value.round();
            });
          },
        ),
        _buildSliderSetting(
          title: 'Short Break',
          value: _shortBreak.toDouble(),
          min: 1,
          max: 15,
          divisions: 14,
          suffix: 'min',
          onChanged: (value) {
            setState(() {
              _shortBreak = value.round();
            });
          },
        ),
        _buildSliderSetting(
          title: 'Long Break',
          value: _longBreak.toDouble(),
          min: 5,
          max: 30,
          divisions: 5,
          suffix: 'min',
          onChanged: (value) {
            setState(() {
              _longBreak = value.round();
            });
          },
        ),
        _buildSliderSetting(
          title: 'Pomodoro Count',
          value: _pomodoroCount.toDouble(),
          min: 1,
          max: 10,
          divisions: 9,
          suffix: '',
          onChanged: (value) {
            setState(() {
              _pomodoroCount = value.round();
            });
          },
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title),
            Text(
              suffix.isNotEmpty
                  ? '${value.round()} $suffix'
                  : '${value.round()}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        pomodoroTime: _pomodoroTime,
        shortBreak: _shortBreak,
        longBreak: _longBreak,
        pomodoroCount: _pomodoroCount,
      );

      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.addTask(task);

      Navigator.pop(context);

      if (_startImmediately) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TimerScreen(task: task)),
        );
      }
    }
  }
}
