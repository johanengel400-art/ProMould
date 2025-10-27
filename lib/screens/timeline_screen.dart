import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends StatelessWidget {
  final int level;
  const TimelineScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final jobsBox = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final mouldsBox = Hive.box('mouldsBox');

    return Scaffold(
      appBar: AppBar(title: const Text('Production Timeline')),
      body: ValueListenableBuilder(
        valueListenable: jobsBox.listenable(),
        builder: (_, __, ___) {
          final jobs = jobsBox.values
              .cast<Map>()
              .where((j) => j['status'] == 'Running' || j['status'] == 'Queued')
              .toList();
          
          final machines = {
            for (final m in machinesBox.values.cast<Map>()) m['id']: m['name']
          };

          final data = <_JobBar>[];
          
          // Group jobs by machine
          final jobsByMachine = <String, List<Map>>{};
          for (final j in jobs) {
            final machineId = j['machineId'] as String? ?? '';
            if (machineId.isNotEmpty) {
              jobsByMachine.putIfAbsent(machineId, () => []).add(j);
            }
          }

          // Calculate timeline for each machine
          for (final entry in jobsByMachine.entries) {
            final machineId = entry.key;
            final machineJobs = entry.value;
            
            // Sort by status (Running first, then Queued)
            machineJobs.sort((a, b) {
              if (a['status'] == 'Running' && b['status'] != 'Running') return -1;
              if (a['status'] != 'Running' && b['status'] == 'Running') return 1;
              return 0;
            });

            DateTime currentTime = DateTime.now();
            
            for (final j in machineJobs) {
              final mould = mouldsBox.values.cast<Map?>().firstWhere(
                (m) => m != null && m['id'] == j['mouldId'],
                orElse: () => null,
              );
              
              final cycleTime = (mould?['cycleTime'] as num?)?.toDouble() ?? 30.0;
              final remaining = (j['targetShots'] as num? ?? 0) - (j['shotsCompleted'] as num? ?? 0);
              final durationMinutes = (remaining * cycleTime / 60).toDouble();
              
              DateTime startTime;
              if (j['status'] == 'Running' && j['startTime'] != null) {
                startTime = DateTime.parse(j['startTime'] as String);
              } else {
                startTime = currentTime;
              }
              
              final endTime = startTime.add(Duration(minutes: durationMinutes.round()));
              
              data.add(_JobBar(
                j['productName'] ?? 'Job',
                machines[machineId] ?? machineId,
                startTime,
                endTime,
                j['status'] ?? 'Queued',
              ));
              
              currentTime = endTime;
            }
          }

          if (data.isEmpty) {
            return const Center(
              child: Text('No active or queued jobs', style: TextStyle(fontSize: 16)),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Production Schedule'),
                    primaryXAxis: CategoryAxis(
                      title: AxisTitle(text: 'Machines'),
                    ),
                    primaryYAxis: DateTimeAxis(
                      intervalType: DateTimeIntervalType.hours,
                      dateFormat: DateFormat.Hm(),
                      interval: 2,
                      edgeLabelPlacement: EdgeLabelPlacement.shift,
                      title: AxisTitle(text: 'Time'),
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x: point.y',
                    ),
                    series: <RangeColumnSeries<_JobBar, String>>[
                      RangeColumnSeries<_JobBar, String>(
                        dataSource: data,
                        xValueMapper: (d, _) => d.machine,
                        lowValueMapper: (d, _) => d.start.millisecondsSinceEpoch.toDouble(),
                        highValueMapper: (d, _) => d.end.millisecondsSinceEpoch.toDouble(),
                        pointColorMapper: (d, _) => d.status == 'Running'
                            ? const Color(0xFF00D26A)
                            : const Color(0xFFFFD166),
                        dataLabelSettings: const DataLabelSettings(
                          isVisible: true,
                          labelAlignment: ChartDataLabelAlignment.middle,
                        ),
                        dataLabelMapper: (d, _) => d.product,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegend('Running', const Color(0xFF00D26A)),
                    const SizedBox(width: 24),
                    _buildLegend('Queued', const Color(0xFFFFD166)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}

class _JobBar {
  final String product;
  final String machine;
  final DateTime start;
  final DateTime end;
  final String status;
  
  _JobBar(this.product, this.machine, this.start, this.end, this.status);
}
