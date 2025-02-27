// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:raksha/edit_profile.dart';
import 'package:raksha/get_started.dart';
import 'package:raksha/login.dart';
import 'package:raksha/profile_pic.dart';
import 'package:raksha/security_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raksha/theme_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<Map<String, dynamic>?> _getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.email)
          .get();
      return doc.data();
    }
    return null;
  }

  // Show logout confirmation dialog with app theme styling
  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Text(
              'Logout Confirmation',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'poppy',
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                fontFamily: 'poppylight',
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'poppy',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'poppy',
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Enhanced logout handling with proper error handling and themed user feedback
  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog first
    final confirmLogout = await _showLogoutConfirmation(context);
    if (!confirmLogout) return;

    // Show loading indicator with app theme
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );

    try {
      // Clear any cached user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_session');
      await prefs.remove('last_login');
      // We don't remove profile_picture_path here as we're keeping it local

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Close the loading dialog
      Navigator.of(context).pop();

      // Navigate to login screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => GetStartedPage()),
        (route) => false,
      );

      // Reset login form state if the key is valid
      if (loginFormKey.currentState != null) {
        loginFormKey.currentState!.resetLoginForm();
      }

      // Show success message with app theme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              const Text(
                'Successfully logged out',
                style: TextStyle(
                  fontFamily: 'poppy',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();

      // Show error message with app theme
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Error logging out: ${e.toString()}',
                  style: const TextStyle(
                    fontFamily: 'poppy',
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
  }

  // Get local profile picture path
  Future<String?> _getLocalProfilePicturePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_picture_path');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'poppy')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(
              context, true), // This indicates that the homepage should refresh
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontFamily: 'poppy',
                ),
              ),
            );
          }

          final userData = snapshot.data;
          final username = userData?['username'] as String? ?? 'User';
          final email = userData?['email'] as String? ?? '';
          final firstLetter =
              username.isNotEmpty ? username[0].toUpperCase() : 'U';

          return FutureBuilder<String?>(
            future: _getLocalProfilePicturePath(),
            builder: (context, profilePicSnapshot) {
              final localProfilePicPath = profilePicSnapshot.data;
              final hasLocalProfilePic = localProfilePicPath != null &&
                  File(localProfilePicPath).existsSync();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _showProfilePictureOptions(context),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              // Show local profile picture if available, otherwise show the default avatar
                              hasLocalProfilePic
                                  ? CircleAvatar(
                                      radius: 40,
                                      backgroundImage:
                                          FileImage(File(localProfilePicPath)),
                                    )
                                  : CircleAvatar(
                                      radius: 40,
                                      backgroundColor:
                                          Theme.of(context).primaryColor,
                                      child: Text(
                                        firstLetter,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontFamily: 'poppy',
                                        ),
                                      ),
                                    ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            username,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'poppy',
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary,
                              fontFamily: 'poppylight',
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),

                    // Settings options in a Card for better theme consistency
                    Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Edit Profile Option
                          _buildSettingsOption(
                            context,
                            Icons.edit,
                            "Edit Profile",
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfilePage(userData: userData),
                                ),
                              );

                              // If the result is true, refresh the user data
                              if (result == true) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SettingsPage(),
                                  ),
                                );
                              }
                            },
                          ),

                          _buildDivider(),

                          _buildSettingsOption(
                              context, Icons.notifications, "Notifications"),

                          _buildDivider(),

                          // Theme Toggle Option with static "Dark Mode" text
                          SwitchListTile(
                            secondary: Icon(
                              Icons.dark_mode,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            title: Text(
                              "Dark Mode",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.secondary,
                                fontFamily: 'poppy',
                              ),
                            ),
                            value: themeProvider.isDarkMode,
                            onChanged: (value) => themeProvider.toggleTheme(),
                          ),

                          _buildDivider(),

                          // Privacy and Security Option
                          _buildSettingsOption(
                            context,
                            Icons.lock,
                            "Privacy and Security",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SecuritySettingsPage(),
                              ),
                            ),
                          ),

                          _buildDivider(),

                          _buildSettingsOption(
                              context, Icons.support, "Support"),

                          _buildDivider(),

                          _buildSettingsOption(context, Icons.info, "About"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Styled logout button
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: themeProvider.isDarkMode
                            ? Colors.red.withOpacity(0.2)
                            : Colors.red.withOpacity(0.1),
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.logout,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          "Logout",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'poppy',
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        onTap: () => _handleLogout(context),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      "Version 0.00.00",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontFamily: 'poppylight',
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Show dialog with profile picture options
  void _showProfilePictureOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15.0)),
      ),
      builder: (context) => ProfilePictureOptionsSheet(),
    ).then((result) {
      // If result is true, refresh the page to show the updated profile picture
      if (result == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsPage(),
          ),
        );
      }
    });
  }

  // Helper method to create a divider between settings options
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 56, // Aligned with the title text's start
      endIndent: 16,
    );
  }

  // Consistent settings option builder
  Widget _buildSettingsOption(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.secondary),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.secondary,
          fontFamily: 'poppy',
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Theme.of(context).colorScheme.secondary,
      ),
      onTap: onTap ??
          () {
            // Default navigation handler
          },
    );
  }
}
