// services/auth_service.dart (updated)
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/database_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/web_storage.dart';

class AuthService {
  static const String _userKey = 'user';
  static const String _authKey = 'is_authenticated';
  static const String _usersListKey = 'users_list';

  // Add StorageService instance
  final StorageService _storageService = StorageService();
  // Add DatabaseHelper instance
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Make sure database tables are created
  Future<void> ensureAuthTablesExist() async {
    if (!kIsWeb) {
      await _dbHelper.repairAuthentication();
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      await ensureAuthTablesExist();

      if (kIsWeb) {
        // For web, check if we have user data in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        return prefs.containsKey(_userKey) && prefs.getBool(_authKey) == true;
      }

      // For native platforms, use SQLite
      return await _dbHelper.isUserAuthenticated();
    } catch (e) {
      print('Error checking authentication: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      print('Attempting sign in for email: $email');
      await ensureAuthTablesExist();

      // For web platform
      if (DatabaseHelper.isWeb) {
        print('Using web authentication flow');
        final usersData = await WebStorage.getData('users') ?? [];
        final usersList = List<Map<String, dynamic>>.from(usersData);

        final userMap = usersList.firstWhere(
          (user) =>
              user['email'].toLowerCase() == email.toLowerCase() &&
              user['password'] == password,
          orElse: () => {},
        );

        if (userMap.isNotEmpty) {
          print('Web authentication successful');
          final user = User.fromJson(userMap);

          // Save current user
          await WebStorage.saveData('current_user', userMap);

          return user;
        }

        print(
            'Web authentication failed: User not found or password incorrect');
        return null;
      }

      // For native platforms
      final db = await _dbHelper.database;
      if (db == null) {
        print('Database not initialized');
        return null;
      }

      print('Querying database for user with email: $email');
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email.toLowerCase(), password],
      );

      print('Found ${maps.length} matching users');
      if (maps.isNotEmpty) {
        print('User found, creating User object');
        final user = User(
          id: maps[0]['id'],
          email: maps[0]['email'],
          name: maps[0]['name'],
          password: maps[0]['password'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(maps[0]['created_at']),
          profileImagePath: maps[0]['profile_image_path'],
          isGuest: maps[0]['is_guest'] == 1,
        );

        // Set as current user
        print('Setting as current user: ${user.id}');
        await _saveCurrentUser(user.id);

        // Update last login time
        print('Updating last login time');
        await db.update(
          'users',
          {'last_login': DateTime.now().millisecondsSinceEpoch},
          where: 'id = ?',
          whereArgs: [user.id],
        );

        print('Login successful for: ${user.email}');
        return user;
      }

      print('No matching user found for email: $email');
      return null;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  // Sign up new user
  Future<User?> signUp(String name, String email, String password) async {
    try {
      print('Attempting sign up for email: $email');
      await ensureAuthTablesExist();

      // Check if user already exists
      bool userExists = await _checkUserExists(email);
      if (userExists) {
        print('Sign up failed: User with email $email already exists');
        return null;
      }

      // Create a new user
      final user = User(
        id: const Uuid().v4(),
        name: name,
        email: email.toLowerCase(),
        password: password,
        createdAt: DateTime.now(),
        isGuest: false,
      );

      // For web platform
      if (DatabaseHelper.isWeb) {
        print('Using web signup flow');
        if (await _saveUserToWebStorage(user)) {
          print('Web signup successful for: ${user.email}');
          return user;
        }
        return null;
      }

      // For native platforms
      final db = await _dbHelper.database;
      if (db == null) {
        print('Database not initialized');
        return null;
      }

      print('Inserting new user into database: ${user.email}');
      final id = await db.insert(
        'users',
        {
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'password': user.password,
          'created_at': user.createdAt.millisecondsSinceEpoch,
          'last_login': DateTime.now().millisecondsSinceEpoch,
          'is_guest': user.isGuest ? 1 : 0,
          'profile_image_path': user.profileImagePath,
        },
      );

      if (id > 0) {
        // Set as current user
        print('Setting as current user: ${user.id}');
        await _saveCurrentUser(user.id);
        print('Signup successful for: ${user.email}');
        return user;
      }

      print('Failed to insert user into database');
      return null;
    } catch (e) {
      print('Error during sign up: $e');
      return null;
    }
  }

  // Sign out
  Future<bool> signOut() async {
    try {
      // For both web and native platforms
      await _dbHelper.clearCurrentUser();
      return true;
    } catch (e) {
      print('Error signing out: $e');
      return false;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      // For both web and native platforms
      return await _dbHelper.getCurrentUser();
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Update current user
  Future<bool> updateCurrentUser(User updatedUser) async {
    try {
      // Update user in database
      await _dbHelper.updateUser(updatedUser);
      return true;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Skip authentication (for users who want to use the app without an account)
  Future<bool> skipAuthentication() async {
    try {
      // Create a temporary guest user
      final guestUser = User(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Guest',
        email: 'guest@example.com',
        password: '',
        createdAt: DateTime.now(),
        isGuest: true,
      );

      // Insert into database
      await _dbHelper.insertUser(guestUser);

      // Set as current user
      await _dbHelper.setCurrentUserById(guestUser.id);

      return true;
    } catch (e) {
      print('Error skipping authentication: $e');
      return false;
    }
  }

  // Add reset password functionality
  Future<Map<String, dynamic>> resetPassword(String email) async {
    // Perform email validation
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      return {
        'success': false,
        'message': 'Please enter a valid email address.',
      };
    }

    try {
      // Check if user exists
      final user = await _dbHelper.getUserByEmail(email);
      if (user == null) {
        return {
          'success': false,
          'message': 'No account found with this email address.',
        };
      }

      // In a real app, this would make an API call to a backend service
      // For this demo app, we'll simulate a successful password reset email send

      // Add a small delay to simulate network request
      await Future.delayed(const Duration(seconds: 1));

      // Return success response
      return {
        'success': true,
        'message': 'Password reset email sent successfully.',
      };
    } catch (e) {
      return {
        'success': false,
        'message':
            'Failed to send password reset email. Please try again later.',
      };
    }
  }

  // Add change password functionality
  Future<Map<String, dynamic>> changePassword(
      String email, String currentPassword, String newPassword) async {
    // Validate inputs
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      return {
        'success': false,
        'message': 'Passwords cannot be empty',
      };
    }

    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'New password must be at least 6 characters long',
      };
    }

    try {
      // Get user by email
      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Verify current password (in a real app, this would check hashed passwords)
      if (user.password != currentPassword) {
        return {
          'success': false,
          'message': 'Current password is incorrect',
        };
      }

      // Create updated user with new password
      final updatedUser = user.copyWith(password: newPassword);

      // Update user in database
      await _dbHelper.updateUser(updatedUser);

      // Add a small delay to simulate network request
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'message': 'Password changed successfully',
      };
    } catch (e) {
      print('Error changing password: $e');
      return {
        'success': false,
        'message': 'Failed to change password. Please try again.',
      };
    }
  }

  // Delete user account
  Future<Map<String, dynamic>> deleteAccount(String password) async {
    try {
      // Get current user
      final currentUser = await _dbHelper.getCurrentUser();

      if (currentUser == null) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }

      // Verify password (in a real app, this would check hashed passwords)
      if (currentUser.password != password) {
        return {'success': false, 'message': 'Incorrect password'};
      }

      // For guest users, just log them out
      if (currentUser.isGuest) {
        await signOut();
        return {'success': true};
      }

      // Delete user from database
      await _dbHelper.deleteUser(currentUser.id);

      // Clear current user
      await _dbHelper.clearCurrentUser();

      // Use the StorageService to clear all user data
      final dataClearSuccess = await _storageService.clearUserData();
      if (!dataClearSuccess) {
        return {
          'success': false,
          'message': 'Failed to clear user data',
        };
      }

      // Add a small delay to simulate network request
      await Future.delayed(const Duration(seconds: 1));

      return {'success': true};
    } catch (e) {
      print('Error deleting account: $e');
      return {
        'success': false,
        'message': 'An error occurred while deleting your account',
      };
    }
  }

