// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:raksha/notification_service.dart';
import 'package:raksha/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool _isLoading = true;
  bool _pushEnabled = true;
  bool _emergencyAlertsEnabled = true;
  bool _safetyTipsEnabled = true;
  bool _locationAlertsEnabled = true;
  bool _appUpdatesEnabled = true;

  // Reference to notification service
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Try to get notification settings from Firestore first
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.email)
            .collection('settings')
            .doc('notifications')
            .get();

        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _pushEnabled = data?['pushEnabled'] ?? true;
            _emergencyAlertsEnabled = data?['emergencyAlertsEnabled'] ?? true;
            _safetyTipsEnabled = data?['safetyTipsEnabled'] ?? true;
            _locationAlertsEnabled = data?['locationAlertsEnabled'] ?? true;
            _appUpdatesEnabled = data?['appUpdatesEnabled'] ?? true;
          });
        } else {
          // If not in Firestore, try local storage
          await _loadFromLocalStorage();
        }
      } else {
        // If not signed in, use local storage
        await _loadFromLocalStorage();
      }
    } catch (e) {
      // In case of any error, fall back to local storage
      await _loadFromLocalStorage();

      // Show error only if it's not a "not found" error
      if (!e.toString().contains('not found') && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading notification settings',
              style: const TextStyle(fontFamily: 'poppy'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _pushEnabled = prefs.getBool('push_notifications') ?? true;
          _emergencyAlertsEnabled = prefs.getBool('emergency_alerts') ?? true;
          _safetyTipsEnabled = prefs.getBool('safety_tips') ?? true;
          _locationAlertsEnabled = prefs.getBool('location_alerts') ?? true;
          _appUpdatesEnabled = prefs.getBool('app_updates') ?? true;
        });
      }
    } catch (e) {
      // Use defaults if local storage fails
    }
  }

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Save to both Firestore and local storage for redundancy
      final user = FirebaseAuth.instance.currentUser;

      // Save to Firestore if user is logged in
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.email)
            .collection('settings')
            .doc('notifications')
            .set({
          'pushEnabled': _pushEnabled,
          'emergencyAlertsEnabled': _emergencyAlertsEnabled,
          'safetyTipsEnabled': _safetyTipsEnabled,
          'locationAlertsEnabled': _locationAlertsEnabled,
          'appUpdatesEnabled': _appUpdatesEnabled,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Always save to local storage as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', _pushEnabled);
      await prefs.setBool('emergency_alerts', _emergencyAlertsEnabled);
      await prefs.setBool('safety_tips', _safetyTipsEnabled);
      await prefs.setBool('location_alerts', _locationAlertsEnabled);
      await prefs.setBool('app_updates', _appUpdatesEnabled);

      // Update notification subscriptions
      await _notificationService.updateNotificationSubscriptions();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                const Text(
                  'Settings saved successfully',
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
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Error saving settings: ${e.toString()}',
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to test notifications
  Future<void> _sendTestNotification(String type) async {
    try {
      await _notificationService.sendTestNotification(type);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Test ${_getNotificationTypeName(type)} sent',
                  style: const TextStyle(
                    fontFamily: 'poppy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not send test notification: ${e.toString()}',
              style: const TextStyle(fontFamily: 'poppy'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  String _getNotificationTypeName(String type) {
    switch (type) {
      case 'emergency':
        return 'Emergency Alert';
      case 'safety_tip':
        return 'Safety Tip';
      case 'location_alert':
        return 'Location Alert';
      case 'app_update':
        return 'App Update';
      default:
        return 'Notification';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'poppy'),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card at the top
                  Card(
                    margin: const EdgeInsets.all(16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Customize which notifications you'd like to receive to stay informed about important safety alerts.",
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.secondary,
                                fontFamily: 'poppylight',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Main settings card
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
                        // General section
                        _buildSectionHeader(context, "General"),

                        // Main push notifications toggle
                        SwitchListTile(
                          secondary: Icon(
                            Icons.notifications,
                            color: _pushEnabled
                                ? Theme.of(context).primaryColor
                                : Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.6),
                          ),
                          title: Text(
                            "Push Notifications",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.secondary,
                              fontFamily: 'poppy',
                            ),
                          ),
                          subtitle: Text(
                            "Enable or disable all notifications",
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.7),
                              fontFamily: 'poppylight',
                            ),
                          ),
                          value: _pushEnabled,
                          onChanged: (value) {
                            setState(() {
                              _pushEnabled = value;
                              // If disabling all notifications, also disable subtypes
                              if (!value) {
                                _emergencyAlertsEnabled = false;
                                _safetyTipsEnabled = false;
                                _locationAlertsEnabled = false;
                                _appUpdatesEnabled = false;
                              }
                            });
                            _saveNotificationSettings();
                          },
                          activeColor: Theme.of(context).primaryColor,
                        ),

                        const Divider(height: 1),

                        // Alert Types section header
                        _buildSectionHeader(context, "Alert Types"),

                        // Emergency alerts toggle with test button
                        _buildNotificationTile(
                          context,
                          "Emergency Alerts",
                          "Critical safety alerts and emergency broadcasts",
                          Icons.warning_amber_rounded,
                          Colors.red,
                          _emergencyAlertsEnabled,
                          (value) {
                            setState(() {
                              _emergencyAlertsEnabled = value;
                            });
                            _saveNotificationSettings();
                          },
                          () => _sendTestNotification('emergency'),
                        ),

                        const Divider(height: 1),

                        // Safety tips toggle with test button
                        _buildNotificationTile(
                          context,
                          "Safety Tips",
                          "Weekly safety advice and reminders",
                          Icons.tips_and_updates,
                          Colors.amber,
                          _safetyTipsEnabled,
                          (value) {
                            setState(() {
                              _safetyTipsEnabled = value;
                            });
                            _saveNotificationSettings();
                          },
                          () => _sendTestNotification('safety_tip'),
                        ),

                        const Divider(height: 1),

                        // Location alerts toggle with test button
                        _buildNotificationTile(
                          context,
                          "Location Alerts",
                          "Notifications about safety concerns in your area",
                          Icons.location_on,
                          Colors.green,
                          _locationAlertsEnabled,
                          (value) {
                            setState(() {
                              _locationAlertsEnabled = value;
                            });
                            _saveNotificationSettings();
                          },
                          () => _sendTestNotification('location_alert'),
                        ),

                        // App Updates section header
                        _buildSectionHeader(context, "App Updates"),

                        // App updates toggle with test button
                        _buildNotificationTile(
                          context,
                          "App Updates",
                          "New features and important app updates",
                          Icons.system_update,
                          Theme.of(context).primaryColor,
                          _appUpdatesEnabled,
                          (value) {
                            setState(() {
                              _appUpdatesEnabled = value;
                            });
                            _saveNotificationSettings();
                          },
                          () => _sendTestNotification('app_update'),
                        ),
                      ],
                    ),
                  ),

                  // Note about permissions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      "Note: Make sure to enable notifications for Raksha in your device settings for these preferences to take effect.",
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.7),
                        fontFamily: 'poppylight',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Save button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveNotificationSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          "Save Preferences",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'poppy',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper method to create section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).primaryColor,
          fontFamily: 'poppy',
        ),
      ),
    );
  }

  // Helper method to build notification tile with test button
  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color activeIconColor,
    bool isEnabled,
    Function(bool) onChanged,
    Function() onTestPressed,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                secondary: Icon(
                  icon,
                  color: (_pushEnabled && isEnabled)
                      ? activeIconColor
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.6),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.secondary,
                    fontFamily: 'poppy',
                  ),
                ),
                subtitle: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.7),
                    fontFamily: 'poppylight',
                  ),
                ),
                value: _pushEnabled && isEnabled,
                onChanged: _pushEnabled ? onChanged : null,
                activeColor: Theme.of(context).primaryColor,
              ),
            ),
            if (_pushEnabled && isEnabled)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: onTestPressed,
                  tooltip: 'Send test notification',
                  color: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
