// lib/screens/planning_screen.dart
// v7.2 – Professional planning page with enhanced layout and styling

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../services/sync_service.dart';
import '../services/live_progress_service.dart';
import '../services/scrap_rate_service.dart';

class PlanningScreen extends StatefulWidget {
  final int level;
  const PlanningScreen({super.key, required this.level});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  final uuid = const Uuid();
  String? selectedFloorId;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    // Update UI every 2 seconds for live progress
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

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

    // Calculate statistics
    final totalJobs = jobsBox.values.cast<Map>().where((j) => 
        j['status'] == 'Running' || j['status'] == 'Queued').length;
    final runningJobs = jobsBox.values.cast<Map>().where((j) => 
        j['status'] == 'Running').length;
    final queuedJobs = jobsBox.values.cast<Map>().where((j) => 
        j['status'] == 'Queued').length;
    final activeMachines = machines.where((m) => 
        m['status'] == 'Running').length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _assignJobDialog,
        icon: const Icon(Icons.add),
        label: const Text('Assign Job'),
        backgroundColor: const Color(0xFF4CC9F0),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Production Planning'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF06D6A0).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Statistics Cards
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _statCard('Total Jobs', totalJobs.toString(), Icons.work_outline, const Color(0xFF4CC9F0))),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard('Running', runningJobs.toString(), Icons.play_circle_outline, const Color(0xFF00D26A))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _statCard('Queued', queuedJobs.toString(), Icons.schedule, const Color(0xFFFFD166))),
                            const SizedBox(width: 12),
                            Expanded(child: _statCard('Active Machines', activeMachines.toString(), Icons.precision_manufacturing, const Color(0xFF9D4EDD))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: floorId,
                          items: floors
                              .map((f) =>
                                  DropdownMenuItem(value: f['id'] as String, child: Text('${f['name']}')))
                              .toList(),
                          onChanged: (v) => setState(() => selectedFloorId = v),
                          decoration: InputDecoration(
                            labelText: 'Select Floor',
                            prefixIcon: const Icon(Icons.apartment),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Machines List
          machines.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.precision_manufacturing, size: 64, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('No machines on this floor', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final m = machines[i];
                        final jobs = jobsBox.values.cast<Map>().where((j) =>
                            j['machineId'] == m['id'] &&
                            (j['status'] == 'Running' || j['status'] == 'Queued')).toList();
                        jobs.sort((a, b) =>
                            (a['startTime'] ?? '').toString().compareTo((b['startTime'] ?? '').toString()));
                        return _machineCard(m, jobs, mouldsBox);
                      },
                      childCount: machines.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _machineCard(Map m, List<Map> jobs, Box mouldsBox) {
    final runningJob = jobs.isNotEmpty ? jobs.first : null;
    final queuedJobs = jobs.skip(1).toList();
    final statusColor = _getStatusColor(m['status'] as String? ?? 'Idle');
    
    // Calculate scrap rate for this machine
    final machineId = m['id'] as String;
    final scrapData = ScrapRateService.calculateMachineScrapRate(machineId);
    final scrapRate = scrapData['scrapRate'] as double;
    final scrapColor = scrapData['color'] as Color;

    // Calculate cumulative time for queued jobs using live progress
    DateTime cumulativeTime = DateTime.now();
    if (runningJob != null) {
      final mould = mouldsBox.values.cast<Map?>().firstWhere(
        (m) => m != null && m['id'] == runningJob['mouldId'],
        orElse: () => null,
      );
      final cycle = (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
      
      // Use live estimated shots for accurate remaining calculation
      final currentShots = LiveProgressService.getEstimatedShots(runningJob, mouldsBox);
      final remaining = (runningJob['targetShots'] as num? ?? 0) - currentShots;
      
      final minutes = (remaining * cycle / 60).toDouble();
      cumulativeTime = cumulativeTime.add(Duration(minutes: minutes.round()));
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.precision_manufacturing, color: statusColor),
        ),
        title: Text(
          '${m['name']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${m['status']}',
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${jobs.length} job${jobs.length != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.white60),
                ),
              ],
            ),
            if (runningJob != null) ...[
              const SizedBox(height: 4),
              Text(
                _etaText(runningJob, mouldsBox, DateTime.now()),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.warning_outlined, size: 12, color: scrapColor),
                const SizedBox(width: 4),
                Text(
                  'Scrap: ${scrapRate.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: scrapColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (runningJob != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D26A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00D26A).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle, color: Color(0xFF00D26A), size: 20),
                      const SizedBox(width: 8),
                      const Text('RUNNING', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00D26A))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    runningJob['productName'] ?? 'Unknown Product',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _etaText(runningJob, mouldsBox, DateTime.now()),
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Builder(builder: (context) {
                    // Use live estimated shots for progress bar
                    final currentShots = LiveProgressService.getEstimatedShots(runningJob, mouldsBox);
                    final targetShots = runningJob['targetShots'] as num? ?? 1;
                    final progress = currentShots / targetShots;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D26A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$currentShots / $targetShots shots',
                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          if (queuedJobs.isEmpty && runningJob != null)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No queued jobs', style: TextStyle(color: Colors.white54)),
            )
          else if (queuedJobs.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.queue, size: 18, color: Colors.white54),
                  SizedBox(width: 8),
                  Text('QUEUE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white54)),
                ],
              ),
            ),
            for (final j in queuedJobs) ...[
              Builder(builder: (context) {
                final etaInfo = _etaText(j, mouldsBox, cumulativeTime);
                final queuePosition = queuedJobs.indexOf(j) + 1;
                
                // Update cumulative time for next job
                final mould = mouldsBox.values.cast<Map?>().firstWhere(
                  (m) => m != null && m['id'] == j['mouldId'],
                  orElse: () => null,
                );
                final cycle = (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
                final remaining = (j['targetShots'] as num? ?? 0) - 
                                 (j['shotsCompleted'] as num? ?? 0);
                final minutes = (remaining * cycle / 60).toDouble();
                cumulativeTime = cumulativeTime.add(Duration(minutes: minutes.round()));
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD166).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '$queuePosition',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD166),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              j['productName'] ?? 'Unknown Product',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              etaInfo,
                              style: const TextStyle(fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Running':
        return const Color(0xFF00D26A);
      case 'Idle':
        return const Color(0xFF6C757D);
      case 'Breakdown':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF4CC9F0);
    }
  }

  String _etaText(Map job, Box mouldsBox, DateTime startTime) {
    final mould = mouldsBox.values.cast<Map?>().firstWhere(
          (m) => m != null && m['id'] == job['mouldId'],
          orElse: () => null,
        );
    final cycle = (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
    
    // Use live estimated shots for accurate remaining calculation
    final currentShots = job['status'] == 'Running'
        ? LiveProgressService.getEstimatedShots(job, mouldsBox)
        : (job['shotsCompleted'] as num? ?? 0);
    final remaining = (job['targetShots'] as num? ?? 0) - currentShots;
    
    final minutes = (remaining * cycle / 60).toDouble();
    final eta = startTime.add(Duration(minutes: minutes.round()));
    final etaDate = DateFormat('MMM d').format(eta);
    final etaTime = DateFormat('HH:mm').format(eta);
    final duration = Duration(minutes: minutes.round());
    final hours = duration.inHours;
    final mins = duration.inMinutes % 60;
    final durationText = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    return 'ETA $etaDate $etaTime • $durationText • ${remaining} shots';
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
                  final mouldId = job['mouldId'] as String?;
                  
                  // Check if this is the first job for this machine
                  final existingJobs = jobsBox.values.cast<Map>().where((j) =>
                      j['machineId'] == machineId && 
                      (j['status'] == 'Running' || j['status'] == 'Queued')).toList();
                  
                  if (existingJobs.isEmpty) {
                    // First job - set to Running and update machine status
                    updatedJob['status'] = 'Running';
                    updatedJob['startTime'] = DateTime.now().toIso8601String();
                    
                    // Update machine status to Running and assign mould
                    final machine = machinesBox.get(machineId!) as Map?;
                    if (machine != null) {
                      final updatedMachine = Map<String, dynamic>.from(machine);
                      updatedMachine['status'] = 'Running';
                      updatedMachine['currentMouldId'] = mouldId ?? '';
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
