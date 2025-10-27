// lib/services/scrap_rate_service.dart
// Scrap rate calculation and tracking

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';

class ScrapRateService {
  /// Calculate scrap rate for a specific machine
  static Map<String, dynamic> calculateMachineScrapRate(String machineId) {
    final inputsBox = Hive.box('inputsBox');
    
    final machineInputs = inputsBox.values
        .cast<Map>()
        .where((input) => input['machineId'] == machineId)
        .toList();
    
    int totalShots = 0;
    int totalScrap = 0;
    
    for (final input in machineInputs) {
      totalShots += (input['shots'] as int? ?? 0);
      totalScrap += (input['scrap'] as int? ?? 0);
    }
    
    final totalProduced = totalShots + totalScrap;
    final scrapRate = totalProduced > 0 ? (totalScrap / totalProduced) * 100 : 0.0;
    
    return {
      'totalShots': totalShots,
      'totalScrap': totalScrap,
      'totalProduced': totalProduced,
      'scrapRate': scrapRate,
      'scrapRateFormatted': '${scrapRate.toStringAsFixed(1)}%',
      'color': getScrapRateColor(scrapRate),
      'status': getScrapRateStatus(scrapRate),
    };
  }
  
  /// Calculate scrap rate for a specific job
  static Map<String, dynamic> calculateJobScrapRate(String jobId) {
    final inputsBox = Hive.box('inputsBox');
    
    final jobInputs = inputsBox.values
        .cast<Map>()
        .where((input) => input['jobId'] == jobId)
        .toList();
    
    int totalShots = 0;
    int totalScrap = 0;
    
    for (final input in jobInputs) {
      totalShots += (input['shots'] as int? ?? 0);
      totalScrap += (input['scrap'] as int? ?? 0);
    }
    
    final totalProduced = totalShots + totalScrap;
    final scrapRate = totalProduced > 0 ? (totalScrap / totalProduced) * 100 : 0.0;
    
    return {
      'totalShots': totalShots,
      'totalScrap': totalScrap,
      'totalProduced': totalProduced,
      'scrapRate': scrapRate,
      'scrapRateFormatted': '${scrapRate.toStringAsFixed(1)}%',
      'color': getScrapRateColor(scrapRate),
      'status': getScrapRateStatus(scrapRate),
    };
  }
  
  /// Calculate overall factory scrap rate
  static Map<String, dynamic> calculateOverallScrapRate() {
    final inputsBox = Hive.box('inputsBox');
    
    int totalShots = 0;
    int totalScrap = 0;
    
    for (final input in inputsBox.values.cast<Map>()) {
      totalShots += (input['shots'] as int? ?? 0);
      totalScrap += (input['scrap'] as int? ?? 0);
    }
    
    final totalProduced = totalShots + totalScrap;
    final scrapRate = totalProduced > 0 ? (totalScrap / totalProduced) * 100 : 0.0;
    
    return {
      'totalShots': totalShots,
      'totalScrap': totalScrap,
      'totalProduced': totalProduced,
      'scrapRate': scrapRate,
      'scrapRateFormatted': '${scrapRate.toStringAsFixed(1)}%',
      'color': getScrapRateColor(scrapRate),
      'status': getScrapRateStatus(scrapRate),
    };
  }
  
  /// Get scrap rate for today only
  static Map<String, dynamic> calculateTodayScrapRate() {
    final inputsBox = Hive.box('inputsBox');
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    int totalShots = 0;
    int totalScrap = 0;
    
    for (final input in inputsBox.values.cast<Map>()) {
      final dateStr = input['date'] as String?;
      if (dateStr != null) {
        final inputDate = DateTime.parse(dateStr);
        if (inputDate.isAfter(todayStart)) {
          totalShots += (input['shots'] as int? ?? 0);
          totalScrap += (input['scrap'] as int? ?? 0);
        }
      }
    }
    
    final totalProduced = totalShots + totalScrap;
    final scrapRate = totalProduced > 0 ? (totalScrap / totalProduced) * 100 : 0.0;
    
    return {
      'totalShots': totalShots,
      'totalScrap': totalScrap,
      'totalProduced': totalProduced,
      'scrapRate': scrapRate,
      'scrapRateFormatted': '${scrapRate.toStringAsFixed(1)}%',
      'color': getScrapRateColor(scrapRate),
      'status': getScrapRateStatus(scrapRate),
    };
  }
  
  /// Get color based on scrap rate
  static Color getScrapRateColor(double scrapRate) {
    if (scrapRate < 2.0) {
      return const Color(0xFF00D26A); // Green - Excellent
    } else if (scrapRate < 5.0) {
      return const Color(0xFFFFD166); // Yellow - Acceptable
    } else if (scrapRate < 10.0) {
      return const Color(0xFFFF9500); // Orange - Concerning
    } else {
      return const Color(0xFFFF6B6B); // Red - Critical
    }
  }
  
  /// Get status text based on scrap rate
  static String getScrapRateStatus(double scrapRate) {
    if (scrapRate < 2.0) {
      return 'Excellent';
    } else if (scrapRate < 5.0) {
      return 'Acceptable';
    } else if (scrapRate < 10.0) {
      return 'Concerning';
    } else {
      return 'Critical';
    }
  }
  
  /// Get scrap trend (comparing today vs yesterday)
  static String getScrapTrend() {
    final inputsBox = Hive.box('inputsBox');
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    
    int todayShots = 0, todayScrap = 0;
    int yesterdayShots = 0, yesterdayScrap = 0;
    
    for (final input in inputsBox.values.cast<Map>()) {
      final dateStr = input['date'] as String?;
      if (dateStr != null) {
        final inputDate = DateTime.parse(dateStr);
        final shots = input['shots'] as int? ?? 0;
        final scrap = input['scrap'] as int? ?? 0;
        
        if (inputDate.isAfter(todayStart)) {
          todayShots += shots;
          todayScrap += scrap;
        } else if (inputDate.isAfter(yesterdayStart) && inputDate.isBefore(todayStart)) {
          yesterdayShots += shots;
          yesterdayScrap += scrap;
        }
      }
    }
    
    final todayTotal = todayShots + todayScrap;
    final yesterdayTotal = yesterdayShots + yesterdayScrap;
    
    final todayRate = todayTotal > 0 ? (todayScrap / todayTotal) * 100 : 0.0;
    final yesterdayRate = yesterdayTotal > 0 ? (yesterdayScrap / yesterdayTotal) * 100 : 0.0;
    
    if (todayRate < yesterdayRate) {
      return '↓ Improving';
    } else if (todayRate > yesterdayRate) {
      return '↑ Worsening';
    } else {
      return '→ Stable';
    }
  }
  
  /// Get top scrap reasons
  static List<Map<String, dynamic>> getTopScrapReasons({int limit = 5}) {
    final inputsBox = Hive.box('inputsBox');
    final reasonCounts = <String, int>{};
    
    for (final input in inputsBox.values.cast<Map>()) {
      final scrap = input['scrap'] as int? ?? 0;
      if (scrap > 0) {
        final reason = input['scrapReason'] as String? ?? 'Unknown';
        reasonCounts[reason] = (reasonCounts[reason] ?? 0) + scrap;
      }
    }
    
    final sorted = reasonCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).map((e) => {
      'reason': e.key,
      'count': e.value,
    }).toList();
  }
}
