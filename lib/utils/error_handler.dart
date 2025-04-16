import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Global error handling
  void initializeErrorHandling(BuildContext context) {
    // Handle Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _reportError(details.exception, details.stack);
    };

    // Handle Dart errors
    runZonedGuarded(() {
      // Your initialization code here
    }, (Object error, StackTrace stack) {
      _reportError(error, stack);
    });
  }

  // Error reporting
  void _reportError(Object error, StackTrace? stackTrace) {
    // In a real app, report to a service like Sentry, Firebase Crashlytics, etc.
    print('Application error: $error');
    if (stackTrace != null) {
      print('Stacktrace: $stackTrace');
    }
  }

  // Public method for error reporting
  void reportError(Object error, StackTrace? stackTrace) {
    _reportError(error, stackTrace);
  }

  // Show error dialog to user
  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Handle network errors
  Future<bool> hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Handle storage errors
  Future<void> handleStorageError(BuildContext context, dynamic error) async {
    if (error is Exception) {
      showErrorDialog(
        context,
        'There was an error saving your data. Please try again or restart the app.',
      );
    }
  }
}
