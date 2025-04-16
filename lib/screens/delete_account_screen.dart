import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../utils/constants.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmTextController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _captchaText = '';
  bool _isCaptchaVerified = false;

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    final buffer = StringBuffer();

    for (var i = 0; i < 6; i++) {
      buffer.write(chars[rnd.nextInt(chars.length)]);
    }

    setState(() {
      _captchaText = buffer.toString();
      _isCaptchaVerified = false;
      _captchaController.clear();
    });
  }

  bool _verifyCaptcha() {
    if (_captchaController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the security code';
      });
      return false;
    }

    if (_captchaController.text.toUpperCase() != _captchaText) {
      setState(() {
        _errorMessage = 'Incorrect security code';
        _generateCaptcha();
      });
      return false;
    }

    setState(() {
      _isCaptchaVerified = true;
      _errorMessage = null;
    });
    return true;
  }

  Future<void> _deleteAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Check confirmation text
    if (_confirmTextController.text != 'DELETE') {
      setState(() {
        _errorMessage = 'Please type DELETE to confirm account deletion';
      });
      return;
    }

    // Check captcha
    if (!_isCaptchaVerified && !_verifyCaptcha()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _authService.deleteAccount(_passwordController.text);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          // Show success and navigate to auth screen
          _showSuccessAndNavigate();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Failed to delete account';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An error occurred. Please try again.';
        });
      }
    }
  }

  void _showSuccessAndNavigate() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Account Deleted'),
        content: const Text(
          'Your account has been successfully deleted. All your data has been removed from our servers.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmTextController.dispose();
    _captchaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Warning icon
              Icon(
                Icons.warning_rounded,
                size: 64,
                color: Colors.red,
              ).animate().fadeIn(duration: 400.ms).shake(),
              const SizedBox(height: AppConstants.spacing16),

              // Title
              Text(
                'Delete Your Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
              const SizedBox(height: AppConstants.spacing16),

              // Warning message
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.red.shade900.withOpacity(0.2)
                      : Colors.red.shade50,
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.red.shade700.withOpacity(0.5)
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Warning: This action cannot be undone!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.red.shade300
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      'Deleting your account will permanently remove all your data, including tasks, settings, and profile information. You will not be able to recover this information later.',
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.red.shade300
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
              const SizedBox(height: AppConstants.spacing24),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppConstants.spacing12),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.red.shade900.withOpacity(0.2)
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.red.shade700.withOpacity(0.5)
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: isDarkMode
                            ? Colors.red.shade300
                            : Colors.red.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: isDarkMode
                                ? Colors.red.shade300
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().shake().fadeIn(duration: 400.ms),
                const SizedBox(height: AppConstants.spacing16),
              ],

              // Password field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  filled: true,
                  fillColor:
                      isDarkMode ? const Color(0xFF262640) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
              const SizedBox(height: AppConstants.spacing16),

              // Confirmation text field
              TextFormField(
                controller: _confirmTextController,
                decoration: InputDecoration(
                  labelText: 'Type "DELETE" to confirm',
                  prefixIcon: const Icon(Icons.delete_forever),
                  filled: true,
                  fillColor:
                      isDarkMode ? const Color(0xFF262640) : Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please type DELETE to confirm';
                  }
                  if (value != 'DELETE') {
                    return 'Please type DELETE exactly as shown';
                  }
                  return null;
                },
              ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
              const SizedBox(height: AppConstants.spacing24),

              // Security verification section
              if (!_isCaptchaVerified) ...[
                Text(
                  'Security Verification',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
                const SizedBox(height: AppConstants.spacing8),

                // Captcha display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacing16,
                    horizontal: AppConstants.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey.shade900
                        : Colors.grey.shade200,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMedium),
                  ),
                  child: Center(
                    child: Text(
                      _captchaText,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 5,
                        fontFamily: 'Courier',
                        color: isDarkMode
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 600.ms),
                const SizedBox(height: AppConstants.spacing8),

                // Refresh captcha button
                TextButton.icon(
                  onPressed: _generateCaptcha,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Code'),
                ).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                const SizedBox(height: AppConstants.spacing16),

                // Captcha input field
                TextFormField(
                  controller: _captchaController,
                  decoration: InputDecoration(
                    labelText: 'Enter the code above',
                    prefixIcon: const Icon(Icons.security),
                    filled: true,
                    fillColor:
                        isDarkMode ? const Color(0xFF262640) : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the security code';
                    }
                    return null;
                  },
                ).animate().fadeIn(duration: 400.ms, delay: 800.ms),
                const SizedBox(height: AppConstants.spacing16),

                // Verify captcha button
                ElevatedButton.icon(
                  onPressed: _verifyCaptcha,
                  icon: const Icon(Icons.check),
                  label: const Text('Verify Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
                const SizedBox(height: AppConstants.spacing24),
              ],

              // Delete button
              ElevatedButton(
                onPressed: _isLoading ? null : _deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.red.withOpacity(0.6),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Delete My Account',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),

              const SizedBox(height: AppConstants.spacing16),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ).animate().fadeIn(duration: 400.ms, delay: 1100.ms),
            ],
          ),
        ),
      ),
    );
  }
}
