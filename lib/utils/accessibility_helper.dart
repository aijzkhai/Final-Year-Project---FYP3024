// utils/accessibility_helper.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';

class AccessibilityHelper {
  // Semantic labels for components
  static const String timerLabel = 'Pomodoro Timer';
  static const String timeRemainingLabel = 'Time remaining';
  static const String taskListLabel = 'Task List';
  static const String addTaskLabel = 'Add a new task';
  static const String deleteTaskLabel = 'Delete task';
  static const String startTimerLabel = 'Start timer';
  static const String pauseTimerLabel = 'Pause timer';
  static const String resetTimerLabel = 'Reset timer';
  static const String skipTimerLabel = 'Skip to next timer';
  static const String completeTaskLabel = 'Mark task as completed';

  // Enhanced tap targets
  static const double minTapSize = 48.0;

  // High contrast colors
  static const Color highContrastPrimary = Color(0xFFE53935); // Darker red
  static const Color highContrastText = Color(0xFF000000); // Black text
  static const Color highContrastBackground =
      Color(0xFFF5F5F5); // Light grey background

  // Enable high contrast mode
  static ThemeData getHighContrastTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: highContrastPrimary,
        onPrimary: Colors.white,
        secondary: Colors.black,
        onSecondary: Colors.white,
        background: highContrastBackground,
        onBackground: highContrastText,
        surface: Colors.white,
        onSurface: highContrastText,
      ),
      textTheme: Typography.blackMountainView.copyWith(
        bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Large text mode
  static TextTheme getLargeTextTheme(BuildContext context) {
    return Typography.blackMountainView.copyWith(
      bodyLarge: const TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
      bodyMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
      bodySmall: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
      titleLarge: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      titleMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      titleSmall: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  // Enhanced focus interactions
  static FocusNode createAccessibleFocusNode({
    required Function onActivate,
    String? label,
  }) {
    return FocusNode()
      ..addListener(() {
        // Handle keystrokes for keyboard navigation
        HardwareKeyboard.instance.addHandler((KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.space) {
              onActivate();
              return true;
            }
          }
          return false;
        });
      });
  }

  // Build accessible button
  static Widget buildAccessibleButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    bool isPrimary = false,
  }) {
    return SizedBox(
      width: minTapSize,
      height: minTapSize,
      child: Semantics(
        label: label,
        button: true,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
            backgroundColor: isPrimary
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            foregroundColor: isPrimary
                ? Colors.white
                : Theme.of(context).colorScheme.primary,
          ),
          child: Icon(icon),
        ),
      ),
    );
  }

  // Apply to text field
  static InputDecoration getAccessibleInputDecoration({
    required String label,
    required String hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      // High contrast border
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 1.0),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      // High contrast when focused
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: highContrastPrimary, width: 2.0),
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    );
  }

  // Helper method to add accessibility to a list tile
  static Widget makeAccessibleListTile({
    required BuildContext context,
    required String title,
    required String semanticLabel,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0, // Increased for better tappability
        ),
      ),
    );
  }

  // Adds screen reader announcements
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  // Update app according to system accessibility settings
  static void applySystemAccessibilitySettings(BuildContext context) {
    // Check if the user has enabled accessibility features
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    // Apply large text if user has enabled it in system settings
    if (mediaQuery.textScaleFactor > 1.3) {
      // Apply your large text theme
    }

    // Apply high contrast if user has enabled it in system settings
    if (mediaQuery.highContrast) {
      // Apply your high contrast theme
    }

    // Check for reduced motion setting
    if (mediaQuery.disableAnimations) {
      // Disable or reduce animations in your app
    }
  }

  // Make a widget accessible with proper semantics
  static Widget makeAccessible({
    required Widget child,
    required String label,
    String? hint,
    bool isButton = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      enabled: onTap != null,
      child: isButton && onTap != null
          ? InkWell(
              onTap: onTap,
              child: child,
            )
          : child,
    );
  }

  // Create an accessible form field
  static Widget createAccessibleFormField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isRequired = false,
    IconData? icon,
    bool isMultiline = false,
    String? Function(String?)? validator,
  }) {
    return Semantics(
      label: label,
      textField: true,
      hint: hint,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
        ),
        maxLines: isMultiline ? 3 : 1,
        validator: validator,
      ),
    );
  }
}

// Example implementation in a screen:
/*
@override
Widget build(BuildContext context) {
  // Apply system accessibility settings
  AccessibilityHelper.applySystemAccessibilitySettings(context);

  return Scaffold(
    appBar: AppBar(
      title: Semantics(
        header: true,
        label: 'Timer Screen',
        child: const Text('Timer'),
      ),
    ),
    body: Column(
      children: [
        // Accessible timer
        Semantics(
          label: '${AccessibilityHelper.timerLabel}: Focus Time',
          value: '${AccessibilityHelper.timeRemainingLabel}: 25:00',
          child: TimerWidget(timerProvider: timerProvider),
        ),
        
        // Accessible controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            AccessibilityHelper.buildAccessibleButton(
              context: context,
              onPressed: () => timerProvider.reset(),
              label: AccessibilityHelper.resetTimerLabel,
              icon: Icons.refresh,
            ),
            AccessibilityHelper.buildAccessibleButton(
              context: context,
              onPressed: () => timerProvider.start(),
              label: AccessibilityHelper.startTimerLabel,
              icon: Icons.play_arrow,
              isPrimary: true,
            ),
            AccessibilityHelper.buildAccessibleButton(
              context: context,
              onPressed: () => timerProvider.skipCurrent(),
              label: AccessibilityHelper.skipTimerLabel,
              icon: Icons.skip_next,
            ),
          ],
        ),
      ],
    ),
  );
}
*/
