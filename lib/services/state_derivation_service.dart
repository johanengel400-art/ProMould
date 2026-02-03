/// ProMould State Derivation Service
/// Calculates all derived state from stored data
/// CRITICAL: Derived state is NEVER stored, always computed

import 'package:hive/hive.dart';
import '../core/constants.dart';
import '../models/machine_model.dart';
import '../models/mould_model.dart';
import '../models/job_model.dart';
import 'log_service.dart';

/// Service for deriving state from stored data
/// All calculations happen here - UI components should use this service
class StateDerivationService {
  // ============ LIVE COUNTER DERIVATION ============

  /// Calculate live counter for a running job
  /// Formula: startCounter + floor((now - jobStartTime) / cycleTime)
  static int deriveLiveCounter({
    required int startCounter,
    required DateTime jobStartTime,
    required double cycleTimeSeconds,
  }) {
    if (cycleTimeSeconds <= 0) return startCounter;

    final elapsedSeconds = DateTime.now().difference(jobStartTime).inSeconds;
    final cyclesCompleted = (elapsedSeconds / cycleTimeSeconds).floor();

    return startCounter + cyclesCompleted;
  }

  /// Calculate parts produced from counter and cavities
  static int derivePartsProduced({
    required int currentCounter,
    required int startCounter,
    required int cavities,
  }) {
    final shots = currentCounter - startCounter;
    return shots * cavities;
  }

  /// Calculate progress percentage
  static double deriveProgressPercentage({
    required int partsProduced,
    required int quantityRequired,
  }) {
    if (quantityRequired <= 0) return 0;
    final progress = (partsProduced / quantityRequired) * 100;
    return progress.clamp(0, 100);
  }

  /// Calculate ETA for job completion
  static DateTime? deriveETA({
    required DateTime jobStartTime,
    required int partsProduced,
    required int quantityRemaining,
  }) {
    if (partsProduced <= 0 || quantityRemaining <= 0) return null;

    final elapsed = DateTime.now().difference(jobStartTime);
    final partsPerSecond = partsProduced / elapsed.inSeconds;

    if (partsPerSecond <= 0) return null;

    final remainingSeconds = quantityRemaining / partsPerSecond;
    return DateTime.now().add(Duration(seconds: remainingSeconds.round()));
  }

  // ============ SCRAP RATE DERIVATION ============

  /// Calculate scrap rate
  static double deriveScrapRate({
    required int scrapQuantity,
    required int totalProduced,
  }) {
    if (totalProduced <= 0) return 0;
    return (scrapQuantity / totalProduced) * 100;
  }

  /// Get scrap rate status
  static String getScrapRateStatus(double scrapRate) {
    if (scrapRate < SystemThresholds.scrapExcellent) return 'excellent';
    if (scrapRate < SystemThresholds.scrapAcceptable) return 'acceptable';
    if (scrapRate < SystemThresholds.scrapConcerning) return 'concerning';
    return 'critical';
  }

  // ============ OEE DERIVATION ============

  /// Calculate OEE (Overall Equipment Effectiveness)
  /// OEE = Availability × Performance × Quality
  static OEEResult deriveOEE({
    required int plannedTimeMinutes,
    required int downtimeMinutes,
    required double targetCycleTime,
    required double actualCycleTime,
    required int partsProduced,
    required int goodParts,
  }) {
    // Availability = (Planned Time - Downtime) / Planned Time
    final availability = plannedTimeMinutes > 0
        ? (plannedTimeMinutes - downtimeMinutes) / plannedTimeMinutes
        : 0.0;

    // Performance = (Actual Cycle Time / Target Cycle Time) × (Parts / Theoretical Parts)
    // Simplified: Actual Output / Theoretical Output
    final runTimeMinutes = plannedTimeMinutes - downtimeMinutes;
    final theoreticalParts = targetCycleTime > 0
        ? (runTimeMinutes * 60 / targetCycleTime).floor()
        : 0;
    final performance =
        theoreticalParts > 0 ? partsProduced / theoreticalParts : 0.0;

    // Quality = Good Parts / Total Parts
    final quality = partsProduced > 0 ? goodParts / partsProduced : 0.0;

    // OEE = A × P × Q
    final oee = availability * performance * quality * 100;

    return OEEResult(
      oee: oee.clamp(0, 100),
      availability: (availability * 100).clamp(0, 100),
      performance: (performance * 100).clamp(0, 100),
      quality: (quality * 100).clamp(0, 100),
    );
  }

