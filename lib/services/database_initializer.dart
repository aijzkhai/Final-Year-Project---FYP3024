// Database initializer that completely separates web and native implementations
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'web_storage.dart';

class DatabaseInitializer {
  static bool _initialized = false;
  static Database? _mockWebDb;

  // Initialize database based on platform
  static Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      await _initializeWebStorage();
    } else {
      await _initializeNativeSqlite();
    }

    _initialized = true;
  }

  // Web initialization - doesn't use SQLite at all
  static Future<void> _initializeWebStorage() async {
    print('Web platform detected - initializing SharedPreferences only');
    try {
      // Let WebStorage class handle the initialization
      await WebStorage.initialize();
    } catch (e) {
      print('Error initializing web storage: $e');
    }
  }

  // Native platforms - properly initialize SQLite
  static Future<void> _initializeNativeSqlite() async {
    print('Native platform detected - initializing SQLite with FFI');
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('SQLite FFI initialized successfully');
    } catch (e) {
      print('Error initializing SQLite FFI: $e');
      print('Will attempt to use default database factory');
    }
  }

  // Method to check if we're running on web
  static bool get isWeb => kIsWeb;

  // Get a mock database for web (that doesn't actually use SQLite)
  static Future<Database> getMockWebDatabase() async {
    if (!kIsWeb) {
      throw Exception('getMockWebDatabase should only be called on web');
    }

    if (_mockWebDb != null) {
      return _mockWebDb!;
    }

    // Create a mock in-memory database that won't actually be used
    // This is just to satisfy the Database interface for compatibility
    try {
      print('Creating mock web database (in-memory only)');
      _mockWebDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          print('Creating mock web database schemas');
        },
      );
      return _mockWebDb!;
    } catch (e) {
      print('Error creating mock web database: $e');
      rethrow;
    }
  }
}
