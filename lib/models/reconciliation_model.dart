/// ProMould Counter Reconciliation Model
/// Handles manual counter reconciliation with audit trail

import '../core/constants.dart';

class CounterReconciliation {
  final String id;
  final String machineId;
  final String jobId;
  final DateTime timestamp;
  final int systemCounter; // What the system calculated
  final int physicalCounter; // What the physical counter shows
  final int variance; // physicalCounter - systemCounter
  final double variancePercent;
  final String reason; // REQUIRED - why the variance occurred
  final String reconciledById;
  final String reconciledByName;
  final String? approvedById; // Required if variance > threshold
  final String? approvedByName;
  final DateTime? approvedAt;
  final ReconciliationStatus status;
  final Map<String, dynamic>? metadata;

  CounterReconciliation({
    required this.id,
    required this.machineId,
    required this.jobId,
    required this.timestamp,
    required this.systemCounter,
    required this.physicalCounter,
    required this.variance,
    required this.variancePercent,
    required this.reason,
    required this.reconciledById,
    required this.reconciledByName,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
    this.status = ReconciliationStatus.pending,
    this.metadata,
  });

  // ============ DERIVED STATE ============

  /// Does this reconciliation require approval?
  bool get requiresApproval =>
      variancePercent.abs() > SystemThresholds.counterVarianceThreshold;

  /// Is reconciliation approved?
  bool get isApproved => status == ReconciliationStatus.approved;

  /// Is reconciliation pending approval?
  bool get isPendingApproval =>
      status == ReconciliationStatus.pending && requiresApproval;

  /// Is reconciliation rejected?
  bool get isRejected => status == ReconciliationStatus.rejected;

  /// Is variance positive (physical > system)?
  bool get isPositiveVariance => variance > 0;

  /// Is variance negative (physical < system)?
  bool get isNegativeVariance => variance < 0;

  /// Variance severity
  String get varianceSeverity {
    final absPercent = variancePercent.abs();
    if (absPercent <= 2) return 'minor';
    if (absPercent <= 5) return 'moderate';
    if (absPercent <= 10) return 'significant';
    return 'critical';
  }

  // ============ METHODS ============

