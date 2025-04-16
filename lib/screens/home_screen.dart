// screens/home_screen.dart (updated)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/task_provider.dart';
import '../providers/timer_provider.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/in_progress_task_model.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';
import '../widgets/side_menu.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_modal.dart';
import '../widgets/resume_task_widget.dart';
import '../widgets/streak_widget.dart';
import '../utils/analytics_helpers.dart';
import '../utils/constants.dart';
import '../screens/timer_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/page_transitions.dart';
import '../screens/ai_chat_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _user;
  bool _isLoadingUser = true;
  InProgressTask? _inProgressTask;
  bool _isLoadingTask = true;
  late TimerProvider _timerProvider;
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeTimerProvider();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);

    try {
      final authService = AuthService();
      final user = await authService.getCurrentUser();

      print(
          "Home screen loaded user: ${user?.name}, isGuest: ${user?.isGuest}");

      if (mounted) {
        setState(() {
          _user = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print("Error loading user in home screen: $e");
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  void _initializeTimerProvider() {
    // Get the TaskProvider first
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Initialize TimerProvider with TaskProvider
    _timerProvider = TimerProvider(taskProvider: taskProvider);

    // Load in-progress task
    _loadInProgressTask();
  }

  Future<void> _loadInProgressTask() async {
    setState(() => _isLoadingTask = true);

    try {
      final inProgressTask = await _storageService.getInProgressTask();

      if (mounted) {
        setState(() {
          _inProgressTask = inProgressTask;
          _isLoadingTask = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTask = false;
        });
      }
    }
  }

  void _discardInProgressTask() async {
    setState(() => _isLoadingTask = true);

    try {
      await _storageService.clearInProgressTask();

      if (mounted) {
        setState(() {
          _inProgressTask = null;
          _isLoadingTask = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTask = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Consumer<TaskProvider>(
            builder: (context, taskProvider, _) {
              final streak =
                  AnalyticsHelpers.calculateStreak(taskProvider.tasks);
              return Padding(
                padding: const EdgeInsets.only(right: AppConstants.spacing8),
                child: StreakWidget(
                  streakCount: streak,
                  onTap: () {
                    _showStreakInfo(context, streak);
                  },
                ),
              );
            },
          ),
          // Profile icon in app bar
          IconButton(
            icon: _isLoadingUser
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : _buildProfileAvatar(),
            onPressed: () {
              Navigator.push(
                context,
                PageTransitions.slideTransition(const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const SideMenu(selectedIndex: 0),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final allTasks = taskProvider.tasks;

          return RefreshIndicator(
            onRefresh: () async {
              // Refresh tasks and in-progress task
              await Future.delayed(const Duration(milliseconds: 500));
              if (context.mounted) {
                await Provider.of<TaskProvider>(context, listen: false)
                    .loadTasks();
                await _loadInProgressTask();
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome message with user name
                  if (!_isLoadingUser && _user != null) ...[
                    Text(
                      'Welcome, ${_user!.name}',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      "Let's boost your productivity today!",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 200.ms)
                        .slideY(begin: -0.2, end: 0),
                    const SizedBox(height: AppConstants.spacing24),
                  ],

                  // In-progress task widget
                  if (!_isLoadingTask && _inProgressTask != null) ...[
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue Where You Left Off',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: AppConstants.spacing8),
                          ResumeTaskWidget(
                            inProgressTask: _inProgressTask!,
                            timerProvider: _timerProvider,
                            onDiscard: _discardInProgressTask,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Daily progress summary
                  _buildDailyProgressSummary(context, allTasks),
                  const SizedBox(height: AppConstants.spacing24),

                  Text(
                    'Pending Tasks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppConstants.spacing12),

                  // Pending tasks with FutureBuilder
                  FutureBuilder<List<Task>>(
                    future: taskProvider.getPendingTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32.0),
                            child: Text(
                              'Error loading tasks: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      final pendingTasks = snapshot.data ?? [];

                      if (pendingTasks.isEmpty) {
                        return _buildEmptyState(context, 'No pending tasks');
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pendingTasks.length,
                        itemBuilder: (context, index) {
                          final task = pendingTasks[index];
                          return TaskItem(
                            task: task,
                            onDelete: (taskId) async {
                              final result =
                                  await taskProvider.deleteTask(taskId);
                              if (result) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Task "${task.title}" deleted'),
                                      action: SnackBarAction(
                                        label: 'Undo',
                                        onPressed: () {
                                          taskProvider.addTask(task);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          const Text('Failed to delete task'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            onStart: () {
                              Navigator.push(
                                context,
                                PageTransitions.fadeTransition(
                                    TimerScreen(task: task)),
                              ).then((_) {
                                // Refresh the in-progress task when returning from timer
                                _loadInProgressTask();
                              });
                            },
                          )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.shortAnimation,
                                delay: Duration(milliseconds: 50 * index),
                              )
                              .slideX(begin: 0.2, end: 0);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: AppConstants.spacing24),

                  // Extra space at bottom for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showActionOptions(context);
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const FaIcon(FontAwesomeIcons.pen, color: Colors.white),
      ).animate().fadeIn(delay: 300.ms).scale(),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacing32),
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  void _showAddTaskModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskModal(),
    ).then((_) {
      // Refresh task list after adding a task
      if (context.mounted) {
        Provider.of<TaskProvider>(context, listen: false).loadTasks();
      }
    });
  }

  void _showActionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.listCheck,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Create Task'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddTaskModal(context);
                },
              ),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.robot,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Chat with DeepSeek AI'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AIChatScreen()),
                  ).then((_) {
                    // Refresh task list when returning from AI chat
                    if (context.mounted) {
                      Provider.of<TaskProvider>(context, listen: false)
                          .loadTasks();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyProgressSummary(BuildContext context, List<Task> allTasks) {
    final timeSpentToday = AnalyticsHelpers.calculateTimeSpentToday(allTasks);
    final tasksCompletedToday =
        AnalyticsHelpers.getTasksCompletedToday(allTasks);
    final formattedTime = AnalyticsHelpers.formatTimeSpent(timeSpentToday);

    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s Progress',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacing16),

            // Time spent today
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacing8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.clock,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.spacing12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Time',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      formattedTime,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacing16),

            // Tasks completed today
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacing8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusSmall),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.listCheck,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.spacing12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Completed Tasks',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$tasksCompletedToday ${tasksCompletedToday == 1 ? 'task' : 'tasks'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakInfo(BuildContext context, int streak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.fire,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: AppConstants.spacing8),
            const Text('Your Streak'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You have a $streak-day streak!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppConstants.spacing8),
            Text(
              'Keep completing tasks daily to maintain and grow your streak. If you miss a day, your streak will reset.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (_user?.profileImagePath != null &&
        _user!.profileImagePath!.isNotEmpty) {
      try {
        // Check if the file exists
        final file = File(_user!.profileImagePath!);
        if (file.existsSync()) {
          return CircleAvatar(
            radius: 14,
            backgroundImage: FileImage(file),
          );
        }
      } catch (e) {
        // Fallback to initial avatar
      }
    }

    // No image or error loading, show initials
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.white,
      child: Text(
        _user?.name.isNotEmpty == true ? _user!.name[0].toUpperCase() : 'G',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}
