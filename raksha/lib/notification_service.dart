// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Notification channels
  static const String _emergencyChannelId = 'emergency_channel';
  static const String _safetyTipsChannelId = 'safety_tips_channel';
  static const String _locationAlertsChannelId = 'location_alerts_channel';
  static const String _appUpdatesChannelId = 'app_updates_channel';

  // Initialize notification service
  Future<void> initialize(BuildContext context) async {
    // Request permission for iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(
            'notification_icon'); // Using drawable resource

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(context, response);
      },
    );

    // Create notification channels on Android
    await _createNotificationChannels();

    // Listen for FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleIncomingMessage(message, context);
    });

    // Handle messages when app is in background but opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(
          context,
          NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: Random().nextInt(1000),
            payload: json.encode(message.data),
          ));
    });

    // Save FCM token to Firestore for targeted messages
    await _saveTokenToFirestore();
  }

  // Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // For Android 8.0+
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Clear existing channels first to prevent any corruption
    try {
      await androidPlugin.deleteNotificationChannel(_emergencyChannelId);
      await androidPlugin.deleteNotificationChannel(_safetyTipsChannelId);
      await androidPlugin.deleteNotificationChannel(_locationAlertsChannelId);
      await androidPlugin.deleteNotificationChannel(_appUpdatesChannelId);
    } catch (e) {
      debugPrint('Error clearing channels: $e');
    }

    // Create each channel individually
    try {
      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _emergencyChannelId,
          'Emergency Alerts',
          description: 'Critical safety alerts and emergency broadcasts',
          importance: Importance.high,
          enableVibration: true,
          enableLights: true,
          ledColor: Colors.red,
        ),
      );

      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _safetyTipsChannelId,
          'Safety Tips',
          description: 'Weekly safety advice and reminders',
          importance: Importance.defaultImportance,
        ),
      );

      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _locationAlertsChannelId,
          'Location Alerts',
          description: 'Notifications about safety concerns in your area',
          importance: Importance.high,
        ),
      );

      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          _appUpdatesChannelId,
          'App Updates',
          description: 'New features and important app updates',
          importance: Importance.low,
        ),
      );
    } catch (e) {
      debugPrint('Error creating channels: $e');
    }
  }

  // Save FCM token to Firestore for targeting specific devices
  Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _firebaseMessaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.email)
        .collection('tokens')
        .doc('fcm')
        .set({
      'token': token,
      'platform': Theme.of(navigatorKey.currentContext!).platform.toString(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Handle incoming FCM messages
  Future<void> _handleIncomingMessage(
      RemoteMessage message, BuildContext context) async {
    // Check user preferences before displaying notification
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('push_notifications') ?? true;

    if (!pushEnabled) return;

    final String notificationType = message.data['type'] ?? 'default';
    bool showNotification = false;
    String channelId = '';

    // Check if this notification type is enabled by user
    switch (notificationType) {
      case 'emergency':
        showNotification = prefs.getBool('emergency_alerts') ?? true;
        channelId = _emergencyChannelId;
        break;
      case 'safety_tip':
        showNotification = prefs.getBool('safety_tips') ?? true;
        channelId = _safetyTipsChannelId;
        break;
      case 'location_alert':
        showNotification = prefs.getBool('location_alerts') ?? true;
        channelId = _locationAlertsChannelId;
        break;
      case 'app_update':
        showNotification = prefs.getBool('app_updates') ?? true;
        channelId = _appUpdatesChannelId;
        break;
      default:
        showNotification = true;
        channelId = _safetyTipsChannelId;
    }

    if (!showNotification) return;

    // Show the notification
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      channelId,
      notificationType == 'emergency'
          ? 'Emergency Alerts'
          : notificationType == 'safety_tip'
              ? 'Safety Tips'
              : notificationType == 'location_alert'
                  ? 'Location Alerts'
                  : 'App Updates',
      channelDescription: 'Raksha app notifications',
      importance: notificationType == 'emergency' ||
              notificationType == 'location_alert'
          ? Importance.high
          : Importance.defaultImportance,
      priority: notificationType == 'emergency' ||
              notificationType == 'location_alert'
          ? Priority.high
          : Priority.defaultPriority,
      color: notificationType == 'emergency'
          ? Colors.red
          : notificationType == 'safety_tip'
              ? Colors.amber
              : notificationType == 'location_alert'
                  ? Colors.green
                  : Colors.blue,
      icon: 'notification_icon', // Using drawable resource instead of mipmap
      channelShowBadge: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _localNotifications.show(
        message.hashCode,
        message.notification?.title ?? 'Raksha Alert',
        message.notification?.body ?? '',
        details,
        payload: json.encode(message.data),
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  // Handle notification tap
  void _handleNotificationTap(
      BuildContext context, NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final data = json.decode(response.payload!) as Map<String, dynamic>;
      final notificationType = data['type'] as String?;
      final notificationId = data['id'] as String?;

      if (notificationType == null) return;

      // Navigate based on notification type
      switch (notificationType) {
        case 'emergency':
          // Navigate to emergency details or emergency contacts screen
          if (notificationId != null) {
            Navigator.pushNamed(
              context,
              '/emergency_details',
              arguments: {'id': notificationId},
            );
          } else {
            Navigator.pushNamed(context, '/emergency_contacts');
          }
          break;
        case 'safety_tip':
          // Navigate to safety tips screen or specific tip
          if (notificationId != null) {
            Navigator.pushNamed(
              context,
              '/safety_tip_details',
              arguments: {'id': notificationId},
            );
          } else {
            Navigator.pushNamed(context, '/safety_tips');
          }
          break;
        case 'location_alert':
          // Navigate to map or location alerts screen
          Navigator.pushNamed(
            context,
            '/map',
            arguments: {'alert': true, 'id': notificationId},
          );
          break;
        case 'app_update':
          // Navigate to app update screen or open app store
          Navigator.pushNamed(context, '/app_updates');
          break;
        default:
          // Navigate to home screen or notification center
          Navigator.pushNamed(context, '/notifications');
      }
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  // Method to subscribe to topics based on user preferences
  Future<void> updateNotificationSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final pushEnabled = prefs.getBool('push_notifications') ?? true;

    if (pushEnabled) {
      // Get individual preferences
      final emergencyEnabled = prefs.getBool('emergency_alerts') ?? true;
      final safetyTipsEnabled = prefs.getBool('safety_tips') ?? true;
      final locationAlertsEnabled = prefs.getBool('location_alerts') ?? true;
      final appUpdatesEnabled = prefs.getBool('app_updates') ?? true;

      // Subscribe or unsubscribe to topics based on preferences
      if (emergencyEnabled) {
        await _firebaseMessaging.subscribeToTopic('emergency');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('emergency');
      }

      if (safetyTipsEnabled) {
        await _firebaseMessaging.subscribeToTopic('safety_tips');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('safety_tips');
      }

      if (locationAlertsEnabled) {
        await _firebaseMessaging.subscribeToTopic('location_alerts');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('location_alerts');
      }

      if (appUpdatesEnabled) {
        await _firebaseMessaging.subscribeToTopic('app_updates');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('app_updates');
      }
    } else {
      // Unsubscribe from all topics if push notifications are disabled
      await _firebaseMessaging.unsubscribeFromTopic('emergency');
      await _firebaseMessaging.unsubscribeFromTopic('safety_tips');
      await _firebaseMessaging.unsubscribeFromTopic('location_alerts');
      await _firebaseMessaging.unsubscribeFromTopic('app_updates');
    }
  }

  // Send test notification (for debugging)
  Future<void> sendTestNotification(String type) async {
    // Simple test notification with fixed parameters to reduce error sources
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'test_channel',
      'Test Channel',
      channelDescription: 'Channel for test notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'notification_icon', // Using drawable resource instead of mipmap
      channelShowBadge: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    String title;
    String body;

    switch (type) {
      case 'emergency':
        title = 'EMERGENCY ALERT';
        body = 'This is a test emergency alert. Tap to view details.';
        break;
      case 'safety_tip':
        title = 'Safety Tip';
        body = 'Always keep emergency contacts updated in the app.';
        break;
      case 'location_alert':
        title = 'Location Alert';
        body = 'Increased incidents reported near your area. Stay vigilant.';
        break;
      case 'app_update':
        title = 'App Update Available';
        body = 'New features are available. Update your app now.';
        break;
      default:
        title = 'Test Notification';
        body = 'This is a test notification.';
    }

    try {
      await _localNotifications.show(
        // Use a fixed ID for testing to avoid potential issues
        100,
        title,
        body,
        details,
        payload: json.encode({'type': type, 'test': true}),
      );
    } catch (e) {
      debugPrint('Error showing test notification: $e');
    }
  }
}

// Add this global key to your main.dart file
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
