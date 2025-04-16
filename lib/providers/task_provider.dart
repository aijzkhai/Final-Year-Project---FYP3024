// providers/task_provider.dart (improved with SQLite)
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/storage_service.dart';

class TaskProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  DateTime? _selectedDate;

  List<Task> get tasks => _filteredTasks.isEmpty ? _tasks : _filteredTasks;
  DateTime? get selectedDate => _selectedDate;

  TaskProvider() {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      _tasks = await _storageService.getTasks();
      notifyListeners();
    } catch (e) {
      print('Error loading tasks: $e');
      // Return empty list on error
      _tasks = [];
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    await _storageService.addTask(task);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    await _storageService.updateTask(task);
    await loadTasks();
  }

  Future<bool> deleteTask(String id) async {
    final result = await _storageService.deleteTask(id);
    await loadTasks();
    return result;
  }

  Future<void> completeTask(String id) async {
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index != -1) {
      final updatedTask = _tasks[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      await updateTask(updatedTask);
    }
  }

  Future<void> filterTasksByDate(DateTime date) async {
    _selectedDate = date;

    // Get filtered tasks directly from the database to ensure accuracy
    _filteredTasks = await _storageService.getTasksByDate(date);

    notifyListeners();
  }

  void clearFilter() {
    _selectedDate = null;
    _filteredTasks = [];
    notifyListeners();
  }

  Future<List<Task>> getCompletedTasks() async {
    return await _storageService.getCompletedTasks();
  }

  Future<List<Task>> getPendingTasks() async {
    return await _storageService.getPendingTasks();
  }

  // Get tasks completed on a specific day
  Future<List<Task>> getTasksCompletedOnDate(DateTime date) async {
    return await _storageService.getTasksByDate(date);
  }
}
