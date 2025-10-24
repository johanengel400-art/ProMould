import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends StatelessWidget{
  final int level; const TimelineScreen({super.key, required this.level});

  @override Widget build(BuildContext context){
    final jobsBox = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');

    return Scaffold(
      appBar: AppBar(title: const Text('Production Timeline')),
      body: ValueListenableBuilder(
        valueListenable: jobsBox.listenable(),
        builder: (_, __, ___) {
          final jobs = jobsBox.values.cast<Map>().where((j)=> j['status']!='Finished').toList();
          final machines = { for(final m in machinesBox.values.cast<Map>()) m['id'] : m['name'] };

          final data = <_JobBar>[];
          for (final j in jobs){
            final start = (j['startTime'] as DateTime?) ?? DateTime.now();
            final eta = (j['eta'] as DateTime?) ?? start.add(const Duration(hours: 2));
            data.add(_JobBar(
              j['productName'] ?? 'Job',
              machines[j['machineId']] ?? j['machineId'],
              start, eta, j['status'] ?? 'Queued'));
          }

          return SfCartesianChart(
            primaryXAxis: DateTimeAxis(
              intervalType: DateTimeIntervalType.hours,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              dateFormat: DateFormat.Hm(), interval: 4),
            primaryYAxis: CategoryAxis(),
            tooltipBehavior: TooltipBehavior(enable: true),
            series: <RangeColumnSeries<_JobBar, DateTime>>[
              RangeColumnSeries<_JobBar, DateTime>(
                dataSource: data,
                xValueMapper: (d, _) => d.start,
                yValueMapper: (d, _) => d.machine,
                highValueMapper: (d, _) => d.end,
                lowValueMapper: (d, _) => d.start,
                name: 'Jobs',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JobBar{
  final String product; final String machine; final DateTime start; final DateTime end; final String status;
  _JobBar(this.product,this.machine,this.start,this.end,this.status);
}
