// lib/screens/timeline_screen_v2.dart
// Mobile-friendly timeline with card-based layout

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/live_progress_service.dart';

class TimelineScreenV2 extends StatefulWidget {
  final int level;
  const TimelineScreenV2({super.key, required this.level});

  @override
  State<TimelineScreenV2> createState() => _TimelineScreenV2State();
}

class _TimelineScreenV2State extends State<TimelineScreenV2> {
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
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
    final jobsBox = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        title: const Text('Production Timeline'),
        backgroundColor: const Color(0xFF0F1419),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: jobsBox.listenable(),
        builder: (_, __, ___) {
          final jobs = jobsBox.values
              .cast<Map>()
              .where((j) => j['status'] == 'Running' || j['status'] == 'Queued')
              .toList();

          // Group jobs by machine
          final jobsByMachine = <String, List<Map>>{};
          for (final j in jobs) {
            final machineId = j['machineId'] as String? ?? '';
            if (machineId.isNotEmpty) {
              jobsByMachine.putIfAbsent(machineId, () => []).add(j);
            }
          }

          if (jobsByMachine.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline,
                      size: 64, color: Colors.white.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No active or queued jobs',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: jobsByMachine.entries.map((entry) {
              final machineId = entry.key;
              final machineJobs = entry.value;
              final machine = machinesBox.get(machineId) as Map?;

              // Sort: Running first, then Queued
              machineJobs.sort((a, b) {
                if (a['status'] == 'Running' && b['status'] != 'Running')
                  return -1;
                if (a['status'] != 'Running' && b['status'] == 'Running')
                  return 1;
                return 0;
              });

              return _buildMachineTimeline(machine, machineJobs, mouldsBox);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildMachineTimeline(Map? machine, List<Map> jobs, Box mouldsBox) {
    if (machine == null) return const SizedBox.shrink();

    final machineName = machine['name'] as String? ?? 'Unknown';
    final machineStatus = machine['status'] as String? ?? 'Idle';
    final statusColor = _getStatusColor(machineStatus);

    DateTime cumulativeTime = DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Machine Header
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
                  child: Icon(Icons.precision_manufacturing,
                      color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        machineName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                  color: statusColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              machineStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${jobs.length} job${jobs.length != 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Jobs Timeline
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: jobs.asMap().entries.map((entry) {
                final index = entry.key;
                final job = entry.value;
                final isLast = index == jobs.length - 1;

                final widget =
                    _buildJobCard(job, mouldsBox, cumulativeTime, index);

                // Update cumulative time for next job
                final mould = mouldsBox.values.cast<Map?>().firstWhere(
                      (m) => m != null && m['id'] == job['mouldId'],
                      orElse: () => null,
                    );
                final cycleTime =
                    (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
                final currentShots = job['status'] == 'Running'
                    ? LiveProgressService.getEstimatedShots(job, mouldsBox)
                    : (job['shotsCompleted'] as num? ?? 0);
                final remaining =
                    (job['targetShots'] as num? ?? 0) - currentShots;
                final durationMinutes = (remaining * cycleTime / 60).toDouble();
                cumulativeTime = cumulativeTime
                    .add(Duration(minutes: durationMinutes.round()));

                return Column(
                  children: [
                    widget,
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const SizedBox(width: 24),
                            Container(
                              width: 2,
                              height: 20,
                              color: Colors.white24,
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.arrow_downward,
                                size: 16, color: Colors.white24),
                          ],
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(
      Map job, Box mouldsBox, DateTime startTime, int position) {
    final isRunning = job['status'] == 'Running';
    final productName = job['productName'] as String? ?? 'Unknown Product';
    final color = job['color'] as String? ?? '';

    final mould = mouldsBox.values.cast<Map?>().firstWhere(
          (m) => m != null && m['id'] == job['mouldId'],
          orElse: () => null,
        );

    final cycleTime = (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
    final currentShots = isRunning
        ? LiveProgressService.getEstimatedShots(job, mouldsBox)
        : (job['shotsCompleted'] as num? ?? 0);
    final targetShots = job['targetShots'] as num? ?? 0;
    final remaining = targetShots - currentShots;
    final progress =
        targetShots > 0 ? (currentShots / targetShots).clamp(0.0, 1.0) : 0.0;

    final durationMinutes = (remaining * cycleTime / 60).toDouble();
    final endTime = startTime.add(Duration(minutes: durationMinutes.round()));

    final statusColor =
        isRunning ? const Color(0xFF00D26A) : const Color(0xFFFFD166);
    final statusIcon = isRunning ? Icons.play_circle : Icons.schedule;
    final statusText = isRunning ? 'RUNNING' : 'QUEUED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and Position
          Row(
            children: [
              if (!isRunning)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Center(
                    child: Text(
                      '${position + 1}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              if (!isRunning) const SizedBox(width: 12),
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Product Name
          Text(
            productName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (color.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  color,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Progress Bar
          if (isRunning) ...[
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor, statusColor.withOpacity(0.6)],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Stats Row
          Row(
            children: [
              _buildStat(Icons.check_circle_outline,
                  '$currentShots / $targetShots shots', Colors.white70),
              const SizedBox(width: 16),
              _buildStat(Icons.speed, '${cycleTime.toStringAsFixed(0)}s cycle',
                  Colors.white70),
            ],
          ),

          const SizedBox(height: 12),

          // Timeline
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Text(
                      isRunning ? 'Started' : 'Will Start',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, HH:mm').format(startTime),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.flag, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    const Text(
                      'Est. Completion',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, HH:mm').format(endTime),
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    const Text(
                      'Duration',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(durationMinutes),
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
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

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: color, fontSize: 11),
        ),
      ],
    );
  }

  String _formatDuration(double minutes) {
    final hours = minutes ~/ 60;
    final mins = (minutes % 60).round();
    if (hours > 0) {
      return '${hours}h ${mins}m';
    } else {
      return '${mins}m';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Running':
        return const Color(0xFF00D26A);
      case 'Changeover':
        return const Color(0xFFFFD166);
      case 'Breakdown':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF6C757D);
    }
  }
}
