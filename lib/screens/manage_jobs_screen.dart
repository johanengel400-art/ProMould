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
    
    // Show dialog to select next job
    if (machineId.isNotEmpty && context.mounted) {
      final queuedJobs = box.values.cast<Map?>()
        .where((job) => job != null && job['machineId'] == machineId && job['status'] == 'Queued')
        .toList();
      
      if (queuedJobs.isNotEmpty) {
        final selectedJob = await showDialog<Map?>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Job Completed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${j['productName']} completed with ${j['shotsCompleted'] ?? 0} shots.'),
                const SizedBox(height: 16),
                const Text('Select next job to start:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...queuedJobs.map((job) => ListTile(
                  title: Text(job!['productName'] ?? 'Unknown'),
                  subtitle: Text('${job['color'] ?? ''} • Target: ${job['targetShots'] ?? 0}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.pop(context, job),
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('No Next Job (Set Idle)'),
              ),
            ],
          ),
        );
        
        if (selectedJob != null) {
          // Start selected job
          final nextJobId = selectedJob['id'] as String;
          final updatedNext = Map<String,dynamic>.from(selectedJob);
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
          // User chose no next job - set machine to Idle
          final machine = machinesBox.get(machineId) as Map?;
          if (machine != null) {
            final updatedMachine = Map<String,dynamic>.from(machine);
            updatedMachine['status'] = 'Idle';
            await machinesBox.put(machineId, updatedMachine);
            await SyncService.pushChange('machinesBox', machineId, updatedMachine);
          }
        }
      } else {
        // No queued jobs - set machine to Idle
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
    final mouldsBox = Hive.box('mouldsBox');
    final moulds = mouldsBox.values.cast<Map>().toList();
    String? selectedMould = moulds.isNotEmpty ? moulds.first['id'] as String : null;
    
    await showDialog(context: context, builder: (_)=>StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('New Job'),
        content: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller:productCtrl, decoration: const InputDecoration(labelText:'Product Name')),
          const SizedBox(height:8),
          TextField(controller:colorCtrl, decoration: const InputDecoration(labelText:'Color')),
          const SizedBox(height:8),
          TextField(controller:targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Target Shots')),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: selectedMould,
            items: moulds.map((m)=>DropdownMenuItem<String>(
              value:m['id'] as String, 
              child: Text('${m['name']} (${m['cycleTime']}s)')
            )).toList(),
            onChanged: (v)=>setDialogState(()=>selectedMould=v),
            decoration: const InputDecoration(labelText:'Mould'),
          ),
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
              'mouldId': selectedMould ?? '',
              'status': 'Pending',
              'startTime': null,
              'endTime': null,
            };
            await box.put(id, data);
            await SyncService.pushChange('jobsBox', id, data);
            if (context.mounted) {
            Navigator.pop(context);
            }
          }, child: const Text('Save')),
        ],
      ),
    ));
    setState((){});
  }

  void _edit(Map j) async {
    final productCtrl=TextEditingController(text: j['productName'] as String?);
    final colorCtrl=TextEditingController(text: j['color'] as String?);
    final targetCtrl=TextEditingController(text: '${j['targetShots'] ?? 0}');
    final mouldsBox = Hive.box('mouldsBox');
    final moulds = mouldsBox.values.cast<Map>().toList();
    String? selectedMould = j['mouldId'] as String?;
    
    await showDialog(context: context, builder: (_)=>StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit Job'),
        content: Column(mainAxisSize: MainAxisSize.min, children:[
          TextField(controller:productCtrl, decoration: const InputDecoration(labelText:'Product Name')),
          const SizedBox(height:8),
          TextField(controller:colorCtrl, decoration: const InputDecoration(labelText:'Color')),
          const SizedBox(height:8),
          TextField(controller:targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText:'Target Shots')),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(
            value: selectedMould,
            items: moulds.map((m)=>DropdownMenuItem<String>(
              value:m['id'] as String, 
              child: Text('${m['name']} (${m['cycleTime']}s)')
            )).toList(),
            onChanged: (v)=>setDialogState(()=>selectedMould=v),
            decoration: const InputDecoration(labelText:'Mould'),
          ),
        ]),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            final box = Hive.box('jobsBox');
            final jobId = j['id'] as String;
            final data = Map<String,dynamic>.from(j);
            data['productName'] = productCtrl.text.trim();
            data['color'] = colorCtrl.text.trim();
            data['targetShots'] = int.tryParse(targetCtrl.text.trim()) ?? 0;
            data['mouldId'] = selectedMould ?? '';
            await box.put(jobId, data);
            await SyncService.pushChange('jobsBox', jobId, data);
            if (context.mounted) {
            Navigator.pop(context);
            }
          }, child: const Text('Save')),
        ],
      ),
    ));
    setState((){});
  }

  @override Widget build(BuildContext context){
    final box = Hive.box('jobsBox');
    final items = box.values.cast<Map>().toList();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Jobs'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CC9F0).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_,i){
                  final j = items[i];
                  final progress = (j['targetShots'] ?? 0) > 0 
                    ? ((j['shotsCompleted'] ?? 0) / (j['targetShots'] ?? 1) * 100).round()
                    : 0;
                  final status = j['status'] ?? 'Queued';
                  final statusColor = status == 'Running' ? const Color(0xFF06D6A0) :
                                     status == 'Paused' ? const Color(0xFFFFD166) :
                                     status == 'Finished' ? const Color(0xFF4CC9F0) :
                                     Colors.white38;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: const Color(0xFF0F1419),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${j['productName']} • ${j['color']??''}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withOpacity(0.5)),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Machine: ${j['machineId'] != '' ? j['machineId'] : 'Unassigned'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress / 100,
                                  backgroundColor: Colors.white12,
                                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$progress%',
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (j['status'] == 'Queued')
                                IconButton(
                                  icon: const Icon(Icons.play_arrow, color: Color(0xFF06D6A0)),
                                  tooltip: 'Start Job',
                                  onPressed: () => _startJob(j),
                                ),
                              if (j['status'] == 'Running')
                                IconButton(
                                  icon: const Icon(Icons.pause, color: Color(0xFFFFD166)),
                                  tooltip: 'Pause Job',
                                  onPressed: () => _pauseJob(j),
                                ),
                              if (j['status'] == 'Paused')
                                IconButton(
                                  icon: const Icon(Icons.play_arrow, color: Color(0xFF06D6A0)),
                                  tooltip: 'Resume Job',
                                  onPressed: () => _resumeJob(j),
                                ),
                              if (j['status'] == 'Running' || j['status'] == 'Paused')
                                IconButton(
                                  icon: const Icon(Icons.stop, color: Color(0xFFEF476F)),
                                  tooltip: 'End Job',
                                  onPressed: () => _endJob(j),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.white70),
                                tooltip: 'Edit Job',
                                onPressed: () => _edit(j),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
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
                        ],
                      ),
                    ),
                  );
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:_add,
        backgroundColor: const Color(0xFF4CC9F0),
        icon: const Icon(Icons.add),
        label: const Text('Add Job'),
      ),
    );
  }
}
