// lib/screens/dashboard_screen_v2.dart
// Professional revamped dashboard with all enhancements

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'machine_detail_screen.dart';
import '../services/live_progress_service.dart';
import '../services/scrap_rate_service.dart';

class DashboardScreenV2 extends StatefulWidget {
  final String username;
  final int level;
  const DashboardScreenV2({super.key, required this.username, required this.level});

  @override
  State<DashboardScreenV2> createState() => _DashboardScreenV2State();
}

class _DashboardScreenV2State extends State<DashboardScreenV2> {
  late Box machinesBox;
  late Box jobsBox;
  late Box floorsBox;
  late Box mouldsBox;
  late Box issuesBox;
  late Box downtimeBox;
  String? selectedFloorId;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    machinesBox = Hive.box('machinesBox');
    jobsBox = Hive.box('jobsBox');
    floorsBox = Hive.box('floorsBox');
    mouldsBox = Hive.box('mouldsBox');
    issuesBox = Hive.box('issuesBox');
    downtimeBox = Hive.box('downtimeBox');
    
    machinesBox.listenable().addListener(_onDataChanged);
    jobsBox.listenable().addListener(_onDataChanged);
    
    _uiUpdateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    machinesBox.listenable().removeListener(_onDataChanged);
    jobsBox.listenable().removeListener(_onDataChanged);
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final allMachines = machinesBox.values.cast<Map>().toList();
    final floors = floorsBox.values.cast<Map>().toList();
    
    final machines = selectedFloorId == null
        ? allMachines
        : allMachines.where((m) => m['floorId'] == selectedFloorId).toList();
    
    // Calculate overall stats
    final runningMachines = machines.where((m) => m['status'] == 'Running').length;
    final breakdownMachines = machines.where((m) => m['status'] == 'Breakdown').length;
    
    final allJobs = jobsBox.values.cast<Map>().toList();
    final runningJobs = allJobs.where((j) => j['status'] == 'Running').length;
    final queuedJobs = allJobs.where((j) => j['status'] == 'Queued').length;
    
    final openIssues = issuesBox.values.cast<Map>().where((i) => i['status'] != 'Resolved').length;
    
    final todayScrap = ScrapRateService.calculateTodayScrapRate();
    final scrapTrend = ScrapRateService.getScrapTrend();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF0F1419),
            flexibleSpace: FlexibleSpaceBar(
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ProMould Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Welcome, ${widget.username}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
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

          // Quick Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time and Date
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.white54),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMM d, yyyy • HH:mm').format(DateTime.now()),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Alerts Section
                  if (breakdownMachines > 0 || openIssues > 0 || (todayScrap['scrapRate'] as double) > 5.0)
                    _buildAlertsPanel(breakdownMachines, openIssues, todayScrap),

                  const SizedBox(height: 16),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Running',
                          runningMachines.toString(),
                          Icons.play_circle,
                          const Color(0xFF00D26A),
                          '${machines.length} total',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Jobs',
                          runningJobs.toString(),
                          Icons.work_outline,
                          const Color(0xFF4CC9F0),
                          '$queuedJobs queued',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Scrap Rate',
                          todayScrap['scrapRateFormatted'] as String,
                          Icons.warning_outlined,
                          todayScrap['color'] as Color,
                          scrapTrend,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Issues',
                          openIssues.toString(),
                          Icons.report_problem_outlined,
                          openIssues > 0 ? const Color(0xFFFF6B6B) : const Color(0xFF6C757D),
                          'Open',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Floor Filter
                  if (floors.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1F2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.apartment, size: 20, color: Color(0xFF4CC9F0)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: selectedFloorId,
                                isExpanded: true,
                                dropdownColor: const Color(0xFF1A1F2E),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All Floors', style: TextStyle(color: Colors.white)),
                                  ),
                                  ...floors.map((f) => DropdownMenuItem<String?>(
                                    value: f['id'] as String,
                                    child: Text('${f['name']}', style: const TextStyle(color: Colors.white)),
                                  )),
                                ],
                                onChanged: (v) => setState(() => selectedFloorId = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Section Header
                  Row(
                    children: [
                      const Text(
                        'Machines',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        '${machines.length} machines',
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Machines Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final m = machines[i];
                  return _buildMachineCard(m);
                },
                childCount: machines.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildAlertsPanel(int breakdowns, int issues, Map<String, dynamic> scrapData) {
    final alerts = <Map<String, dynamic>>[];
    
    if (breakdowns > 0) {
      alerts.add({
        'icon': Icons.build_outlined,
        'color': const Color(0xFFFF6B6B),
        'title': '$breakdowns Machine${breakdowns > 1 ? 's' : ''} Down',
        'subtitle': 'Requires immediate attention',
      });
    }
    
    if ((scrapData['scrapRate'] as double) > 5.0) {
      alerts.add({
        'icon': Icons.warning_outlined,
        'color': const Color(0xFFFF9500),
        'title': 'High Scrap Rate',
        'subtitle': 'Today: ${scrapData['scrapRateFormatted']}',
      });
    }
    
    if (issues > 0) {
      alerts.add({
        'icon': Icons.report_problem_outlined,
        'color': const Color(0xFFFFD166),
        'title': '$issues Open Issue${issues > 1 ? 's' : ''}',
        'subtitle': 'Pending resolution',
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B6B).withOpacity(0.1),
            const Color(0xFF1A1F2E),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_active, color: Color(0xFFFF6B6B), size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Alerts',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...alerts.map((alert) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(alert['icon'] as IconData, size: 18, color: alert['color'] as Color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert['title'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        alert['subtitle'] as String,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            const Color(0xFF1A1F2E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMachineCard(Map m) {
    final mId = (m['id'] ?? '') as String;
    final job = jobsBox.values.cast<Map?>().firstWhere(
      (j) => j != null && j['machineId'] == mId && j['status'] == 'Running',
      orElse: () => null,
    );
    
    final shots = job != null ? LiveProgressService.getEstimatedShots(job, mouldsBox) : 0;
    final target = (job?['targetShots'] ?? 0) as int;
    final progress = target > 0 ? (shots / target).clamp(0.0, 1.0) : 0.0;
    final progress100 = (progress * 100).round();
    
    final scrapData = ScrapRateService.calculateMachineScrapRate(mId);
    final scrapRate = scrapData['scrapRate'] as double;
    final scrapColor = scrapData['color'] as Color;
    
    final statusColor = _getStatusColor(m['status'] as String? ?? 'Idle');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MachineDetailScreen(machine: m),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              statusColor.withOpacity(0.15),
              const Color(0xFF1A1F2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        ),
        child: Stack(
          children: [
            // Status Badge
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  '${m['status'] ?? 'Idle'}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Machine Icon and Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.precision_manufacturing,
                          color: statusColor,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    '${m['name']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  Text(
                    '${m['tonnage'] ?? ''}T',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Progress Section
                  if (job != null) ...[
                    Text(
                      job['productName'] ?? 'Job',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
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
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$progress100%',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$shots/$target',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'No active job',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // Scrap Rate
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: scrapColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scrapColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_outlined, size: 12, color: scrapColor),
                        const SizedBox(width: 4),
                        Text(
                          'Scrap: ${scrapRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: scrapColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
