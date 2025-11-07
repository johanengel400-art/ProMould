// lib/services/notification_service.dart
// Smart notifications and alerts

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'live_progress_service.dart';
import 'scrap_rate_service.dart';
import 'log_service.dart';
import 'push_notification_service.dart';

class NotificationService {
  static final List<Map<String, dynamic>> _notifications = [];
  static Timer? _checkTimer;
  static bool _isRunning = false;
  
  static List<Map<String, dynamic>> get notifications => _notifications;
  
  static void start() {
    if (_isRunning) return;
    _isRunning = true;
    
    LogService.service('NotificationService', 'Starting...');
    
    // Check every 30 seconds
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkForAlerts();
    });
  }
  
  static void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isRunning = false;
    LogService.service('NotificationService', 'Stopped');
  }
  
  static void _checkForAlerts() {
    _notifications.clear();
    
    _checkJobCompletionAlerts();
    _checkScrapRateAlerts();
    _checkMaintenanceAlerts();
    _checkMouldChangeAlerts();
    _checkBreakdownAlerts();
    
    // Send push notifications for high priority alerts
    _sendPushNotifications();
  }
  
  /// Send push notifications for high priority alerts
  static void _sendPushNotifications() {
    final highPriorityAlerts = _notifications.where((n) => n['priority'] == 'high').toList();
    
    for (final alert in highPriorityAlerts) {
      // Send to appropriate topic based on alert type
      String topic = NotificationTopic.allUsers;
      
      switch (alert['type']) {
        case 'breakdown':
          topic = NotificationTopic.maintenance;
          break;
        case 'high_scrap':
        case 'quality_issue':
          topic = NotificationTopic.quality;
          break;
        case 'maintenance_due':
          topic = NotificationTopic.maintenance;
          break;
        case 'mould_change':
        case 'mould_change_overdue':
          topic = NotificationTopic.setters;
          break;
        default:
          topic = NotificationTopic.managers;
      }
      
      PushNotificationService.sendToTopic(
        topic,
        title: alert['title'] as String,
        body: alert['message'] as String,
        data: {
          'type': alert['type'] as String,
          'id': alert['id'] as String,
        },
        priority: 'high',
      );
    }
  }
  
  /// Check for jobs finishing soon
  static void _checkJobCompletionAlerts() {
    final jobsBox = Hive.box('jobsBox');
    final mouldsBox = Hive.box('mouldsBox');
    final machinesBox = Hive.box('machinesBox');
    
    final runningJobs = jobsBox.values.cast<Map>().where((j) => j['status'] == 'Running').toList();
    
    for (final job in runningJobs) {
      final mould = mouldsBox.values.cast<Map?>().firstWhere(
        (m) => m != null && m['id'] == job['mouldId'],
        orElse: () => null,
      );
      
      if (mould == null) continue;
      
      final cycleTime = (mould['cycleTime'] as num?)?.toDouble() ?? 30.0;
      final currentShots = LiveProgressService.getEstimatedShots(job, mouldsBox);
      final targetShots = job['targetShots'] as int? ?? 0;
      final remaining = targetShots - currentShots;
      
      if (remaining <= 0) continue;
      
      final minutesRemaining = (remaining * cycleTime / 60).toDouble();
      
      // Alert if finishing in 30 minutes
      if (minutesRemaining <= 30 && minutesRemaining > 0) {
        final machine = machinesBox.get(job['machineId']) as Map?;
        _notifications.add({
          'id': 'job_${job['id']}',
          'type': 'job_completion',
          'priority': 'medium',
          'icon': Icons.access_time,
          'color': const Color(0xFFFFD166),
          'title': 'Job Finishing Soon',
          'message': '${job['productName']} on ${machine?['name'] ?? 'Unknown'} will finish in ${minutesRemaining.round()} min',
          'timestamp': DateTime.now(),
          'data': job,
        });
      }
    }
  }
  
  /// Check for high scrap rates
  static void _checkScrapRateAlerts() {
    final machinesBox = Hive.box('machinesBox');
    
    for (final machine in machinesBox.values.cast<Map>()) {
      final machineId = machine['id'] as String;
      final scrapData = ScrapRateService.calculateMachineScrapRate(machineId);
      final scrapRate = scrapData['scrapRate'] as double;
      
      if (scrapRate > 5.0) {
        _notifications.add({
          'id': 'scrap_$machineId',
          'type': 'high_scrap',
          'priority': scrapRate > 10 ? 'high' : 'medium',
          'icon': Icons.warning,
          'color': scrapRate > 10 ? const Color(0xFFFF6B6B) : const Color(0xFFFF9500),
          'title': 'High Scrap Rate',
          'message': '${machine['name']}: ${scrapRate.toStringAsFixed(1)}% scrap rate',
          'timestamp': DateTime.now(),
          'data': machine,
        });
      }
    }
  }
  
  /// Check for maintenance due
  static void _checkMaintenanceAlerts() {
    final machinesBox = Hive.box('machinesBox');
    final inputsBox = Hive.box('inputsBox');
    
    for (final machine in machinesBox.values.cast<Map>()) {
      final machineId = machine['id'] as String;
      final lastMaintenance = machine['lastMaintenance'] as String?;
      final maintenanceInterval = machine['maintenanceInterval'] as int? ?? 100000; // shots
      
      // Calculate total shots since last maintenance
      final inputs = inputsBox.values.cast<Map>().where((i) => i['machineId'] == machineId);
      
      DateTime? lastMaintenanceDate;
      if (lastMaintenance != null) {
        lastMaintenanceDate = DateTime.tryParse(lastMaintenance);
      }
      
      int shotsSinceMaintenance = 0;
      for (final input in inputs) {
        final inputDate = DateTime.tryParse(input['date'] ?? '');
        if (lastMaintenanceDate == null || (inputDate != null && inputDate.isAfter(lastMaintenanceDate))) {
          shotsSinceMaintenance += input['shots'] as int? ?? 0;
        }
      }
      
      // Alert if 90% of interval reached
      if (shotsSinceMaintenance >= maintenanceInterval * 0.9) {
        _notifications.add({
          'id': 'maintenance_$machineId',
          'type': 'maintenance_due',
          'priority': shotsSinceMaintenance >= maintenanceInterval ? 'high' : 'medium',
          'icon': Icons.build,
          'color': const Color(0xFF4CC9F0),
          'title': 'Maintenance Due',
          'message': '${machine['name']}: $shotsSinceMaintenance shots since last maintenance',
          'timestamp': DateTime.now(),
          'data': machine,
        });
      }
    }
  }
  
  /// Check for upcoming mould changes
  static void _checkMouldChangeAlerts() {
    if (!Hive.isBoxOpen('mouldChangesBox')) return;
    
    final mouldChangesBox = Hive.box('mouldChangesBox');
    final machinesBox = Hive.box('machinesBox');
    final now = DateTime.now();
    
    for (final change in mouldChangesBox.values.cast<Map>()) {
      if (change['status'] != 'Scheduled') continue;
      
      final scheduledDate = DateTime.tryParse(change['scheduledDate'] ?? '');
      if (scheduledDate == null) continue;
      
      final minutesUntil = scheduledDate.difference(now).inMinutes;
      
      // Alert if within 1 hour
      if (minutesUntil > 0 && minutesUntil <= 60) {
        final machine = machinesBox.get(change['machineId']) as Map?;
        _notifications.add({
          'id': 'mould_change_${change['id']}',
          'type': 'mould_change',
          'priority': minutesUntil <= 15 ? 'high' : 'medium',
          'icon': Icons.swap_horiz,
          'color': const Color(0xFFFFD166),
          'title': 'Mould Change Soon',
          'message': '${machine?['name'] ?? 'Machine'} mould change in $minutesUntil min',
          'timestamp': DateTime.now(),
          'data': change,
        });
      }
      
      // Alert if overdue
      if (minutesUntil < 0) {
        final machine = machinesBox.get(change['machineId']) as Map?;
        _notifications.add({
          'id': 'mould_change_overdue_${change['id']}',
          'type': 'mould_change_overdue',
          'priority': 'high',
          'icon': Icons.error,
          'color': const Color(0xFFFF6B6B),
          'title': 'Mould Change Overdue',
          'message': '${machine?['name'] ?? 'Machine'} mould change is ${(-minutesUntil)} min overdue',
          'timestamp': DateTime.now(),
          'data': change,
        });
      }
    }
  }
  
  /// Check for machine breakdowns
  static void _checkBreakdownAlerts() {
    final machinesBox = Hive.box('machinesBox');
    
    for (final machine in machinesBox.values.cast<Map>()) {
      if (machine['status'] == 'Breakdown') {
        _notifications.add({
          'id': 'breakdown_${machine['id']}',
          'type': 'breakdown',
          'priority': 'high',
          'icon': Icons.build_circle,
          'color': const Color(0xFFFF6B6B),
          'title': 'Machine Breakdown',
          'message': '${machine['name']} is currently broken down',
          'timestamp': DateTime.now(),
          'data': machine,
        });
      }
    }
  }
  
  /// Get notifications by priority
  static List<Map<String, dynamic>> getByPriority(String priority) {
    return _notifications.where((n) => n['priority'] == priority).toList();
  }
  
  /// Get unread count
  static int getUnreadCount() {
    return _notifications.length;
  }
  
  /// Clear all notifications
  static void clearAll() {
    _notifications.clear();
  }
  
  /// Remove specific notification
  static void remove(String id) {
    _notifications.removeWhere((n) => n['id'] == id);
  }
}
