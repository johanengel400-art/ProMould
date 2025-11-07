import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'machine_detail_screen.dart';
import '../services/live_progress_service.dart';
import '../services/scrap_rate_service.dart';

class DashboardScreen extends StatefulWidget{
  final String username; final int level;
  const DashboardScreen({super.key, required this.username, required this.level});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box machinesBox;
  late Box jobsBox;
  late Box floorsBox;
  late Box mouldsBox;
  String? selectedFloorId;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    machinesBox = Hive.box('machinesBox');
    jobsBox = Hive.box('jobsBox');
    floorsBox = Hive.box('floorsBox');
    mouldsBox = Hive.box('mouldsBox');
    machinesBox.listenable().addListener(_onDataChanged);
    jobsBox.listenable().addListener(_onDataChanged);
    
    // Update UI every 2 seconds to show live progress
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

  Color statusColor(String s){
    switch(s){
      case 'Running': return const Color(0xFF00D26A);
      case 'Changeover': return const Color(0xFFFFD166);
      case 'Breakdown': return const Color(0xFFFF6B6B);
      default: return const Color(0xFF6C757D);
    }
  }

  String _calculateETA(Map job) {
    final mould = mouldsBox.values.cast<Map?>().firstWhere(
      (m) => m != null && m['id'] == job['mouldId'],
      orElse: () => null,
    );
    
    if (mould == null) return 'No mould assigned';
    
    final cycleTime = (mould['cycleTime'] as num?)?.toDouble() ?? 30.0;
    
    // Use live estimated shots for accurate ETA
    final currentShots = LiveProgressService.getEstimatedShots(job, mouldsBox);
    final remaining = (job['targetShots'] as num? ?? 0) - currentShots;
    
    if (remaining <= 0) return 'Target reached';
    
    final minutes = (remaining * cycleTime / 60).toDouble();
    final eta = DateTime.now().add(Duration(minutes: minutes.round()));
    final etaDate = DateFormat('MMM d').format(eta);
    final etaTime = DateFormat('HH:mm').format(eta);
    
    final hours = minutes ~/ 60;
    final mins = (minutes % 60).round();
    final durationText = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    
    return 'ETA $etaDate $etaTime ($durationText)';
  }

  @override Widget build(BuildContext context){
    final allMachines = machinesBox.values.cast<Map>().toList();
    final floors = floorsBox.values.cast<Map>().toList();
    
    // Filter machines by selected floor
    final machines = selectedFloorId == null
        ? allMachines
        : allMachines.where((m) => m['floorId'] == selectedFloorId).toList();
    
    return Scaffold(
      appBar: AppBar(title: const Text('ProMould • Dashboard')),
      body: Column(
        children: [
          if (floors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Text('Floor: ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: selectedFloorId,
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Floors'),
                        ),
                        ...floors.map((f) => DropdownMenuItem<String?>(
                          value: f['id'] as String,
                          child: Text('${f['name']}'),
                        )),
                      ],
                      onChanged: (v) => setState(() => selectedFloorId = v),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 1.1, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemCount: machines.length,
        itemBuilder: (_,i){
          final m = machines[i];
          final mId = (m['id'] ?? '') as String;
          final job = jobsBox.values.cast<Map?>().firstWhere(
            (j)=> j!=null && j['machineId']==mId && j['status']=='Running',
            orElse: ()=>null);
          
          // Use live progress service to get real-time estimated shots
          final shots = job != null 
              ? LiveProgressService.getEstimatedShots(job, mouldsBox)
              : 0;
          final target = (job?['targetShots'] ?? 0) as int;
          final progress = target>0 ? (shots/target).clamp(0.0,1.0) : 0.0;
          final progress100 = (progress*100).round();
          
          // Calculate scrap rate for this machine
          final scrapData = ScrapRateService.calculateMachineScrapRate(mId);
          final scrapRate = scrapData['scrapRate'] as double;
          final scrapColor = scrapData['color'] as Color;

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
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [statusColor((m['status']??'Idle') as String).withOpacity(0.14),
                    const Color(0xFF121821)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                border: Border.all(color: Colors.white12)),
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Row(children:[
                Text('${m['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                Chip(label: Text('${m['status']??'Idle'}'),
                  backgroundColor: statusColor('${m['status']??'Idle'}').withOpacity(0.18),
                  shape: StadiumBorder(side: BorderSide(color: statusColor('${m['status']??'Idle'}').withOpacity(0.6)))),
              ]),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: progress, minHeight: 8, borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 6),
              Text(job==null ? 'No active job'
                : 'Job: ${job['productName']} • $progress100%',
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
              if (job != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.white54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _calculateETA(job),
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
              const Spacer(),
              Row(children:[
                Icon(Icons.warning_outlined, size:14, color: scrapColor),
                const SizedBox(width:4),
                Text('Scrap: ${scrapRate.toStringAsFixed(1)}%', 
                  style: TextStyle(color: scrapColor, fontSize: 11, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.precision_manufacturing_outlined, size:14, color: Colors.white54),
                const SizedBox(width:4),
                Text('${m['tonnage']??''}T', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ]),
            ]),
            ),
          );
        }),
          ),
        ],
      ),
    );
  }
}
