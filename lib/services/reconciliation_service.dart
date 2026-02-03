/// ProMould Counter Reconciliation Service
/// Handles manual counter reconciliation with audit trail

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/reconciliation_model.dart';
import 'log_service.dart';
import 'sync_service.dart';
import 'audit_service.dart';
import 'alert_service.dart';

class ReconciliationService {
  static const _uuid = Uuid();
  static Box? _reconciliationsBox;
  static Box? _productionLogsBox;
  static Box? _machinesBox;
  static Box? _jobsBox;

  /// Initialize the reconciliation service
  static Future<void> initialize() async {
    _reconciliationsBox = await Hive.openBox(HiveBoxes.reconciliations);
    _productionLogsBox = await Hive.openBox(HiveBoxes.productionLogs);
    _machinesBox = await Hive.openBox(HiveBoxes.machines);
    _jobsBox = await Hive.openBox(HiveBoxes.jobs);
    LogService.info('ReconciliationService initialized');
  }

  // ============ RECONCILIATION CRUD ============

  /// Get all reconciliations
  static List<CounterReconciliation> getAllReconciliations() {
    if (_reconciliationsBox == null) return [];

    return _reconciliationsBox!.values
        .map((map) =>
            CounterReconciliation.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get reconciliation by ID
  static CounterReconciliation? getReconciliation(String id) {
    if (_reconciliationsBox == null) return null;

    final map = _reconciliationsBox!.get(id);
    if (map == null) return null;

    return CounterReconciliation.fromMap(Map<String, dynamic>.from(map));
  }

  /// Get reconciliations for a machine
  static List<CounterReconciliation> getReconciliationsForMachine(
      String machineId) {
    return getAllReconciliations()
        .where((r) => r.machineId == machineId)
        .toList();
  }

  /// Get reconciliations for a job
  static List<CounterReconciliation> getReconciliationsForJob(String jobId) {
    return getAllReconciliations().where((r) => r.jobId == jobId).toList();
  }

  /// Get pending reconciliations (awaiting approval)
  static List<CounterReconciliation> getPendingReconciliations() {
    return getAllReconciliations().where((r) => r.isPendingApproval).toList();
  }

  // ============ RECONCILIATION WORKFLOW ============

  /// Create a counter reconciliation
  static Future<CounterReconciliation> createReconciliation({
    required String machineId,
    required String jobId,
    required int systemCounter,
    required int physicalCounter,
    required String reason,
    required String reconciledById,
    required String reconciledByName,
  }) async {
    // Validate reason is provided
    if (reason.trim().isEmpty) {
      throw ArgumentError('Reconciliation reason is required');
    }

    // Create the reconciliation
    final reconciliation = CounterReconciliation.create(
      id: _uuid.v4(),
      machineId: machineId,
      jobId: jobId,
      systemCounter: systemCounter,
      physicalCounter: physicalCounter,
      reason: reason,
      reconciledById: reconciledById,
      reconciledByName: reconciledByName,
    );

    await _reconciliationsBox?.put(reconciliation.id, reconciliation.toMap());
    await SyncService.push(
        HiveBoxes.reconciliations, reconciliation.id, reconciliation.toMap());

    // Log the reconciliation
    await AuditService.logReconciliation(
      entityType: 'Counter',
      entityId: '$machineId/$jobId',
      beforeValue: {'counter': systemCounter},
      afterValue: {'counter': physicalCounter},
      reason: reason,
      metadata: {
        'variance': reconciliation.variance,
        'variancePercent': reconciliation.variancePercent,
        'requiresApproval': reconciliation.requiresApproval,
      },
    );

    LogService.info(
        'Counter reconciliation created: ${reconciliation.id} (variance: ${reconciliation.variance})');

    // If auto-approved, apply the reconciliation
    if (reconciliation.isApproved) {
      await _applyReconciliation(reconciliation);
    } else {
      // Generate alert for pending approval
      await AlertService.generateAlert(
        type: AlertType.counterReconciliation,
        severity: AlertSeverity.medium,
        title: 'Counter Reconciliation Pending Approval',
        message:
            'Counter reconciliation for machine requires approval. Variance: ${reconciliation.variancePercent.toStringAsFixed(1)}%',
        sourceType: 'Reconciliation',
        sourceId: reconciliation.id,
        machineId: machineId,
        jobId: jobId,
      );
    }

    return reconciliation;
  }

  /// Approve a pending reconciliation
  static Future<CounterReconciliation?> approveReconciliation(
    String reconciliationId,
    String approvedById,
    String approvedByName,
  ) async {
    final reconciliation = getReconciliation(reconciliationId);
    if (reconciliation == null) return null;

    if (!reconciliation.isPendingApproval) {
      LogService.warning(
          'Reconciliation is not pending approval: $reconciliationId');
      return reconciliation;
    }

    final approved = reconciliation.approve(approvedById, approvedByName);
    await _reconciliationsBox?.put(reconciliationId, approved.toMap());
    await SyncService.push(
        HiveBoxes.reconciliations, reconciliationId, approved.toMap());

    await AuditService.logApproval(
      entityType: 'Reconciliation',
      entityId: reconciliationId,
      metadata: {
        'approvedBy': approvedByName,
        'variance': approved.variance,
      },
    );

    // Apply the reconciliation
    await _applyReconciliation(approved);

    // Resolve the alert
    await AlertService.autoResolveForSource(
      'Reconciliation',
      reconciliationId,
      AlertType.counterReconciliation,
    );

    LogService.info('Reconciliation approved: $reconciliationId');
    return approved;
  }

  /// Reject a pending reconciliation
  static Future<CounterReconciliation?> rejectReconciliation(
    String reconciliationId,
    String rejectedById,
    String rejectedByName,
    String rejectionReason,
  ) async {
    final reconciliation = getReconciliation(reconciliationId);
    if (reconciliation == null) return null;

    if (!reconciliation.isPendingApproval) {
      LogService.warning(
          'Reconciliation is not pending approval: $reconciliationId');
      return reconciliation;
    }

    final rejected = reconciliation.reject(rejectedById, rejectedByName);
    await _reconciliationsBox?.put(reconciliationId, rejected.toMap());
    await SyncService.push(
        HiveBoxes.reconciliations, reconciliationId, rejected.toMap());

    await AuditService.logRejection(
      entityType: 'Reconciliation',
      entityId: reconciliationId,
      reason: rejectionReason,
      metadata: {
        'rejectedBy': rejectedByName,
        'variance': rejected.variance,
      },
    );

    // Resolve the alert
    await AlertService.autoResolveForSource(
      'Reconciliation',
      reconciliationId,
      AlertType.counterReconciliation,
    );

    LogService.info('Reconciliation rejected: $reconciliationId');
    return rejected;
  }

  /// Apply an approved reconciliation
  static Future<void> _applyReconciliation(
      CounterReconciliation reconciliation) async {
    if (!reconciliation.isApproved) return;

    // Update the job's start counter to reflect the reconciliation
    // This ensures seamless continuation after reconciliation
    if (_jobsBox != null) {
      final jobMap = _jobsBox!.get(reconciliation.jobId);
      if (jobMap != null) {
        final job = Map<String, dynamic>.from(jobMap);

        // Adjust the start counter to account for the variance
        // New effective start = old start + variance
        // This way: physicalCounter - newStart = correct parts produced
        final oldStartCounter = job['startCounter'] as int? ?? 0;
        final newStartCounter = oldStartCounter + reconciliation.variance;

        job['startCounter'] = newStartCounter;
        job['lastReconciliationId'] = reconciliation.id;
        job['lastReconciliationAt'] = DateTime.now().toIso8601String();

        await _jobsBox!.put(reconciliation.jobId, job);
        await SyncService.push(HiveBoxes.jobs, reconciliation.jobId, job);

        LogService.info(
            'Job start counter adjusted: ${reconciliation.jobId} ($oldStartCounter -> $newStartCounter)');
      }
    }

    // Create a production log entry for the reconciliation
    await _createReconciliationLog(reconciliation);
  }

  /// Create a production log entry for reconciliation
  static Future<void> _createReconciliationLog(
      CounterReconciliation reconciliation) async {
    if (_productionLogsBox == null) return;

    final log = ProductionLog(
      id: _uuid.v4(),
      jobId: reconciliation.jobId,
      machineId: reconciliation.machineId,
      mouldId: '', // Would need to look this up
      operatorId: reconciliation.reconciledById,
      operatorName: reconciliation.reconciledByName,
      shiftId: '', // Would need to look this up
      timestamp: reconciliation.timestamp,
      counterValue: reconciliation.physicalCounter,
      partsProduced: 0, // Reconciliation doesn't add parts
      goodParts: 0,
      scrapParts: 0,
      source: ProductionLogSource.reconciliation,
      reconciliationId: reconciliation.id,
    );

    await _productionLogsBox!.put(log.id, log.toMap());
    await SyncService.push(HiveBoxes.productionLogs, log.id, log.toMap());
  }

  // ============ LIVE COUNTER CALCULATION ============

  /// Calculate the current live counter for a job
  /// This is the core derivation that accounts for reconciliations
  static int calculateLiveCounter({
    required String jobId,
    required int startCounter,
    required DateTime jobStartTime,
    required double cycleTimeSeconds,
    List<CounterReconciliation>? reconciliations,
  }) {
    if (cycleTimeSeconds <= 0) return startCounter;

    // Get approved reconciliations for this job
    final jobReconciliations = reconciliations ??
        getReconciliationsForJob(jobId).where((r) => r.isApproved).toList();

    // Find the most recent reconciliation
    CounterReconciliation? latestReconciliation;
    for (final r in jobReconciliations) {
      if (latestReconciliation == null ||
          r.timestamp.isAfter(latestReconciliation.timestamp)) {
        latestReconciliation = r;
      }
    }

    // If there's a reconciliation, use it as the base
    int baseCounter;
    DateTime baseTime;

    if (latestReconciliation != null) {
      baseCounter = latestReconciliation.physicalCounter;
      baseTime = latestReconciliation.timestamp;
    } else {
      baseCounter = startCounter;
      baseTime = jobStartTime;
    }

    // Calculate cycles since base time
    final elapsedSeconds = DateTime.now().difference(baseTime).inSeconds;
    final cyclesCompleted = (elapsedSeconds / cycleTimeSeconds).floor();

    return baseCounter + cyclesCompleted;
  }

  /// Check if reconciliation is needed
  /// Returns the variance if significant, null otherwise
  static int? checkReconciliationNeeded({
    required int systemCounter,
    required int physicalCounter,
    double thresholdPercent = 5.0,
  }) {
    if (systemCounter == 0) return null;

    final variance = physicalCounter - systemCounter;
    final variancePercent = (variance.abs() / systemCounter) * 100;

    if (variancePercent > thresholdPercent) {
      return variance;
    }

    return null;
  }

  // ============ STATISTICS ============

  /// Get reconciliation statistics
  static ReconciliationStatistics getStatistics({DateTime? since}) {
    var reconciliations = getAllReconciliations();

    if (since != null) {
      reconciliations =
          reconciliations.where((r) => r.timestamp.isAfter(since)).toList();
    }

    final total = reconciliations.length;
    final approved = reconciliations.where((r) => r.isApproved).length;
    final rejected = reconciliations.where((r) => r.isRejected).length;
    final pending = reconciliations.where((r) => r.isPendingApproval).length;

    final variances = reconciliations.map((r) => r.variancePercent.abs()).toList();
    final avgVariance =
        variances.isEmpty ? 0.0 : variances.reduce((a, b) => a + b) / variances.length;

    final positiveVariances =
        reconciliations.where((r) => r.isPositiveVariance).length;
    final negativeVariances =
        reconciliations.where((r) => r.isNegativeVariance).length;

    return ReconciliationStatistics(
      total: total,
      approved: approved,
      rejected: rejected,
      pending: pending,
      averageVariancePercent: avgVariance,
      positiveVariances: positiveVariances,
      negativeVariances: negativeVariances,
    );
  }
}

/// Reconciliation statistics
class ReconciliationStatistics {
  final int total;
  final int approved;
  final int rejected;
  final int pending;
  final double averageVariancePercent;
  final int positiveVariances;
  final int negativeVariances;

  ReconciliationStatistics({
    required this.total,
    required this.approved,
    required this.rejected,
    required this.pending,
    required this.averageVariancePercent,
    required this.positiveVariances,
    required this.negativeVariances,
  });

  /// Approval rate
  double get approvalRate => total > 0 ? (approved / total) * 100 : 0;

  /// Rejection rate
  double get rejectionRate => total > 0 ? (rejected / total) * 100 : 0;
}
