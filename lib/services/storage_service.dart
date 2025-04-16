// services/storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../models/timer_settings_model.dart';
import '../models/user_model.dart';
import '../models/in_progress_task_model.dart';
import '../services/database_helper.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  // Key constants
  static const String _tasksKey = 'tasks';
  static const String _settingsKey = 'settings';
  static const String _firstTimeKey = 'first_time';
  static const String _darkModeKey = 'dark_mode';
  static const String _profileImageKey = 'profile_image';
  static const String _userKey = 'user';
  static const String _inProgressTaskKey = 'in_progress_task';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _migratedToSQLiteKey = 'migrated_to_sqlite';
  static const String _migratedPrefsToSQLiteKey = 'migrated_prefs_to_sqlite';

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Platform compatibility helper
  bool get isWeb => identical(0, 0.0);

  // Tasks - Now using SQLite
  Future<List<Task>> getTasks() async {
    try {
      if (kIsWeb) {
        return await _dbHelper.getTasks();
      }

      final db = await _dbHelper.database;
      final currentUser = await _dbHelper.getCurrentUserId();

      if (currentUser == null) {
        print("No current user found, returning empty task list");
        return [];
      }

      final List<Map<String, dynamic>> maps = await db!
          .query('tasks', where: 'user_id = ?', whereArgs: [currentUser]);

      return List.generate(maps.length, (i) {
        return Task(
          id: maps[i]['id'],
          title: maps[i]['title'],
          description: maps[i]['description'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
          pomodoroTime: maps[i]['pomodoro_time'],
          shortBreak: maps[i]['short_break'],
          longBreak: maps[i]['long_break'],
          pomodoroCount: maps[i]['pomodoro_count'],
          isCompleted: maps[i]['is_completed'] == 1,
          completedAt: maps[i]['completed_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(maps[i]['completed_at'])
              : null,
        );
      });
    } catch (e) {
      print('Error getting tasks: $e');
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    // This is no longer used directly as tasks are saved individually
    // in SQLite, but we'll keep it for backward compatibility
    for (final task in tasks) {
      await _dbHelper.insertTask(task);
    }
  }

  Future<bool> addTask(Task task) async {
    try {
      if (kIsWeb) {
        final tasks = await _dbHelper.getTasks();
        tasks.add(task);
        await _dbHelper.updateTasks(tasks);
        return true;
      }

      final db = await _dbHelper.database;
      final currentUser = await _dbHelper.getCurrentUserId();
      if (currentUser == null) return false;

      await db!.insert(
        'tasks',
        {
          'id': task.id,
          'title': task.title,
          'description': task.description,
          'created_at': task.createdAt.millisecondsSinceEpoch,
          'pomodoro_time': task.pomodoroTime,
          'short_break': task.shortBreak,
          'long_break': task.longBreak,
          'pomodoro_count': task.pomodoroCount,
          'is_completed': task.isCompleted ? 1 : 0,
          'completed_at': task.completedAt?.millisecondsSinceEpoch,
          'user_id': currentUser,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return true;
    } catch (e) {
      print('Error adding task: $e');
      return false;
    }
  }

  Future<bool> updateTask(Task task) async {
    try {
      if (kIsWeb) {
        final tasks = await _dbHelper.getTasks();
        final index = tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          tasks[index] = task;
          await _dbHelper.updateTasks(tasks);
          return true;
        }
        return false;
      }

      final db = await _dbHelper.database;
      final currentUser = await _dbHelper.getCurrentUserId();
      if (currentUser == null) return false;

      await db!.update(
        'tasks',
        {
          'title': task.title,
          'description': task.description,
          'pomodoro_time': task.pomodoroTime,
          'short_break': task.shortBreak,
          'long_break': task.longBreak,
          'pomodoro_count': task.pomodoroCount,
          'is_completed': task.isCompleted ? 1 : 0,
          'completed_at': task.completedAt?.millisecondsSinceEpoch,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [task.id, currentUser],
      );
      return true;
    } catch (e) {
      print('Error updating task: $e');
      return false;
    }
  }

  Future<bool> deleteTask(String taskId) async {
    try {
      if (kIsWeb) {
        final tasks = await _dbHelper.getTasks();
        tasks.removeWhere((task) => task.id == taskId);
        await _dbHelper.updateTasks(tasks);
        return true;
      }

      final db = await _dbHelper.database;
      final currentUser = await _dbHelper.getCurrentUserId();
      if (currentUser == null) return false;

      await db!.delete(
        'tasks',
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, currentUser],
      );
      return true;
    } catch (e) {
      print('Error deleting task: $e');
      return false;
    }
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    return await _dbHelper.getTasksByDate(date);
  }

  // Get tasks completed between two dates (inclusive)
  Future<List<Task>> getTasksByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _dbHelper.getTasksByDateRange(startDate, endDate);
  }

  // Get all completed tasks
  Future<List<Task>> getCompletedTasks() async {
    return await _dbHelper.getCompletedTasks();
  }

  // Get all pending tasks
  Future<List<Task>> getPendingTasks() async {
    return await _dbHelper.getPendingTasks();
  }

  // Timer Settings - Now using SQLite
  Future<TimerSettings> getTimerSettings() async {
    return await _dbHelper.getTimerSettings();
  }

  Future<void> saveTimerSettings(TimerSettings settings) async {
    await _dbHelper.saveTimerSettings(settings);
  }

  // First time app open check - Now using SQLite
  Future<bool> isFirstTime() async {
    try {
      await _migratePrefsToSQLite(); // Check if we need to migrate preferences

      final isFirstTime = await _dbHelper.getAppPreference<bool>(
        _firstTimeKey,
        defaultValue: true,
      );
      if (isFirstTime == true) {
        await _dbHelper.saveAppPreference(_firstTimeKey, false);
      }
      return isFirstTime ?? true; // Return true if null
    } catch (e) {
      print('Error checking first time: $e');
      return true; // Assume first time on error
    }
  }

  // Save and get dark mode preference - Now using SQLite
  Future<void> saveDarkMode(bool isDarkMode) async {
    await _dbHelper.saveAppPreference(_darkModeKey, isDarkMode);
  }

  Future<bool> isDarkMode() async {
    try {
      final result = await _dbHelper.getAppPreference<bool>(
        _darkModeKey,
        defaultValue: false,
      );
      return result ?? false; // Default to light mode if null
    } catch (e) {
      print('Error getting dark mode: $e');
      return false; // Default to light mode on error
    }
  }

  // Save profile image path - Now using SQLite + File Storage
  Future<String> saveProfileImage(String imagePath) async {
    try {
      // For web platform, store the path directly
      if (isWeb) {
        await _dbHelper.saveAppPreference(_profileImageKey, imagePath);
        return imagePath;
      }

      // Native platforms - copy to app directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final targetPath = path.join(directory.path, fileName);

      // Copy the image file
      final sourceFile = File(imagePath);
      final savedImage = await sourceFile.copy(targetPath);

      // Save path in preferences
      await _dbHelper.saveAppPreference(_profileImageKey, savedImage.path);

      return savedImage.path;
    } catch (e) {
      print('Error saving profile image: $e');
      return '';
    }
  }

  Future<String?> getProfileImagePath() async {
    try {
      final imagePath = await _dbHelper.getAppPreference<String>(
        _profileImageKey,
      );

      // On web, return the path directly
      if (isWeb) {
        return imagePath;
      }

      // On native platforms, check if file exists
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          return imagePath;
        } else {
          // Remove reference to non-existent file
          await _dbHelper.deleteAppPreference(_profileImageKey);
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting profile image path: $e');
      return null;
    }
  }

  // User profile related methods are now in AuthService

  // Clear all user data (for account deletion) - Now using both SQLite and file deletion
  Future<bool> clearUserData() async {
    try {
      // Delete profile image if exists
      final imagePath = await _dbHelper.getAppPreference<String>(
        _profileImageKey,
      );
      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Clear profile image path
      await _dbHelper.deleteAppPreference(_profileImageKey);

      // Clear dark mode setting
      await _dbHelper.deleteAppPreference(_darkModeKey);

      // Clear first time flag
      await _dbHelper.deleteAppPreference(_firstTimeKey);

      // Clear onboarding complete flag
      await _dbHelper.deleteAppPreference(_onboardingCompleteKey);

      // Database tasks and settings are deleted cascading when the user
      // is deleted from the database (handled by AuthService)

      return true;
    } catch (e) {
      print('Error clearing user data: $e');
      return false;
    }
  }

  // Save in-progress task - Now using SQLite
  Future<void> saveInProgressTask(
    Task task,
    int currentPomodoro,
    int timerType,
    int timeLeft,
    int totalTime,
    DateTime? pausedTime,
  ) async {
    try {
      final inProgressTask = InProgressTask(
        task: task,
        currentPomodoro: currentPomodoro,
        timerType: timerType,
        timeLeft: timeLeft,
        totalTime: totalTime,
        pausedTime: pausedTime,
      );

      await _dbHelper.saveInProgressTask(inProgressTask);
    } catch (e) {
      print('Error saving in-progress task: $e');
    }
  }

  // Get in-progress task - Now using SQLite
  Future<InProgressTask?> getInProgressTask() async {
    return await _dbHelper.getInProgressTask();
  }

  // Check if there's an in-progress task - Now using SQLite
  Future<bool> hasInProgressTask() async {
    return await _dbHelper.hasInProgressTask();
  }

  // Clear in-progress task - Now using SQLite
  Future<void> clearInProgressTask() async {
    await _dbHelper.clearInProgressTask();
  }

  // Onboarding complete check - Now using SQLite
  Future<bool> isOnboardingComplete() async {
    try {
      final result = await _dbHelper.getAppPreference<bool>(
        _onboardingCompleteKey,
        defaultValue: false,
      );
      return result ?? false; // Default to false if null
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false; // Default to showing onboarding on error
    }
  }

  Future<void> saveOnboardingComplete(bool isComplete) async {
    try {
      await _dbHelper.saveAppPreference(_onboardingCompleteKey, isComplete);
    } catch (e) {
      print('Error saving onboarding status: $e');
    }
  }

  // Migration status checks
  Future<bool> isMigratedToSQLite() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migratedToSQLiteKey) ?? false;
  }

  Future<void> setMigratedToSQLite() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migratedToSQLiteKey, true);
  }

  Future<bool> isMigratedPrefsToSQLite() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_migratedPrefsToSQLiteKey) ?? false;
  }

  Future<void> setMigratedPrefsToSQLite() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migratedPrefsToSQLiteKey, true);
  }

  // Migrate SharedPreferences to SQLite app_preferences
  Future<bool> _migratePrefsToSQLite() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if already migrated
      if (prefs.getBool(_migratedPrefsToSQLiteKey) ?? false) {
        return true; // Already migrated
      }

      // Migrate first-time flag
      final isFirstTime = prefs.getBool(_firstTimeKey);
      if (isFirstTime != null) {
        await _dbHelper.saveAppPreference(_firstTimeKey, isFirstTime);
      }

      // Migrate dark mode setting
      final isDarkMode = prefs.getBool(_darkModeKey);
      if (isDarkMode != null) {
        await _dbHelper.saveAppPreference(_darkModeKey, isDarkMode);
      }

      // Migrate profile image path
      final profileImagePath = prefs.getString(_profileImageKey);
      if (profileImagePath != null) {
        await _dbHelper.saveAppPreference(_profileImageKey, profileImagePath);
      }

      // Migrate onboarding complete flag
      final onboardingComplete = prefs.getBool(_onboardingCompleteKey);
      if (onboardingComplete != null) {
        await _dbHelper.saveAppPreference(
          _onboardingCompleteKey,
          onboardingComplete,
        );
      }

      // Clear old data from SharedPreferences
      await prefs.remove(_firstTimeKey);
      await prefs.remove(_darkModeKey);
      await prefs.remove(_profileImageKey);
      await prefs.remove(_onboardingCompleteKey);

      // Mark prefs as migrated
      await prefs.setBool(_migratedPrefsToSQLiteKey, true);

      return true;
    } catch (e) {
      print('Error migrating prefs to SQLite: $e');
      return false;
    }
  }

  // Original migrateDataToSQLite method
  Future<bool> migrateDataToSQLite() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if already migrated
      if (prefs.getBool(_migratedToSQLiteKey) ?? false) {
        return true; // Already migrated
      }

      // Migrate tasks
      final tasksJson = prefs.getStringList(_tasksKey) ?? [];
      final tasks = tasksJson
          .map((taskString) => Task.fromJson(jsonDecode(taskString)))
          .toList();
      await _dbHelper.migrateTasksToSQLite(tasks);

      // Migrate timer settings
      final settingsJson = prefs.getString(_settingsKey);
      TimerSettings settings = TimerSettings(); // Default settings
      if (settingsJson != null) {
        settings = TimerSettings.fromJson(jsonDecode(settingsJson));
      }
      await _dbHelper.migrateTimerSettingsToSQLite(settings);

      // Migrate in-progress task
      final inProgressJson = prefs.getString(_inProgressTaskKey);
      if (inProgressJson != null) {
        final inProgressTask = InProgressTask.fromJson(
          jsonDecode(inProgressJson),
        );
        await _dbHelper.migrateInProgressTaskToSQLite(inProgressTask);
      }

      // Delete old data from SharedPreferences
      await prefs.remove(_tasksKey);
      await prefs.remove(_settingsKey);
      await prefs.remove(_inProgressTaskKey);

      // Mark as migrated
      await prefs.setBool(_migratedToSQLiteKey, true);

      // Also migrate preferences
      await _migratePrefsToSQLite();

      return true;
    } catch (e) {
      print('Error migrating data to SQLite: $e');
      return false;
    }
  }

  // JSON object storage methods
  Future<void> saveJsonObject(String key, dynamic object) async {
    await _dbHelper.saveJsonObject(key, object);
  }

  Future<Map<String, dynamic>?> getJsonObject(String key) async {
    return await _dbHelper.getJsonObject(key);
  }

  // Batch save for better performance
  Future<void> batchSaveTasks(List<Task> tasks) async {
    await _dbHelper.batchSaveTasks(tasks);
  }

  // Export/Import functionality
  Future<Map<String, dynamic>> exportUserData() async {
    return await _dbHelper.exportDatabaseToJson();
  }

  Future<bool> importUserData(Map<String, dynamic> jsonData) async {
    return await _dbHelper.importDataFromJson(jsonData);
  }

  // Export data to file with web compatibility
  Future<String?> exportDataToFile() async {
    try {
      final exportData = await exportUserData();
      final jsonString = jsonEncode(exportData);

      if (isWeb) {
        // On web, we'd handle this differently - store in localStorage or offer download
        // This is a placeholder for web implementation
        print("Web export would trigger a download here");
        return jsonString; // Return JSON string directly on web
      }

      // Native platforms - write to file
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'pomodoro_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final filePath = path.join(directory.path, fileName);

      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      print('Error exporting data to file: $e');
      return null;
    }
  }

  // Import data from a file
  Future<bool> importDataFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('Import file does not exist');
        return false;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return await importUserData(jsonData);
    } catch (e) {
      print('Error importing data from file: $e');
      return false;
    }
  }

  // User profile methods - bridge to AuthService
  Future<void> updateUserProfile(User user) async {
    // Update user in database via AuthService's updateUser method
    await _dbHelper.updateUser(user);

    // If profile image path is set, store it in preferences too
    if (user.profileImagePath != null) {
      await _dbHelper.saveAppPreference(
        _profileImageKey,
        user.profileImagePath,
      );
    }
  }
}
