import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DashboardScreen extends StatefulWidget{
  final String username; final int level;
  const DashboardScreen({super.key, required this.username, required this.level});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Box machinesBox;
  late Box jobsBox;

  @override
  void initState() {
    super.initState();
    machinesBox = Hive.box('machinesBox');
    jobsBox = Hive.box('jobsBox');
    machinesBox.listenable().addListener(_onDataChanged);
    jobsBox.listenable().addListener(_onDataChanged);
  }

  @override
  void dispose() {
    machinesBox.listenable().removeListener(_onDataChanged);
    jobsBox.listenable().removeListener(_onDataChanged);
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

  @override Widget build(BuildContext context){
    final machines = machinesBox.values.cast<Map>().toList();
    
    return Scaffold(
      appBar: AppBar(title: const Text('ProMould • Dashboard')),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 1.1, mainAxisSpacing: 12, crossAxisSpacing: 12),
        itemCount: machines.length,
        itemBuilder: (_,i){
          final m = machines[i] as Map;
          final mId = (m['id'] ?? '') as String;
          final job = jobsBox.values.cast<Map?>().firstWhere(
            (j)=> j!=null && j!['machineId']==mId && j!['status']=='Running',
            orElse: ()=>null);
          final shots = (job?['shotsCompleted'] ?? 0) as int;
          final target = (job?['targetShots'] ?? 0) as int;
          final progress = target>0 ? (shots/target).clamp(0.0,1.0) : 0.0;
          final progress100 = (progress*100).round();

          return Container(
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
                : 'Job: ${job['productName']} • ${progress100}%',
                style: const TextStyle(color: Colors.white70)),
              const Spacer(),
              Row(children:[
                const Icon(Icons.precision_manufacturing_outlined, size:18, color: Colors.white54),
                const SizedBox(width:6),
                Text('Tonnage: ${m['tonnage']??''}', style: const TextStyle(color: Colors.white60)),
              ]),
            ]),
          );
        }),
    );
  }
}
