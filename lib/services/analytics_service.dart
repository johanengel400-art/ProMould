// lib/services/analytics_service.dart
// Advanced Analytics and Predictive Engine

import 'package:hive_flutter/hive_flutter.dart';
import 'dart:math';

class AnalyticsService {
  /// Calculate real-time KPIs
  static Map<String, dynamic> calculateRealTimeKPIs() {
    final machinesBox = Hive.box('machinesBox');
    final jobsBox = Hive.box('jobsBox');
    final inputsBox = Hive.box('inputsBox');
    final downtimeBox = Hive.box('downtimeBox');
    final issuesBox = Hive.box('issuesBox');

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Machine Utilization
    final totalMachines = machinesBox.length;
    final runningMachines = machinesBox.values
        .cast<Map>()
        .where((m) => m['status'] == 'Running')
        .length;
    final utilizationRate =
        totalMachines > 0 ? (runningMachines / totalMachines * 100).round() : 0;

    // Production Metrics
    final todayInputs = inputsBox.values.cast<Map>().where((i) {
      final date = DateTime.tryParse(i['date'] ?? '');
      return date != null && date.isAfter(today);
    }).toList();

    final totalShots =
        todayInputs.fold<int>(0, (sum, i) => sum + (i['shots'] as int? ?? 0));
    final totalScrap =
        todayInputs.fold<int>(0, (sum, i) => sum + (i['scrap'] as int? ?? 0));
    final scrapRate = (totalShots + totalScrap) > 0
        ? (totalScrap / (totalShots + totalScrap) * 100)
        : 0.0;

    // Job Performance
    final activeJobs = jobsBox.values
        .cast<Map>()
        .where((j) => j['status'] == 'Running' || j['status'] == 'Queued')
        .length;
    final completedToday = jobsBox.values.cast<Map>().where((j) {
      if (j['status'] != 'Finished') return false;
      final endTime = DateTime.tryParse(j['endTime'] ?? '');
      return endTime != null && endTime.isAfter(today);
    }).length;

    // Downtime Analysis
    final todayDowntime = downtimeBox.values.cast<Map>().where((d) {
      final date = DateTime.tryParse(d['date'] ?? '');
      return date != null && date.isAfter(today);
    }).toList();

    final totalDowntimeMinutes = todayDowntime.fold<int>(
        0, (sum, d) => sum + (d['minutes'] as int? ?? 0));

    // Quality Metrics
    final openIssues = issuesBox.values
        .cast<Map>()
        .where((i) => i['status'] != 'Resolved' && i['status'] != 'Closed')
        .length;
    final criticalIssues = issuesBox.values
        .cast<Map>()
        .where((i) =>
            i['priority'] == 'Critical' &&
            i['status'] != 'Resolved' &&
            i['status'] != 'Closed')
        .length;

    // OEE Calculation (simplified)
    final availableMinutes = runningMachines * 60 * 8; // 8 hour shift
    final actualMinutes = availableMinutes - totalDowntimeMinutes;
    final availability =
        availableMinutes > 0 ? (actualMinutes / availableMinutes * 100) : 0.0;
    final performance = 85.0; // Simplified - would need cycle time data
    final quality = 100 - scrapRate;
    final oee = (availability * performance * quality) / 10000;

    return {
      'utilizationRate': utilizationRate,
      'runningMachines': runningMachines,
      'totalMachines': totalMachines,
      'totalShots': totalShots,
      'totalScrap': totalScrap,
      'scrapRate': scrapRate.toStringAsFixed(2),
      'activeJobs': activeJobs,
      'completedToday': completedToday,
      'totalDowntimeMinutes': totalDowntimeMinutes,
      'openIssues': openIssues,
      'criticalIssues': criticalIssues,
      'oee': oee.toStringAsFixed(1),
      'availability': availability.toStringAsFixed(1),
      'performance': performance.toStringAsFixed(1),
      'quality': quality.toStringAsFixed(1),
    };
  }

