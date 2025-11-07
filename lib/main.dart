import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/dark_theme.dart';
import 'services/sync_service.dart';
import 'services/background_sync.dart';
import 'services/live_progress_service.dart';
import 'services/notification_service.dart';
import 'services/log_service.dart';
import 'services/error_handler.dart';
import 'utils/memory_manager.dart';
import 'screens/login_screen.dart';

import 'firebase_options.dart';

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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  LogService.info('ProMould: Starting app...');
  
  try {
    LogService.info('Initializing Firebase...');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    LogService.info('Firebase initialized successfully');
    
    LogService.info('Initializing Hive...');
    await Hive.initFlutter();
    await _openCoreBoxes();
    LogService.info('Hive initialized successfully');

    // Seed one admin if empty
    final users = Hive.box('usersBox');
    if(users.isEmpty){
      users.put('admin', {'username':'admin','password':'admin123','level':4,'shift':'Any'});
      LogService.auth('Created default admin user');
    }

    LogService.info('Starting sync services...');
    await SyncService.start();
    await BackgroundSync.initialize();
    LogService.info('Sync services started successfully');

    LogService.info('Starting live progress service...');
    LiveProgressService.start();
    LogService.info('Live progress service started successfully');

    LogService.info('Starting notification service...');
    NotificationService.start();
    LogService.info('Notification service started successfully');

    LogService.info('Initializing memory manager...');
    MemoryManager.initialize();
    LogService.info('Memory manager initialized successfully');

    LogService.info('Launching app UI...');
    runApp(const ProMouldApp());
  } catch (e, stackTrace) {
    LogService.fatal('Failed to start app', e, stackTrace);
    rethrow;
  }
}

class ProMouldApp extends StatelessWidget {
  const ProMouldApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProMould',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      scaffoldMessengerKey: ErrorHandler.scaffoldMessengerKey,
      home: const LoginScreen(),
    );
  }
}
