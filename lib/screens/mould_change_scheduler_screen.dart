// lib/screens/mould_change_scheduler_screen.dart
// Mould change scheduling and management

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';

class MouldChangeSchedulerScreen extends StatefulWidget {
  final int level;
  const MouldChangeSchedulerScreen({super.key, required this.level});

  @override
  State<MouldChangeSchedulerScreen> createState() => _MouldChangeSchedulerScreenState();
}

class _MouldChangeSchedulerScreenState extends State<MouldChangeSchedulerScreen> {
  final uuid = const Uuid();
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    if (!Hive.isBoxOpen('mouldChangesBox')) {
      await Hive.openBox('mouldChangesBox');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeBox(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final mouldChangesBox = Hive.box('mouldChangesBox');
        var changes = mouldChangesBox.values.cast<Map>().toList();

        // Filter
        if (selectedFilter != 'All') {
          changes = changes.where((c) => c['status'] == selectedFilter).toList();
        }

        // Sort by scheduled date
        changes.sort((a, b) {
          final aDate = DateTime.tryParse(a['scheduledDate'] ?? '') ?? DateTime.now();
          final bDate = DateTime.tryParse(b['scheduledDate'] ?? '') ?? DateTime.now();
          return aDate.compareTo(bDate);
        });

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          appBar: AppBar(
            title: const Text('Mould Change Scheduler'),
            backgroundColor: const Color(0xFF0F1419),
            elevation: 0,
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _scheduleMouldChange,
            icon: const Icon(Icons.add),
            label: const Text('Schedule Change'),
            backgroundColor: const Color(0xFF4CC9F0),
          ),
          body: Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', changes.length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Scheduled', changes.where((c) => c['status'] == 'Scheduled').length),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress', changes.where((c) => c['status'] == 'In Progress').length),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', changes.where((c) => c['status'] == 'Completed').length),
                    ],
                  ),
                ),
              ),

              // Changes List
              Expanded(
                child: changes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swap_horiz, size: 64, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'No mould changes ${selectedFilter != 'All' ? 'with status: $selectedFilter' : 'scheduled'}',
                              style: TextStyle(color: Colors.white.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: changes.length,
                        itemBuilder: (_, i) => _buildChangeCard(changes[i]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = selectedFilter == label;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => selectedFilter = label);
      },
      backgroundColor: const Color(0xFF1A1F2E),
      selectedColor: const Color(0xFF4CC9F0).withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4CC9F0) : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF4CC9F0) : Colors.white24,
      ),
    );
  }

  Widget _buildChangeCard(Map change) {
    final status = change['status'] as String? ?? 'Scheduled';
    final statusColor = _getStatusColor(status);
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');
    final usersBox = Hive.box('usersBox');

    final machine = machinesBox.get(change['machineId']) as Map?;
    final fromMould = mouldsBox.get(change['fromMouldId']) as Map?;
    final toMould = mouldsBox.get(change['toMouldId']) as Map?;
    final setter = usersBox.values.cast<Map>().firstWhere(
      (u) => u['username'] == change['assignedTo'],
      orElse: () => {'username': 'Unassigned'},
    );

    final scheduledDate = DateTime.tryParse(change['scheduledDate'] ?? '') ?? DateTime.now();
    final isOverdue = status == 'Scheduled' && scheduledDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            const Color(0xFF1A1F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? const Color(0xFFFF6B6B) : statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.swap_horiz, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machine?['name'] ?? 'Unknown Machine',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFF6B6B)),
                              ),
                              child: const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Color(0xFFFF6B6B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Mould Change
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FROM',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fromMould?['number'] ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            fromMould?['name'] ?? '',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, color: Color(0xFF4CC9F0)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TO',
                            style: TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            toMould?['number'] ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF00D26A),
                            ),
                          ),
                          Text(
                            toMould?['name'] ?? '',
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.person_outline, 'Assigned To', setter['username'] as String),
                      const Divider(height: 16, color: Colors.white12),
                      _buildInfoRow(Icons.calendar_today, 'Scheduled', DateFormat('MMM d, yyyy HH:mm').format(scheduledDate)),
                      if (change['estimatedDuration'] != null) ...[
                        const Divider(height: 16, color: Colors.white12),
                        _buildInfoRow(Icons.timer_outlined, 'Est. Duration', '${change['estimatedDuration']} min'),
                      ],
                      if (change['notes'] != null && (change['notes'] as String).isNotEmpty) ...[
                        const Divider(height: 16, color: Colors.white12),
                        _buildInfoRow(Icons.notes, 'Notes', change['notes'] as String),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    if (status == 'Scheduled') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatus(change, 'In Progress'),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Start'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF00D26A),
                            side: const BorderSide(color: Color(0xFF00D26A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (status == 'In Progress') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _updateStatus(change, 'Completed'),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Complete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00D26A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editMouldChange(change),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4CC9F0),
                          side: const BorderSide(color: Color(0xFF4CC9F0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteMouldChange(change),
                      icon: const Icon(Icons.delete_outline),
                      color: const Color(0xFFFF6B6B),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Future<void> _scheduleMouldChange() async {
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');
    final usersBox = Hive.box('usersBox');

    final machines = machinesBox.values.cast<Map>().toList();
    final moulds = mouldsBox.values.cast<Map>().toList();
    final setters = usersBox.values.cast<Map>().where((u) => (u['level'] as int? ?? 0) == 3).toList();

    if (machines.isEmpty || moulds.isEmpty || setters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need machines, moulds, and setters to schedule')),
      );
      return;
    }

    String? machineId = machines.first['id'] as String;
    String? fromMouldId = moulds.first['id'] as String;
    String? toMouldId = moulds.length > 1 ? moulds[1]['id'] as String : moulds.first['id'] as String;
    String? assignedTo = setters.first['username'] as String;
    DateTime scheduledDate = DateTime.now().add(const Duration(hours: 1));
    final durationCtrl = TextEditingController(text: '30');
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Mould Change'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: machineId,
                  decoration: const InputDecoration(labelText: 'Machine'),
                  items: machines
                      .map((m) => DropdownMenuItem(
                          value: m['id'] as String, child: Text(m['name'] as String)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => machineId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: fromMouldId,
                  decoration: const InputDecoration(labelText: 'From Mould'),
                  items: moulds
                      .map((m) => DropdownMenuItem(
                          value: m['id'] as String,
                          child: Text('${m['number']} - ${m['name']}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => fromMouldId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: toMouldId,
                  decoration: const InputDecoration(labelText: 'To Mould'),
                  items: moulds
                      .map((m) => DropdownMenuItem(
                          value: m['id'] as String,
                          child: Text('${m['number']} - ${m['name']}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => toMouldId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: assignedTo,
                  decoration: const InputDecoration(labelText: 'Assign To'),
                  items: setters
                      .map((s) => DropdownMenuItem(
                          value: s['username'] as String,
                          child: Text(s['username'] as String)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => assignedTo = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date: ${DateFormat('MMM d, yyyy HH:mm').format(scheduledDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(scheduledDate),
                      );
                      if (time != null) {
                        setDialogState(() {
                          scheduledDate = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  decoration: const InputDecoration(labelText: 'Est. Duration (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final mouldChangesBox = Hive.box('mouldChangesBox');
                final id = uuid.v4();
                final data = {
                  'id': id,
                  'machineId': machineId,
                  'fromMouldId': fromMouldId,
                  'toMouldId': toMouldId,
                  'assignedTo': assignedTo,
                  'scheduledDate': scheduledDate.toIso8601String(),
                  'estimatedDuration': int.tryParse(durationCtrl.text) ?? 30,
                  'notes': notesCtrl.text.trim(),
                  'status': 'Scheduled',
                  'createdAt': DateTime.now().toIso8601String(),
                };
                await mouldChangesBox.put(id, data);
                await SyncService.push('mouldChangesBox', id, data);
                Navigator.pop(dialogContext);
                setState(() {});
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMouldChange(Map change) async {
    // Similar to _scheduleMouldChange but pre-filled
    // Implementation similar to above
  }

  Future<void> _updateStatus(Map change, String newStatus) async {
    final mouldChangesBox = Hive.box('mouldChangesBox');
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');
    final id = change['id'] as String;
    final machineId = change['machineId'] as String?;
    final toMouldId = change['toMouldId'] as String?;
    
    final updated = Map<String, dynamic>.from(change);
    updated['status'] = newStatus;
    
    if (newStatus == 'In Progress' && machineId != null) {
      // Setter starts mould change - stop the machine
      updated['startedAt'] = DateTime.now().toIso8601String();
      
      // Update machine status to "Mould Change"
      final machine = machinesBox.get(machineId) as Map?;
      if (machine != null) {
        final updatedMachine = Map<String, dynamic>.from(machine);
        updatedMachine['status'] = 'Mould Change';
        updatedMachine['mouldChangeInProgress'] = true;
        await machinesBox.put(machineId, updatedMachine);
        await SyncService.pushChange('machinesBox', machineId, updatedMachine);
      }
      
      // Pause any running jobs on this machine
      final runningJobs = jobsBox.values.cast<Map>().where((j) =>
          j['machineId'] == machineId && j['status'] == 'Running').toList();
      
      for (final job in runningJobs) {
        final jobId = job['id'] as String;
        final updatedJob = Map<String, dynamic>.from(job);
        updatedJob['status'] = 'Paused';
        updatedJob['pausedTime'] = DateTime.now().toIso8601String();
        updatedJob['pauseReason'] = 'Mould Change';
        await jobsBox.put(jobId, updatedJob);
        await SyncService.pushChange('jobsBox', jobId, updatedJob);
      }
    } else if (newStatus == 'Completed' && machineId != null && toMouldId != null) {
      // Setter completes mould change
      updated['completedAt'] = DateTime.now().toIso8601String();
      
      // Update machine with new mould and set to Running
      final machine = machinesBox.get(machineId) as Map?;
      if (machine != null) {
        final updatedMachine = Map<String, dynamic>.from(machine);
        updatedMachine['status'] = 'Running';
        updatedMachine['currentMouldId'] = toMouldId;
        updatedMachine['mouldChangeInProgress'] = false;
        await machinesBox.put(machineId, updatedMachine);
        await SyncService.pushChange('machinesBox', machineId, updatedMachine);
      }
      
      // Find all pending jobs with the same mould and assign them to this machine
      final pendingJobsWithMould = jobsBox.values.cast<Map>().where((j) =>
          j['mouldId'] == toMouldId && 
          (j['status'] == 'Pending' || j['machineId'] == null || j['machineId'] == '')).toList();
      
      // Start the first job with this mould
      if (pendingJobsWithMould.isNotEmpty) {
        final firstJob = pendingJobsWithMould.first;
        final jobId = firstJob['id'] as String;
        final updatedJob = Map<String, dynamic>.from(firstJob);
        updatedJob['machineId'] = machineId;
        updatedJob['status'] = 'Running';
        updatedJob['startTime'] = DateTime.now().toIso8601String();
        await jobsBox.put(jobId, updatedJob);
        await SyncService.pushChange('jobsBox', jobId, updatedJob);
        
        // Queue remaining jobs with same mould
        for (var i = 1; i < pendingJobsWithMould.length; i++) {
          final job = pendingJobsWithMould[i];
          final jobId = job['id'] as String;
          final updatedJob = Map<String, dynamic>.from(job);
          updatedJob['machineId'] = machineId;
          updatedJob['status'] = 'Queued';
          await jobsBox.put(jobId, updatedJob);
          await SyncService.pushChange('jobsBox', jobId, updatedJob);
        }
      }
    }
    
    await mouldChangesBox.put(id, updated);
    await SyncService.push('mouldChangesBox', id, updated);
    setState(() {});
  }

  Future<void> _deleteMouldChange(Map change) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Mould Change'),
        content: const Text('Are you sure you want to delete this scheduled mould change?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final mouldChangesBox = Hive.box('mouldChangesBox');
      final id = change['id'] as String;
      await mouldChangesBox.delete(id);
      await SyncService.deleteRemote('mouldChangesBox', id);
      setState(() {});
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Scheduled':
        return const Color(0xFFFFD166);
      case 'In Progress':
        return const Color(0xFF4CC9F0);
      case 'Completed':
        return const Color(0xFF00D26A);
      default:
        return const Color(0xFF6C757D);
    }
  }
}
