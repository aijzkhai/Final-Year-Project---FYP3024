// screens/profile_screen.dart (updated with image upload)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../screens/auth_screen.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/profile_image_picker.dart';
import '../screens/change_password_screen.dart';
import 'dart:io';
import '../screens/delete_account_screen.dart';
import '../models/task_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  String? _currentProfileImage;

  // Text controllers for editable fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUser();
      final imagePath = await _storageService.getProfileImagePath();

      if (mounted) {
        setState(() {
          _user = user;
          _currentProfileImage = imagePath;
          _isLoading = false;

          // Set initial values for text controllers
          if (user != null) {
            _nameController.text = user.name;
            _emailController.text = user.email;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

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

  void _toggleEditMode() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;

      // Reset form values when canceling edit
      if (!_isEditingProfile && _user != null) {
        _nameController.text = _user!.name;
        _emailController.text = _user!.email;
      }
    });
  }

  Future<void> _saveProfileChanges() async {
    if (_user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated user
      final updatedUser = _user!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        profileImagePath: _currentProfileImage,
      );

      // Save to storage
      await _storageService.updateUserProfile(updatedUser);

      // Update current user in auth service
      await _authService.updateCurrentUser(updatedUser);

      if (mounted) {
        setState(() {
          _user = updatedUser;
          _isEditingProfile = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    }
  }

  void _handleProfileImageSelected(String imagePath) {
    setState(() {
      _currentProfileImage = imagePath;
    });

    // If we already have a user, update their profile image
    if (_user != null) {
      _user = _user!.copyWith(profileImagePath: imagePath);
      _storageService.updateUserProfile(_user!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Simply navigate back without any sign out
            Navigator.pop(context);
          },
        ),
        actions: [
          if (!_isEditingProfile)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _user?.isGuest == true ? null : _toggleEditMode,
              tooltip: 'Edit Profile',
            )
          else
            TextButton(
              onPressed: _toggleEditMode,
              child: const Text('Cancel'),
            ),
          if (_isEditingProfile)
            TextButton(
              onPressed: _saveProfileChanges,
              child: const Text('Save'),
            ),
          if (!_isEditingProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _isLoading ? null : _signOut,
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image
                  Center(
                    child: ProfileImagePicker(
                      onImageSelected: _handleProfileImageSelected,
                      currentImagePath: _currentProfileImage,
                      userInitial: _user?.initial ?? '?',
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing24),

                  // User Info
                  if (_isEditingProfile)
                    _buildEditableProfileInfo()
                  else
                    _buildProfileInfo(),

                  const SizedBox(height: AppConstants.spacing32),

                  // User Stats section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppConstants.spacing8),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusMedium),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing8,
                        vertical: AppConstants.spacing4,
                      ),
                      child: Text(
                        'Your Stats',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing16),

                  // Stats grid with FutureBuilder
                  FutureBuilder<Map<String, dynamic>>(
                    future: _loadStats(taskProvider),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              'Error loading stats: ${snapshot.error}',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final completedTasks =
                          data['completedTasks'] as List<Task>;
                      final pendingTasks = data['pendingTasks'] as List<Task>;

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: AppConstants.spacing12,
                        mainAxisSpacing: AppConstants.spacing12,
                        children: [
                          _buildProgressCard(
                            title: 'Completed Tasks',
                            value: completedTasks.length.toString(),
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          _buildProgressCard(
                            title: 'Pending Tasks',
                            value: pendingTasks.length.toString(),
                            icon: Icons.pending_actions,
                            color: Colors.orange,
                          ),
                          _buildProgressCard(
                            title: 'Focus Hours',
                            value: _calculateFocusHours(completedTasks),
                            icon: Icons.timer,
                            color: Colors.blue,
                          ),
                          _buildProgressCard(
                            title: 'Completion Rate',
                            value: _calculateCompletionRate(
                                completedTasks, pendingTasks),
                            icon: Icons.trending_up,
                            color: Colors.purple,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: AppConstants.spacing32),

                  // Account settings section (only for registered users)
                  if (_user?.isGuest != true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppConstants.spacing8),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacing8,
                          vertical: AppConstants.spacing4,
                        ),
                        child: Text(
                          'Account Settings',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing16),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.lock_outline,
                                color: Theme.of(context).primaryColor),
                            title: const Text('Change Password'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              // Navigate to change password
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChangePasswordScreen(),
                                ),
                              );
                              // Refresh user data when returning from change password screen
                              _loadUserData();
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            title: const Text('Delete Account'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Navigate to delete account screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DeleteAccountScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // For guest users, show upgrade option
                    Container(
                      padding: const EdgeInsets.all(AppConstants.spacing16),
                      decoration: BoxDecoration(
                        color: themeProvider.isDarkMode
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.blue[50],
                        borderRadius:
                            BorderRadius.circular(AppConstants.radiusMedium),
                        border: Border.all(
                          color: themeProvider.isDarkMode
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.blue[200]!,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: themeProvider.isDarkMode
                                      ? Colors.blue[300]
                                      : Colors.blue[700]),
                              const SizedBox(width: AppConstants.spacing8),
                              Text(
                                'Guest Account',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.isDarkMode
                                          ? Colors.blue[300]
                                          : Colors.blue[700],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.spacing8),
                          Text(
                            'You\'re using a guest account. Create an account to save your data permanently and access all features.',
                            style: TextStyle(
                              color: themeProvider.isDarkMode
                                  ? Colors.blue[300]
                                  : Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacing16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AuthScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.isDarkMode
                                  ? Colors.blue[700]
                                  : Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Create Account'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name
            Text(
              _user?.name ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),

            if (_user?.isGuest != true) ...[
              const SizedBox(height: AppConstants.spacing8),
              // Email
              Text(
                _user?.email ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],

            if (_user?.isGuest == true) ...[
              const SizedBox(height: AppConstants.spacing8),
              // Guest badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing12,
                  vertical: AppConstants.spacing4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Text(
                  'Guest User',
                  style: TextStyle(
                    color: Colors.amber[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppConstants.spacing16),

            // Member since
            Text(
              'Member since ${_formatDate(_user?.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableProfileInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppConstants.spacing16),

            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28, // Slightly smaller icon
              color: color,
            ),
            const SizedBox(width: AppConstants.spacing8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppConstants.spacing4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _calculateFocusHours(List<dynamic> completedTasks) {
    num totalMinutes = 0;
    for (final task in completedTasks) {
      totalMinutes += (task.pomodoroCount * task.pomodoroTime).toDouble();
    }

    final hours = totalMinutes / 60;
    return hours.toStringAsFixed(1);
  }

  String _calculateCompletionRate(
      List<dynamic> completedTasks, List<dynamic> pendingTasks) {
    final totalTasks = completedTasks.length + pendingTasks.length;
    if (totalTasks == 0) return '0%';

    final rate = (completedTasks.length / totalTasks) * 100;
    return '${rate.toStringAsFixed(0)}%';
  }

  // Helper method to load all statistics data
  Future<Map<String, dynamic>> _loadStats(TaskProvider taskProvider) async {
    final completedTasks = await taskProvider.getCompletedTasks();
    final pendingTasks = await taskProvider.getPendingTasks();

    return {
      'completedTasks': completedTasks,
      'pendingTasks': pendingTasks,
    };
  }
}
