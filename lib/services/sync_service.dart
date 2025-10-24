import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class SyncService {
  static final _fire = FirebaseFirestore.instance;
  static final _subs = <StreamSubscription>[];

  static Future<void> start() async {
    for (final name in [
      'machines','moulds','jobs','queue','inputs','issues','downtime','floors','users'
    ]) {
      await _listen(name);
    }
  }

  static Future<void> _listen(String boxName) async {
    final box = await Hive.openBox(boxName);
    _subs.add(_fire.collection(boxName).snapshots().listen((snap) async {
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        await box.put(doc.id, data);
      }
    }));
  }

  static Future<void> pushChange(String boxName, String id, Map<String, dynamic> data) async {
    await _fire.collection(boxName).doc(id).set(data, SetOptions(merge: true));
  }

  static Future<void> deleteRemote(String boxName, String id) async {
    await _fire.collection(boxName).doc(id).delete();
  }

  static Future<void> stop() async {
    for (final s in _subs) { await s.cancel(); }
  }
}
