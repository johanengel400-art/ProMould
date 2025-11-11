// lib/services/push_notification_service.dart
// Firebase Cloud Messaging push notification service

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive/hive.dart';
import 'log_service.dart';

/// Push notification service using Firebase Cloud Messaging
/// Note: Uses FCM only, no local notifications (to avoid build issues)
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;
  static String? _fcmToken;
  static final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of received messages
  static Stream<RemoteMessage> get messageStream =>
      _messageStreamController.stream;

  /// Get FCM token
  static String? get fcmToken => _fcmToken;

  /// Initialize push notifications
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      LogService.info('Initializing push notifications...');

      // Request permission
      final settings = await _requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        LogService.warning('Push notification permission denied');
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      LogService.info('FCM Token: $_fcmToken');

      // Save token to Hive for backend use
      if (_fcmToken != null) {
        final box = await Hive.openBox('settingsBox');
        await box.put('fcmToken', _fcmToken);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        LogService.info('FCM Token refreshed: $newToken');
        Hive.box('settingsBox').put('fcmToken', newToken);
      });

      // Set up message handlers
      _setupMessageHandlers();

      _initialized = true;
      LogService.info('Push notifications initialized successfully');
    } catch (e, stackTrace) {
      LogService.error(
          'Failed to initialize push notifications', e, stackTrace);
    }
  }

  /// Request notification permission
  static Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    LogService.info('Notification permission: ${settings.authorizationStatus}');
    return settings;
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LogService.info('Foreground message received: ${message.messageId}');
      _messageStreamController.add(message);

      // Note: System will show notification automatically on Android/iOS
      // No local notification needed
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LogService.info('Notification tapped: ${message.messageId}');
      _messageStreamController.add(message);
    });

    // Check for initial message (app opened from terminated state)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        LogService.info('App opened from notification: ${message.messageId}');
        _messageStreamController.add(message);
      }
    });
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      LogService.info('Subscribed to topic: $topic');
    } catch (e) {
      LogService.error('Failed to subscribe to topic $topic', e);
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      LogService.info('Unsubscribed from topic: $topic');
    } catch (e) {
      LogService.error('Failed to unsubscribe from topic $topic', e);
    }
  }

  /// Send to topic (backend would handle this)
  static Future<void> sendToTopic(
    String topic, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'default',
  }) async {
    LogService.info('Would send notification to topic $topic: $title');
    // Note: Actual sending must be done from backend with FCM server key
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Get notification settings
  static Future<NotificationSettings> getSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Dispose
  static void dispose() {
    _messageStreamController.close();
    LogService.info('Push notifications disposed');
  }
}

/// Notification types
class NotificationType {
  static const String jobComplete = 'job_complete';
  static const String jobStarted = 'job_started';
  static const String machineBreakdown = 'machine_breakdown';
  static const String qualityIssue = 'quality_issue';
  static const String mouldChange = 'mould_change';
  static const String maintenanceDue = 'maintenance_due';
  static const String highScrapRate = 'high_scrap_rate';
  static const String lowMaterial = 'low_material';
  static const String shiftHandover = 'shift_handover';
}

/// Notification topics
class NotificationTopic {
  static const String allUsers = 'all_users';
  static const String operators = 'operators';
  static const String setters = 'setters';
  static const String managers = 'managers';
  static const String maintenance = 'maintenance';
  static const String quality = 'quality';
}