  /// Create a copy with updated fields
  CounterReconciliation copyWith({
    String? id,
    String? machineId,
    String? jobId,
    DateTime? timestamp,
    int? systemCounter,
    int? physicalCounter,
    int? variance,
    double? variancePercent,
    String? reason,
    String? reconciledById,
    String? reconciledByName,
    String? approvedById,
    String? approvedByName,
    DateTime? approvedAt,
    ReconciliationStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return CounterReconciliation(
      id: id ?? this.id,
      machineId: machineId ?? this.machineId,
      jobId: jobId ?? this.jobId,
      timestamp: timestamp ?? this.timestamp,
      systemCounter: systemCounter ?? this.systemCounter,
      physicalCounter: physicalCounter ?? this.physicalCounter,
      variance: variance ?? this.variance,
      variancePercent: variancePercent ?? this.variancePercent,
      reason: reason ?? this.reason,
      reconciledById: reconciledById ?? this.reconciledById,
      reconciledByName: reconciledByName ?? this.reconciledByName,
      approvedById: approvedById ?? this.approvedById,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Approve the reconciliation
  CounterReconciliation approve(String userId, String userName) {
    return copyWith(
      status: ReconciliationStatus.approved,
      approvedById: userId,
      approvedByName: userName,
      approvedAt: DateTime.now(),
    );
  }

  /// Reject the reconciliation
  CounterReconciliation reject(String userId, String userName) {
    return copyWith(
      status: ReconciliationStatus.rejected,
      approvedById: userId,
      approvedByName: userName,
      approvedAt: DateTime.now(),
    );
  }

  /// Auto-approve (for small variances)
  CounterReconciliation autoApprove() {
    return copyWith(
      status: ReconciliationStatus.approved,
      approvedById: 'system',
      approvedByName: 'Auto-approved',
      approvedAt: DateTime.now(),
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'machineId': machineId,
        'jobId': jobId,
        'timestamp': timestamp.toIso8601String(),
        'systemCounter': systemCounter,
        'physicalCounter': physicalCounter,
        'variance': variance,
        'variancePercent': variancePercent,
        'reason': reason,
        'reconciledById': reconciledById,
        'reconciledByName': reconciledByName,
        'approvedById': approvedById,
        'approvedByName': approvedByName,
        'approvedAt': approvedAt?.toIso8601String(),
        'status': status.name,
        'metadata': metadata,
      };

  /// Create from map
  factory CounterReconciliation.fromMap(Map<String, dynamic> map) =>
      CounterReconciliation(
        id: map['id'] as String,
        machineId: map['machineId'] as String,
        jobId: map['jobId'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        systemCounter: map['systemCounter'] as int,
        physicalCounter: map['physicalCounter'] as int,
        variance: map['variance'] as int,
        variancePercent: (map['variancePercent'] as num).toDouble(),
        reason: map['reason'] as String,
        reconciledById: map['reconciledById'] as String,
        reconciledByName: map['reconciledByName'] as String,
        approvedById: map['approvedById'] as String?,
        approvedByName: map['approvedByName'] as String?,
        approvedAt: map['approvedAt'] != null
            ? DateTime.parse(map['approvedAt'] as String)
            : null,
        status: ReconciliationStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => ReconciliationStatus.pending,
        ),
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  /// Create a new reconciliation
  factory CounterReconciliation.create({
    required String id,
    required String machineId,
    required String jobId,
    required int systemCounter,
    required int physicalCounter,
    required String reason,
    required String reconciledById,
    required String reconciledByName,
  }) {
    final variance = physicalCounter - systemCounter;
    final variancePercent =
        systemCounter > 0 ? (variance / systemCounter) * 100 : 0.0;

    final reconciliation = CounterReconciliation(
      id: id,
      machineId: machineId,
      jobId: jobId,
      timestamp: DateTime.now(),
      systemCounter: systemCounter,
      physicalCounter: physicalCounter,
      variance: variance,
      variancePercent: variancePercent,
      reason: reason,
      reconciledById: reconciledById,
      reconciledByName: reconciledByName,
    );

    // Auto-approve if variance is within threshold
    if (!reconciliation.requiresApproval) {
      return reconciliation.autoApprove();
    }

    return reconciliation;
  }

  @override
  String toString() =>
      'CounterReconciliation($id, variance: $variance, status: $status)';
}

/// Reconciliation status
enum ReconciliationStatus {
  pending('Pending Approval'),
  approved('Approved'),
  rejected('Rejected');

  final String displayName;
  const ReconciliationStatus(this.displayName);
}

/// Production log entry (append-only)
class ProductionLog {
  final String id;
  final String jobId;
  final String machineId;
  final String mouldId;
  final String operatorId;
  final String operatorName;
  final String shiftId;
  final DateTime timestamp;
  final int counterValue;
  final int partsProduced;
  final int goodParts;
  final int scrapParts;
  final double? cycleTime;
  final ProductionLogSource source;
  final String? reconciliationId; // If this log was created from reconciliation

  ProductionLog({
    required this.id,
    required this.jobId,
    required this.machineId,
    required this.mouldId,
    required this.operatorId,
    required this.operatorName,
    required this.shiftId,
    required this.timestamp,
    required this.counterValue,
    required this.partsProduced,
    required this.goodParts,
    required this.scrapParts,
    this.cycleTime,
    required this.source,
    this.reconciliationId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobId': jobId,
        'machineId': machineId,
        'mouldId': mouldId,
        'operatorId': operatorId,
        'operatorName': operatorName,
        'shiftId': shiftId,
        'timestamp': timestamp.toIso8601String(),
        'counterValue': counterValue,
        'partsProduced': partsProduced,
        'goodParts': goodParts,
        'scrapParts': scrapParts,
        'cycleTime': cycleTime,
        'source': source.name,
        'reconciliationId': reconciliationId,
      };

  factory ProductionLog.fromMap(Map<String, dynamic> map) => ProductionLog(
        id: map['id'] as String,
        jobId: map['jobId'] as String,
        machineId: map['machineId'] as String,
        mouldId: map['mouldId'] as String,
        operatorId: map['operatorId'] as String,
        operatorName: map['operatorName'] as String,
        shiftId: map['shiftId'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        counterValue: map['counterValue'] as int,
        partsProduced: map['partsProduced'] as int,
        goodParts: map['goodParts'] as int,
        scrapParts: map['scrapParts'] as int,
        cycleTime: (map['cycleTime'] as num?)?.toDouble(),
        source: ProductionLogSource.values.firstWhere(
          (s) => s.name == map['source'],
          orElse: () => ProductionLogSource.automatic,
        ),
        reconciliationId: map['reconciliationId'] as String?,
      );
}

/// Production log source
enum ProductionLogSource {
  automatic('Automatic'),
  manual('Manual Entry'),
  reconciliation('Reconciliation');

  final String displayName;
  const ProductionLogSource(this.displayName);
}

/// Scrap log entry (append-only)
class ScrapLog {
  final String id;
  final String jobId;
  final String machineId;
  final String mouldId;
  final String operatorId;
  final String operatorName;
  final String shiftId;
  final DateTime timestamp;
  final int quantity;
  final String reasonCode;
  final String? reasonDescription;
  final String? defectType;
  final int? cavityNumber;
  final String? notes;

  ScrapLog({
    required this.id,
    required this.jobId,
    required this.machineId,
    required this.mouldId,
    required this.operatorId,
    required this.operatorName,
    required this.shiftId,
    required this.timestamp,
    required this.quantity,
    required this.reasonCode,
    this.reasonDescription,
    this.defectType,
    this.cavityNumber,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobId': jobId,
        'machineId': machineId,
        'mouldId': mouldId,
        'operatorId': operatorId,
        'operatorName': operatorName,
        'shiftId': shiftId,
        'timestamp': timestamp.toIso8601String(),
        'quantity': quantity,
        'reasonCode': reasonCode,
        'reasonDescription': reasonDescription,
        'defectType': defectType,
        'cavityNumber': cavityNumber,
        'notes': notes,
      };

  factory ScrapLog.fromMap(Map<String, dynamic> map) => ScrapLog(
        id: map['id'] as String,
        jobId: map['jobId'] as String,
        machineId: map['machineId'] as String,
        mouldId: map['mouldId'] as String,
        operatorId: map['operatorId'] as String,
        operatorName: map['operatorName'] as String,
        shiftId: map['shiftId'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String),
        quantity: map['quantity'] as int,
        reasonCode: map['reasonCode'] as String,
        reasonDescription: map['reasonDescription'] as String?,
        defectType: map['defectType'] as String?,
        cavityNumber: map['cavityNumber'] as int?,
        notes: map['notes'] as String?,
      );
}

/// Downtime log entry
class DowntimeLog {
  final String id;
  final String machineId;
  final String? jobId;
  final String operatorId;
  final String operatorName;
  final String shiftId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final String reasonCode;
  final String? reasonDescription;
  final String? subReasonCode;
  final bool isPlanned;
  final String? notes;
  final DowntimeStatus status;

  DowntimeLog({
    required this.id,
    required this.machineId,
    this.jobId,
    required this.operatorId,
    required this.operatorName,
    required this.shiftId,
    required this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.reasonCode,
    this.reasonDescription,
    this.subReasonCode,
    required this.isPlanned,
    this.notes,
    this.status = DowntimeStatus.active,
  });

  /// Is downtime currently active
  bool get isActive => status == DowntimeStatus.active;

  /// Current duration (if active, calculate from start)
  int get currentDurationMinutes {
    if (durationMinutes != null) return durationMinutes!;
    return DateTime.now().difference(startTime).inMinutes;
  }

  /// End the downtime
  DowntimeLog end() {
    final now = DateTime.now();
    return DowntimeLog(
      id: id,
      machineId: machineId,
      jobId: jobId,
      operatorId: operatorId,
      operatorName: operatorName,
      shiftId: shiftId,
      startTime: startTime,
      endTime: now,
      durationMinutes: now.difference(startTime).inMinutes,
      reasonCode: reasonCode,
      reasonDescription: reasonDescription,
      subReasonCode: subReasonCode,
      isPlanned: isPlanned,
      notes: notes,
      status: DowntimeStatus.ended,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'machineId': machineId,
        'jobId': jobId,
        'operatorId': operatorId,
        'operatorName': operatorName,
        'shiftId': shiftId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'durationMinutes': durationMinutes,
        'reasonCode': reasonCode,
        'reasonDescription': reasonDescription,
        'subReasonCode': subReasonCode,
        'isPlanned': isPlanned,
        'notes': notes,
        'status': status.name,
      };

  factory DowntimeLog.fromMap(Map<String, dynamic> map) => DowntimeLog(
        id: map['id'] as String,
        machineId: map['machineId'] as String,
        jobId: map['jobId'] as String?,
        operatorId: map['operatorId'] as String,
        operatorName: map['operatorName'] as String,
        shiftId: map['shiftId'] as String,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: map['endTime'] != null
            ? DateTime.parse(map['endTime'] as String)
            : null,
        durationMinutes: map['durationMinutes'] as int?,
        reasonCode: map['reasonCode'] as String,
        reasonDescription: map['reasonDescription'] as String?,
        subReasonCode: map['subReasonCode'] as String?,
        isPlanned: map['isPlanned'] as bool,
        notes: map['notes'] as String?,
        status: DowntimeStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => DowntimeStatus.active,
        ),
      );
}

/// Downtime status
enum DowntimeStatus {
  active('Active'),
  ended('Ended');

  final String displayName;
  const DowntimeStatus(this.displayName);
}
