import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/sync_service.dart';
import '../utils/job_status.dart';
import '../widgets/overrun_indicator.dart';

class MachineDetailScreen extends StatefulWidget {
  final Map machine;
  const MachineDetailScreen({super.key, required this.machine});

  @override
  State<MachineDetailScreen> createState() => _MachineDetailScreenState();
}

class _MachineDetailScreenState extends State<MachineDetailScreen> {
  late Box jobsBox;
  late Box mouldsBox;
  late Box machinesBox;

  @override
  void initState() {
    super.initState();
    jobsBox = Hive.box('jobsBox');
    mouldsBox = Hive.box('mouldsBox');
    machinesBox = Hive.box('machinesBox');
    jobsBox.listenable().addListener(_onDataChanged);
    machinesBox.listenable().addListener(_onDataChanged);
  }

  @override
  void dispose() {
    jobsBox.listenable().removeListener(_onDataChanged);
    machinesBox.listenable().removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Running':
        return const Color(0xFF00D26A);
      case 'Breakdown':
        return const Color(0xFFFF6B6B);
      case 'Changeover':
        return const Color(0xFFFFD166);
      default:
        return const Color(0xFF6C757D);
    }
  }

  Future<void> _setMachineStatus(String status) async {
    final machineId = widget.machine['id'] as String;
    final machine = machinesBox.get(machineId) as Map?;
    if (machine != null) {
      final updated = Map<String, dynamic>.from(machine);
      updated['status'] = status;
      await machinesBox.put(machineId, updated);
      await SyncService.pushChange('machinesBox', machineId, updated);
      setState(() {});
    }
  }

  String _calculateETA(Map job, DateTime startTime) {
    final mould = mouldsBox.values.cast<Map?>().firstWhere(
      (m) => m != null && m['id'] == job['mouldId'],
      orElse: () => null,
    );

    if (mould == null) return 'No mould';

    final cycleTime = (mould['cycleTime'] as num?)?.toDouble() ?? 30.0;
    final remaining = (job['targetShots'] as num? ?? 0) - (job['shotsCompleted'] as num? ?? 0);

    if (remaining <= 0) return 'Complete';

    final minutes = (remaining * cycleTime / 60).toDouble();
    final eta = startTime.add(Duration(minutes: minutes.round()));
    final etaDate = DateFormat('MMM d').format(eta);
    final etaTime = DateFormat('HH:mm').format(eta);

    final hours = minutes ~/ 60;
    final mins = (minutes % 60).round();
    final durationText = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return 'ETA $etaDate $etaTime ($durationText)';
  }

  @override
  Widget build(BuildContext context) {
    final machineId = widget.machine['id'] as String;
    final machine = machinesBox.get(machineId) as Map? ?? widget.machine;
    
    final jobs = jobsBox.values
        .cast<Map>()
        .where((j) =>
            j['machineId'] == machineId &&
            (JobStatus.isActivelyRunning(j['status'] as String?) || j['status'] == JobStatus.queued))
        .toList();

    jobs.sort((a, b) {
      final aRunning = JobStatus.isActivelyRunning(a['status'] as String?);
      final bRunning = JobStatus.isActivelyRunning(b['status'] as String?);
      if (aRunning && !bRunning) return -1;
      if (!aRunning && bRunning) return 1;
      return 0;
    });

    final runningJob = jobs.isNotEmpty && JobStatus.isActivelyRunning(jobs.first['status'] as String?) ? jobs.first : null;
    final queuedJobs = runningJob != null ? jobs.skip(1).toList() : jobs;

    DateTime cumulativeTime = DateTime.now();
    if (runningJob != null) {
      final mould = mouldsBox.values.cast<Map?>().firstWhere(
        (m) => m != null && m['id'] == runningJob['mouldId'],
        orElse: () => null,
      );
      if (mould != null) {
        final cycle = (mould['cycleTime'] as num?)?.toDouble() ?? 30.0;
        final remaining = (runningJob['targetShots'] as num? ?? 0) -
            (runningJob['shotsCompleted'] as num? ?? 0);
        final minutes = (remaining * cycle / 60).toDouble();
        cumulativeTime = cumulativeTime.add(Duration(minutes: minutes.round()));
      }
    }

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
              title: Text('${machine['name']}'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _statusColor('${machine['status'] ?? 'Idle'}').withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: _setMachineStatus,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'Running', child: Text('Set Running')),
                  const PopupMenuItem(value: 'Idle', child: Text('Set Idle')),
                  const PopupMenuItem(value: 'Breakdown', child: Text('Set Breakdown')),
                  const PopupMenuItem(value: 'Changeover', child: Text('Set Changeover')),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Machine Info Card
                  Card(
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
                              const Text('Status: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor('${machine['status'] ?? 'Idle'}').withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: _statusColor('${machine['status'] ?? 'Idle'}').withOpacity(0.5)),
                                ),
                                child: Text(
                                  '${machine['status'] ?? 'Idle'}',
                                  style: TextStyle(
                                    color: _statusColor('${machine['status'] ?? 'Idle'}'),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Tonnage: ${machine['tonnage'] ?? 'N/A'}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text('Floor: ${machine['floorId'] ?? 'N/A'}', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Current Job
                  if (runningJob != null) ...[
                    const Text('Current Job', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Card(
                      color: const Color(0xFF0F1419),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFF06D6A0).withOpacity(0.3)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06D6A0).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.play_circle, color: Color(0xFF06D6A0), size: 32),
                        ),
                        title: Text('${runningJob['productName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                final completed = (runningJob['shotsCompleted'] as num? ?? 0).toInt();
                                final target = (runningJob['targetShots'] as num? ?? 1).toInt();
                                final overrun = completed > target ? completed - target : 0;
                                final isOverrun = completed > target;
                                return Text(
                                  isOverrun 
                                    ? '$completed/$target shots (+$overrun overrun)'
                                    : '$completed/$target shots',
                                  style: TextStyle(
                                    color: isOverrun ? const Color(0xFFFFD166) : Colors.white70,
                                    fontWeight: isOverrun ? FontWeight.bold : FontWeight.normal,
                                  ),
                                );
                              },
                            ),
                            Text(_calculateETA(runningJob, DateTime.now()), style: const TextStyle(fontSize: 12, color: Colors.white38)),
                          ],
                        ),
                        trailing: Builder(
                          builder: (context) {
                            final completed = (runningJob['shotsCompleted'] as num? ?? 0).toInt();
                            final target = (runningJob['targetShots'] as num? ?? 1).toInt();
                            final overrun = completed > target ? completed - target : 0;
                            final isOverrun = completed > target;
                            final percentage = ((completed / target) * 100).round().clamp(0, 100);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isOverrun ? '100%' : '$percentage%',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isOverrun ? const Color(0xFFFFD166) : const Color(0xFF06D6A0),
                                  ),
                                ),
                                if (isOverrun)
                                  Text(
                                    '+$overrun',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFD166),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Queued Jobs
                  const Text('Upcoming Jobs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  if (queuedJobs.isEmpty)
                    Card(
                      color: const Color(0xFF0F1419),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      child: const ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.white38),
                        title: Text('No queued jobs', style: TextStyle(color: Colors.white70)),
                      ),
                    )
                  else
                    ...queuedJobs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final j = entry.value;
                      final etaInfo = _calculateETA(j, cumulativeTime);

                      // Update cumulative time for next job
                      final mould = mouldsBox.values.cast<Map?>().firstWhere(
                        (m) => m != null && m['id'] == j['mouldId'],
                        orElse: () => null,
                      );
                      if (mould != null) {
                        final cycle = (mould['cycleTime'] as num?)?.toDouble() ?? 30.0;
                        final remaining = (j['targetShots'] as num? ?? 0) - (j['shotsCompleted'] as num? ?? 0);
                        final minutes = (remaining * cycle / 60).toDouble();
                        cumulativeTime = cumulativeTime.add(Duration(minutes: minutes.round()));
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: const Color(0xFF0F1419),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.white12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD166).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          title: Text('${j['productName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${j['targetShots']} shots', style: const TextStyle(color: Colors.white70)),
                              Text(etaInfo, style: const TextStyle(fontSize: 12, color: Colors.white38)),
                            ],
                          ),
                          trailing: const Icon(Icons.schedule, color: Color(0xFFFFD166)),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
