// lib/utils/job_status.dart
// Centralized job status management and utilities

import 'package:flutter/material.dart';

/// Job status constants and utilities
class JobStatus {
  // Status constants
  static const String queued = 'Queued';
  static const String running = 'Running';
  static const String overrunning = 'Overrunning';
  static const String paused = 'Paused';
  static const String finished = 'Finished';
  
  /// Check if job is actively running (Running or Overrunning)
  static bool isActivelyRunning(String? status) {
    return status == running || status == overrunning;
  }
  
  /// Check if job is in any active state (Running, Overrunning, or Paused)
  static bool isActive(String? status) {
    return status == running || status == overrunning || status == paused;
  }
  
  /// Check if job should be tracked by live progress
  static bool shouldTrackProgress(String? status) {
    return status == running || status == overrunning;
  }
  
  /// Get color for status
  static Color getColor(String? status) {
    switch (status) {
      case running:
        return const Color(0xFF06D6A0); // Green
      case overrunning:
        return const Color(0xFFFF6B6B); // Red
      case paused:
        return const Color(0xFFFFD166); // Yellow
      case finished:
        return const Color(0xFF4CC9F0); // Blue
      case queued:
        return Colors.white38; // Gray
      default:
        return Colors.white38;
    }
  }
  
  /// Get icon for status
  static IconData getIcon(String? status) {
    switch (status) {
      case running:
        return Icons.play_circle;
      case overrunning:
        return Icons.warning;
      case paused:
        return Icons.pause_circle;
      case finished:
        return Icons.check_circle;
      case queued:
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }
  
  /// Get display name for status
  static String getDisplayName(String? status) {
    return status ?? 'Unknown';
  }
  
  /// Calculate overrun percentage
  static double getOverrunPercentage(int shotsCompleted, int targetShots) {
    if (targetShots == 0) return 0.0;
    if (shotsCompleted <= targetShots) return 0.0;
    return ((shotsCompleted - targetShots) / targetShots * 100);
  }
  
  /// Get overrun shots count
  static int getOverrunShots(int shotsCompleted, int targetShots) {
    return shotsCompleted > targetShots ? shotsCompleted - targetShots : 0;
  }
  
  /// Check if job is overrunning
  static bool isOverrunning(Map job) {
    final status = job['status'] as String?;
    final shotsCompleted = job['shotsCompleted'] as int? ?? 0;
    final targetShots = job['targetShots'] as int? ?? 0;
    
    return status == overrunning || 
           (status == running && shotsCompleted >= targetShots && targetShots > 0);
  }
  
  /// Get overrun duration in minutes
  static int? getOverrunDuration(Map job) {
    final overrunStartTime = job['overrunStartTime'] as String?;
    if (overrunStartTime == null) return null;
    
    final start = DateTime.parse(overrunStartTime);
    final now = DateTime.now();
    return now.difference(start).inMinutes;
  }
  
  /// Format overrun duration
  static String formatOverrunDuration(int? minutes) {
    if (minutes == null) return '';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }
}
