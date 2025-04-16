// services/timer_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/timer_settings_model.dart';

class TimerService {
  // Singleton instance
  static final TimerService _instance = TimerService._internal();
  factory TimerService() => _instance;
  TimerService._internal();

  // Sound and vibration channels
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.pomodoro/timer');

  // Play notification sound
  Future<void> playSound() async {
    try {
      await _methodChannel.invokeMethod('playSound');
    } catch (e) {
      // Fallback to a simple print for now
      print('Error playing sound: $e');
      // In a real app, you would implement a proper fallback mechanism
    }
  }

  // Trigger vibration
  Future<void> vibrate() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      print('Error triggering vibration: $e');
    }
  }

  // Show timer completion notification
  Future<void> showTimerCompletionNotification({
    required String title,
    required String body,
  }) async {
    try {
      await _methodChannel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Handle timer completion with notifications based on settings
  Future<void> handleTimerCompletion({
    required TimerSettings settings,
    required String notificationTitle,
    required String notificationBody,
  }) async {
    if (settings.soundEnabled) {
      await playSound();
    }

    if (settings.vibrationEnabled) {
      await vibrate();
    }

    await showTimerCompletionNotification(
      title: notificationTitle,
      body: notificationBody,
    );
  }
}
