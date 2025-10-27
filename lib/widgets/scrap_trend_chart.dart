// lib/widgets/scrap_trend_chart.dart
// Scrap rate trend visualization

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class ScrapTrendChart extends StatelessWidget {
  final String? machineId;
  final int days;
  
  const ScrapTrendChart({
    super.key,
    this.machineId,
    this.days = 7,
  });

  @override
  Widget build(BuildContext context) {
    final inputsBox = Hive.box('inputsBox');
    final startDate = DateTime.now().subtract(Duration(days: days));
    
    // Get inputs for the period
    var inputs = inputsBox.values.cast<Map>().where((input) {
      final date = DateTime.tryParse(input['date'] ?? '');
      if (date == null || date.isBefore(startDate)) return false;
      if (machineId != null && input['machineId'] != machineId) return false;
      return true;
    }).toList();
    
    // Group by date
    final Map<String, Map<String, int>> dailyData = {};
    
    for (final input in inputs) {
      final date = DateTime.tryParse(input['date'] ?? '');
      if (date == null) continue;
      
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      if (!dailyData.containsKey(dateKey)) {
        dailyData[dateKey] = {'shots': 0, 'scrap': 0};
      }
      
      dailyData[dateKey]!['shots'] = (dailyData[dateKey]!['shots'] ?? 0) + (input['shots'] as int? ?? 0);
      dailyData[dateKey]!['scrap'] = (dailyData[dateKey]!['scrap'] ?? 0) + (input['scrap'] as int? ?? 0);
    }
    
    // Convert to chart data
    final chartData = <_ScrapDataPoint>[];
    for (var i = 0; i < days; i++) {
      final date = DateTime.now().subtract(Duration(days: days - i - 1));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      
      final data = dailyData[dateKey];
      final shots = data?['shots'] ?? 0;
      final scrap = data?['scrap'] ?? 0;
      final total = shots + scrap;
      final scrapRate = total > 0 ? (scrap / total) * 100 : 0.0;
      
      chartData.add(_ScrapDataPoint(date, scrapRate));
    }
    
    if (chartData.isEmpty) {
      return const Center(
        child: Text('No data available', style: TextStyle(color: Colors.white54)),
      );
    }

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      title: ChartTitle(
        text: 'Scrap Rate Trend (Last $days Days)',
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('MMM d'),
        intervalType: DateTimeIntervalType.days,
        majorGridLines: const MajorGridLines(width: 0),
        edgeLabelPlacement: EdgeLabelPlacement.shift,
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Scrap Rate (%)'),
        minimum: 0,
        maximum: 15,
        interval: 5,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x: point.y%',
      ),
      series: <ChartSeries>[
        // Area series for trend
        AreaSeries<_ScrapDataPoint, DateTime>(
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.scrapRate,
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF6B6B).withOpacity(0.3),
              const Color(0xFFFF6B6B).withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderColor: const Color(0xFFFF6B6B),
          borderWidth: 2,
        ),
        // Line series for clarity
        LineSeries<_ScrapDataPoint, DateTime>(
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.scrapRate,
          color: const Color(0xFFFF6B6B),
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            borderColor: Color(0xFFFF6B6B),
            borderWidth: 2,
            color: Color(0xFF1A1F2E),
          ),
        ),
        // Target line at 5%
        LineSeries<_ScrapDataPoint, DateTime>(
          dataSource: [
            _ScrapDataPoint(chartData.first.date, 5.0),
            _ScrapDataPoint(chartData.last.date, 5.0),
          ],
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.scrapRate,
          color: const Color(0xFFFFD166),
          width: 1,
          dashArray: const [5, 5],
          name: 'Target (5%)',
        ),
      ],
    );
  }
}

class _ScrapDataPoint {
  final DateTime date;
  final double scrapRate;
  
  _ScrapDataPoint(this.date, this.scrapRate);
}
