import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/task_provider.dart';
import '../widgets/side_menu.dart';
import '../widgets/task_item.dart';
import '../utils/constants.dart';
import '../utils/page_transitions.dart';
import '../models/task_model.dart';

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      drawer: const SideMenu(selectedIndex: 4), // New index for completed tasks
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return FutureBuilder<List<Task>>(
            future: taskProvider.getCompletedTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading tasks: ${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              final completedTasks = snapshot.data ?? [];

              // Filter tasks if search query exists
              final filteredTasks = _searchQuery.isEmpty
                  ? completedTasks
                  : completedTasks
                      .where((task) =>
                          task.title
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          task.description
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                  if (context.mounted) {
                    await Provider.of<TaskProvider>(context, listen: false)
                        .loadTasks();
                  }
                },
                child: filteredTasks.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppConstants.spacing16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];
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
                          )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.shortAnimation,
                                delay: Duration(milliseconds: 50 * index),
                              )
                              .slideY(begin: 0.2, end: 0);
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.spacing16),
          Text(
            'No completed tasks yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            'Completed tasks will appear here',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController =
        TextEditingController(text: _searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Tasks'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title or description',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = searchController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
