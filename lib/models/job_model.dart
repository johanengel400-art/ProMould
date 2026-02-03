/// ProMould Job Model
/// Complete job entity with production tracking

import '../core/constants.dart';

class Job {
  final String id;
  final String jobNumber;
  final String partNumber;
  final String? partDescription;
  final String? customerId;
  final String? customerName;
  final String? orderNumber;
  final int quantityRequired;
  final int priority; // 1-5, 1 is highest
  final DateTime? dueDate;
  final JobStatus status;
  final String mouldId;
  final String? materialId;
  final double? materialQuantityRequired;
  final double targetCycleTime; // seconds
  final DateTime createdAt;
  final DateTime updatedAt;

  // Set on job events (stored)
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? pausedAt;
  final int? startCounter; // Machine counter at job start

  // Current assignment (stored)
  final String? machineId;
  final int? queuePosition;

  // Notes and metadata
  final String? notes;
  final Map<String, dynamic>? metadata;

  Job({
    required this.id,
    required this.jobNumber,
    required this.partNumber,
    this.partDescription,
    this.customerId,
    this.customerName,
    this.orderNumber,
    required this.quantityRequired,
    this.priority = 3,
    this.dueDate,
    this.status = JobStatus.pending,
    required this.mouldId,
    this.materialId,
    this.materialQuantityRequired,
    required this.targetCycleTime,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.pausedAt,
    this.startCounter,
    this.machineId,
    this.queuePosition,
    this.notes,
    this.metadata,
  });

  // ============ DERIVED STATE (never stored) ============
  // These are calculated at runtime from other data sources

  /// Check if job is active (running or paused)
  bool get isActive => status.isActive;

  /// Check if job can be started
  bool get canStart => status.canStart;

  /// Check if job is in a final state
  bool get isFinal => status.isFinal;

  /// Check if job is assigned to a machine
  bool get isAssigned => machineId != null;

