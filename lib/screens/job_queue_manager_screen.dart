// lib/screens/job_queue_manager_screen.dart
// Enhanced job management with drag-drop reordering

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/sync_service.dart';

class JobQueueManagerScreen extends StatefulWidget {
  final int level;
  const JobQueueManagerScreen({super.key, required this.level});

  @override
  State<JobQueueManagerScreen> createState() => _JobQueueManagerScreenState();
}

class _JobQueueManagerScreenState extends State<JobQueueManagerScreen> {
  String? selectedMachineId;

  @override
  Widget build(BuildContext context) {
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');
    
    final machines = machinesBox.values.cast<Map>().toList();
    
    if (machines.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Job Queue Manager')),
        body: const Center(child: Text('No machines available')),
      );
    }
    
    selectedMachineId ??= machines.first['id'] as String;
    
    final machineJobs = jobsBox.values.cast<Map>().where((j) =>
        j['machineId'] == selectedMachineId &&
        (j['status'] == 'Running' || j['status'] == 'Queued')).toList();
    
    // Sort by status and order
    machineJobs.sort((a, b) {
      if (a['status'] == 'Running' && b['status'] != 'Running') return -1;
      if (a['status'] != 'Running' && b['status'] == 'Running') return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Job Queue Manager'),
        backgroundColor: const Color(0xFF0F1419),
      ),
      body: Column(
        children: [
          // Machine Selector
          Container(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedMachineId,
              decoration: InputDecoration(
                labelText: 'Select Machine',
                prefixIcon: const Icon(Icons.precision_manufacturing),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF1A1F2E),
              ),
              items: machines.map((m) => DropdownMenuItem(
                value: m['id'] as String,
                child: Text(m['name'] as String),
              )).toList(),
              onChanged: (v) => setState(() => selectedMachineId = v),
            ),
          ),
          
          // Instructions
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CC9F0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF4CC9F0).withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF4CC9F0), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Long press and drag to reorder queued jobs',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Job List with Reordering
          Expanded(
            child: machineJobs.isEmpty
                ? const Center(
                    child: Text(
                      'No jobs in queue',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: machineJobs.length,
                    onReorder: (oldIndex, newIndex) {
                      // Don't allow reordering running job
                      if (oldIndex == 0 || newIndex == 0) return;
                      
                      setState(() {
                        if (newIndex > oldIndex) {
                          newIndex -= 1;
                        }
                        final item = machineJobs.removeAt(oldIndex);
                        machineJobs.insert(newIndex, item);
                      });
                      
                      // Update order in database
                      _updateJobOrder(machineJobs);
                    },
                    itemBuilder: (context, index) {
                      final job = machineJobs[index];
                      final isRunning = job['status'] == 'Running';
                      
                      return _buildJobCard(
                        key: ValueKey(job['id']),
                        job: job,
                        index: index,
                        isRunning: isRunning,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard({
    required Key key,
    required Map job,
    required int index,
    required bool isRunning,
  }) {
    final color = isRunning ? const Color(0xFF00D26A) : const Color(0xFFFFD166);
    
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            const Color(0xFF1A1F2E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Center(
            child: isRunning
                ? Icon(Icons.play_circle, color: color, size: 24)
                : Text(
                    '${index}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        title: Text(
          job['productName'] ?? 'Unknown Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Color: ${job['color'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
            Text(
              'Target: ${job['targetShots']} shots',
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
            if (isRunning)
              Text(
                'Completed: ${job['shotsCompleted']} shots',
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
          ],
        ),
        trailing: isRunning
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color),
                ),
                child: Text(
                  'RUNNING',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : const Icon(Icons.drag_handle, color: Colors.white54),
      ),
    );
  }

  Future<void> _updateJobOrder(List<Map> jobs) async {
    final jobsBox = Hive.box('jobsBox');
    
    for (var i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      final jobId = job['id'] as String;
      final updated = Map<String, dynamic>.from(job);
      updated['queuePosition'] = i;
      
      await jobsBox.put(jobId, updated);
      await SyncService.pushChange('jobsBox', jobId, updated);
    }
  }
}
