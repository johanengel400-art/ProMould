// lib/screens/production_timeline_screen.dart
// Production timeline and schedule view for management

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/live_progress_service.dart';

class ProductionTimelineScreen extends StatefulWidget {
  const ProductionTimelineScreen({super.key});

  @override
  State<ProductionTimelineScreen> createState() =>
      _ProductionTimelineScreenState();
}

class _ProductionTimelineScreenState extends State<ProductionTimelineScreen> {
  String _viewMode = 'timeline'; // 'timeline' or 'list'
  String _filterMachine = 'All';

  @override
  Widget build(BuildContext context) {
    final jobsBox = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');
    final mouldChangesBox = Hive.box('mouldChangesBox');

    final machines = machinesBox.values.cast<Map>().toList();
    final allJobs = jobsBox.values
        .cast<Map>()
        .where((j) => j['status'] == 'Running' || j['status'] == 'Queued')
        .toList();

    // Get scheduled and in-progress mould changes
    final mouldChanges = mouldChangesBox.values
        .cast<Map>()
        .where((mc) =>
            mc['status'] == 'Scheduled' || mc['status'] == 'In Progress')
        .toList();

    // Filter jobs by machine
    final filteredJobs = _filterMachine == 'All'
        ? allJobs
        : allJobs.where((j) => j['machineId'] == _filterMachine).toList();

    // Filter mould changes by machine
    final filteredMouldChanges = _filterMachine == 'All'
        ? mouldChanges
        : mouldChanges
            .where((mc) => mc['machineId'] == _filterMachine)
            .toList();

    // Calculate timeline data
    final timelineData = _calculateTimeline(filteredJobs, mouldsBox);
    final mouldChangeData = _calculateMouldChangeTimeline(
        filteredMouldChanges, machinesBox, mouldsBox);

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
              title: const Text('Production Timeline'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7209B7).withOpacity(0.3),
                      const Color(0xFF0F1419),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon:
                    Icon(_viewMode == 'timeline' ? Icons.list : Icons.timeline),
                onPressed: () {
                  setState(() {
                    _viewMode = _viewMode == 'timeline' ? 'list' : 'timeline';
                  });
                },
                tooltip:
                    _viewMode == 'timeline' ? 'List View' : 'Timeline View',
              ),
            ],
          ),

          // Filters
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filterMachine,
                      dropdownColor: const Color(0xFF0F1419),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Filter by Machine',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.filter_list,
                            color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF7209B7)),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: 'All', child: Text('All Machines')),
                        ...machines.map((m) => DropdownMenuItem(
                              value: m['id'] as String,
                              child: Text(m['name'] as String),
                            )),
                      ],
                      onChanged: (v) =>
                          setState(() => _filterMachine = v ?? 'All'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Summary Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSummaryStats(timelineData),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Mould Changes Section
          if (mouldChangeData.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Scheduled Mould Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildMouldChangeCard(mouldChangeData[index]),
                  childCount: mouldChangeData.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],

          // Jobs Section Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Production Jobs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Timeline or List View
          if (_viewMode == 'timeline')
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildTimelineView(timelineData, machinesBox, mouldsBox),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildJobCard(
                      timelineData[index], machinesBox, mouldsBox),
                  childCount: timelineData.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculateMouldChangeTimeline(
      List<Map> mouldChanges, Box machinesBox, Box mouldsBox) {
    final timeline = <Map<String, dynamic>>[];

    for (final change in mouldChanges) {
      final machine = machinesBox.get(change['machineId']) as Map?;
      final fromMould = mouldsBox.get(change['fromMouldId']) as Map?;
      final toMould = mouldsBox.get(change['toMouldId']) as Map?;
      final scheduledDate = DateTime.tryParse(change['scheduledDate'] ?? '');
      final estimatedDuration =
          (change['estimatedDuration'] as num? ?? 30).toInt();

      timeline.add({
        'type': 'mouldChange',
        'change': change,
        'machine': machine,
        'fromMould': fromMould,
        'toMould': toMould,
        'scheduledDate': scheduledDate,
        'estimatedEnd':
            scheduledDate?.add(Duration(minutes: estimatedDuration)),
        'duration': estimatedDuration,
        'status': change['status'],
      });
    }

    return timeline;
  }

  List<Map<String, dynamic>> _calculateTimeline(List<Map> jobs, Box mouldsBox) {
    final now = DateTime.now();
    final timeline = <Map<String, dynamic>>[];

    for (final job in jobs) {
      final mould = mouldsBox.values.cast<Map?>().firstWhere(
            (m) => m != null && m['id'] == job['mouldId'],
            orElse: () => null,
          );

      final cycleTime = (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
      final currentShots = job['status'] == 'Running'
          ? LiveProgressService.getEstimatedShots(job, mouldsBox)
          : (job['shotsCompleted'] as num? ?? 0).toInt();
      final targetShots = (job['targetShots'] as num? ?? 0).toInt();
      final remaining = targetShots - currentShots;

      DateTime? startTime;
      DateTime? estimatedEnd;
      Duration? timeRemaining;

      if (job['status'] == 'Running') {
        startTime = DateTime.tryParse(job['startTime'] ?? '');
        if (remaining > 0) {
          final minutesRemaining = (remaining * cycleTime / 60).toDouble();
          timeRemaining = Duration(minutes: minutesRemaining.round());
          estimatedEnd = now.add(timeRemaining);
        } else {
          // Overrun - already past target
          estimatedEnd = now;
          timeRemaining = Duration.zero;
        }
      }

      // Check if mould change is needed
      final mouldChangeNeeded = mould != null &&
          (mould['shotsRemaining'] as num? ?? 999999) < remaining;

      timeline.add({
        'job': job,
        'mould': mould,
        'currentShots': currentShots,
        'targetShots': targetShots,
        'remaining': remaining,
        'cycleTime': cycleTime,
        'startTime': startTime,
        'estimatedEnd': estimatedEnd,
        'timeRemaining': timeRemaining,
        'mouldChangeNeeded': mouldChangeNeeded,
        'isOverrun': currentShots > targetShots,
        'progress': targetShots > 0
            ? (currentShots / targetShots).clamp(0.0, 1.0)
            : 0.0,
      });
    }

    // Sort by estimated end time (running jobs first, then queued)
    timeline.sort((a, b) {
      if (a['job']['status'] == 'Running' && b['job']['status'] != 'Running')
        return -1;
      if (a['job']['status'] != 'Running' && b['job']['status'] == 'Running')
        return 1;

      final aEnd = a['estimatedEnd'] as DateTime?;
      final bEnd = b['estimatedEnd'] as DateTime?;

      if (aEnd == null && bEnd == null) return 0;
      if (aEnd == null) return 1;
      if (bEnd == null) return -1;

      return aEnd.compareTo(bEnd);
    });

    return timeline;
  }

  Widget _buildSummaryStats(List<Map<String, dynamic>> timeline) {
    final runningJobs =
        timeline.where((t) => t['job']['status'] == 'Running').length;
    final queuedJobs =
        timeline.where((t) => t['job']['status'] == 'Queued').length;
    final mouldChangesNeeded =
        timeline.where((t) => t['mouldChangeNeeded'] == true).length;
    final overrunJobs = timeline.where((t) => t['isOverrun'] == true).length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard('Running', runningJobs.toString(),
                const Color(0xFF06D6A0), Icons.play_circle)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Queued', queuedJobs.toString(),
                const Color(0xFF4CC9F0), Icons.schedule)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Mould Changes',
                mouldChangesNeeded.toString(),
                const Color(0xFFFFD166),
                Icons.build)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Overrun', overrunJobs.toString(),
                const Color(0xFFFF6B6B), Icons.warning)),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
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
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineView(
      List<Map<String, dynamic>> timeline, Box machinesBox, Box mouldsBox) {
    if (timeline.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No active or queued jobs',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final maxEndTime = timeline
        .where((t) => t['estimatedEnd'] != null)
        .fold<DateTime?>(null, (max, t) {
      final end = t['estimatedEnd'] as DateTime?;
      if (end == null) return max;
      if (max == null) return end;
      return end.isAfter(max) ? end : max;
    });

    final timelineSpan = maxEndTime != null
        ? maxEndTime.difference(now).inHours.toDouble()
        : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeline View',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // Time axis
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(
              (timelineSpan / 2).ceil() + 1,
              (i) {
                final time = now.add(Duration(hours: i * 2));
                return Expanded(
                  child: Text(
                    DateFormat('HH:mm').format(time),
                    style: const TextStyle(fontSize: 10, color: Colors.white38),
                  ),
                );
              },
            ),
          ),
        ),

        // Timeline bars
        ...timeline.map(
            (data) => _buildTimelineBar(data, now, timelineSpan, machinesBox)),
      ],
    );
  }

  Widget _buildTimelineBar(Map<String, dynamic> data, DateTime now,
      double timelineSpan, Box machinesBox) {
    final job = data['job'] as Map;
    final machine = machinesBox.get(job['machineId']) as Map?;
    final estimatedEnd = data['estimatedEnd'] as DateTime?;
    final isRunning = job['status'] == 'Running';
    final mouldChangeNeeded = data['mouldChangeNeeded'] as bool;
    final isOverrun = data['isOverrun'] as bool;

    Color barColor =
        isRunning ? const Color(0xFF06D6A0) : const Color(0xFF4CC9F0);
    if (isOverrun) barColor = const Color(0xFFFF6B6B);
    if (mouldChangeNeeded) barColor = const Color(0xFFFFD166);

    double barWidth = 0.5; // Default for queued jobs
    if (isRunning && estimatedEnd != null) {
      final hoursUntilEnd = estimatedEnd.difference(now).inMinutes / 60;
      barWidth = (hoursUntilEnd / timelineSpan).clamp(0.0, 1.0);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine?['name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      job['productName'] ?? 'Job',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: barWidth,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor, barColor.withOpacity(0.6)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            estimatedEnd != null
                                ? DateFormat('HH:mm').format(estimatedEnd)
                                : 'Queued',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (mouldChangeNeeded)
                      Positioned(
                        right: 8,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD166),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.build, size: 10, color: Colors.black),
                              SizedBox(width: 2),
                              Text(
                                'MOULD CHANGE',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  data['timeRemaining'] != null
                      ? _formatDuration(data['timeRemaining'] as Duration)
                      : 'Queued',
                  style: TextStyle(
                    fontSize: 11,
                    color: barColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(
      Map<String, dynamic> data, Box machinesBox, Box mouldsBox) {
    final job = data['job'] as Map;
    final machine = machinesBox.get(job['machineId']) as Map?;
    final mould = data['mould'] as Map?;
    final isRunning = job['status'] == 'Running';
    final mouldChangeNeeded = data['mouldChangeNeeded'] as bool;
    final isOverrun = data['isOverrun'] as bool;
    final estimatedEnd = data['estimatedEnd'] as DateTime?;
    final timeRemaining = data['timeRemaining'] as Duration?;

    Color statusColor =
        isRunning ? const Color(0xFF06D6A0) : const Color(0xFF4CC9F0);
    if (isOverrun) statusColor = const Color(0xFFFF6B6B);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F1419),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: mouldChangeNeeded
              ? const Color(0xFFFFD166)
              : statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isRunning ? Icons.play_circle : Icons.schedule,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['productName'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${machine?['name'] ?? 'Unknown'} • ${job['color'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isRunning ? 'RUNNING' : 'QUEUED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            if (isRunning) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              isOverrun
                                  ? '${data['currentShots']}/${data['targetShots']} (+${data['currentShots'] - data['targetShots']} overrun)'
                                  : '${data['currentShots']}/${data['targetShots']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isOverrun
                                    ? const Color(0xFFFF6B6B)
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: data['progress'] as double,
                            backgroundColor: Colors.white12,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(statusColor),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Estimated End',
                    estimatedEnd != null
                        ? DateFormat('MMM d, HH:mm').format(estimatedEnd)
                        : 'Not started',
                    Icons.access_time,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Time Remaining',
                    timeRemaining != null
                        ? _formatDuration(timeRemaining)
                        : 'Queued',
                    Icons.timer,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Mould',
                    mould?['name'] ?? 'Unknown',
                    Icons.category,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Cycle Time',
                    '${data['cycleTime']}s',
                    Icons.speed,
                  ),
                ),
              ],
            ),

            // Mould change warning
            if (mouldChangeNeeded) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFFD166).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning,
                        color: Color(0xFFFFD166), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mould change required before completion',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD166),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 24) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return '${days}d ${hours}h';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  Widget _buildMouldChangeCard(Map<String, dynamic> data) {
    final change = data['change'] as Map;
    final machine = data['machine'] as Map?;
    final fromMould = data['fromMould'] as Map?;
    final toMould = data['toMould'] as Map?;
    final scheduledDate = data['scheduledDate'] as DateTime?;
    final estimatedEnd = data['estimatedEnd'] as DateTime?;
    final status = data['status'] as String;
    final duration = data['duration'] as int;

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'Scheduled':
        statusColor = const Color(0xFFFFD166);
        statusIcon = Icons.schedule;
        break;
      case 'In Progress':
        statusColor = const Color(0xFF4CC9F0);
        statusIcon = Icons.build;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF0F1419),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mould Change - ${machine?['name'] ?? 'Unknown Machine'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${fromMould?['name'] ?? 'Unknown'} → ${toMould?['name'] ?? 'Unknown'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.calendar_today,
                      'Scheduled',
                      scheduledDate != null
                          ? DateFormat('MMM dd, HH:mm').format(scheduledDate)
                          : 'Not set',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white12,
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.timer,
                      'Duration',
                      '$duration min',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white12,
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.access_time,
                      'Est. End',
                      estimatedEnd != null
                          ? DateFormat('HH:mm').format(estimatedEnd)
                          : 'N/A',
                    ),
                  ),
                ],
              ),
            ),
            if (change['assignedTo'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.white54),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned to: ${change['assignedTo']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