  /// Predictive Analytics - Machine Failure Prediction
  static Map<String, dynamic> predictMachineFailures() {
    final machinesBox = Hive.box('machinesBox');
    final downtimeBox = Hive.box('downtimeBox');
    final issuesBox = Hive.box('issuesBox');

    final predictions = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    for (final machine in machinesBox.values.cast<Map>()) {
      final machineId = machine['id'] as String;

      // Analyze downtime frequency
      final recentDowntime = downtimeBox.values.cast<Map>().where((d) {
        if (d['machineId'] != machineId) return false;
        final date = DateTime.tryParse(d['date'] ?? '');
        return date != null && date.isAfter(last30Days);
      }).toList();

      // Analyze issue frequency
      final recentIssues = issuesBox.values.cast<Map>().where((i) {
        if (i['machineId'] != machineId) return false;
        final timestamp = DateTime.tryParse(i['timestamp'] ?? '');
        return timestamp != null && timestamp.isAfter(last30Days);
      }).toList();

      // Calculate risk score (0-100)
      final downtimeCount = recentDowntime.length;
      final issueCount = recentIssues.length;
      final criticalIssues =
          recentIssues.where((i) => i['priority'] == 'Critical').length;

      var riskScore = 0.0;
      riskScore += downtimeCount * 5; // Each downtime adds 5 points
      riskScore += issueCount * 3; // Each issue adds 3 points
      riskScore += criticalIssues * 10; // Critical issues add 10 points

      riskScore = min(riskScore, 100.0);

      if (riskScore >= 30) {
        // Only include machines with significant risk
        predictions.add({
          'machineId': machineId,
          'machineName': machine['name'],
          'riskScore': riskScore.round(),
          'downtimeEvents': downtimeCount,
          'issueCount': issueCount,
          'criticalIssues': criticalIssues,
          'recommendation': _getRecommendation(riskScore),
        });
      }
    }

    // Sort by risk score descending
    predictions.sort(
        (a, b) => (b['riskScore'] as int).compareTo(a['riskScore'] as int));

    return {
      'predictions': predictions,
      'highRiskCount': predictions.where((p) => p['riskScore'] >= 70).length,
      'mediumRiskCount': predictions
          .where((p) => p['riskScore'] >= 40 && p['riskScore'] < 70)
          .length,
      'lowRiskCount': predictions.where((p) => p['riskScore'] < 40).length,
    };
  }

  static String _getRecommendation(double riskScore) {
    if (riskScore >= 70) {
      return 'URGENT: Schedule immediate maintenance inspection';
    } else if (riskScore >= 50) {
      return 'Schedule preventive maintenance within 48 hours';
    } else if (riskScore >= 30) {
      return 'Monitor closely and schedule maintenance this week';
    } else {
      return 'Continue normal monitoring';
    }
  }

  /// Trend Analysis - Last 7 days
  static Map<String, dynamic> calculateTrends() {
    final inputsBox = Hive.box('inputsBox');
    final downtimeBox = Hive.box('downtimeBox');
    final issuesBox = Hive.box('issuesBox');
    final now = DateTime.now();
    final productionTrend = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);

      final dayInputs = inputsBox.values.cast<Map>().where((input) {
        final inputDate = DateTime.tryParse(input['date'] ?? '');
        if (inputDate == null) return false;
        final inputDateKey =
            DateTime(inputDate.year, inputDate.month, inputDate.day);
        return inputDateKey == dateKey;
      }).toList();

      final shots =
          dayInputs.fold<int>(0, (sum, i) => sum + (i['shots'] as int? ?? 0));
      final scrap =
          dayInputs.fold<int>(0, (sum, i) => sum + (i['scrap'] as int? ?? 0));

