// providers/theme_provider.dart
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Dark theme data
  ThemeData get darkTheme => AppTheme.darkTheme;

  // Light theme data
  ThemeData get lightTheme => AppTheme.lightTheme;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Initialize theme from storage
  Future<void> _loadThemePreference() async {
    final isDark = await _storageService.isDarkMode();
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    await _storageService.saveDarkMode(isDark);
    notifyListeners();
  }

  // Check if the current theme is dark
  bool isCurrentlyDark(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  // Get the appropriate background color based on theme
  Color getBackgroundColor(BuildContext context) {
    return isCurrentlyDark(context)
        ? const Color(0xFF1A1A2E) // Dark blue-gray for dark mode
        : Colors.white;
  }

  // Get the appropriate text color based on theme
  Color getTextColor(BuildContext context) {
    return isCurrentlyDark(context) ? Colors.white : Colors.black;
  }
}
