// lib/screens/planning_screen.dart
// v7.2 – ETA calculation + refreshed layout

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class PlanningScreen extends StatefulWidget {
  final int level;
  const PlanningScreen({super.key, required this.level});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final uuid = const Uuid();
  String? selectedFloorId;

  @override
  Widget build(BuildContext context) {
    final floorsBox = Hive.box('floorsBox');
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');
    final mouldsBox = Hive.box('mouldsBox');

    final floors = floorsBox.values.cast<Map>().toList();
    final floorId =
        selectedFloorId ?? (floors.isNotEmpty ? floors.first['id'] as String : null);
    final machines = machinesBox.values
        .cast<Map>()
        .where((m) => (m['floorId'] ?? '') == (floorId ?? ''))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Production Planning')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _assignJobDialog,
        icon: const Icon(Icons.add),
        label: const Text('Assign Job'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: floorId,
              items: floors
                  .map((f) =>
                      DropdownMenuItem(value: f['id'] as String, child: Text('${f['name']}')))
                  .toList(),
              onChanged: (v) => setState(() => selectedFloorId = v),
              decoration: const InputDecoration(labelText: 'Select Floor'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: machines.length,
              itemBuilder: (_, i) {
                final m = machines[i];
                final jobs = jobsBox.values.cast<Map>().where((j) =>
                    j['machineId'] == m['id'] &&
                    (j['status'] == 'Running' || j['status'] == 'Queued')).toList();
                jobs.sort((a, b) =>
                    (a['startTime'] ?? '').toString().compareTo((b['startTime'] ?? '').toString()));
                return _machineCard(m, jobs, mouldsBox);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _machineCard(Map m, List<Map> jobs, Box mouldsBox) {
    final runningJob = jobs.isNotEmpty ? jobs.first : null;
    final queuedJobs = jobs.skip(1).toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ExpansionTile(
        title: Text('${m['name']} • ${m['status']}'),
        subtitle: runningJob == null
            ? const Text('No active job')
            : Text(_etaText(runningJob, mouldsBox)),
        children: [
          if (queuedJobs.isEmpty)
            const ListTile(title: Text('No queued jobs'))
          else
            for (final j in queuedJobs)
              ListTile(
                leading: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                title: Text(j['productName'] ?? ''),
                subtitle: Text(_etaText(j, mouldsBox)),
              ),
        ],
      ),
    );
  }

  String _etaText(Map job, Box mouldsBox) {
    final mould = mouldsBox.values.cast<Map?>().firstWhere(
          (m) => m != null && m['id'] == job['mouldId'],
          orElse: () => null,
        );
    final cycle = (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
    final remaining =
        (job['targetShots'] as num? ?? 0) - (job['shotsCompleted'] as num? ?? 0);
    final minutes = (remaining * cycle / 60).toDouble();
    final eta = DateTime.now().add(Duration(minutes: minutes.round()));
    final etaText = DateFormat('HH:mm').format(eta);
    return 'ETA $etaText • ${remaining} shots left';
  }

  Future<void> _assignJobDialog() async {
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');

    // Only show unassigned jobs (Pending status or empty machineId)
    final availableJobs = jobsBox.values.cast<Map>().where((j) =>
        (j['status'] == 'Pending' || j['machineId'] == '' || j['machineId'] == null)).toList();

    String? machineId =
        machinesBox.values.cast<Map>().isNotEmpty ? machinesBox.values.cast<Map>().first['id'] as String : null;
    String? jobId =
        availableJobs.isNotEmpty ? availableJobs.first['id'] as String : null;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Assign Job to Machine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: machineId,
                items: machinesBox.values
                    .cast<Map>()
                    .map((m) =>
                        DropdownMenuItem(value: m['id'] as String, child: Text('${m['name']}')))
                    .toList(),
                onChanged: (v) => setDialogState(() => machineId = v),
                decoration: const InputDecoration(labelText: 'Machine'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: jobId,
                items: availableJobs
                    .map((j) => DropdownMenuItem(
                        value: j['id'] as String, child: Text('${j['productName']}')))
                    .toList(),
                onChanged: (v) => setDialogState(() => jobId = v),
                decoration: const InputDecoration(labelText: 'Job (Unassigned)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (machineId == null || jobId == null) return;
                
                // Update the job with machineId and status
                final job = jobsBox.get(jobId) as Map?;
                if (job != null) {
                  final updatedJob = Map<String, dynamic>.from(job);
                  updatedJob['machineId'] = machineId;
                  
                  // Check if this is the first job for this machine
                  final existingJobs = jobsBox.values.cast<Map>().where((j) =>
                      j['machineId'] == machineId && 
                      (j['status'] == 'Running' || j['status'] == 'Queued')).toList();
                  
                  if (existingJobs.isEmpty) {
                    // First job - set to Running and update machine status
                    updatedJob['status'] = 'Running';
                    updatedJob['startTime'] = DateTime.now().toIso8601String();
                    
                    // Update machine status to Running
                    final machine = machinesBox.get(machineId!) as Map?;
                    if (machine != null) {
                      final updatedMachine = Map<String, dynamic>.from(machine);
                      updatedMachine['status'] = 'Running';
                      await machinesBox.put(machineId!, updatedMachine);
                      await SyncService.pushChange('machinesBox', machineId!, updatedMachine);
                    }
                  } else {
                    // Additional job - set to Queued
                    updatedJob['status'] = 'Queued';
                  }
                  
                  await jobsBox.put(jobId!, updatedJob);
                  await SyncService.pushChange('jobsBox', jobId!, updatedJob);
                }
                
                Navigator.pop(dialogContext);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    setState(() {});
  }
}
