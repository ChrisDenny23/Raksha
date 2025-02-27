// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:raksha/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _deletePasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isDeletePasswordVisible = false;
  bool _isLoading = false;
  bool _isTwoFactorEnabled = false;
  bool _isLoadingTwoFactor = true;

  @override
  void initState() {
    super.initState();
    _checkTwoFactorStatus();
  }

  Future<void> _checkTwoFactorStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          setState(() {
            _isTwoFactorEnabled = userDoc.data()!['twoFactorEnabled'] ?? false;
            _isLoadingTwoFactor = false;
          });
        } else {
          setState(() => _isLoadingTwoFactor = false);
        }
      } else {
        setState(() => _isLoadingTwoFactor = false);
      }
    } catch (e) {
      setState(() => _isLoadingTwoFactor = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _deletePasswordController.dispose();
    super.dispose();
  }

  // Password strength checker
  String _getPasswordStrength(String password) {
    if (password.isEmpty) return "Empty";
    if (password.length < 6) return "Weak";
    if (password.length < 8) return "Medium";

    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (hasUppercase && hasDigits && hasSpecialChars) return "Strong";
    if ((hasUppercase && hasDigits) ||
        (hasUppercase && hasSpecialChars) ||
        (hasDigits && hasSpecialChars)) {
      return "Good";
    }
    return "Medium";
  }

  // Get color based on password strength
  Color _getStrengthColor(String strength) {
    switch (strength) {
      case "Strong":
        return Colors.green;
      case "Good":
        return Colors.blue;
      case "Medium":
        return Colors.orange;
      case "Weak":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Show themed success dialog
  void _showSuccessDialog(BuildContext context, String title, String message) {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppy',
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'PoppyLight',
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'OK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppy',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show error snackbar
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Poppy',
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Toggle two-factor authentication
  Future<void> _toggleTwoFactorAuth() async {
    setState(() => _isLoadingTwoFactor = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update user's two-factor authentication status in Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'twoFactorEnabled': !_isTwoFactorEnabled,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        setState(() {
          _isTwoFactorEnabled = !_isTwoFactorEnabled;
          _isLoadingTwoFactor = false;
        });

        // Show success message
        _showSuccessDialog(context, "Settings Updated",
            "Two-factor authentication has been ${_isTwoFactorEnabled ? 'enabled' : 'disabled'}.");
      }
    } catch (e) {
      setState(() => _isLoadingTwoFactor = false);
      _showErrorSnackbar(
          context, "Failed to update two-factor authentication settings.");
    }
  }

  // Navigate to two-factor authentication setup page
  void _navigateToTwoFactorSetup() {
    // Implementation for navigating to 2FA setup page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(
            child: Text("Two-Factor Authentication Setup Page (Coming Soon)"),
          ),
        ),
      ),
    );
  }

  // Change password functionality
  Future<void> _changePassword(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    final credential = EmailAuthProvider.credential(
      email: user!.email!,
      password: _currentPasswordController.text,
    );

    try {
      // Re-authenticate user
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(_newPasswordController.text);

      setState(() => _isLoading = false);

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Show success dialog
      if (mounted) {
        _showSuccessDialog(
            context, 'Success', 'Your password has been changed successfully.');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String errorMessage = "An error occurred. Please try again.";

      switch (e.code) {
        case 'wrong-password':
          errorMessage = "The current password is incorrect.";
          break;
        case 'weak-password':
          errorMessage = "The new password is too weak.";
          break;
        case 'requires-recent-login':
          errorMessage =
              "This operation requires recent authentication. Please log in again.";
          break;
      }

      // Show error snackbar
      _showErrorSnackbar(context, errorMessage);
    }
  }

  // Show delete account confirmation dialog
  void _showDeleteAccountDialog() {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppy',
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is permanent and cannot be undone. All your data will be permanently deleted.',
              style: TextStyle(
                fontFamily: 'PoppyLight',
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Please enter your password to confirm:',
              style: TextStyle(
                fontFamily: 'Poppy',
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _deletePasswordController,
              obscureText: !_isDeletePasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isDeletePasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isDeletePasswordVisible = !_isDeletePasswordVisible;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _deletePasswordController.clear();
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Poppy',
                color: isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _deleteAccount(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppy',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Delete account functionality
  Future<void> _deleteAccount(BuildContext context) async {
    if (_deletePasswordController.text.isEmpty) {
      _showErrorSnackbar(context, "Please enter your password to confirm.");
      return;
    }

    Navigator.of(context).pop(); // Close the confirmation dialog

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    try {
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _deletePasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();

      // Delete user account
      await user.delete();

      setState(() => _isLoading = false);

      // Clear password field
      _deletePasswordController.clear();

      // Navigate to login page
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String errorMessage = "An error occurred. Please try again.";

      switch (e.code) {
        case 'wrong-password':
          errorMessage = "The password is incorrect.";
          break;
        case 'requires-recent-login':
          errorMessage =
              "This operation requires recent authentication. Please log in again.";
          break;
      }

      // Show error snackbar
      _showErrorSnackbar(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final passwordStrength = _getPasswordStrength(_newPasswordController.text);
    final strengthColor = _getStrengthColor(passwordStrength);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Security Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppy'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security title section
                  Container(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield,
                          color: Theme.of(context).primaryColor,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Security & Privacy",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppy',
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[700]
                        : Colors.grey[300],
                  ),

                  // Two-factor authentication option
                  ListTile(
                    leading: Icon(
                      Icons.security,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      "Two-Factor Authentication",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.secondary,
                        fontFamily: 'Poppy',
                      ),
                    ),
                    subtitle: Text(
                      _isLoadingTwoFactor
                          ? "Loading status..."
                          : _isTwoFactorEnabled
                              ? "Enabled"
                              : "Disabled",
                      style: TextStyle(
                        fontFamily: 'PoppyLight',
                        color: _isTwoFactorEnabled ? Colors.green : null,
                      ),
                    ),
                    trailing: _isLoadingTwoFactor
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          )
                        : Switch(
                            value: _isTwoFactorEnabled,
                            onChanged: (value) {
                              if (value) {
                                _navigateToTwoFactorSetup();
                              } else {
                                _toggleTwoFactorAuth();
                              }
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                    onTap: () {
                      if (!_isLoadingTwoFactor) {
                        if (_isTwoFactorEnabled) {
                          _toggleTwoFactorAuth();
                        } else {
                          _navigateToTwoFactorSetup();
                        }
                      }
                    },
                  ),

                  // Login activity option
                  ListTile(
                    leading: Icon(
                      Icons.history,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(
                      "Login Activity",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.secondary,
                        fontFamily: 'Poppy',
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onTap: () {
                      // Handle navigation to login activity page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Scaffold(
                            body: Center(
                              child: Text("Login Activity Page (Coming Soon)"),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Change password section
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.grey[850]
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: themeProvider.isDarkMode
                            ? Colors.grey[700]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppy',
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Your password must be at least 8 characters long with a mix of letters, numbers, and symbols.",
                          style: TextStyle(
                            fontSize: 14,
                            color: themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontFamily: 'PoppyLight',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password change form
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Current password field
                              TextFormField(
                                controller: _currentPasswordController,
                                obscureText: !_isCurrentPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: "Current Password",
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isCurrentPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isCurrentPasswordVisible =
                                            !_isCurrentPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your current password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // New password field
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: !_isNewPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: "New Password",
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isNewPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isNewPasswordVisible =
                                            !_isNewPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {});
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a new password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters long';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),

                              // Password strength indicator
                              if (_newPasswordController.text.isNotEmpty)
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        "Password Strength: ",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: themeProvider.isDarkMode
                                              ? Colors.grey[400]
                                              : Colors.grey[600],
                                          fontFamily: 'PoppyLight',
                                        ),
                                      ),
                                      Text(
                                        passwordStrength,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: strengthColor,
                                          fontFamily: 'Poppy',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),

                              // Confirm password field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: "Confirm Password",
                                  prefixIcon: Icon(
                                    Icons.lock_clock,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible =
                                            !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your new password';
                                  }
                                  if (value != _newPasswordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _changePassword(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        themeProvider.isDarkMode
                                            ? Colors.grey[700]
                                            : Colors.grey[300],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          "Update Password",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Poppy',
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Additional security options
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.red.withOpacity(0.1)
                          : Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Danger Zone",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppy',
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            Icons.delete_forever,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            "Delete Account",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.error,
                              fontFamily: 'Poppy',
                            ),
                          ),
                          subtitle: Text(
                            "Permanently delete your account and all data",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'PoppyLight',
                              color: themeProvider.isDarkMode
                                  ? Colors.red[300]
                                  : Colors.red[700],
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onTap: () => _showDeleteAccountDialog(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
