import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:percent_indicator/percent_indicator.dart';

class OEEScreen extends StatelessWidget{
  final int level; const OEEScreen({super.key, required this.level});

  @override Widget build(BuildContext context){
    final inputs = Hive.box('inputsBox').values.cast<Map>().toList();
    final downtime = Hive.box('downtimeBox').values.cast<Map?>().toList();

    final good = inputs.fold<int>(0,(p,e)=> p + (e['shots'] as int? ?? 0));
    final scrap = inputs.fold<int>(0,(p,e)=> p + (e['scrap'] as int? ?? 0));
    final total = good + scrap;
    final quality = total>0 ? good/total : 0.0;

    final plannedMins = 8*60; // simple example: 8 hour shift
    final downMins = downtime.fold<int>(0,(p,e)=> p + (e?['minutes'] as int? ?? 0));
    final runMins = (plannedMins - downMins).clamp(0, plannedMins);
    final availability = plannedMins>0 ? runMins/plannedMins : 0.0;

    // dummy performance based on target 30s cycle
    final targetShots = (runMins*60)/30.0;
    final performance = targetShots>0 ? (good/targetShots).clamp(0.0, 1.0) : 0.0;

    final oee = (availability*performance*quality).clamp(0.0, 1.0);

    Color getColor(double value) {
      if (value >= 0.85) return const Color(0xFF80ED99); // Excellent
      if (value >= 0.60) return const Color(0xFFFFD166); // Good
      return const Color(0xFFFF6B6B); // Needs improvement
    }

    Widget metricCard(String label, double value, IconData icon) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: getColor(value)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 8),
              CircularPercentIndicator(
                radius: 50,
                lineWidth: 8,
                percent: value,
                center: Text('${(value*100).toStringAsFixed(1)}%', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                progressColor: getColor(value),
                backgroundColor: Colors.white12,
              ),
            ],
          ),
        ),
      );
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
              title: const Text('OEE Report'),
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children:[
          Card(
            color: const Color(0xFF1A2332),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                const Text('Overall Equipment Effectiveness', 
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
                const SizedBox(height: 16),
                CircularPercentIndicator(
                  radius: 80,
                  lineWidth: 12,
                  percent: oee,
                  center: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${(oee*100).toStringAsFixed(1)}%', 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                      const Text('OEE', style: TextStyle(fontSize: 14, color: Colors.white70)),
                    ],
                  ),
                  progressColor: getColor(oee),
                  backgroundColor: Colors.white12,
                ),
                const SizedBox(height: 16),
                Text(
                  oee >= 0.85 ? 'World Class!' : 
                  oee >= 0.60 ? 'Good Performance' : 
                  'Needs Improvement',
                  style: TextStyle(fontSize: 16, color: getColor(oee), fontWeight: FontWeight.bold),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Components', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: metricCard('Availability', availability, Icons.access_time)),
              const SizedBox(width: 12),
              Expanded(child: metricCard('Performance', performance, Icons.speed)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: metricCard('Quality', quality, Icons.verified)),
              const SizedBox(width: 12),
              Expanded(child: Container()), // Spacer for symmetry
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Production Summary', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(height: 20),
                  _statRow('Good Shots', '$good'),
                  _statRow('Scrap', '$scrap'),
                  _statRow('Total', '$total'),
                  const Divider(height: 20),
                  _statRow('Planned Time', '${plannedMins}min'),
                  _statRow('Downtime', '${downMins}min'),
                  _statRow('Run Time', '${runMins}min'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Card(
            color: Color(0xFF1A2332),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'ℹ️ Note: OEE calculation uses simplified assumptions. '
                'Configure actual cycle times and planned production time for accurate results.',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ),
          ),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
