import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/timer_settings_model.dart';
import '../models/in_progress_task_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_initializer.dart';
import '../services/web_storage.dart';

// Basic memory cache for web platform
final Map<String, dynamic> _webCache = {};

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  // Web compatibility flag
  static bool get isWeb => kIsWeb;

  // Web storage fields
  List<Task> _tasks = [];
  List<User> _users = [];
  Map<String, dynamic> _preferences = {};

  DatabaseHelper._internal();

  Future<Database?> get database async {
    if (_database != null) return _database;

    if (isWeb) {
      // For web, we won't use a real database at all, just return null
      // All web operations will use WebStorage directly
      print('Web platform detected - skipping SQLite database initialization');
      return null;
    } else {
      // Only initialize the database for native platforms
      _database = await _initDatabase();
      return _database;
    }
  }

  Future<void> _loadJsonStorage() async {
    if (!isWeb) return;

    try {
      // Load tasks
      final tasksData = await WebStorage.getData('tasks') ?? [];
      if (tasksData is List) {
        _tasks = tasksData
            .map((task) {
              try {
                return Task.fromJson(task);
              } catch (e) {
                print('Error parsing task: $e');
                return null;
              }
            })
            .whereType<Task>()
            .toList();
      } else {
        _tasks = [];
      }

      // Load users
      final usersData = await WebStorage.getData('users') ?? [];
      if (usersData is List) {
        _users = usersData
            .map((user) {
              try {
                return User.fromJson(user);
              } catch (e) {
                print('Error parsing user: $e');
                return null;
              }
            })
            .whereType<User>()
            .toList();
      } else {
        _users = [];
      }

      // Load preferences
      final preferencesData = await WebStorage.getData('preferences');
      if (preferencesData is Map) {
        _preferences = Map<String, dynamic>.from(preferencesData);
      } else {
        _preferences = {};
      }

      print('Web storage loaded successfully');
      print('Tasks loaded: ${_tasks.length}');
      print('Users loaded: ${_users.length}');
      print('Preferences loaded: ${_preferences.length}');
    } catch (e) {
      print('Error loading web storage: $e');
      // Initialize empty storage
      _tasks = [];
      _users = [];
      _preferences = {};
    }
  }

  Future<void> _saveJsonTable(
      String table, List<Map<String, dynamic>> data) async {
    if (!isWeb) return;

    try {
      print('Saving $table to web storage');

      switch (table) {
        case 'tasks':
          try {
            _tasks = data
                .map((task) {
                  try {
                    return Task.fromJson(task);
                  } catch (e) {
                    print('Error parsing task: $e');
                    return null;
                  }
                })
                .whereType<Task>()
                .toList();

            await WebStorage.saveData('tasks', data);
            print('Saved ${_tasks.length} tasks');
          } catch (e) {
            print('Error saving tasks: $e');
            rethrow;
          }
          break;

        case 'users':
          try {
            _users = data
                .map((user) {
                  try {
                    return User.fromJson(user);
                  } catch (e) {
                    print('Error parsing user: $e');
                    return null;
                  }
                })
                .whereType<User>()
                .toList();

            await WebStorage.saveData('users', data);
            print('Saved ${_users.length} users');
          } catch (e) {
            print('Error saving users: $e');
            rethrow;
          }
          break;

        case 'preferences':
          try {
            _preferences = data.isNotEmpty ? data.first : {};

            await WebStorage.saveData('preferences', _preferences);
            print('Saved preferences');
          } catch (e) {
            print('Error saving preferences: $e');
            rethrow;
          }
          break;

        case 'current_user':
          try {
            if (data.isNotEmpty) {
              final currentUser = data.first;

              await WebStorage.saveData('current_user', currentUser);
              print('Saved current user: ${currentUser['id']}');
            } else {
              await WebStorage.removeData('current_user');
              print('Cleared current user');
            }
          } catch (e) {
            print('Error saving current user: $e');
            rethrow;
          }
          break;

        default:
          print('Unknown table: $table');
          break;
      }
    } catch (e) {
      print('Error saving $table to web storage: $e');
      rethrow;
    }
  }

  // Database-agnostic method to get web table data
  Future<List<Map<String, dynamic>>> _getWebTable(String tableName) async {
    if (!isWeb) {
      throw Exception('_getWebTable should only be called on web platform');
    }

    try {
      final data = await WebStorage.getData(tableName) ?? [];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      print('Error getting web table $tableName: $e');
      return [];
    }
  }

  // Initialize SQLite database
  Future<Database> _initDatabase() async {
    if (isWeb) {
      print('Using web platform - getting mock database');
      try {
        // For web, use the mock database from the initializer
        return await DatabaseInitializer.getMockWebDatabase();
      } catch (e, stackTrace) {
        print('Error getting mock web database: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    } else {
      // For native platforms, use SQLite with databaseFactory
      try {
        final databasesPath = await getDatabasesPath();
        final path = join(databasesPath, 'pomodoro.db');
        print('Using native SQLite database at: $path');

        return await databaseFactory.openDatabase(
          path,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: _createDatabase,
            onUpgrade: _onUpgrade,
          ),
        );
      } catch (e, stackTrace) {
        print('Error opening native database: $e');
        print('Stack trace: $stackTrace');
        rethrow;
      }
    }
  }

  Future<void> _createDatabase(Database db, int version) async {
    print('Creating database tables');
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        name TEXT,
        password TEXT,
        created_at INTEGER,
        last_login INTEGER,
        profile_image_path TEXT,
        is_guest INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
        CREATE TABLE tasks(
          id TEXT PRIMARY KEY,
        title TEXT,
          description TEXT,
        created_at INTEGER,
        pomodoro_time INTEGER,
        short_break INTEGER,
        long_break INTEGER,
        pomodoro_count INTEGER,
        is_completed INTEGER,
          completed_at INTEGER,
          user_id TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id)
        )
      ''');
    await db.execute('''
      CREATE TABLE current_user(
        id TEXT PRIMARY KEY,
        user_id TEXT,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');
    await db.execute('''
        CREATE TABLE settings(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          default_pomodoro_time INTEGER NOT NULL DEFAULT 25,
          default_short_break INTEGER NOT NULL DEFAULT 5,
          default_long_break INTEGER NOT NULL DEFAULT 15,
          default_pomodoro_count INTEGER NOT NULL DEFAULT 4,
          auto_start_breaks INTEGER NOT NULL DEFAULT 0,
          auto_start_pomodoros INTEGER NOT NULL DEFAULT 0,
          vibration_enabled INTEGER NOT NULL DEFAULT 1,
          sound_enabled INTEGER NOT NULL DEFAULT 1,
          user_id TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    await db.execute('''
        CREATE TABLE in_progress_tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id TEXT NOT NULL,
          current_pomodoro INTEGER NOT NULL,
          timer_type INTEGER NOT NULL,
          time_left INTEGER NOT NULL,
          total_time INTEGER NOT NULL,
          paused_time INTEGER,
          user_id TEXT,
          FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    await db.execute('''
      CREATE TABLE app_preferences(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        preference_key TEXT NOT NULL,
        preference_value TEXT NOT NULL,
        value_type TEXT NOT NULL,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add tasks table
      await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        created_at INTEGER NOT NULL,
        pomodoro_time INTEGER NOT NULL,
        short_break INTEGER NOT NULL,
        long_break INTEGER NOT NULL,
        pomodoro_count INTEGER NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

      // Add settings table
      await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        default_pomodoro_time INTEGER NOT NULL DEFAULT 25,
        default_short_break INTEGER NOT NULL DEFAULT 5,
        default_long_break INTEGER NOT NULL DEFAULT 15,
        default_pomodoro_count INTEGER NOT NULL DEFAULT 4,
        auto_start_breaks INTEGER NOT NULL DEFAULT 0,
        auto_start_pomodoros INTEGER NOT NULL DEFAULT 0,
        vibration_enabled INTEGER NOT NULL DEFAULT 1,
        sound_enabled INTEGER NOT NULL DEFAULT 1,
        user_id TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

      // Add in-progress task table
      await db.execute('''
      CREATE TABLE in_progress_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT NOT NULL,
        current_pomodoro INTEGER NOT NULL,
        timer_type INTEGER NOT NULL,
        time_left INTEGER NOT NULL,
        total_time INTEGER NOT NULL,
        paused_time INTEGER,
        user_id TEXT,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
    }

    if (oldVersion < 3) {
      // Add app_preferences table
      await db.execute('''
        CREATE TABLE app_preferences(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          preference_key TEXT NOT NULL,
          preference_value TEXT NOT NULL,
          value_type TEXT NOT NULL,
          user_id TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // User operations
  Future<int> insertUser(User user) async {
    try {
      print('Inserting user into database: ${user.email}');

      final userMap = {
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'created_at': user.createdAt.millisecondsSinceEpoch,
      };

      if (isWeb) {
        print('Using web storage for user insertion');
        await _saveJsonTable('users', [userMap]);
        return 1;
      } else {
        print('Using SQLite for user insertion');
        final db = await database;
        if (db == null) {
          print('Database is null, cannot insert user');
          return -1;
        }

        final result = await db.insert(
          'users',
          userMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        print('User inserted with result: $result');
        return result;
      }
    } catch (e, stackTrace) {
      print('Error inserting user: $e');
      print('Stack trace: $stackTrace');
      return -1;
    }
  }

  Future<List<User>> getUsers() async {
    if (isWeb) {
      final users = await _getWebTable('users');
      return users
          .map((map) => User(
                id: map['id'],
                email: map['email'],
                name: map['name'],
                password: map['password'],
                createdAt:
                    DateTime.fromMillisecondsSinceEpoch(map['created_at']),
                profileImagePath: map['profile_image_path'],
                isGuest: map['is_guest'] == 1 || map['is_guest'] == true,
              ))
          .toList();
    } else {
      final db = await database;
      final currentUser = await getCurrentUserId();

      final List<Map<String, dynamic>> maps = await db!.query(
        'users',
        where: currentUser != null ? 'id = ?' : null,
        whereArgs: currentUser != null ? [currentUser] : null,
      );

      return List.generate(maps.length, (i) {
        return User(
          id: maps[i]['id'],
          email: maps[i]['email'],
          name: maps[i]['name'],
          password: maps[i]['password'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(maps[i]['created_at']),
          isGuest: maps[i]['is_guest'] == 1,
        );
      });
    }
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isEmpty) return null;

    return User(
      id: maps[0]['id'],
      name: maps[0]['name'],
      email: maps[0]['email'],
      password: maps[0]['password'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at']),
      profileImagePath: maps[0]['profile_image_path'],
      isGuest: maps[0]['is_guest'] == 1,
    );
  }

  Future<User?> getUserById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return User(
      id: maps[0]['id'],
      name: maps[0]['name'],
      email: maps[0]['email'],
      password: maps[0]['password'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at']),
      profileImagePath: maps[0]['profile_image_path'],
      isGuest: maps[0]['is_guest'] == 1,
    );
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db!.update(
      'users',
      {
        'name': user.name,
        'email': user.email,
        'password': user.password,
        'profile_image_path': user.profileImagePath,
        'is_guest': user.isGuest ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(String id) async {
    final db = await database;
    return await db!.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Current user operations
  Future<bool> setCurrentUser(User user) async {
    try {
      if (isWeb) {
        print('Setting current user in web storage: ${user.id}');
        // Save user data to web storage
        await WebStorage.saveData('current_user', user.toJson());
        return true;
      } else {
        final db = await database;

        // First clear any existing current user
        await db!.delete('current_user');

        // Then insert the new current user
        await db.insert('current_user', {
          'id': 'current', // Always use the same ID
          'user_id': user.id
        });
        return true;
      }
    } catch (e) {
      print('Error setting current user: $e');
      return false;
    }
  }

  Future<bool> setCurrentUserById(String userId) async {
    try {
      if (isWeb) {
        print('Setting current user ID in web storage: $userId');
        // For web, we need the full user object
        final users = await getUsers();
        final user = users.where((u) => u.id == userId).firstOrNull;
        if (user != null) {
          return await setCurrentUser(user);
        }
        return false;
      } else {
        final db = await database;

        // First clear any existing current user
        await db!.delete('current_user');

        // Then insert the new current user
        await db.insert('current_user', {
          'id': 'current', // Always use the same ID
          'user_id': userId
        });
        return true;
      }
    } catch (e) {
      print('Error setting current user ID: $e');
      return false;
    }
  }

  Future<void> clearCurrentUser() async {
    final db = await database;
    await db!.delete('current_user');
  }

  Future<User?> getCurrentUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.rawQuery('''
      SELECT u.* FROM users u
      JOIN current_user c ON u.id = c.user_id
      LIMIT 1
    ''');

    if (maps.isEmpty) return null;

    return User(
      id: maps[0]['id'],
      name: maps[0]['name'],
      email: maps[0]['email'],
      password: maps[0]['password'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at']),
      profileImagePath: maps[0]['profile_image_path'],
      isGuest: maps[0]['is_guest'] == 1,
    );
  }

  Future<bool> isUserAuthenticated() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('current_user');
    return maps.isNotEmpty;
  }

  // Task operations
  Future<List<Task>> getTasks() async {
    if (isWeb) {
      final taskMaps = await _getWebTable('tasks');
      return taskMaps
          .map((map) => Task(
                id: map['id'],
                title: map['title'],
                description: map['description'],
                createdAt:
                    DateTime.fromMillisecondsSinceEpoch(map['created_at']),
                pomodoroTime: map['pomodoro_time'],
                shortBreak: map['short_break'],
                longBreak: map['long_break'],
                pomodoroCount: map['pomodoro_count'],
                isCompleted: map['is_completed'] == 1,
                completedAt: map['completed_at'] != null
                    ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'])
                    : null,
              ))
          .toList();
    }

    final db = await database;
    final currentUser = await getCurrentUserId();
    if (currentUser == null) return [];

    final List<Map<String, dynamic>> maps = await db!.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );

    // Also save to JSON storage for backup
    await _saveJsonTable('tasks', maps);

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
  }

  Future<void> insertTask(Task task) async {
    final currentUser = await getCurrentUserId();
    if (currentUser == null) return;

    final taskMap = {
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
    };

    if (isWeb) {
      final tasks = await _getWebTable('tasks');
      tasks.add(taskMap);
      await _saveJsonTable('tasks', tasks);
    } else {
      final db = await database;
      await db!.insert('tasks', taskMap);
      // Also save to JSON storage for backup
      final tasks = await _getWebTable('tasks');
      tasks.add(taskMap);
      await _saveJsonTable('tasks', tasks);
    }
  }

  Future<void> updateTasks(List<Task> tasks) async {
    final currentUser = await getCurrentUserId();
    if (currentUser == null) return;

    final taskMaps = tasks
        .map((task) => {
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
            })
        .toList();

    if (isWeb) {
      await _saveJsonTable('tasks', taskMaps);
    } else {
      final db = await database;
      try {
        for (final task in tasks) {
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
        }
        // Also save to JSON storage for backup
        await _saveJsonTable('tasks', taskMaps);
      } catch (e) {
        print('Error updating tasks: $e');
        rethrow;
      }
    }
  }

  Future<Task?> getTaskById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return Task(
      id: maps[0]['id'],
      title: maps[0]['title'],
      description: maps[0]['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at']),
      pomodoroTime: maps[0]['pomodoro_time'],
      shortBreak: maps[0]['short_break'],
      longBreak: maps[0]['long_break'],
      pomodoroCount: maps[0]['pomodoro_count'],
      isCompleted: maps[0]['is_completed'] == 1,
      completedAt: maps[0]['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(maps[0]['completed_at'])
          : null,
    );
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db!.update(
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
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String taskId) async {
    final currentUser = await getCurrentUserId();
    if (currentUser == null) return 0;

    if (isWeb) {
      final tasks = await _getWebTable('tasks');
      tasks.removeWhere((task) => task['id'] == taskId);
      await _saveJsonTable('tasks', tasks);
      return 1;
    } else {
      final db = await database;
      await db!.delete(
        'tasks',
        where: 'id = ? AND user_id = ?',
        whereArgs: [taskId, currentUser],
      );
      // Also update JSON storage
      final tasks = await _getWebTable('tasks');
      tasks.removeWhere((task) => task['id'] == taskId);
      await _saveJsonTable('tasks', tasks);
      return 1;
    }
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return [];

    // Normalize date to start and end of day
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db!.query(
      'tasks',
      where:
          'user_id = ? AND is_completed = 1 AND completed_at >= ? AND completed_at <= ?',
      whereArgs: [
        currentUser,
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
    );

    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
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
  }

  Future<List<Task>> getTasksByDateRange(
      DateTime startDate, DateTime endDate) async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return [];

    // Normalize dates
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    final List<Map<String, dynamic>> maps = await db!.query(
      'tasks',
      where:
          'user_id = ? AND is_completed = 1 AND completed_at >= ? AND completed_at <= ?',
      whereArgs: [
        currentUser,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
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
  }

  Future<List<Task>> getCompletedTasks() async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return [];

    final List<Map<String, dynamic>> maps = await db!.query(
      'tasks',
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [currentUser],
    );

    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
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
  }

  Future<List<Task>> getPendingTasks() async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return [];

    final List<Map<String, dynamic>> maps = await db!.query(
      'tasks',
      where: 'user_id = ? AND is_completed = 0',
      whereArgs: [currentUser],
    );

    return List.generate(maps.length, (i) {
      return Task(
        id: maps[i]['id'],
        title: maps[i]['title'],
        description: maps[i]['description'] ?? '',
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
  }

  // Timer settings operations
  Future<int> saveTimerSettings(TimerSettings settings) async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    // Delete existing settings for this user
    if (currentUser != null) {
      await db!.delete(
        'settings',
        where: 'user_id = ?',
        whereArgs: [currentUser],
      );
    }

    // Insert new settings
    return await db!.insert(
      'settings',
      {
        'default_pomodoro_time': settings.defaultPomodoroTime,
        'default_short_break': settings.defaultShortBreak,
        'default_long_break': settings.defaultLongBreak,
        'default_pomodoro_count': settings.defaultPomodoroCount,
        'auto_start_breaks': settings.autoStartBreaks ? 1 : 0,
        'auto_start_pomodoros': settings.autoStartPomodoros ? 1 : 0,
        'vibration_enabled': settings.vibrationEnabled ? 1 : 0,
        'sound_enabled': settings.soundEnabled ? 1 : 0,
        'user_id': currentUser,
      },
    );
  }

  Future<TimerSettings> getTimerSettings() async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) {
      return TimerSettings(); // Return default settings
    }

    final List<Map<String, dynamic>> maps = await db!.query(
      'settings',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );

    if (maps.isEmpty) {
      return TimerSettings(); // Return default settings
    }

    return TimerSettings(
      defaultPomodoroTime: maps[0]['default_pomodoro_time'],
      defaultShortBreak: maps[0]['default_short_break'],
      defaultLongBreak: maps[0]['default_long_break'],
      defaultPomodoroCount: maps[0]['default_pomodoro_count'],
      autoStartBreaks: maps[0]['auto_start_breaks'] == 1,
      autoStartPomodoros: maps[0]['auto_start_pomodoros'] == 1,
      vibrationEnabled: maps[0]['vibration_enabled'] == 1,
      soundEnabled: maps[0]['sound_enabled'] == 1,
    );
  }

  // In-progress task operations
  Future<void> saveInProgressTask(InProgressTask inProgressTask) async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    // First ensure the task exists
    await insertTask(inProgressTask.task);

    // Clear existing in-progress task
    if (currentUser != null) {
      await db!.delete(
        'in_progress_tasks',
        where: 'user_id = ?',
        whereArgs: [currentUser],
      );
    }

    // Insert new in-progress task
    await db!.insert(
      'in_progress_tasks',
      {
        'task_id': inProgressTask.task.id,
        'current_pomodoro': inProgressTask.currentPomodoro,
        'timer_type': inProgressTask.timerType,
        'time_left': inProgressTask.timeLeft,
        'total_time': inProgressTask.totalTime,
        'paused_time': inProgressTask.pausedTime?.millisecondsSinceEpoch,
        'user_id': currentUser,
      },
    );
  }

  Future<InProgressTask?> getInProgressTask() async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return null;

    final List<Map<String, dynamic>> maps = await db!.rawQuery('''
      SELECT ipt.*, t.*
      FROM in_progress_tasks ipt
      JOIN tasks t ON ipt.task_id = t.id
      WHERE ipt.user_id = ?
      LIMIT 1
    ''', [currentUser]);

    if (maps.isEmpty) return null;

    final task = Task(
      id: maps[0]['id'],
      title: maps[0]['title'],
      description: maps[0]['description'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at']),
      pomodoroTime: maps[0]['pomodoro_time'],
      shortBreak: maps[0]['short_break'],
      longBreak: maps[0]['long_break'],
      pomodoroCount: maps[0]['pomodoro_count'],
      isCompleted: maps[0]['is_completed'] == 1,
      completedAt: maps[0]['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(maps[0]['completed_at'])
          : null,
    );

    return InProgressTask(
      task: task,
      currentPomodoro: maps[0]['current_pomodoro'],
      timerType: maps[0]['timer_type'],
      timeLeft: maps[0]['time_left'],
      totalTime: maps[0]['total_time'],
      pausedTime: maps[0]['paused_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(maps[0]['paused_time'])
          : null,
    );
  }

  Future<bool> hasInProgressTask() async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return false;

    final List<Map<String, dynamic>> maps = await db!.query(
      'in_progress_tasks',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );

    return maps.isNotEmpty;
  }

  Future<void> clearInProgressTask() async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return;

    await db!.delete(
      'in_progress_tasks',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );
  }

  // Modified to handle null database on web
  Future<String?> getCurrentUserId() async {
    if (isWeb) {
      try {
        final currentUserData = await WebStorage.getData('current_user');
        if (currentUserData == null) return null;

        // Depending on what's stored, return the ID
        if (currentUserData is Map) {
          print("Found current user with ID: ${currentUserData['id']}");
          return currentUserData['id'];
        } else if (currentUserData is String) {
          return currentUserData;
        }
        return null;
      } catch (e) {
        print('Error getting current user from web storage: $e');
        return null;
      }
    } else {
      final db = await database;
      if (db == null) return null;

      final List<Map<String, dynamic>> maps = await db.query('current_user');
      final userId = maps.isNotEmpty ? maps[0]['user_id'] : null;
      print("Found current user with ID: $userId");
      return userId;
    }
  }

  // Migration methods for moving data from SharedPreferences to SQLite
  Future<void> migrateTasksToSQLite(List<Task> tasks) async {
    final db = await database;
    final batch = db!.batch();
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return;

    for (final task in tasks) {
      batch.insert(
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
    }

    await batch.commit();
  }

  Future<void> migrateTimerSettingsToSQLite(TimerSettings settings) async {
    await saveTimerSettings(settings);
  }

  Future<void> migrateInProgressTaskToSQLite(
      InProgressTask? inProgressTask) async {
    if (inProgressTask != null) {
      await saveInProgressTask(inProgressTask);
    }
  }

  // App preferences operations
  Future<void> saveAppPreference(String key, dynamic value) async {
    if (isWeb) {
      // For web, use SharedPreferences or memory cache
      await _saveWebPreference(key, value);
      return;
    }

    final db = await database;
    final currentUser = await getCurrentUserId();

    // Convert value to JSON string if it's not a primitive type
    String stringValue;
    if (value is bool || value is int || value is double || value is String) {
      stringValue = value.toString();
    } else {
      stringValue = jsonEncode(value);
    }

    // Check if preference exists
    final List<Map<String, dynamic>> existing = await db!.query(
      'app_preferences',
      where: 'preference_key = ? AND user_id = ?',
      whereArgs: [key, currentUser],
    );

    if (existing.isNotEmpty) {
      // Update existing preference
      await db.update(
        'app_preferences',
        {
          'preference_value': stringValue,
          'value_type': value.runtimeType.toString(),
        },
        where: 'preference_key = ? AND user_id = ?',
        whereArgs: [key, currentUser],
      );
    } else {
      // Insert new preference
      await db.insert(
        'app_preferences',
        {
          'preference_key': key,
          'preference_value': stringValue,
          'value_type': value.runtimeType.toString(),
          'user_id': currentUser,
        },
      );
    }
  }

  Future<T?> getAppPreference<T>(String key, {T? defaultValue}) async {
    if (isWeb) {
      // For web, use SharedPreferences or memory cache
      return await _getWebPreference<T>(key, defaultValue: defaultValue);
    }

    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return defaultValue;

    final List<Map<String, dynamic>> maps = await db!.query(
      'app_preferences',
      where: 'preference_key = ? AND user_id = ?',
      whereArgs: [key, currentUser],
    );

    if (maps.isEmpty) return defaultValue;

    final String valueType = maps[0]['value_type'];
    final String stringValue = maps[0]['preference_value'];

    try {
      if (T == bool || valueType == 'bool') {
        return (stringValue.toLowerCase() == 'true') as T?;
      } else if (T == int || valueType == 'int') {
        return int.parse(stringValue) as T?;
      } else if (T == double || valueType == 'double') {
        return double.parse(stringValue) as T?;
      } else if (T == String || valueType == 'String') {
        return stringValue as T?;
      } else {
        // Try to decode JSON for complex objects
        return jsonDecode(stringValue) as T?;
      }
    } catch (e) {
      print('Error parsing preference value: $e');
      return defaultValue;
    }
  }

  Future<void> deleteAppPreference(String key) async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    await db!.delete(
      'app_preferences',
      where: 'preference_key = ? AND user_id = ?',
      whereArgs: [key, currentUser],
    );
  }

  // JSON object storage - Store any object as a JSON blob
  Future<void> saveJsonObject(String key, dynamic object) async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return;

    // Convert object to JSON
    final jsonData = jsonEncode(object);

    // Check if object with this key exists
    final List<Map<String, dynamic>> existing = await db!.query(
      'app_preferences',
      where: 'preference_key = ? AND user_id = ?',
      whereArgs: [key, currentUser],
    );

    if (existing.isNotEmpty) {
      // Update
      await db.update(
        'app_preferences',
        {
          'preference_value': jsonData,
          'value_type': 'json',
        },
        where: 'preference_key = ? AND user_id = ?',
        whereArgs: [key, currentUser],
      );
    } else {
      // Insert
      await db.insert(
        'app_preferences',
        {
          'preference_key': key,
          'preference_value': jsonData,
          'value_type': 'json',
          'user_id': currentUser,
        },
      );
    }
  }

  // Retrieve a JSON object
  Future<Map<String, dynamic>?> getJsonObject(String key) async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return null;

    final List<Map<String, dynamic>> maps = await db!.query(
      'app_preferences',
      where: 'preference_key = ? AND user_id = ?',
      whereArgs: [key, currentUser],
    );

    if (maps.isEmpty) return null;

    try {
      return jsonDecode(maps[0]['preference_value']) as Map<String, dynamic>;
    } catch (e) {
      print('Error decoding JSON object: $e');
      return null;
    }
  }

  // Batch operations for tasks
  Future<void> batchSaveTasks(List<Task> tasks) async {
    final db = await database;
    final batch = db!.batch();
    final currentUser = await getCurrentUserId();

    if (currentUser == null) return;

    for (final task in tasks) {
      batch.insert(
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
    }

    await batch.commit();
  }

  // Export database to JSON
  Future<Map<String, dynamic>> exportDatabaseToJson() async {
    final db = await database;
    final currentUser = await getCurrentUserId();

    if (currentUser == null) {
      return {'error': 'No user logged in'};
    }

    // Get user data
    final List<Map<String, dynamic>> userMaps = await db!.query(
      'users',
      where: 'id = ?',
      whereArgs: [currentUser],
    );

    if (userMaps.isEmpty) {
      return {'error': 'User not found'};
    }

    final userData = userMaps[0];

    // Get tasks
    final List<Map<String, dynamic>> taskMaps = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );

    // Get settings
    final List<Map<String, dynamic>> settingsMaps = await db.query(
      'settings',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );

    // Get preferences
    final List<Map<String, dynamic>> prefsMaps = await db.query(
      'app_preferences',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );

    // Get in-progress task
    final List<Map<String, dynamic>> inProgressMaps = await db.query(
      'in_progress_tasks',
      where: 'user_id = ?',
      whereArgs: [currentUser],
    );

    // Build export object
    final exportData = {
      'export_date': DateTime.now().toIso8601String(),
      'app_version': '1.0.0', // Update with your app version
      'user': {
        'id': userData['id'],
        'name': userData['name'],
        'email': userData['email'],
        'created_at':
            DateTime.fromMillisecondsSinceEpoch(userData['created_at'])
                .toIso8601String(),
        // Don't export password for security reasons
      },
      'tasks': taskMaps.map((task) {
        return {
          'id': task['id'],
          'title': task['title'],
          'description': task['description'],
          'created_at': DateTime.fromMillisecondsSinceEpoch(task['created_at'])
              .toIso8601String(),
          'pomodoro_time': task['pomodoro_time'],
          'short_break': task['short_break'],
          'long_break': task['long_break'],
          'pomodoro_count': task['pomodoro_count'],
          'is_completed': task['is_completed'] == 1,
          'completed_at': task['completed_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(task['completed_at'])
                  .toIso8601String()
              : null,
        };
      }).toList(),
      'settings': settingsMaps.isNotEmpty
          ? {
              'default_pomodoro_time': settingsMaps[0]['default_pomodoro_time'],
              'default_short_break': settingsMaps[0]['default_short_break'],
              'default_long_break': settingsMaps[0]['default_long_break'],
              'default_pomodoro_count': settingsMaps[0]
                  ['default_pomodoro_count'],
              'auto_start_breaks': settingsMaps[0]['auto_start_breaks'] == 1,
              'auto_start_pomodoros':
                  settingsMaps[0]['auto_start_pomodoros'] == 1,
              'vibration_enabled': settingsMaps[0]['vibration_enabled'] == 1,
              'sound_enabled': settingsMaps[0]['sound_enabled'] == 1,
            }
          : null,
      'preferences': prefsMaps.map((pref) {
        // Try to parse based on value_type
        dynamic value = pref['preference_value'];
        final valueType = pref['value_type'];

        if (valueType == 'bool') {
          value = value.toLowerCase() == 'true';
        } else if (valueType == 'int') {
          value = int.tryParse(value) ?? value;
        } else if (valueType == 'double') {
          value = double.tryParse(value) ?? value;
        } else if (valueType == 'json') {
          try {
            value = jsonDecode(value);
          } catch (e) {
            // Keep as string if not valid JSON
          }
        }

        return {
          'key': pref['preference_key'],
          'value': value,
          'type': valueType,
        };
      }).toList(),
      'in_progress_task': inProgressMaps.isNotEmpty
          ? {
              'task_id': inProgressMaps[0]['task_id'],
              'current_pomodoro': inProgressMaps[0]['current_pomodoro'],
              'timer_type': inProgressMaps[0]['timer_type'],
              'time_left': inProgressMaps[0]['time_left'],
              'total_time': inProgressMaps[0]['total_time'],
              'paused_time': inProgressMaps[0]['paused_time'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(
                          inProgressMaps[0]['paused_time'])
                      .toIso8601String()
                  : null,
            }
          : null,
    };

    return exportData;
  }

  // Import data from JSON
  Future<bool> importDataFromJson(Map<String, dynamic> jsonData) async {
    try {
      if (isWeb) {
        print('Import not supported on web platform');
        return false;
      }

      final db = await database;
      if (db == null) return false;

      // Current user is required for import
      final currentUser = await getCurrentUserId();
      if (currentUser == null) {
        print('No user logged in, cannot import data');
        return false;
      }

      // Import tasks
      if (jsonData.containsKey('tasks') && jsonData['tasks'] is List) {
        final batch = db.batch();

        // Delete existing tasks for this user
        batch.delete(
          'tasks',
          where: 'user_id = ?',
          whereArgs: [currentUser],
        );

        // Import tasks
        for (final taskJson in jsonData['tasks']) {
          batch.insert(
            'tasks',
            {
              'id': taskJson['id'],
              'title': taskJson['title'],
              'description': taskJson['description'] ?? '',
              'created_at':
                  DateTime.parse(taskJson['created_at']).millisecondsSinceEpoch,
              'pomodoro_time': taskJson['pomodoro_time'],
              'short_break': taskJson['short_break'],
              'long_break': taskJson['long_break'],
              'pomodoro_count': taskJson['pomodoro_count'],
              'is_completed': taskJson['is_completed'] ? 1 : 0,
              'completed_at': taskJson['completed_at'] != null
                  ? DateTime.parse(taskJson['completed_at'])
                      .millisecondsSinceEpoch
                  : null,
              'user_id': currentUser,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit();
      }

      // Import settings
      if (jsonData.containsKey('settings') && jsonData['settings'] != null) {
        final settingsJson = jsonData['settings'];

        // Delete existing settings
        await db.delete(
          'settings',
          where: 'user_id = ?',
          whereArgs: [currentUser],
        );

        // Insert new settings
        await db.insert(
          'settings',
          {
            'default_pomodoro_time': settingsJson['default_pomodoro_time'],
            'default_short_break': settingsJson['default_short_break'],
            'default_long_break': settingsJson['default_long_break'],
            'default_pomodoro_count': settingsJson['default_pomodoro_count'],
            'auto_start_breaks': settingsJson['auto_start_breaks'] ? 1 : 0,
            'auto_start_pomodoros':
                settingsJson['auto_start_pomodoros'] ? 1 : 0,
            'vibration_enabled': settingsJson['vibration_enabled'] ? 1 : 0,
            'sound_enabled': settingsJson['sound_enabled'] ? 1 : 0,
            'user_id': currentUser,
          },
        );
      }

      // Import preferences
      if (jsonData.containsKey('preferences') &&
          jsonData['preferences'] is List) {
        final batch = db.batch();

        // Delete existing preferences
        batch.delete(
          'app_preferences',
          where: 'user_id = ?',
          whereArgs: [currentUser],
        );

        // Import preferences
        for (final prefJson in jsonData['preferences']) {
          String stringValue;
          final valueType = prefJson['type'];
          final value = prefJson['value'];

          if (valueType == 'json') {
            stringValue = jsonEncode(value);
          } else {
            stringValue = value.toString();
          }

          batch.insert(
            'app_preferences',
            {
              'preference_key': prefJson['key'],
              'preference_value': stringValue,
              'value_type': valueType,
              'user_id': currentUser,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        await batch.commit();
      }

      // Import in-progress task if exists
      if (jsonData.containsKey('in_progress_task') &&
          jsonData['in_progress_task'] != null) {
        final inProgressJson = jsonData['in_progress_task'];
        final taskId = inProgressJson['task_id'];

        // Make sure the task exists
        final taskExists = await db.query(
          'tasks',
          where: 'id = ? AND user_id = ?',
          whereArgs: [taskId, currentUser],
        );

        if (taskExists.isNotEmpty) {
          // Delete existing in-progress task
          await db.delete(
            'in_progress_tasks',
            where: 'user_id = ?',
            whereArgs: [currentUser],
          );

          // Insert new in-progress task
          await db.insert(
            'in_progress_tasks',
            {
              'task_id': taskId,
              'current_pomodoro': inProgressJson['current_pomodoro'],
              'timer_type': inProgressJson['timer_type'],
              'time_left': inProgressJson['time_left'],
              'total_time': inProgressJson['total_time'],
              'paused_time': inProgressJson['paused_time'] != null
                  ? DateTime.parse(inProgressJson['paused_time'])
                      .millisecondsSinceEpoch
                  : null,
              'user_id': currentUser,
            },
          );
        }
      }

      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }

  // Web alternative implementations
  Future<void> _saveWebPreference(String key, dynamic value) async {
    try {
      // First save in memory cache
      _webCache[key] = value;

      // Then try to persist with SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else {
        // For complex objects, convert to JSON
        await prefs.setString(key, jsonEncode(value));
      }
    } catch (e) {
      print('Error saving web preference: $e');
    }
  }

  Future<T?> _getWebPreference<T>(String key, {T? defaultValue}) async {
    try {
      // First check memory cache
      if (_webCache.containsKey(key)) {
        final value = _webCache[key];
        if (value is T) {
          return value;
        }
      }

      // Then try to load from SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      if (!prefs.containsKey(key)) {
        return defaultValue;
      }

      if (T == bool) {
        return prefs.getBool(key) as T?;
      } else if (T == int) {
        return prefs.getInt(key) as T?;
      } else if (T == double) {
        return prefs.getDouble(key) as T?;
      } else if (T == String) {
        return prefs.getString(key) as T?;
      } else {
        // For complex objects, parse from JSON
        final String? jsonString = prefs.getString(key);
        if (jsonString != null) {
          return jsonDecode(jsonString) as T?;
        }
      }

      return defaultValue;
    } catch (e) {
      print('Error getting web preference: $e');
      return defaultValue;
    }
  }

  // Check and fix database tables
  Future<void> fixDatabaseTables() async {
    if (isWeb) return; // No need to fix web storage

    try {
      final db = await database;
      if (db == null) return;

      // Check if current_user table exists
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='current_user'");

      if (tables.isEmpty) {
        print('Creating missing current_user table');
        await db.execute('''
          CREATE TABLE current_user(
            id TEXT PRIMARY KEY,
            user_id TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');
      }
    } catch (e) {
      print('Error fixing database tables: $e');
    }
  }

  // Add method to completely reset the database
  Future<void> resetDatabase() async {
    if (isWeb) return; // No need to reset web storage

    try {
      // Close existing database if open
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }

      // Delete the database file
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'pomodoro.db');
      print('Deleting database at path: $path');

      if (await databaseExists(path)) {
        await deleteDatabase(path);
        print('Database deleted successfully');
      }

      // Re-open the database, which will create all tables
      print('Reinitializing database...');
      _database = await _initDatabase();
      print('Database reinitialized successfully');

      return;
    } catch (e) {
      print('Error resetting database: $e');
    }
  }
}
