import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

class SyncService {
  static final _fire = FirebaseFirestore.instance;
  static final _subs = <StreamSubscription>[];

  static final _boxToCollection = {
    'machinesBox': 'machines',
    'mouldsBox': 'moulds',
    'jobsBox': 'jobs',
    'queueBox': 'queue',
    'inputsBox': 'inputs',
    'issuesBox': 'issues',
    'downtimeBox': 'downtime',
    'floorsBox': 'floors',
    'usersBox': 'users',
  };

  static Future<void> start() async {
    try {
      print('🔄 SyncService: Starting Firebase sync...');
      for (final entry in _boxToCollection.entries) {
        await _listen(entry.key, entry.value);
        print('✅ SyncService: Listening to ${entry.value} → ${entry.key}');
      }
      print('🔄 SyncService: All listeners active');
    } catch (e) {
      print('❌ SyncService start error: $e');
    }
  }

  static Future<void> _listen(String boxName, String collectionName) async {
    try {
      final box = Hive.box(boxName);
      _subs.add(_fire.collection(collectionName).snapshots().listen(
        (snap) async {
          print('📥 Received ${snap.docs.length} docs from $collectionName');
          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            await box.put(doc.id, data);
            print('💾 Saved ${doc.id} to $boxName');
          }
        },
        onError: (error) {
          print('❌ Sync error for $collectionName: $error');
        },
      ));
    } catch (e) {
      print('❌ Listen error for $boxName: $e');
    }
  }

  static Future<void> pushChange(String boxName, String id, Map<String, dynamic> data) async {
    try {
      final collectionName = _boxToCollection[boxName] ?? boxName;
      print('📤 Pushing $id to $collectionName...');
      await _fire.collection(collectionName).doc(id).set(data, SetOptions(merge: true));
      print('✅ Pushed $id to $collectionName');
    } catch (e) {
      print('❌ Push error for $boxName/$id: $e');
      rethrow;
    }
  }

  static Future<void> deleteRemote(String boxName, String id) async {
    try {
      final collectionName = _boxToCollection[boxName] ?? boxName;
      print('🗑️ Deleting $id from $collectionName...');
      await _fire.collection(collectionName).doc(id).delete();
      print('✅ Deleted $id from $collectionName');
    } catch (e) {
      print('❌ Delete error for $boxName/$id: $e');
      rethrow;
    }
  }

  static Future<void> stop() async {
    for (final s in _subs) { await s.cancel(); }
  }
}