  /// Get OEE status
  static String getOEEStatus(double oee) {
    if (oee >= SystemThresholds.oeeWorldClass) return 'worldClass';
    if (oee >= SystemThresholds.oeeGood) return 'good';
    if (oee >= SystemThresholds.oeeFair) return 'fair';
    return 'poor';
  }

  // ============ HEALTH SCORE DERIVATION ============

  /// Calculate machine health score (0-100)
  /// Uptime: 40 points, Quality: 30 points, Productivity: 30 points
  static HealthScoreResult deriveHealthScore({
    required double uptimePercent,
    required double scrapRate,
    required double productivityPercent,
  }) {
    // Uptime score (40 points max)
    final uptimeScore = (uptimePercent / 100) * 40;

    // Quality score (30 points max) - inverse of scrap rate
    final qualityPercent = (100 - scrapRate).clamp(0, 100);
    final qualityScore = (qualityPercent / 100) * 30;

    // Productivity score (30 points max)
    final productivityScore = (productivityPercent / 100) * 30;

    final totalScore =
        (uptimeScore + qualityScore + productivityScore).round().clamp(0, 100);

    return HealthScoreResult(
      score: totalScore,
      grade: _getHealthGrade(totalScore),
      uptimeScore: uptimeScore,
      qualityScore: qualityScore,
      productivityScore: productivityScore,
    );
  }

  static String _getHealthGrade(int score) {
    if (score >= 95) return 'A+';
    if (score >= 90) return 'A';
    if (score >= 85) return 'A-';
    if (score >= 80) return 'B+';
    if (score >= 75) return 'B';
    if (score >= 70) return 'B-';
    if (score >= 65) return 'C+';
    if (score >= 60) return 'C';
    if (score >= 55) return 'C-';
    if (score >= 50) return 'D';
    return 'F';
  }

  /// Get health status
  static String getHealthStatus(int score) {
    if (score >= SystemThresholds.healthExcellent) return 'excellent';
    if (score >= SystemThresholds.healthGood) return 'good';
    if (score >= SystemThresholds.healthFair) return 'fair';
    return 'poor';
  }

  // ============ CYCLE TIME DERIVATION ============

  /// Calculate actual cycle time from production data
  static double? deriveActualCycleTime({
    required DateTime jobStartTime,
    required int shotsCompleted,
  }) {
    if (shotsCompleted <= 0) return null;

    final elapsedSeconds = DateTime.now().difference(jobStartTime).inSeconds;
    return elapsedSeconds / shotsCompleted;
  }

  /// Calculate cycle time variance
  static double deriveCycleTimeVariance({
    required double targetCycleTime,
    required double actualCycleTime,
  }) {
    return actualCycleTime - targetCycleTime;
  }

  /// Calculate cycle time variance percentage
  static double deriveCycleTimeVariancePercent({
    required double targetCycleTime,
    required double actualCycleTime,
  }) {
    if (targetCycleTime <= 0) return 0;
    return ((actualCycleTime - targetCycleTime) / targetCycleTime) * 100;
  }

  // ============ MOULD LIFE DERIVATION ============

  /// Calculate remaining mould life
  static int deriveMouldRemainingLife({
    required int expectedLifeShots,
    required int totalLifetimeShots,
  }) {
    return (expectedLifeShots - totalLifetimeShots).clamp(0, expectedLifeShots);
  }

