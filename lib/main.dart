import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/dark_theme.dart';
import 'services/sync_service.dart';
import 'services/background_sync.dart';
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await _openCoreBoxes();

  // Seed one admin if empty
  final users = Hive.box('usersBox');
  if(users.isEmpty){
    users.add({'username':'admin','password':'admin123','level':4,'shift':'Any'});
  }

  await SyncService.start();
  await BackgroundSync.initialize();

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
