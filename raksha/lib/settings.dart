// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:raksha/edit_profile.dart';
import 'package:raksha/get_started.dart';
import 'package:raksha/login.dart';
import 'package:raksha/notifications_page.dart';
import 'package:raksha/security_settings.dart';
import 'package:raksha/support_page.dart';
import 'package:raksha/about_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:raksha/theme_provider.dart';
import 'package:raksha/language_provider.dart'; // Add this import

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
                    color: Theme.of(context).primaryColor,
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

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Close the loading dialog
      Navigator.of(context).pop();

      // Navigate to login screen and clear navigation stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const GetStartedPage()),
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

  // Show language selection dialog
  Future<void> _showLanguageSelector(BuildContext context) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    // Map of available languages
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'हिंदी (Hindi)',
      'es': 'Español (Spanish)',
      'fr': 'Français (French)',
      'de': 'Deutsch (German)',
    };

    String? selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Select Language',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'poppy',
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final langCode = languages.keys.elementAt(index);
              final langName = languages.values.elementAt(index);

              return RadioListTile<String>(
                title: Text(
                  langName,
                  style: TextStyle(
                    fontFamily: 'poppy',
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                value: langCode,
                groupValue: languageProvider.currentLanguage,
                onChanged: (value) {
                  Navigator.of(context).pop(value);
                },
                activeColor: Theme.of(context).primaryColor,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'poppy',
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );

    if (selectedLanguage != null &&
        selectedLanguage != languageProvider.currentLanguage) {
      await languageProvider.setLanguage(selectedLanguage);

      // Show confirmation of language change
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Language changed to ${languages[selectedLanguage]}',
                style: const TextStyle(
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider =
        Provider.of<LanguageProvider>(context); // Add language provider
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'poppy'),
        ),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontFamily: 'poppy',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Force refresh of the page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: isDarkMode ? Colors.white : Colors.white,
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(fontFamily: 'poppy'),
                    ),
                  ),
                ],
              ),
            );
          }

          final userData = snapshot.data;
          final username = userData?['username'] as String? ?? 'User';
          final email = userData?['email'] as String? ?? '';

          // Get the first letter of username for avatar
          final firstLetter =
              username.isNotEmpty ? username[0].toUpperCase() : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Profile Section with Avatar showing first letter
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isDarkMode ? const Color(0xFF333333) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar with first letter
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              firstLetter,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'poppy',
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Username with verified badge if applicable
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'poppy',
                                color:
                                    Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            if (userData?['verified'] == true) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.verified,
                                size: 18,
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Email address
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: 'poppylight',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Settings options in a Card with categorized sections
                Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  color: isDarkMode ? const Color(0xFF333333) : Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account section header
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                        child: Text(
                          "Account",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                            fontFamily: 'poppy',
                          ),
                        ),
                      ),

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

                      _buildDivider(context),

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

                      // Preferences section header
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                        child: Text(
                          "Preferences",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                            fontFamily: 'poppy',
                          ),
                        ),
                      ),

                      _buildSettingsOption(
                        context,
                        Icons.notifications,
                        "Notifications",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsPage(),
                          ),
                        ),
                      ),

                      _buildDivider(context),

                      // Theme Toggle Option with dynamic icon and text
                      SwitchListTile(
                        secondary: Icon(
                          themeProvider.isDarkMode
                              ? Icons.dark_mode
                              : Icons.light_mode,
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
                        activeColor: Theme.of(context).primaryColor,
                      ),

                      _buildDivider(context),

                      // Language Option - NEW ADDITION
                      _buildSettingsOption(
                        context,
                        Icons.language,
                        "Language",
                        onTap: () => _showLanguageSelector(context),
                        subtitle:
                            _getLanguageName(languageProvider.currentLanguage),
                      ),

                      // Help & About section header
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                        child: Text(
                          "Help & About",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                            fontFamily: 'poppy',
                          ),
                        ),
                      ),

                      // Support Option
                      _buildSettingsOption(
                        context,
                        Icons.support,
                        "Support",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SupportPage(),
                          ),
                        ),
                      ),

                      _buildDivider(context),

                      // About Option
                      _buildSettingsOption(
                        context,
                        Icons.info,
                        "About",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AboutPage(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Styled logout button
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Logout",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'poppy',
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),

                // Version info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.6),
                      fontFamily: 'poppylight',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to get language name from language code
  String _getLanguageName(String languageCode) {
    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'हिंदी (Hindi)',
      'es': 'Español (Spanish)',
      'fr': 'Français (French)',
      'de': 'Deutsch (German)',
    };

    return languages[languageCode] ?? 'English';
  }

  // Helper method to create a divider between settings options
  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56, // Aligned with the title text's start
      endIndent: 16,
      color: Theme.of(context).dividerColor,
    );
  }

  // Consistent settings option builder with ripple effect
  Widget _buildSettingsOption(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap, String? subtitle}) {
    return InkWell(
      onTap: onTap ?? () {},
      splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
      highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
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
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.7),
                    fontFamily: 'poppylight',
                  ),
                )
              : null,
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
