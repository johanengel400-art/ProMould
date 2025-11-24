import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme/dark_theme.dart';
import 'services/sync_service.dart';
import 'services/background_sync.dart';
import 'services/live_progress_service.dart';
import 'services/notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/overrun_notification_service.dart';
import 'services/log_service.dart';
import 'services/error_handler.dart';
import 'utils/memory_manager.dart';
import 'utils/data_initializer.dart';
import 'screens/login_screen.dart';

import 'firebase_options.dart';

/// Handle background messages - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  LogService.info('Background message received: ${message.messageId}');
}

Future<void> _openCoreBoxes() async {
  await Hive.openBox('usersBox');
  await Hive.openBox('floorsBox');
  await Hive.openBox('machinesBox');
  await Hive.openBox('jobsBox');
  await Hive.openBox('mouldsBox');
  await Hive.openBox('issuesBox');
  await Hive.openBox('inputsBox');
  await Hive.openBox('queueBox');
  await Hive.openBox('downtimeBox');
  await Hive.openBox('checklistsBox');
  await Hive.openBox('mouldChangesBox');
  await Hive.openBox('qualityInspectionsBox');
  await Hive.openBox('qualityHoldsBox');
  await Hive.openBox('machineInspectionsBox');
  await Hive.openBox('dailyInspectionsBox');
  await Hive.openBox('dailyProductionBox');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LogService.info('ProMould: Starting app...');

  try {
    // Initialize Firebase first
    LogService.info('Initializing Firebase...');
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      LogService.info('Firebase initialized successfully');
    } catch (e) {
      LogService.error('Firebase initialization failed', e);
      // Continue without Firebase - app can work offline
    }

    // Register background message handler (only if Firebase initialized)
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      LogService.info('Background message handler registered');
    } catch (e) {
      LogService.warning('Could not register background message handler', e);
    }

    // Initialize Hive (critical - must succeed)
    LogService.info('Initializing Hive...');
    await Hive.initFlutter();
    await _openCoreBoxes();
    LogService.info('Hive initialized successfully');

    // Ensure admin user exists
    LogService.info('Ensuring admin user exists...');
    await DataInitializer.ensureAdminExists();

    final users = Hive.box('usersBox');
    LogService.info('Users box has ${users.length} users');
    LogService.info('User keys: ${users.keys.toList()}');

    // Start sync services (non-critical)
    try {
      LogService.info('Starting sync services...');
      await SyncService.start();
      await BackgroundSync.initialize();
      LogService.info('Sync services started successfully');
    } catch (e) {
      LogService.warning('Sync services failed to start - running offline', e);
    }

    // Start monitoring services (non-critical)
    try {
      LogService.info('Starting live progress service...');
      LiveProgressService.start();
      LogService.info('Live progress service started successfully');
    } catch (e) {
      LogService.warning('Live progress service failed', e);
    }

    try {
      LogService.info('Starting notification service...');
      NotificationService.start();
      LogService.info('Notification service started successfully');
    } catch (e) {
      LogService.warning('Notification service failed', e);
    }

    try {
      LogService.info('Starting overrun notification service...');
      OverrunNotificationService.start();
      LogService.info('Overrun notification service started successfully');
    } catch (e) {
      LogService.warning('Overrun notification service failed', e);
    }

    // Initialize push notifications (non-critical)
    try {
      LogService.info('Initializing push notifications...');
      await PushNotificationService.initialize();
      LogService.info('Push notifications initialized successfully');
    } catch (e) {
      LogService.warning('Push notifications failed to initialize', e);
    }

    // Initialize memory manager
    LogService.info('Initializing memory manager...');
    MemoryManager.initialize();
    LogService.info('Memory manager initialized successfully');

    LogService.info('Launching app UI...');
    runApp(const ProMouldApp());
  } catch (e, stackTrace) {
    LogService.fatal('Failed to start app', e, stackTrace);
    // Show error screen instead of crashing
    runApp(ErrorApp(error: e.toString()));
  }
}

class ProMouldApp extends StatelessWidget {
  const ProMouldApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProMould',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
      home: const LoginScreen(),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProMould - Error',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Start App',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Please check:\n'
                  '• Internet connection\n'
                  '• Firebase configuration\n'
                  '• App permissions',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