  /// Calculate mould life percentage
  static double deriveMouldLifePercentage({
    required int expectedLifeShots,
    required int totalLifetimeShots,
  }) {
    if (expectedLifeShots <= 0) return 0;
    return (totalLifetimeShots / expectedLifeShots) * 100;
  }

  /// Check if mould maintenance is due
  static bool isMouldMaintenanceDue({
    required int shotsSinceLastMaintenance,
    required int maintenanceIntervalShots,
  }) {
    return shotsSinceLastMaintenance >= maintenanceIntervalShots;
  }

  /// Calculate maintenance due percentage
  static double deriveMaintenanceDuePercentage({
    required int shotsSinceLastMaintenance,
    required int maintenanceIntervalShots,
  }) {
    if (maintenanceIntervalShots <= 0) return 0;
    return (shotsSinceLastMaintenance / maintenanceIntervalShots) * 100;
  }

  // ============ SHIFT DETECTION ============

  /// Determine current shift based on time
  static String? deriveCurrentShift(List<Map<String, dynamic>> shifts) {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute; // Minutes since midnight

    for (final shift in shifts) {
      final startTime = shift['startTime'] as String?;
      final endTime = shift['endTime'] as String?;

      if (startTime == null || endTime == null) continue;

      final startParts = startTime.split(':');
      final endParts = endTime.split(':');

      if (startParts.length < 2 || endParts.length < 2) continue;

      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
      final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      // Handle overnight shifts
      if (endMinutes < startMinutes) {
        // Shift crosses midnight
        if (currentTime >= startMinutes || currentTime < endMinutes) {
          return shift['id'] as String?;
        }
      } else {
        // Normal shift
        if (currentTime >= startMinutes && currentTime < endMinutes) {
          return shift['id'] as String?;
        }
      }
    }

    return null;
  }

  // ============ AGGREGATE DERIVATIONS ============

