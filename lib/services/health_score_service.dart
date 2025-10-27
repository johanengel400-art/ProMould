// lib/services/health_score_service.dart
// Machine health score calculation

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'scrap_rate_service.dart';

class HealthScoreService {
  /// Calculate comprehensive health score for a machine (0-100)
  static Map<String, dynamic> calculateMachineHealth(String machineId) {
    final inputsBox = Hive.box('inputsBox');
    final downtimeBox = Hive.box('downtimeBox');
    final jobsBox = Hive.box('jobsBox');
    
    // Get data from last 7 days
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    // 1. Uptime Score (40 points)
    final downtimeEntries = downtimeBox.values.cast<Map>().where((d) {
      if (d['machineId'] != machineId) return false;
      final date = DateTime.tryParse(d['date'] ?? '');
      return date != null && date.isAfter(sevenDaysAgo);
    }).toList();
    
    final totalDowntimeMinutes = downtimeEntries.fold<int>(
      0, (sum, d) => sum + (d['minutes'] as int? ?? 0)
    );
    
    // Assume 16 hours/day operation, 7 days = 6720 minutes
    final totalAvailableMinutes = 16 * 60 * 7;
    final uptimePercentage = totalAvailableMinutes > 0
        ? ((totalAvailableMinutes - totalDowntimeMinutes) / totalAvailableMinutes) * 100
        : 100.0;
    final uptimeScore = (uptimePercentage / 100 * 40).clamp(0, 40);
    
    // 2. Quality Score (30 points) - Based on scrap rate
    final scrapData = ScrapRateService.calculateMachineScrapRate(machineId);
    final scrapRate = scrapData['scrapRate'] as double;
    double qualityScore;
    if (scrapRate < 2) {
      qualityScore = 30;
    } else if (scrapRate < 5) {
      qualityScore = 25;
    } else if (scrapRate < 10) {
      qualityScore = 15;
    } else {
      qualityScore = 5;
    }
    
    // 3. Productivity Score (30 points) - Based on job completion
    final machineJobs = jobsBox.values.cast<Map>().where((j) {
      if (j['machineId'] != machineId) return false;
      final endTime = j['endTime'] as String?;
      if (endTime == null) return false;
      final date = DateTime.tryParse(endTime);
      return date != null && date.isAfter(sevenDaysAgo);
    }).toList();
    
    int completedOnTime = 0;
    int totalCompleted = machineJobs.length;
    
    for (final job in machineJobs) {
      final targetShots = job['targetShots'] as int? ?? 0;
      final completedShots = job['shotsCompleted'] as int? ?? 0;
      if (completedShots >= targetShots) {
        completedOnTime++;
      }
    }
    
    final productivityPercentage = totalCompleted > 0
        ? (completedOnTime / totalCompleted) * 100
        : 100.0;
    final productivityScore = (productivityPercentage / 100 * 30).clamp(0, 30);
    
    // Total Health Score
    final totalScore = (uptimeScore + qualityScore + productivityScore).round();
    
    return {
      'totalScore': totalScore,
      'uptimeScore': uptimeScore.round(),
      'qualityScore': qualityScore.round(),
      'productivityScore': productivityScore.round(),
      'uptimePercentage': uptimePercentage,
      'scrapRate': scrapRate,
      'productivityPercentage': productivityPercentage,
      'color': _getHealthColor(totalScore),
      'status': _getHealthStatus(totalScore),
      'grade': _getHealthGrade(totalScore),
    };
  }
  
  /// Calculate shift summary
  static Map<String, dynamic> calculateShiftSummary() {
    final inputsBox = Hive.box('inputsBox');
    final jobsBox = Hive.box('jobsBox');
    final issuesBox = Hive.box('issuesBox');
    final downtimeBox = Hive.box('downtimeBox');
    
    // Determine current shift (simplified: Day 6-18, Night 18-6)
    final now = DateTime.now();
    final hour = now.hour;
    final isDay = hour >= 6 && hour < 18;
    final shiftName = isDay ? 'Day Shift' : 'Night Shift';
    
    // Get shift start time
    DateTime shiftStart;
    if (isDay) {
      shiftStart = DateTime(now.year, now.month, now.day, 6, 0);
    } else {
      if (hour >= 18) {
        shiftStart = DateTime(now.year, now.month, now.day, 18, 0);
      } else {
        shiftStart = DateTime(now.year, now.month, now.day - 1, 18, 0);
      }
    }
    
    // Calculate shift metrics
    final shiftInputs = inputsBox.values.cast<Map>().where((input) {
      final date = DateTime.tryParse(input['date'] ?? '');
      return date != null && date.isAfter(shiftStart);
    }).toList();
    
    int totalShots = 0;
    int totalScrap = 0;
    for (final input in shiftInputs) {
      totalShots += input['shots'] as int? ?? 0;
      totalScrap += input['scrap'] as int? ?? 0;
    }
    
    final totalProduced = totalShots + totalScrap;
    final shiftScrapRate = totalProduced > 0 ? (totalScrap / totalProduced) * 100 : 0.0;
    
    // Jobs completed this shift
    final jobsCompleted = jobsBox.values.cast<Map>().where((job) {
      final endTime = DateTime.tryParse(job['endTime'] ?? '');
      return endTime != null && endTime.isAfter(shiftStart) && job['status'] == 'Finished';
    }).length;
    
    // Issues reported this shift
    final issuesReported = issuesBox.values.cast<Map>().where((issue) {
      final date = DateTime.tryParse(issue['date'] ?? '');
      return date != null && date.isAfter(shiftStart);
    }).length;
    
    // Downtime this shift
    final shiftDowntime = downtimeBox.values.cast<Map>().where((d) {
      final date = DateTime.tryParse(d['date'] ?? '');
      return date != null && date.isAfter(shiftStart);
    }).toList();
    
    final totalDowntimeMinutes = shiftDowntime.fold<int>(
      0, (sum, d) => sum + (d['minutes'] as int? ?? 0)
    );
    
    return {
      'shiftName': shiftName,
      'shiftStart': shiftStart,
      'totalShots': totalShots,
      'totalScrap': totalScrap,
      'totalProduced': totalProduced,
      'scrapRate': shiftScrapRate,
      'jobsCompleted': jobsCompleted,
      'issuesReported': issuesReported,
      'downtimeMinutes': totalDowntimeMinutes,
      'duration': now.difference(shiftStart),
    };
  }
  
  static Color _getHealthColor(int score) {
    if (score >= 80) return const Color(0xFF00D26A); // Green
    if (score >= 60) return const Color(0xFF80ED99); // Light Green
    if (score >= 40) return const Color(0xFFFFD166); // Yellow
    if (score >= 20) return const Color(0xFFFF9500); // Orange
    return const Color(0xFFFF6B6B); // Red
  }
  
  static String _getHealthStatus(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    if (score >= 20) return 'Poor';
    return 'Critical';
  }
  
  static String _getHealthGrade(int score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'F';
  }
}