      productionTrend.add({
        'date': dateKey.toIso8601String(),
        'shots': shots,
        'scrap': scrap,
        'scrapRate': (shots + scrap) > 0
            ? ((scrap / (shots + scrap)) * 100).toStringAsFixed(1)
            : '0.0',
      });
    }

    // Downtime trend
    final downtimeTrend = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);

      final dayDowntime = downtimeBox.values.cast<Map>().where((d) {
        final downtimeDate = DateTime.tryParse(d['date'] ?? '');
        if (downtimeDate == null) return false;
        final downtimeDateKey =
            DateTime(downtimeDate.year, downtimeDate.month, downtimeDate.day);
        return downtimeDateKey == dateKey;
      }).toList();

      final minutes = dayDowntime.fold<int>(
          0, (sum, d) => sum + (d['minutes'] as int? ?? 0));

      downtimeTrend.add({
        'date': dateKey.toIso8601String(),
        'minutes': minutes,
      });
    }

    // Issues trend
    final issuesTrend = <Map<String, dynamic>>[];
    for (var i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateTime(date.year, date.month, date.day);

      final dayIssues = issuesBox.values.cast<Map>().where((issue) {
        final issueDate = DateTime.tryParse(issue['timestamp'] ?? '');
        if (issueDate == null) return false;
        final issueDateKey =
            DateTime(issueDate.year, issueDate.month, issueDate.day);
        return issueDateKey == dateKey;
      }).length;

      issuesTrend.add({
        'date': dateKey.toIso8601String(),
        'count': dayIssues,
      });
    }

    return {
      'productionTrend': productionTrend,
      'downtimeTrend': downtimeTrend,
      'issuesTrend': issuesTrend,
    };
  }

  /// Top Issues Analysis
  static Map<String, dynamic> analyzeTopIssues() {
    final issuesBox = Hive.box('issuesBox');
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final recentIssues = issuesBox.values.cast<Map>().where((i) {
      final timestamp = DateTime.tryParse(i['timestamp'] ?? '');
      return timestamp != null && timestamp.isAfter(last30Days);
    }).toList();

    // Group by category
    final categoryCount = <String, int>{};
    for (final issue in recentIssues) {
      final category = issue['category'] as String? ?? 'Unknown';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    // Group by machine
    final machineCount = <String, int>{};
    final machinesBox = Hive.box('machinesBox');
    for (final issue in recentIssues) {
      final machineId = issue['machineId'] as String?;
      if (machineId != null) {
        final machine = machinesBox.get(machineId) as Map?;
        final machineName = machine?['name'] ?? 'Unknown';
        machineCount[machineName] = (machineCount[machineName] ?? 0) + 1;
      }
    }

    // Sort and get top 5
    final topCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topMachines = machineCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'topCategories': topCategories
          .take(5)
          .map((e) => {
                'category': e.key,
                'count': e.value,
              })
          .toList(),
      'topMachines': topMachines
          .take(5)
          .map((e) => {
                'machine': e.key,
                'count': e.value,
              })
          .toList(),
      'totalIssues': recentIssues.length,
      'openIssues': recentIssues
          .where((i) => i['status'] != 'Resolved' && i['status'] != 'Closed')
          .length,
    };
  }

  /// Performance Metrics by Shift
  static Map<String, dynamic> analyzeShiftPerformance() {
    final inputsBox = Hive.box('inputsBox');
    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));

    final recentInputs = inputsBox.values.cast<Map>().where((i) {
      final date = DateTime.tryParse(i['date'] ?? '');
      return date != null && date.isAfter(last7Days);
    }).toList();

    // Determine shift based on hour (simplified)
    final dayShift = <Map>[];
    final nightShift = <Map>[];

    for (final input in recentInputs) {
      final date = DateTime.tryParse(input['date'] ?? '');
      if (date != null) {
        final hour = date.hour;
        if (hour >= 6 && hour < 18) {
          dayShift.add(input);
        } else {
          nightShift.add(input);
        }
      }
    }

    final dayShots =
        dayShift.fold<int>(0, (sum, i) => sum + (i['shots'] as int? ?? 0));
    final dayScrap =
        dayShift.fold<int>(0, (sum, i) => sum + (i['scrap'] as int? ?? 0));
    final nightShots =
        nightShift.fold<int>(0, (sum, i) => sum + (i['shots'] as int? ?? 0));
    final nightScrap =
        nightShift.fold<int>(0, (sum, i) => sum + (i['scrap'] as int? ?? 0));

    return {
      'dayShift': {
        'shots': dayShots,
        'scrap': dayScrap,
        'scrapRate': (dayShots + dayScrap) > 0
            ? ((dayScrap / (dayShots + dayScrap)) * 100).toStringAsFixed(1)
            : '0.0',
      },
      'nightShift': {
        'shots': nightShots,
        'scrap': nightScrap,
        'scrapRate': (nightShots + nightScrap) > 0
            ? ((nightScrap / (nightShots + nightScrap)) * 100)
                .toStringAsFixed(1)
            : '0.0',
      },
    };
  }
}