  /// Derive complete machine state with all calculated values
  static MachineWithState deriveMachineState({
    required Machine machine,
    Job? currentJob,
    Mould? currentMould,
    String? operatorId,
    String? operatorName,
    int? liveCounter,
    int scrapCount = 0,
    int downtimeMinutes = 0,
    int plannedTimeMinutes = 480, // 8 hour shift default
  }) {
    int? partsProduced;
    double? progressPercentage;
    double? scrapRate;
    DateTime? eta;
    double? actualCycleTime;
    double? cycleTimeVariance;

    if (currentJob != null && currentMould != null && liveCounter != null) {
      final startCounter = currentJob.startCounter ?? 0;
      partsProduced = derivePartsProduced(
        currentCounter: liveCounter,
        startCounter: startCounter,
        cavities: currentMould.cavities,
      );

      progressPercentage = deriveProgressPercentage(
        partsProduced: partsProduced,
        quantityRequired: currentJob.quantityRequired,
      );

      final totalProduced = partsProduced + scrapCount;
      scrapRate = deriveScrapRate(
        scrapQuantity: scrapCount,
        totalProduced: totalProduced,
      );

      if (currentJob.startedAt != null) {
        eta = deriveETA(
          jobStartTime: currentJob.startedAt!,
          partsProduced: partsProduced,
          quantityRemaining: currentJob.quantityRequired - partsProduced,
        );

        actualCycleTime = deriveActualCycleTime(
          jobStartTime: currentJob.startedAt!,
          shotsCompleted: liveCounter - startCounter,
        );

        if (actualCycleTime != null) {
          cycleTimeVariance = deriveCycleTimeVariance(
            targetCycleTime: currentJob.targetCycleTime,
            actualCycleTime: actualCycleTime,
          );
        }
      }
    }

    // Calculate OEE
    OEEResult? oeeResult;
    if (currentJob != null && partsProduced != null) {
      oeeResult = deriveOEE(
        plannedTimeMinutes: plannedTimeMinutes,
        downtimeMinutes: downtimeMinutes,
        targetCycleTime: currentJob.targetCycleTime,
        actualCycleTime: actualCycleTime ?? currentJob.targetCycleTime,
        partsProduced: partsProduced,
        goodParts: partsProduced - scrapCount,
      );
    }

    // Calculate health score
    final uptimePercent = plannedTimeMinutes > 0
        ? ((plannedTimeMinutes - downtimeMinutes) / plannedTimeMinutes) * 100
        : 100.0;
    final productivityPercent = oeeResult?.performance ?? 100.0;

    final healthResult = deriveHealthScore(
      uptimePercent: uptimePercent,
      scrapRate: scrapRate ?? 0,
      productivityPercent: productivityPercent,
    );

    return MachineWithState(
      machine: machine,
      currentJobId: currentJob?.id,
      currentJobNumber: currentJob?.jobNumber,
      currentMouldId: currentMould?.id,
      currentMouldNumber: currentMould?.mouldNumber,
      currentOperatorId: operatorId,
      currentOperatorName: operatorName,
      liveCounter: liveCounter,
      partsProduced: partsProduced,
      targetQuantity: currentJob?.quantityRequired,
      progressPercentage: progressPercentage,
      currentCycleTime: actualCycleTime,
      targetCycleTime: currentJob?.targetCycleTime,
      cycleTimeVariance: cycleTimeVariance,
      scrapCount: scrapCount,
      scrapRate: scrapRate,
      oee: oeeResult?.oee,
      availability: oeeResult?.availability,
      performance: oeeResult?.performance,
      quality: oeeResult?.quality,
      healthScore: healthResult.score,
      healthGrade: healthResult.grade,
      eta: eta,
      isOverrunning:
          eta != null && currentJob?.dueDate != null && eta.isAfter(currentJob!.dueDate!),
      downtimeMinutes: downtimeMinutes,
      downtimeRate: plannedTimeMinutes > 0
          ? (downtimeMinutes / plannedTimeMinutes) * 100
          : 0,
    );
  }

  /// Derive complete job state with all calculated values
  static JobWithState deriveJobState({
    required Job job,
    Mould? mould,
    String? machineName,
    String? operatorId,
    String? operatorName,
    int? currentCounter,
    int scrapQuantity = 0,
  }) {
    int quantityProduced = 0;
    double? actualCycleTime;

    if (mould != null && currentCounter != null && job.startCounter != null) {
      quantityProduced = derivePartsProduced(
        currentCounter: currentCounter,
        startCounter: job.startCounter!,
        cavities: mould.cavities,
      );

      if (job.startedAt != null) {
        actualCycleTime = deriveActualCycleTime(
          jobStartTime: job.startedAt!,
          shotsCompleted: currentCounter - job.startCounter!,
        );
      }
    }

    return JobWithState(
      job: job,
      mouldNumber: mould?.mouldNumber,
      mouldName: mould?.name,
      cavities: mould?.cavities,
      machineName: machineName,
      operatorId: operatorId,
      operatorName: operatorName,
      quantityProduced: quantityProduced,
      scrapQuantity: scrapQuantity,
      currentCounter: currentCounter,
      actualCycleTime: actualCycleTime,
    );
  }
}

/// OEE calculation result
class OEEResult {
  final double oee;
  final double availability;
  final double performance;
  final double quality;

  const OEEResult({
    required this.oee,
    required this.availability,
    required this.performance,
    required this.quality,
  });
}

/// Health score calculation result
class HealthScoreResult {
  final int score;
  final String grade;
  final double uptimeScore;
  final double qualityScore;
  final double productivityScore;

  const HealthScoreResult({
    required this.score,
    required this.grade,
    required this.uptimeScore,
    required this.qualityScore,
    required this.productivityScore,
  });
}
