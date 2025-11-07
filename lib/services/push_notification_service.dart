// lib/services/push_notification_service.dart
// Firebase Cloud Messaging push notification service

import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'log_service.dart';

/// Handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  LogService.info('Background message received: ${message.messageId}');
  // Handle background message
}

/// Push notification service using Firebase Cloud Messaging
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static String? _fcmToken;
  static final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of received messages
  static Stream<RemoteMessage> get messageStream => _messageStreamController.stream;

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

      // Initialize local notifications
      await _initializeLocalNotifications();

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

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _initialized = true;
      LogService.info('Push notifications initialized successfully');
    } catch (e, stackTrace) {
      LogService.error('Failed to initialize push notifications', e, stackTrace);
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

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create Android notification channels
  static Future<void> _createNotificationChannels() async {
    const channels = [
      AndroidNotificationChannel(
        'high_importance',
        'High Importance Notifications',
        description: 'Critical alerts and urgent notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'default',
        'Default Notifications',
        description: 'General notifications',
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'low_importance',
        'Low Importance Notifications',
        description: 'Non-urgent notifications',
        importance: Importance.low,
      ),
    ];

    for (final channel in channels) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Set up message handlers
  static void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      LogService.info('Foreground message received: ${message.messageId}');
      _messageStreamController.add(message);
      _showLocalNotification(message);
    });

    // Message opened app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      LogService.info('Message opened app: ${message.messageId}');
      _messageStreamController.add(message);
      _handleNotificationTap(message);
    });

    // Check for initial message (app opened from terminated state)
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        LogService.info('App opened from notification: ${message.messageId}');
        _messageStreamController.add(message);
        _handleNotificationTap(message);
      }
    });
  }

  /// Show local notification for foreground messages
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      final channelId = _getChannelId(message);
      
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelId == 'high_importance' ? 'High Importance Notifications' : 'Default Notifications',
            channelDescription: notification.body,
            importance: channelId == 'high_importance' ? Importance.high : Importance.defaultImportance,
            priority: channelId == 'high_importance' ? Priority.high : Priority.defaultPriority,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Get notification channel ID based on priority
  static String _getChannelId(RemoteMessage message) {
    final priority = message.data['priority'] as String?;
    switch (priority) {
      case 'high':
        return 'high_importance';
      case 'low':
        return 'low_importance';
      default:
        return 'default';
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    LogService.info('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Handle notification tap with message data
  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    final id = message.data['id'] as String?;

    LogService.info('Handling notification tap: type=$type, id=$id');

    // Navigate based on notification type
    // This will be handled by the app's navigation system
  }

  /// Send notification to specific user (requires backend)
  static Future<void> sendToUser(String userId, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'default',
  }) async {
    // This would typically be done from your backend
    // Here's the data structure you'd send to FCM
    LogService.info('Sending notification to user: $userId');
    
    // In production, call your backend API to send the notification
    // Example payload:
    final payload = {
      'to': userId, // FCM token
      'notification': {
        'title': title,
        'body': body,
      },
      'data': {
        ...?data,
        'priority': priority,
      },
      'priority': priority == 'high' ? 'high' : 'normal',
    };
    
    LogService.debug('Notification payload: $payload');
  }

  /// Send notification to topic (requires backend)
  static Future<void> sendToTopic(String topic, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String priority = 'default',
  }) async {
    LogService.info('Sending notification to topic: $topic');
    
    // Subscribe to topic first
    await _messaging.subscribeToTopic(topic);
    
    // Backend would send to topic
    final payload = {
      'to': '/topics/$topic',
      'notification': {
        'title': title,
        'body': body,
      },
      'data': {
        ...?data,
        'priority': priority,
      },
    };
    
    LogService.debug('Topic notification payload: $payload');
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      LogService.info('Subscribed to topic: $topic');
    } catch (e) {
      LogService.error('Failed to subscribe to topic: $topic', e);
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      LogService.info('Unsubscribed from topic: $topic');
    } catch (e) {
      LogService.error('Failed to unsubscribe from topic: $topic', e);
    }
  }

  /// Get notification settings
  static Future<NotificationSettings> getSettings() async {
    return await _messaging.getNotificationSettings();
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await getSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Dispose resources
  static void dispose() {
    _messageStreamController.close();
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
