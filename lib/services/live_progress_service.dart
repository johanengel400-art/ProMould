// lib/services/live_progress_service.dart
// Real-time progress tracking for running jobs

import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'sync_service.dart';
import 'log_service.dart';

class LiveProgressService {
  static Timer? _timer;
  static bool _isRunning = false;

  static void start() {
    if (_isRunning) return;
    _isRunning = true;
    
    LogService.service('LiveProgressService', 'Starting real-time progress updates...');
    
    // Update every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateRunningJobs();
    });
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    LogService.service('LiveProgressService', 'Stopped');
  }

  static Future<void> _updateRunningJobs() async {
    try {
      final jobsBox = Hive.box('jobsBox');
      final mouldsBox = Hive.box('mouldsBox');
      final now = DateTime.now();
      
      final runningJobs = jobsBox.values
          .cast<Map>()
          .where((j) => j['status'] == 'Running')
          .toList();
      
      for (final job in runningJobs) {
        final jobId = job['id'] as String;
        final mouldId = job['mouldId'] as String?;
        
        if (mouldId == null) continue;
        
        // Get mould to find cycle time and cavities
        final mould = mouldsBox.get(mouldId) as Map?;
        if (mould == null) continue;
        
        final cycleTime = (mould['cycleTime'] as num?)?.toDouble() ?? 30.0;
        final cavities = (mould['cavities'] as int?) ?? 1;
        
        // Get start time and last manual update
        final startTimeStr = job['startTime'] as String?;
        final lastManualUpdate = job['lastManualUpdate'] as String?;
        final manualShotsCompleted = job['manualShotsCompleted'] as int?;
        
        if (startTimeStr == null) continue;
        
        DateTime referenceTime;
        int baselineShots;
        
        // If there was a manual update, use that as the reference point
        if (lastManualUpdate != null && manualShotsCompleted != null) {
          referenceTime = DateTime.parse(lastManualUpdate);
          baselineShots = manualShotsCompleted;
        } else {
          // Otherwise, use job start time
          referenceTime = DateTime.parse(startTimeStr);
          baselineShots = 0;
        }
        
        // Calculate elapsed time since reference point
        final elapsedSeconds = now.difference(referenceTime).inSeconds;
        
        // Calculate estimated shots based on cycle time and cavities
        // Each cycle produces 'cavities' number of parts
        final estimatedNewShots = ((elapsedSeconds / cycleTime) * cavities).floor();
        final estimatedTotalShots = baselineShots + estimatedNewShots;
        
        // Don't exceed target
        final targetShots = job['targetShots'] as int? ?? 0;
        final currentShots = estimatedTotalShots.clamp(baselineShots, targetShots);
        
        // Only update if shots changed
        if (currentShots != (job['shotsCompleted'] as int? ?? 0)) {
          final updatedJob = Map<String, dynamic>.from(job);
          updatedJob['shotsCompleted'] = currentShots;
          
          // Check if job is complete
          if (currentShots >= targetShots && targetShots > 0) {
            updatedJob['status'] = 'Finished';
            updatedJob['endTime'] = now.toIso8601String();
            
            // Handle machine status and next job
            await _handleJobCompletion(jobId, updatedJob);
          } else {
            await jobsBox.put(jobId, updatedJob);
            // Sync to Firebase less frequently to avoid excessive writes
            if (estimatedNewShots % 10 == 0) {
              await SyncService.pushChange('jobsBox', jobId, updatedJob);
            }
          }
        }
      }
    } catch (e) {
      LogService.error('LiveProgressService error', e);
    }
  }

  static Future<void> _handleJobCompletion(String jobId, Map<String, dynamic> finishedJob) async {
    final jobsBox = Hive.box('jobsBox');
    final machinesBox = Hive.box('machinesBox');
    final machineId = finishedJob['machineId'] as String?;
    
    // Save finished job
    await jobsBox.put(jobId, finishedJob);
    await SyncService.pushChange('jobsBox', jobId, finishedJob);
    
    if (machineId == null) return;
    
    // Find next queued job for this machine
    final nextJob = jobsBox.values.cast<Map?>().firstWhere(
      (j) => j != null && j['machineId'] == machineId && j['status'] == 'Queued',
      orElse: () => null,
    );
    
    if (nextJob != null) {
      // Start next job
      final nextJobId = nextJob['id'] as String;
      final updatedNext = Map<String, dynamic>.from(nextJob);
      updatedNext['status'] = 'Running';
      updatedNext['startTime'] = DateTime.now().toIso8601String();
      await jobsBox.put(nextJobId, updatedNext);
      await SyncService.pushChange('jobsBox', nextJobId, updatedNext);
      LogService.info('Started next job: ${updatedNext['productName']}');
    } else {
      // No more jobs - set machine to Idle
      final machine = machinesBox.get(machineId) as Map?;
      if (machine != null) {
        final updatedMachine = Map<String, dynamic>.from(machine);
        updatedMachine['status'] = 'Idle';
        await machinesBox.put(machineId, updatedMachine);
        await SyncService.pushChange('machinesBox', machineId, updatedMachine);
        LogService.info('Machine ${machine['name']} set to Idle');
      }
    }
  }

  /// Call this when user manually inputs shots to reset the baseline
  static Future<void> recordManualInput(String jobId, int actualShots) async {
    final jobsBox = Hive.box('jobsBox');
    final job = jobsBox.get(jobId) as Map?;
    
    if (job == null) return;
    
    final updatedJob = Map<String, dynamic>.from(job);
    updatedJob['shotsCompleted'] = actualShots;
    updatedJob['manualShotsCompleted'] = actualShots;
    updatedJob['lastManualUpdate'] = DateTime.now().toIso8601String();
    
    await jobsBox.put(jobId, updatedJob);
    await SyncService.pushChange('jobsBox', jobId, updatedJob);
    
    LogService.info('Manual input recorded: $actualShots shots for job $jobId');
  }

  /// Get current estimated shots for a running job (for display purposes)
  static int getEstimatedShots(Map job, Box mouldsBox) {
    if (job['status'] != 'Running') {
      return job['shotsCompleted'] as int? ?? 0;
    }
    
    final mouldId = job['mouldId'] as String?;
    if (mouldId == null) return job['shotsCompleted'] as int? ?? 0;
    
    final mould = mouldsBox.get(mouldId) as Map?;
    if (mould == null) return job['shotsCompleted'] as int? ?? 0;
    
    final cycleTime = (mould['cycleTime'] as num?)?.toDouble() ?? 30.0;
    final cavities = (mould['cavities'] as int?) ?? 1;
    final startTimeStr = job['startTime'] as String?;
    final lastManualUpdate = job['lastManualUpdate'] as String?;
    final manualShotsCompleted = job['manualShotsCompleted'] as int?;
    
    if (startTimeStr == null) return job['shotsCompleted'] as int? ?? 0;
    
    DateTime referenceTime;
    int baselineShots;
    
    if (lastManualUpdate != null && manualShotsCompleted != null) {
      referenceTime = DateTime.parse(lastManualUpdate);
      baselineShots = manualShotsCompleted;
    } else {
      referenceTime = DateTime.parse(startTimeStr);
      baselineShots = 0;
    }
    
    final elapsedSeconds = DateTime.now().difference(referenceTime).inSeconds;
    final estimatedNewShots = ((elapsedSeconds / cycleTime) * cavities).floor();
    final estimatedTotalShots = baselineShots + estimatedNewShots;
    final targetShots = job['targetShots'] as int? ?? 0;
    
    return estimatedTotalShots.clamp(baselineShots, targetShots);
  }
}
