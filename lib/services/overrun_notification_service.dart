// lib/services/overrun_notification_service.dart
// Smart notifications for job overruns with escalation logic

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'log_service.dart';
import '../utils/job_status.dart';

class OverrunNotificationService {
  static Timer? _timer;
  static bool _isRunning = false;
  static final Map<String, DateTime> _lastNotified = {};
  static final Map<String, int> _notificationCount = {};
  
  // Notification thresholds
  static const int _initialThresholdMinutes = 5;
  static const int _escalationThresholdMinutes = 15;
  static const int _criticalThresholdMinutes = 30;
  
  static void start() {
    if (_isRunning) return;
    _isRunning = true;
    
    LogService.service('OverrunNotificationService', 'Starting overrun monitoring...');
    
    // Check every 2 minutes
    _timer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _checkOverruns();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    LogService.service('OverrunNotificationService', 'Stopped');
  }

  static Future<void> _checkOverruns() async {
    try {
      final jobsBox = Hive.box('jobsBox');
      final now = DateTime.now();
      
      final overrunningJobs = jobsBox.values
          .cast<Map>()
          .where((j) => j['status'] == JobStatus.overrunning)
          .toList();
      
      for (final job in overrunningJobs) {
        final jobId = job['id'] as String;
        final overrunDuration = JobStatus.getOverrunDuration(job);
        
        if (overrunDuration == null) continue;
        
        // Check if we should send a notification
        final lastNotification = _lastNotified[jobId];
        final notificationCount = _notificationCount[jobId] ?? 0;
        
        // Determine notification level and interval
        String? level;
        Duration? interval;
        
        if (overrunDuration >= _criticalThresholdMinutes) {
          level = 'CRITICAL';
          interval = const Duration(minutes: 10); // Notify every 10 minutes
        } else if (overrunDuration >= _escalationThresholdMinutes) {
          level = 'HIGH';
          interval = const Duration(minutes: 15); // Notify every 15 minutes
        } else if (overrunDuration >= _initialThresholdMinutes) {
          level = 'MODERATE';
          interval = const Duration(minutes: 20); // Notify every 20 minutes
        }
        
        if (level != null && interval != null) {
          // Check if enough time has passed since last notification
          if (lastNotification == null || 
              now.difference(lastNotification) >= interval) {
            await _sendOverrunNotification(job, level, overrunDuration);
            _lastNotified[jobId] = now;
            _notificationCount[jobId] = notificationCount + 1;
          }
        }
      }
      
      // Clean up tracking for jobs that are no longer overrunning
      _lastNotified.removeWhere((jobId, _) => 
        !overrunningJobs.any((j) => j['id'] == jobId));
      _notificationCount.removeWhere((jobId, _) => 
        !overrunningJobs.any((j) => j['id'] == jobId));
      
    } catch (e) {
      LogService.error('OverrunNotificationService error', e);
    }
  }

  static Future<void> _sendOverrunNotification(
    Map job,
    String level,
    int durationMinutes,
  ) async {
    try {
      final productName = job['productName'] as String? ?? 'Unknown Product';
      final machineId = job['machineId'] as String? ?? 'Unknown Machine';
      final shotsCompleted = job['shotsCompleted'] as int? ?? 0;
      final targetShots = job['targetShots'] as int? ?? 0;
      final overrunShots = JobStatus.getOverrunShots(shotsCompleted, targetShots);
      final overrunPercentage = JobStatus.getOverrunPercentage(shotsCompleted, targetShots);
      
      final durationFormatted = JobStatus.formatOverrunDuration(durationMinutes);
      
      // Construct notification message
      String title;
      String body;
      
      switch (level) {
        case 'CRITICAL':
          title = '🚨 CRITICAL: Job Severely Overrunning';
          body = '$productName on $machineId has been overrunning for $durationFormatted! '
                 '+$overrunShots shots (${overrunPercentage.toStringAsFixed(1)}% over target). '
                 'Immediate action required!';
          break;
        case 'HIGH':
          title = '⚠️ HIGH: Job Overrunning';
          body = '$productName on $machineId overrunning for $durationFormatted. '
                 '+$overrunShots shots (${overrunPercentage.toStringAsFixed(1)}% over). '
                 'Please review.';
          break;
        case 'MODERATE':
        default:
          title = '⚡ Job Overrunning';
          body = '$productName on $machineId has exceeded target by $overrunShots shots '
                 '(${overrunPercentage.toStringAsFixed(1)}%).';
          break;
      }
      
      // Send via FCM topic
      // Note: Actual sending would be done server-side via Firebase Cloud Functions
      // This logs the notification for now
      LogService.info('Overrun Notification [$level]: $title - $body');
      
      // In a production setup, you would call a Cloud Function here:
      // await _sendToCloudFunction(title, body, level, job);
      
    } catch (e) {
      LogService.error('Failed to send overrun notification', e);
    }
  }

  /// Check if a specific job should trigger an immediate notification
  static Future<void> checkJobImmediately(Map job) async {
    final status = job['status'] as String?;
    if (status != JobStatus.overrunning) return;
    
    final jobId = job['id'] as String;
    final overrunDuration = JobStatus.getOverrunDuration(job);
    
    if (overrunDuration == null || overrunDuration < _initialThresholdMinutes) return;
    
    // Only send if we haven't notified recently
    final lastNotification = _lastNotified[jobId];
    if (lastNotification != null && 
        DateTime.now().difference(lastNotification).inMinutes < 5) {
      return;
    }
    
    String level;
    if (overrunDuration >= _criticalThresholdMinutes) {
      level = 'CRITICAL';
    } else if (overrunDuration >= _escalationThresholdMinutes) {
      level = 'HIGH';
    } else {
      level = 'MODERATE';
    }
    
    await _sendOverrunNotification(job, level, overrunDuration);
    _lastNotified[jobId] = DateTime.now();
  }

  /// Get overrun summary for dashboard
  static Map<String, dynamic> getOverrunSummary() {
    try {
      final jobsBox = Hive.box('jobsBox');
      final overrunningJobs = jobsBox.values
          .cast<Map>()
          .where((j) => j['status'] == JobStatus.overrunning)
          .toList();
      
      var criticalCount = 0;
      var highCount = 0;
      var moderateCount = 0;
      
      for (final job in overrunningJobs) {
        final duration = JobStatus.getOverrunDuration(job);
        if (duration == null) continue;
        
        if (duration >= _criticalThresholdMinutes) {
          criticalCount++;
        } else if (duration >= _escalationThresholdMinutes) {
          highCount++;
        } else if (duration >= _initialThresholdMinutes) {
          moderateCount++;
        }
      }
      
      return {
        'total': overrunningJobs.length,
        'critical': criticalCount,
        'high': highCount,
        'moderate': moderateCount,
        'jobs': overrunningJobs,
      };
    } catch (e) {
      LogService.error('Failed to get overrun summary', e);
      return {
        'total': 0,
        'critical': 0,
        'high': 0,
        'moderate': 0,
        'jobs': [],
      };
    }
  }

  /// Reset notification tracking for a job (when it's finished or status changes)
  static void resetJobTracking(String jobId) {
    _lastNotified.remove(jobId);
    _notificationCount.remove(jobId);
  }

  /// Get notification history for a job
  static Map<String, dynamic>? getJobNotificationInfo(String jobId) {
    final lastNotification = _lastNotified[jobId];
    final count = _notificationCount[jobId];
    
    if (lastNotification == null) return null;
    
    return {
      'lastNotified': lastNotification,
      'count': count,
      'minutesSinceLastNotification': DateTime.now().difference(lastNotification).inMinutes,
    };
  }
}
