import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';

class ManageJobsScreen extends StatefulWidget{
  final int level; const ManageJobsScreen({super.key, required this.level});
  @override State<ManageJobsScreen> createState()=>_ManageJobsScreenState();
}

class _ManageJobsScreenState extends State<ManageJobsScreen>{
  final uuid=const Uuid();

  Future<void> _startJob(Map j) async {
    final box = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final jobId = j['id'] as String;
    final updated = Map<String,dynamic>.from(j);
    updated['status'] = 'Running';
    updated['startTime'] = DateTime.now().toIso8601String();
    await box.put(jobId, updated);
    await SyncService.pushChange('jobsBox', jobId, updated);
    
    // Update machine status
    final machineId = j['machineId'] as String;
    if (machineId.isNotEmpty) {
      final machine = machinesBox.get(machineId) as Map?;
      if (machine != null) {
        final updatedMachine = Map<String,dynamic>.from(machine);
        updatedMachine['status'] = 'Running';
        await machinesBox.put(machineId, updatedMachine);
        await SyncService.pushChange('machinesBox', machineId, updatedMachine);
      }
    }
    setState((){});
  }

  Future<void> _pauseJob(Map j) async {
    final box = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final jobId = j['id'] as String;
    final updated = Map<String,dynamic>.from(j);
    updated['status'] = 'Paused';
    updated['pausedTime'] = DateTime.now().toIso8601String();
    await box.put(jobId, updated);
    await SyncService.pushChange('jobsBox', jobId, updated);
    
    // Update machine status to Idle
    final machineId = j['machineId'] as String;
    if (machineId.isNotEmpty) {
      final machine = machinesBox.get(machineId) as Map?;
      if (machine != null) {
        final updatedMachine = Map<String,dynamic>.from(machine);
        updatedMachine['status'] = 'Idle';
        await machinesBox.put(machineId, updatedMachine);
        await SyncService.pushChange('machinesBox', machineId, updatedMachine);
      }
    }
    setState((){});
  }

  Future<void> _resumeJob(Map j) async {
    final box = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final jobId = j['id'] as String;
    final updated = Map<String,dynamic>.from(j);
    updated['status'] = 'Running';
    updated['resumedTime'] = DateTime.now().toIso8601String();
    await box.put(jobId, updated);
    await SyncService.pushChange('jobsBox', jobId, updated);
    
    // Update machine status to Running
    final machineId = j['machineId'] as String;
    if (machineId.isNotEmpty) {
      final machine = machinesBox.get(machineId) as Map?;
      if (machine != null) {
        final updatedMachine = Map<String,dynamic>.from(machine);
        updatedMachine['status'] = 'Running';
        await machinesBox.put(machineId, updatedMachine);
        await SyncService.pushChange('machinesBox', machineId, updatedMachine);
      }
    }
    setState((){});
  }

  Future<void> _endJob(Map j) async {
    final box = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final jobId = j['id'] as String;
    final machineId = j['machineId'] as String;
    
    // Mark job as finished
    final updated = Map<String,dynamic>.from(j);
    updated['status'] = 'Finished';
    updated['endTime'] = DateTime.now().toIso8601String();
    await box.put(jobId, updated);
    await SyncService.pushChange('jobsBox', jobId, updated);
    
    // Start next queued job for this machine
    if (machineId.isNotEmpty) {
      final nextJob = box.values.cast<Map?>().firstWhere(
        (job) => job != null && job['machineId'] == machineId && job['status'] == 'Queued',
        orElse: () => null,
      );
      
      if (nextJob != null) {
        final nextJobId = nextJob['id'] as String;
        final updatedNext = Map<String,dynamic>.from(nextJob);
        updatedNext['status'] = 'Running';
        updatedNext['startTime'] = DateTime.now().toIso8601String();
        await box.put(nextJobId, updatedNext);
        await SyncService.pushChange('jobsBox', nextJobId, updatedNext);
        
        // Keep machine Running
        final machine = machinesBox.get(machineId) as Map?;
        if (machine != null) {
          final updatedMachine = Map<String,dynamic>.from(machine);
          updatedMachine['status'] = 'Running';
          await machinesBox.put(machineId, updatedMachine);
          await SyncService.pushChange('machinesBox', machineId, updatedMachine);
        }
      } else {
        // No more jobs - set machine to Idle
        final machine = machinesBox.get(machineId) as Map?;
        if (machine != null) {
          final updatedMachine = Map<String,dynamic>.from(machine);
          updatedMachine['status'] = 'Idle';
          await machinesBox.put(machineId, updatedMachine);
          await SyncService.pushChange('machinesBox', machineId, updatedMachine);
        }
      }
    }
    
    setState((){});
  }

  void _add() async {
    final productCtrl=TextEditingController();
    final colorCtrl=TextEditingController();
    final targetCtrl=TextEditingController();
    
    await showDialog(context: context, builder: (_)=>AlertDialog(
      title: const Text('New Job'),
      content: Column(mainAxisSize: MainAxisSize.min, children:[
        TextField(controller:productCtrl, decoration: const InputDecoration(labelText:'Product Name')),
        const SizedBox(height:8),
        TextField(controller:colorCtrl, decoration: const InputDecoration(labelText:'Color')),
        const SizedBox(height:8),
        TextField(controller:targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Target Shots')),
        const SizedBox(height:8),
        const Text('Note: Assign this job to a machine in Production Planning', 
          style: TextStyle(fontSize: 12, color: Colors.white70)),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final box = Hive.box('jobsBox');
          final id = uuid.v4();
          final data = {
            'id': id,
            'productName': productCtrl.text.trim(),
            'color': colorCtrl.text.trim(),
            'targetShots': int.tryParse(targetCtrl.text.trim()) ?? 0,
            'shotsCompleted': 0,
            'machineId': '',
            'status': 'Pending',
            'startTime': null,
            'endTime': null,
            'eta': null,
          };
          await box.put(id, data);
          await SyncService.pushChange('jobsBox', id, data);
          Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('jobsBox');
    final items = box.values.cast<Map>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Jobs')),
      floatingActionButton: FloatingActionButton(onPressed:_add, child: const Icon(Icons.add)),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_,i){
          final j = items[i];
          final progress = (j['targetShots'] ?? 0) > 0 
            ? ((j['shotsCompleted'] ?? 0) / (j['targetShots'] ?? 1) * 100).round()
            : 0;
          return Card(child: ListTile(
            title: Text('${j['productName']} • ${j['color']??''}'),
            subtitle: Text('Status: ${j['status']} • Machine: ${j['machineId'] != '' ? j['machineId'] : 'Unassigned'} • Progress: $progress%'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (j['status'] == 'Queued')
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    tooltip: 'Start Job',
                    onPressed: () => _startJob(j),
                  ),
                if (j['status'] == 'Running')
                  IconButton(
                    icon: const Icon(Icons.pause, color: Colors.orange),
                    tooltip: 'Pause Job',
                    onPressed: () => _pauseJob(j),
                  ),
                if (j['status'] == 'Paused')
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    tooltip: 'Resume Job',
                    onPressed: () => _resumeJob(j),
                  ),
                if (j['status'] == 'Running' || j['status'] == 'Paused')
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    tooltip: 'End Job',
                    onPressed: () => _endJob(j),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete Job',
                  onPressed: () async {
                    final jobId = j['id'] as String;
                    await box.delete(jobId);
                    await SyncService.deleteRemote('jobsBox', jobId);
                    setState((){});
                  },
                ),
              ],
            ),
          ));
        }),
    );
  }
}