  /// Get elapsed time since start
  Duration? get elapsedTime {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  /// Priority display
  String get priorityDisplay {
    switch (priority) {
      case 1:
        return 'Critical';
      case 2:
        return 'High';
      case 3:
        return 'Medium';
      case 4:
        return 'Low';
      case 5:
        return 'Very Low';
      default:
        return 'Medium';
    }
  }

  // ============ METHODS ============

  /// Create a copy with updated fields
  Job copyWith({
    String? id,
    String? jobNumber,
    String? partNumber,
    String? partDescription,
    String? customerId,
    String? customerName,
    String? orderNumber,
    int? quantityRequired,
    int? priority,
    DateTime? dueDate,
    JobStatus? status,
    String? mouldId,
    String? materialId,
    double? materialQuantityRequired,
    double? targetCycleTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? pausedAt,
    int? startCounter,
    String? machineId,
    int? queuePosition,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Job(
      id: id ?? this.id,
      jobNumber: jobNumber ?? this.jobNumber,
      partNumber: partNumber ?? this.partNumber,
      partDescription: partDescription ?? this.partDescription,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      orderNumber: orderNumber ?? this.orderNumber,
      quantityRequired: quantityRequired ?? this.quantityRequired,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      mouldId: mouldId ?? this.mouldId,
      materialId: materialId ?? this.materialId,
      materialQuantityRequired:
          materialQuantityRequired ?? this.materialQuantityRequired,
      targetCycleTime: targetCycleTime ?? this.targetCycleTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      startCounter: startCounter ?? this.startCounter,
      machineId: machineId ?? this.machineId,
      queuePosition: queuePosition ?? this.queuePosition,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Start the job
  Job start({required int machineCounter}) {
    return copyWith(
      status: JobStatus.running,
      startedAt: DateTime.now(),
      startCounter: machineCounter,
      pausedAt: null,
    );
  }

  /// Pause the job
  Job pause() {
    return copyWith(
      status: JobStatus.paused,
      pausedAt: DateTime.now(),
    );
  }

  /// Resume the job
  Job resume() {
    return copyWith(
      status: JobStatus.running,
      pausedAt: null,
    );
  }

  /// Complete the job
  Job complete() {
    return copyWith(
      status: JobStatus.complete,
      completedAt: DateTime.now(),
    );
  }

  /// Put job on hold
  Job putOnHold() {
    return copyWith(
      status: JobStatus.onHold,
    );
  }

  /// Release job from hold
  Job releaseFromHold() {
    return copyWith(
      status: startedAt != null ? JobStatus.running : JobStatus.queued,
    );
  }

  /// Cancel the job
  Job cancel() {
    return copyWith(
      status: JobStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  /// Assign to machine
  Job assignToMachine(String machineId, {int? queuePosition}) {
    return copyWith(
      machineId: machineId,
      queuePosition: queuePosition,
      status: status == JobStatus.pending ? JobStatus.queued : status,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'jobNumber': jobNumber,
        'partNumber': partNumber,
        'partDescription': partDescription,
        'customerId': customerId,
        'customerName': customerName,
        'orderNumber': orderNumber,
        'quantityRequired': quantityRequired,
        'priority': priority,
        'dueDate': dueDate?.toIso8601String(),
        'status': status.name,
        'mouldId': mouldId,
        'materialId': materialId,
        'materialQuantityRequired': materialQuantityRequired,
        'targetCycleTime': targetCycleTime,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'pausedAt': pausedAt?.toIso8601String(),
        'startCounter': startCounter,
        'machineId': machineId,
        'queuePosition': queuePosition,
        'notes': notes,
        'metadata': metadata,
      };

  /// Create from map
  factory Job.fromMap(Map<String, dynamic> map) => Job(
        id: map['id'] as String,
        jobNumber: map['jobNumber'] as String? ?? map['id'] as String,
        partNumber: map['partNumber'] as String? ?? '',
        partDescription: map['partDescription'] as String?,
        customerId: map['customerId'] as String?,
        customerName: map['customerName'] as String?,
        orderNumber: map['orderNumber'] as String?,
        quantityRequired: map['quantityRequired'] as int? ?? 0,
        priority: map['priority'] as int? ?? 3,
        dueDate: _parseDateTime(map['dueDate']),
        status: _parseStatus(map['status']),
        mouldId: map['mouldId'] as String? ?? '',
        materialId: map['materialId'] as String?,
        materialQuantityRequired: _parseDouble(map['materialQuantityRequired']),
        targetCycleTime: _parseDouble(map['targetCycleTime']) ?? 30.0,
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        startedAt: _parseDateTime(map['startedAt']),
        completedAt: _parseDateTime(map['completedAt']),
        pausedAt: _parseDateTime(map['pausedAt']),
        startCounter: map['startCounter'] as int?,
        machineId: map['machineId'] as String?,
        queuePosition: map['queuePosition'] as int?,
        notes: map['notes'] as String?,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static JobStatus _parseStatus(dynamic value) {
    if (value == null) return JobStatus.pending;
    if (value is JobStatus) return value;
    if (value is String) {
      return JobStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => JobStatus.pending,
      );
    }
    return JobStatus.pending;
  }

  @override
  String toString() => 'Job($jobNumber, $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Job && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Job with derived state (for UI display)
/// This class adds computed properties that should never be stored
class JobWithState {
  final Job job;

  // Derived from mould
  final String? mouldNumber;
  final String? mouldName;
  final int? cavities;

  // Derived from machine
  final String? machineName;

  // Derived from operator assignment
  final String? operatorId;
  final String? operatorName;

  // Derived from production logs
  final int quantityProduced;
  final int scrapQuantity;

  // Derived from current counter
  final int? currentCounter;

  // Calculated values
  final double? actualCycleTime;

  JobWithState({
    required this.job,
    this.mouldNumber,
    this.mouldName,
    this.cavities,
    this.machineName,
    this.operatorId,
    this.operatorName,
    this.quantityProduced = 0,
    this.scrapQuantity = 0,
    this.currentCounter,
    this.actualCycleTime,
  });

  // Convenience getters
  String get id => job.id;
  String get jobNumber => job.jobNumber;
  JobStatus get status => job.status;
  int get quantityRequired => job.quantityRequired;
  double get targetCycleTime => job.targetCycleTime;
  DateTime? get dueDate => job.dueDate;
  DateTime? get startedAt => job.startedAt;

  /// Quantity remaining
  int get quantityRemaining => quantityRequired - quantityProduced;

  /// Progress percentage
  double get progressPercentage =>
      quantityRequired > 0 ? (quantityProduced / quantityRequired) * 100 : 0;

  /// Scrap rate
  double get scrapRate {
    final total = quantityProduced + scrapQuantity;
    return total > 0 ? (scrapQuantity / total) * 100 : 0;
  }

  /// Good parts (produced minus scrap)
  int get goodParts => quantityProduced - scrapQuantity;

  /// Cycle time variance
  double? get cycleTimeVariance {
    if (actualCycleTime == null) return null;
    return actualCycleTime! - targetCycleTime;
  }

  /// Cycle time variance percentage
  double? get cycleTimeVariancePercent {
    if (actualCycleTime == null || targetCycleTime == 0) return null;
    return ((actualCycleTime! - targetCycleTime) / targetCycleTime) * 100;
  }

  /// ETA calculation
  DateTime? get eta {
    if (job.startedAt == null || quantityProduced == 0) return null;
    if (quantityRemaining <= 0) return DateTime.now();

    final elapsed = DateTime.now().difference(job.startedAt!);
    final partsPerSecond = quantityProduced / elapsed.inSeconds;
    if (partsPerSecond <= 0) return null;

    final remainingSeconds = quantityRemaining / partsPerSecond;
    return DateTime.now().add(Duration(seconds: remainingSeconds.round()));
  }

  /// Is job overrunning (ETA past due date)
  bool get isOverrunning {
    if (dueDate == null || eta == null) return false;
    return eta!.isAfter(dueDate!);
  }

  /// Time until due
  Duration? get timeUntilDue {
    if (dueDate == null) return null;
    return dueDate!.difference(DateTime.now());
  }

  /// Is due soon (within 24 hours)
  bool get isDueSoon {
    final remaining = timeUntilDue;
    if (remaining == null) return false;
    return remaining.inHours <= 24 && remaining.inHours > 0;
  }

  /// Is overdue
  bool get isOverdue {
    final remaining = timeUntilDue;
    if (remaining == null) return false;
    return remaining.isNegative;
  }

  /// Scrap rate status
  String get scrapRateStatus {
    if (scrapRate < SystemThresholds.scrapExcellent) return 'excellent';
    if (scrapRate < SystemThresholds.scrapAcceptable) return 'acceptable';
    if (scrapRate < SystemThresholds.scrapConcerning) return 'concerning';
    return 'critical';
  }

  /// Cycle time status
  String get cycleTimeStatus {
    final variance = cycleTimeVariancePercent;
    if (variance == null) return 'unknown';
    if (variance.abs() <= 5) return 'onTarget';
    if (variance < 0) return 'faster';
    if (variance <= SystemThresholds.cycleTimeDeviationThreshold) return 'slower';
    return 'critical';
  }
}
