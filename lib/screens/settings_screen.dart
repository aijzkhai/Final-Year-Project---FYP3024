// screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../models/timer_settings_model.dart';
import '../utils/constants.dart';
import '../providers/theme_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart'; // Import for home navigation
import '../services/auth_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/change_password_screen.dart';
import '../screens/user_manual_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  late TimerSettings _settings;
  bool _isLoading = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await _storageService.getTimerSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _settings = TimerSettings();
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to load settings. Using defaults.')),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    // In a real app, you would handle notification permissions here
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.signOut();

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      } else if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to sign out. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  // Method to safely navigate back
  void _navigateBack() {
    // Check if we can pop
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // If no previous route, go to home (fallback)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white : Colors.black;
    final dividerColor = isDark ? Colors.white24 : Colors.black12;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Notifications
                _buildListItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notification',
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: _toggleNotifications,
                    activeColor: AppColors.primary,
                  ),
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Dark Mode
                _buildListItem(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    activeColor: AppColors.primary,
                  ),
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Pomodoro Settings section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Timer Settings',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Auto-start Breaks
                _buildListItem(
                  icon: Icons.play_circle_outline,
                  title: 'Auto-start Breaks',
                  trailing: Switch(
                    value: _settings.autoStartBreaks,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(autoStartBreaks: value);
                      });
                      _saveSettings();
                    },
                    activeColor: AppColors.primary,
                  ),
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Auto-start Pomodoros
                _buildListItem(
                  icon: Icons.double_arrow_outlined,
                  title: 'Auto-start Pomodoros',
                  trailing: Switch(
                    value: _settings.autoStartPomodoros,
                    onChanged: (value) {
                      setState(() {
                        _settings =
                            _settings.copyWith(autoStartPomodoros: value);
                      });
                      _saveSettings();
                    },
                    activeColor: AppColors.primary,
                  ),
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Notifications section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Sound
                _buildListItem(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound',
                  trailing: Switch(
                    value: _settings.soundEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(soundEnabled: value);
                      });
                      _saveSettings();
                    },
                    activeColor: AppColors.primary,
                  ),
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Vibration
                _buildListItem(
                  icon: Icons.vibration_outlined,
                  title: 'Vibration',
                  trailing: Switch(
                    value: _settings.vibrationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _settings = _settings.copyWith(vibrationEnabled: value);
                      });
                      _saveSettings();
                    },
                    activeColor: AppColors.primary,
                  ),
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // App section header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'App',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Rate App
                _buildListItem(
                  icon: Icons.star_outline,
                  title: 'Rate App',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Rate App functionality would go here')),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Share App
                _buildListItem(
                  icon: Icons.share_outlined,
                  title: 'Share App',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Share App functionality would go here')),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Privacy Policy
                _buildListItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Privacy Policy would go here')),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Terms and Conditions
                _buildListItem(
                  icon: Icons.description_outlined,
                  title: 'Terms and Conditions',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Terms and Conditions would go here')),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Cookies Policy
                _buildListItem(
                  icon: Icons.cookie_outlined,
                  title: 'Cookies Policy',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cookies Policy would go here')),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Contact
                _buildListItem(
                  icon: Icons.email_outlined,
                  title: 'Contact',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Contact functionality would go here')),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Feedback
                _buildListItem(
                  icon: Icons.feedback_outlined,
                  title: 'Feedback',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Feedback functionality would go here')),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Change Password
                _buildListItem(
                  icon: Icons.lock_outlined,
                  title: 'Change Password',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // User Manual
                _buildListItem(
                  icon: Icons.menu_book_outlined,
                  title: 'User Manual',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const UserManualScreen()),
                    );
                  },
                  iconColor: iconColor,
                  textColor: textColor,
                  dividerColor: dividerColor,
                ),

                // Logout
                _buildListItem(
                  icon: Icons.logout_outlined,
                  title: 'Logout',
                  onTap: _signOut,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  dividerColor: dividerColor,
                ),

                // Version info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    required Color iconColor,
    required Color textColor,
    required Color dividerColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                    ),
                  )
                : null,
            trailing: trailing,
          ),
          Divider(
            color: dividerColor,
            height: 1,
            indent: 72,
            endIndent: 0,
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await _storageService.saveTimerSettings(_settings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings')),
        );
      }
    }
  }
}
