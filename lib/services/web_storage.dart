// A dedicated storage service for web platforms
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WebStorage {
  // Cache data in memory
  static Map<String, dynamic> _cache = {};

  // Initialize and load cached data
  static Future<void> initialize() async {
    if (!kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          try {
            _cache[key] = json.decode(value);
          } catch (e) {
            _cache[key] = value;
          }
        }
      }

      print('Web storage initialized with ${_cache.length} keys');
    } catch (e) {
      print('Error initializing web storage: $e');
    }
  }

  // Save data to SharedPreferences
  static Future<bool> saveData(String key, dynamic data) async {
    if (!kIsWeb) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(data);
      final result = await prefs.setString(key, jsonData);

      // Also update the cache
      _cache[key] = data;

      print('Data saved to web storage: $key');
      return result;
    } catch (e) {
      print('Error saving data to web storage: $e');
      return false;
    }
  }

  // Get data from SharedPreferences
  static Future<dynamic> getData(String key) async {
    if (!kIsWeb) return null;

    // First check the cache
    if (_cache.containsKey(key)) {
      return _cache[key];
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(key);

      if (jsonData == null) {
        return null;
      }

      final data = json.decode(jsonData);
      // Update cache
      _cache[key] = data;

      return data;
    } catch (e) {
      print('Error getting data from web storage: $e');
      return null;
    }
  }

  // Remove data from SharedPreferences
  static Future<bool> removeData(String key) async {
    if (!kIsWeb) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(key);

      // Also remove from cache
      _cache.remove(key);

      return result;
    } catch (e) {
      print('Error removing data from web storage: $e');
      return false;
    }
  }

  // Clear all data
  static Future<bool> clearAll() async {
    if (!kIsWeb) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.clear();

      // Clear cache
      _cache.clear();

      return result;
    } catch (e) {
      print('Error clearing web storage: $e');
      return false;
    }
  }
}
