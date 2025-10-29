// lib/services/sync_service.dart
// v7.2 – Realtime Firestore listeners + local Hive mirror

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

/// Handles realtime Firestore <-> Hive synchronization.
/// Each Firestore collection listed below is mirrored locally in Hive.
/// Updates are streamed via .snapshots() so UI widgets rebuild automatically.
class SyncService {
  static final FirebaseFirestore _fire = FirebaseFirestore.instance;
  static final List<StreamSubscription> _subs = [];

  /// Start listening to all Firestore collections.
  static Future<void> start() async {
    _cancelAll();
    await _listenBox('machinesBox', 'machines');
    await _listenBox('mouldsBox', 'moulds');
    await _listenBox('jobsBox', 'jobs');
    await _listenBox('inputsBox', 'inputs');
    await _listenBox('issuesBox', 'issues');
    await _listenBox('floorsBox', 'floors');
    await _listenBox('queueBox', 'queue');
    await _listenBox('downtimeBox', 'downtime');
    await _listenBox('usersBox', 'users');
    await _listenBox('mouldChangesBox', 'mouldChanges');
    await _listenBox('checklistsBox', 'checklists');
    await _listenBox('qualityInspectionsBox', 'qualityInspections');
    await _listenBox('qualityHoldsBox', 'qualityHolds');
    await _listenBox('machineInspectionsBox', 'machineInspections');
    await _listenBox('dailyInspectionsBox', 'dailyInspections');
  }

  static Future<void> _listenBox(String hiveBox, String collection) async {
    final box = await Hive.openBox(hiveBox);

    // Load initial snapshot
    final snapshot = await _fire.collection(collection).get();
    for (var doc in snapshot.docs) {
      await box.put(doc.id, doc.data());
    }

    // Listen for realtime updates
    final sub = _fire.collection(collection).snapshots().listen(
      (snap) async {
        for (final change in snap.docChanges) {
          switch (change.type) {
            case DocumentChangeType.added:
            case DocumentChangeType.modified:
              await box.put(change.doc.id, change.doc.data());
              break;
            case DocumentChangeType.removed:
              await box.delete(change.doc.id);
              break;
          }
        }
      },
      onError: (e) => print('[SyncService] Error for $collection: $e'),
      cancelOnError: false,
    );

    _subs.add(sub);
    print('[SyncService] Listening to $collection');
  }

  /// Push a local Hive record to Firestore.
  static Future<void> push(String boxName, String id, Map<String, dynamic> data) async {
    try {
      await _fire.collection(boxName.replaceAll('Box', '')).doc(id).set(data, SetOptions(merge: true));
    } catch (e) {
      print('[SyncService] Push error ($boxName/$id): $e');
    }
  }

  /// Cancel all active subscriptions.
  static void _cancelAll() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
  }

  /// Stop all listeners (called on logout or app close).
  static Future<void> stop() async {
    _cancelAll();
    print('[SyncService] All listeners cancelled');
  }

  // Legacy method names for backward compatibility
  static Future<void> pushChange(String boxName, String id, Map<String, dynamic> data) async {
    await push(boxName, id, data);
  }

  static Future<void> deleteRemote(String boxName, String id) async {
    try {
      await _fire.collection(boxName.replaceAll('Box', '')).doc(id).delete();
    } catch (e) {
      print('[SyncService] Delete error ($boxName/$id): $e');
    }
  }
}
