import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/dark_theme.dart';
import 'services/sync_service.dart';
import 'services/background_sync.dart';
import 'services/live_progress_service.dart';
import 'services/notification_service.dart';
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 ProMould: Starting app...');
  
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('✅ Firebase initialized');
  
  print('📦 Initializing Hive...');
  await Hive.initFlutter();
  await _openCoreBoxes();
  print('✅ Hive initialized');

  // Seed one admin if empty
  final users = Hive.box('usersBox');
  if(users.isEmpty){
    users.put('admin', {'username':'admin','password':'admin123','level':4,'shift':'Any'});
    print('👤 Created admin user');
  }

  print('🔄 Starting sync services...');
  await SyncService.start();
  await BackgroundSync.initialize();
  print('✅ Sync services started');

  print('⏱️ Starting live progress service...');
  LiveProgressService.start();
  print('✅ Live progress service started');

  print('🔔 Starting notification service...');
  NotificationService.start();
  print('✅ Notification service started');

  print('🎨 Launching app UI...');
  runApp(const ProMouldApp());
}

class ProMouldApp extends StatelessWidget {
  const ProMouldApp({super.key});
  @override Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ProMould',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const LoginScreen(),
    );
  }
}