  // Migration: Move users from SharedPreferences to SQLite
  Future<bool> migrateUsersToSQLite() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if we have users in SharedPreferences
      final usersList = prefs.getStringList(_usersListKey) ?? [];

      if (usersList.isEmpty) {
        // No users to migrate
        return true;
      }

      // Get current user from SharedPreferences
      final currentUserJson = prefs.getString(_userKey);
      User? currentUser;

      if (currentUserJson != null) {
        currentUser = User.fromJson(jsonDecode(currentUserJson));
      }

      // Migrate all users to SQLite
      for (final userJson in usersList) {
        final user = User.fromJson(jsonDecode(userJson));
        await _dbHelper.insertUser(user);
      }

      // Set current user if one exists
      if (currentUser != null) {
        await _dbHelper.setCurrentUserById(currentUser.id);
      }

      // Clear SharedPreferences data after successful migration
      await prefs.remove(_usersListKey);
      await prefs.remove(_userKey);
      await prefs.remove(_authKey);

      return true;
    } catch (e) {
      print('Error migrating users to SQLite: $e');
      return false;
    }
  }

  // Helper method to check if user with email exists
  Future<bool> _checkUserExists(String email) async {
    try {
      if (DatabaseHelper.isWeb) {
        final users = await _dbHelper.getUsers();
        return users
            .any((user) => user.email.toLowerCase() == email.toLowerCase());
      } else {
        final db = await _dbHelper.database;
        final result = await db!.query(
          'users',
          where: 'email = ?',
          whereArgs: [email.toLowerCase()],
        );
        return result.isNotEmpty;
      }
    } catch (e) {
      print('Error checking if user exists: $e');
      return false;
    }
  }

  // Helper method to save current user
  Future<void> _saveCurrentUser(String userId) async {
    try {
      print('Saving current user ID: $userId');
      await ensureAuthTablesExist();

      if (DatabaseHelper.isWeb) {
        // For web, save in SharedPreferences
        print('Saving current user ID to web storage');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_id', userId);
        await prefs.setBool(_authKey, true);
        return;
      }

      // For native platforms, use SQLite
      final db = await _dbHelper.database;
      if (db == null) {
        print('Database not initialized');
        return;
      }

      // Clear existing current user entries
      print('Clearing existing current user entries');
      await db.delete('current_user');

      // Insert new current user
      print('Inserting new current user entry');
      await db.insert(
        'current_user',
        {
          'id': const Uuid().v4(),
          'user_id': userId,
        },
      );

      print('Current user saved successfully');
    } catch (e) {
      print('Error saving current user: $e');
    }
  }

  // Helper method to saveUserToWebStorage
  Future<bool> _saveUserToWebStorage(User user) async {
    try {
      // Get existing users
      final usersData = await WebStorage.getData('users') ?? [];
      List<Map<String, dynamic>> users =
          List<Map<String, dynamic>>.from(usersData);

      // Remove existing user with same ID if exists
      users.removeWhere((u) => u['id'] == user.id);

      // Add the updated user
      final userJson = user.toJson();
      users.add(userJson);

      // Save back to storage
      await WebStorage.saveData('users', users);

      // Also set as current user
      await WebStorage.saveData('current_user', userJson);

      print("Saved current user with ID: ${user.id}");

      return true;
    } catch (e) {
      print('Error saving user to web storage: $e');
      return false;
    }
  }
}
