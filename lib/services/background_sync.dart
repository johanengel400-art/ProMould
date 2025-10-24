import 'package:workmanager/workmanager.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BackgroundSync {
  static const String taskName = "promould_background_sync";

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      taskName, taskName,
      frequency: const Duration(minutes: 1),
      initialDelay: const Duration(seconds: 15),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  static void callbackDispatcher() {
    Workmanager().executeTask((_, __) async {
      try {
        final fire = FirebaseFirestore.instance;
        for (final pair in {
          'jobsBox':'jobs',
          'inputsBox':'inputs',
          'issuesBox':'issues',
          'queueBox':'queue',
        }.entries) {
          final box = await Hive.openBox(pair.key);
          for (final key in box.keys) {
            final v = box.get(key);
            if (v is Map) {
              await fire.collection(pair.value).doc('$key').set(Map<String,dynamic>.from(v), SetOptions(merge: true));
            }
          }
        }
      } catch (_) {}
      return Future.value(true);
    });
  }
}
