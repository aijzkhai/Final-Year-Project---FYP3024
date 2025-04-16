import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF4B4B);
  static const Color secondary = Color(0xFF2D3047);
  static const Color accent = Color(0xFF93B7BE);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);

  // Timer colors
  static const Color pomodoro = Color(0xFFFF4B4B);
  static const Color shortBreak = Color(0xFF4CAF50);
  static const Color longBreak = Color(0xFF2196F3);
}

class AppConstants {
  static const String appName = 'FocusMate AI';

  // Animations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);

  // Padding/Margin
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;

  // Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Welcome Screen
  static const List<String> welcomeFeatures = [
    'Create tasks with custom timer settings',
    'Track your progress with detailed analytics',
    'Customize your Pomodoro experience',
    'Stay focused and boost productivity',
  ];
}
