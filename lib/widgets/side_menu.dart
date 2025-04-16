// widgets/side_menu.dart (updated with dark mode toggle)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../screens/analytics_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/completed_tasks_screen.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import '../utils/page_transitions.dart';
import 'dart:io';

class SideMenu extends StatefulWidget {
  final int selectedIndex;

  const SideMenu({
    super.key,
    this.selectedIndex = 0,
  });

  @override
  State<SideMenu> createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final user = await authService.getCurrentUser();

    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Drawer(
      child: Column(
        children: [
          // User profile header
          _buildProfileHeader(context),

          // Menu items
          _buildMenuItem(
            context,
            title: 'Tasks',
            icon: Icons.task_alt,
            index: 0,
          ),
          _buildMenuItem(
            context,
            title: 'Analytics',
            icon: Icons.analytics,
            index: 1,
          ),
          _buildMenuItem(
            context,
            title: 'Settings',
            icon: Icons.settings,
            index: 2,
          ),
          _buildMenuItem(
            context,
            title: 'Completed Tasks',
            icon: Icons.done_all,
            index: 4,
          ),

          // Flexible spacer between menu items and bottom content
          const Spacer(),

          // Dark mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacing16,
              vertical: AppConstants.spacing8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode : Icons.light_mode,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: AppConstants.spacing8),
                    Text(
                      'Dark Mode',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),

          // Version info
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            child: Text(
              'Version 1.0.0',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        image: DecorationImage(
          image: const AssetImage('assets/images/header_bg.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColor.withOpacity(0.7),
            BlendMode.srcOver,
          ),
          onError: (exception, stackTrace) {
            // If image loading fails, we'll just use the solid color
          },
        ),
      ),
      currentAccountPicture: _isLoading
          ? CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            )
          : _buildProfileAvatar(),
      accountName: Text(
        _isLoading ? 'Loading...' : _user?.name ?? 'Guest User',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      accountEmail: Text(
        _isLoading ? '' : _user?.email ?? '',
      ),
      onDetailsPressed: () {
        Navigator.pop(context); // Close drawer
        Navigator.push(
          // Changed from pushReplacement to push
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    if (_user?.profileImagePath != null &&
        _user!.profileImagePath!.isNotEmpty) {
      try {
        // Check if the file exists
        final file = File(_user!.profileImagePath!);
        if (file.existsSync()) {
          return CircleAvatar(
            backgroundImage: FileImage(file),
          );
        }
      } catch (e) {
        // Fallback to initial avatar
      }
    }

    // Use initials if no image or error loading
    return CircleAvatar(
      backgroundColor: Colors.white,
      child: Text(
        _user?.initial ?? '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int index,
  }) {
    final bool isSelected = widget.selectedIndex == index;
    final Color color = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context); // Close drawer

        if (isSelected) return; // Don't navigate if already on this page

        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              PageTransitions.slideTransition(const HomeScreen()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              PageTransitions.slideTransition(const AnalyticsScreen()),
            );
            break;
          case 2:
            // Use push for Settings to preserve navigation stack
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            break;
          case 4:
            Navigator.pushReplacement(
              context,
              PageTransitions.slideTransition(const CompletedTasksScreen()),
            );
            break;
        }
      },
    );
  }
}
