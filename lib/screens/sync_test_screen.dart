import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../services/sync_service.dart';

class SyncTestScreen extends StatefulWidget {
  const SyncTestScreen({super.key});
  @override
  State<SyncTestScreen> createState() => _SyncTestScreenState();
}

class _SyncTestScreenState extends State<SyncTestScreen> {
  String _status = 'Ready to test';
  final _fire = FirebaseFirestore.instance;

  Future<void> _testWrite() async {
    setState(() => _status = 'Writing to Firestore...');
    try {
      final testData = {
        'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'message': 'Test from device',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _fire
          .collection('test')
          .doc(testData['id'] as String)
          .set(testData);
      setState(() => _status = '✅ Write successful! Check other device.');
    } catch (e) {
      setState(() => _status = '❌ Write failed: $e');
    }
  }

  Future<void> _testRead() async {
    setState(() => _status = 'Reading from Firestore...');
    try {
      final snapshot = await _fire.collection('test').get();
      setState(() => _status = '✅ Found ${snapshot.docs.length} documents');
    } catch (e) {
      setState(() => _status = '❌ Read failed: $e');
    }
  }

  Future<void> _testMachineSync() async {
    setState(() => _status = 'Testing machine sync...');
    try {
      final box = Hive.box('machinesBox');
      final testId = 'test-machine-${DateTime.now().millisecondsSinceEpoch}';
      final data = {
        'id': testId,
        'name': 'Test Machine',
        'status': 'Idle',
        'tonnage': '100',
      };

      await box.put(testId, data);
      await SyncService.pushChange('machinesBox', testId, data);

      setState(() => _status = '✅ Machine synced! Check Firestore console.');
    } catch (e) {
      setState(() => _status = '❌ Machine sync failed: $e');
    }
  }

  Future<void> _checkFirestoreRules() async {
    setState(() => _status = 'Checking Firestore access...');
    try {
      // Try to write to a test collection
      await _fire.collection('_test_access').doc('test').set({'test': true});
      await _fire.collection('_test_access').doc('test').delete();
      setState(() => _status = '✅ Firestore rules allow read/write');
    } catch (e) {
      setState(() => _status = '❌ Firestore rules blocking access: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_status, style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkFirestoreRules,
              child: const Text('1. Check Firestore Rules'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testWrite,
              child: const Text('2. Test Write to Firestore'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testRead,
              child: const Text('3. Test Read from Firestore'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _testMachineSync,
              child: const Text('4. Test Machine Sync'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Instructions:\n'
              '1. Run test on Device A\n'
              '2. Check if data appears on Device B\n'
              '3. Check logs for sync messages',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
