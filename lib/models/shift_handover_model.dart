/// ProMould Shift Handover Model
/// Immutable shift handover with snapshot

import '../core/constants.dart';

class ShiftHandover {
  final String id;
  final String shiftId;
  final DateTime handoverDate;
  final String outgoingUserId;
  final String outgoingUserName;
  final String? incomingUserId;
  final String? incomingUserName;
  final HandoverStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;

  // Immutable snapshot (stored as JSON, never modified after creation)
  final HandoverSnapshot? snapshot;

  // Handover notes
  final String? notes;
  final String? safetyNotes;
  final String? specialInstructions;

  // Sign-offs
  final bool outgoingSignOff;
  final DateTime? outgoingSignOffAt;
  final bool incomingAcknowledgment;
  final DateTime? incomingAcknowledgmentAt;

  final DateTime createdAt;

  ShiftHandover({
    required this.id,
    required this.shiftId,
    required this.handoverDate,
    required this.outgoingUserId,
    required this.outgoingUserName,
    this.incomingUserId,
    this.incomingUserName,
    this.status = HandoverStatus.pending,
    this.startedAt,
    this.completedAt,
    this.snapshot,
    this.notes,
    this.safetyNotes,
    this.specialInstructions,
    this.outgoingSignOff = false,
    this.outgoingSignOffAt,
    this.incomingAcknowledgment = false,
    this.incomingAcknowledgmentAt,
    required this.createdAt,
  });

  // ============ DERIVED STATE ============

  /// Is handover complete
  bool get isComplete => status == HandoverStatus.complete;

  /// Is handover in progress
  bool get isInProgress => status == HandoverStatus.inProgress;

  /// Is handover pending
  bool get isPending => status == HandoverStatus.pending;

  /// Is handover skipped
  bool get isSkipped => status == HandoverStatus.skipped;

  /// Duration of handover
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Is fully signed off
  bool get isFullySignedOff => outgoingSignOff && incomingAcknowledgment;

  // ============ METHODS ============

  /// Create a copy with updated fields
  ShiftHandover copyWith({
    String? id,
    String? shiftId,
    DateTime? handoverDate,
    String? outgoingUserId,
    String? outgoingUserName,
    String? incomingUserId,
    String? incomingUserName,
    HandoverStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    HandoverSnapshot? snapshot,
    String? notes,
    String? safetyNotes,
    String? specialInstructions,
    bool? outgoingSignOff,
    DateTime? outgoingSignOffAt,
    bool? incomingAcknowledgment,
    DateTime? incomingAcknowledgmentAt,
    DateTime? createdAt,
  }) {
    return ShiftHandover(
      id: id ?? this.id,
      shiftId: shiftId ?? this.shiftId,
      handoverDate: handoverDate ?? this.handoverDate,
      outgoingUserId: outgoingUserId ?? this.outgoingUserId,
      outgoingUserName: outgoingUserName ?? this.outgoingUserName,
      incomingUserId: incomingUserId ?? this.incomingUserId,
      incomingUserName: incomingUserName ?? this.incomingUserName,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      snapshot: snapshot ?? this.snapshot,
      notes: notes ?? this.notes,
      safetyNotes: safetyNotes ?? this.safetyNotes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      outgoingSignOff: outgoingSignOff ?? this.outgoingSignOff,
      outgoingSignOffAt: outgoingSignOffAt ?? this.outgoingSignOffAt,
      incomingAcknowledgment:
          incomingAcknowledgment ?? this.incomingAcknowledgment,
      incomingAcknowledgmentAt:
          incomingAcknowledgmentAt ?? this.incomingAcknowledgmentAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Start the handover
  ShiftHandover start(HandoverSnapshot snapshot) {
    return copyWith(
      status: HandoverStatus.inProgress,
      startedAt: DateTime.now(),
      snapshot: snapshot,
    );
  }

  /// Outgoing user signs off
  ShiftHandover signOffOutgoing() {
    return copyWith(
      outgoingSignOff: true,
      outgoingSignOffAt: DateTime.now(),
    );
  }

  /// Incoming user acknowledges
  ShiftHandover acknowledgeIncoming(String userId, String userName) {
    final updated = copyWith(
      incomingUserId: userId,
      incomingUserName: userName,
      incomingAcknowledgment: true,
      incomingAcknowledgmentAt: DateTime.now(),
    );

    // Auto-complete if both signed off
    if (updated.outgoingSignOff && updated.incomingAcknowledgment) {
      return updated.copyWith(
        status: HandoverStatus.complete,
        completedAt: DateTime.now(),
      );
    }

    return updated;
  }

  /// Skip the handover (with audit)
  ShiftHandover skip() {
    return copyWith(
      status: HandoverStatus.skipped,
      completedAt: DateTime.now(),
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'shiftId': shiftId,
        'handoverDate': handoverDate.toIso8601String(),
        'outgoingUserId': outgoingUserId,
        'outgoingUserName': outgoingUserName,
        'incomingUserId': incomingUserId,
        'incomingUserName': incomingUserName,
        'status': status.name,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'snapshot': snapshot?.toMap(),
        'notes': notes,
        'safetyNotes': safetyNotes,
        'specialInstructions': specialInstructions,
        'outgoingSignOff': outgoingSignOff,
        'outgoingSignOffAt': outgoingSignOffAt?.toIso8601String(),
        'incomingAcknowledgment': incomingAcknowledgment,
        'incomingAcknowledgmentAt': incomingAcknowledgmentAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  /// Create from map
  factory ShiftHandover.fromMap(Map<String, dynamic> map) => ShiftHandover(
        id: map['id'] as String,
        shiftId: map['shiftId'] as String,
        handoverDate: DateTime.parse(map['handoverDate'] as String),
        outgoingUserId: map['outgoingUserId'] as String,
        outgoingUserName: map['outgoingUserName'] as String,
        incomingUserId: map['incomingUserId'] as String?,
        incomingUserName: map['incomingUserName'] as String?,
        status: HandoverStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => HandoverStatus.pending,
        ),
        startedAt: _parseDateTime(map['startedAt']),
        completedAt: _parseDateTime(map['completedAt']),
        snapshot: map['snapshot'] != null
            ? HandoverSnapshot.fromMap(
                Map<String, dynamic>.from(map['snapshot']))
            : null,
        notes: map['notes'] as String?,
        safetyNotes: map['safetyNotes'] as String?,
        specialInstructions: map['specialInstructions'] as String?,
        outgoingSignOff: map['outgoingSignOff'] as bool? ?? false,
        outgoingSignOffAt: _parseDateTime(map['outgoingSignOffAt']),
        incomingAcknowledgment: map['incomingAcknowledgment'] as bool? ?? false,
        incomingAcknowledgmentAt:
            _parseDateTime(map['incomingAcknowledgmentAt']),
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'ShiftHandover($id, $status)';
}

/// Handover status
enum HandoverStatus {
  pending('Pending'),
  inProgress('In Progress'),
  complete('Complete'),
  skipped('Skipped');

  final String displayName;
  const HandoverStatus(this.displayName);
}

/// Immutable snapshot of factory state at handover time
class HandoverSnapshot {
  final DateTime capturedAt;
  final List<MachineSnapshot> machines;
  final List<JobSnapshot> jobs;
  final List<IssueSnapshot> openIssues;
  final List<TaskSnapshot> pendingTasks;
  final List<QualityHoldSnapshot> qualityHolds;
  final List<MaterialSnapshot> materialStatus;
  final List<MaintenanceSnapshot> maintenanceStatus;
  final ProductionSummary productionSummary;

  const HandoverSnapshot({
    required this.capturedAt,
    required this.machines,
    required this.jobs,
    required this.openIssues,
    required this.pendingTasks,
    required this.qualityHolds,
    required this.materialStatus,
    required this.maintenanceStatus,
    required this.productionSummary,
  });

  Map<String, dynamic> toMap() => {
        'capturedAt': capturedAt.toIso8601String(),
        'machines': machines.map((m) => m.toMap()).toList(),
        'jobs': jobs.map((j) => j.toMap()).toList(),
        'openIssues': openIssues.map((i) => i.toMap()).toList(),
        'pendingTasks': pendingTasks.map((t) => t.toMap()).toList(),
        'qualityHolds': qualityHolds.map((q) => q.toMap()).toList(),
        'materialStatus': materialStatus.map((m) => m.toMap()).toList(),
        'maintenanceStatus': maintenanceStatus.map((m) => m.toMap()).toList(),
        'productionSummary': productionSummary.toMap(),
      };

  factory HandoverSnapshot.fromMap(Map<String, dynamic> map) => HandoverSnapshot(
        capturedAt: DateTime.parse(map['capturedAt'] as String),
        machines: (map['machines'] as List?)
                ?.map((m) => MachineSnapshot.fromMap(Map<String, dynamic>.from(m)))
                .toList() ??
            [],
        jobs: (map['jobs'] as List?)
                ?.map((j) => JobSnapshot.fromMap(Map<String, dynamic>.from(j)))
                .toList() ??
            [],
        openIssues: (map['openIssues'] as List?)
                ?.map((i) => IssueSnapshot.fromMap(Map<String, dynamic>.from(i)))
                .toList() ??
            [],
        pendingTasks: (map['pendingTasks'] as List?)
                ?.map((t) => TaskSnapshot.fromMap(Map<String, dynamic>.from(t)))
                .toList() ??
            [],
        qualityHolds: (map['qualityHolds'] as List?)
                ?.map(
                    (q) => QualityHoldSnapshot.fromMap(Map<String, dynamic>.from(q)))
                .toList() ??
            [],
        materialStatus: (map['materialStatus'] as List?)
                ?.map(
                    (m) => MaterialSnapshot.fromMap(Map<String, dynamic>.from(m)))
                .toList() ??
            [],
        maintenanceStatus: (map['maintenanceStatus'] as List?)
                ?.map((m) =>
                    MaintenanceSnapshot.fromMap(Map<String, dynamic>.from(m)))
                .toList() ??
            [],
        productionSummary: ProductionSummary.fromMap(
            Map<String, dynamic>.from(map['productionSummary'] ?? {})),
      );
}

/// Machine snapshot for handover
class MachineSnapshot {
  final String machineId;
  final String machineName;
  final String status;
  final String? currentJobNumber;
  final String? currentMouldNumber;
  final int? partsProduced;
  final double? scrapRate;

  const MachineSnapshot({
    required this.machineId,
    required this.machineName,
    required this.status,
    this.currentJobNumber,
    this.currentMouldNumber,
    this.partsProduced,
    this.scrapRate,
  });

  Map<String, dynamic> toMap() => {
        'machineId': machineId,
        'machineName': machineName,
        'status': status,
        'currentJobNumber': currentJobNumber,
        'currentMouldNumber': currentMouldNumber,
        'partsProduced': partsProduced,
        'scrapRate': scrapRate,
      };

  factory MachineSnapshot.fromMap(Map<String, dynamic> map) => MachineSnapshot(
        machineId: map['machineId'] as String,
        machineName: map['machineName'] as String,
        status: map['status'] as String,
        currentJobNumber: map['currentJobNumber'] as String?,
        currentMouldNumber: map['currentMouldNumber'] as String?,
        partsProduced: map['partsProduced'] as int?,
        scrapRate: (map['scrapRate'] as num?)?.toDouble(),
      );
}

/// Job snapshot for handover
class JobSnapshot {
  final String jobId;
  final String jobNumber;
  final String status;
  final int quantityRequired;
  final int quantityProduced;
  final double progressPercentage;

  const JobSnapshot({
    required this.jobId,
    required this.jobNumber,
    required this.status,
    required this.quantityRequired,
    required this.quantityProduced,
    required this.progressPercentage,
  });

  Map<String, dynamic> toMap() => {
        'jobId': jobId,
        'jobNumber': jobNumber,
        'status': status,
        'quantityRequired': quantityRequired,
        'quantityProduced': quantityProduced,
        'progressPercentage': progressPercentage,
      };

  factory JobSnapshot.fromMap(Map<String, dynamic> map) => JobSnapshot(
        jobId: map['jobId'] as String,
        jobNumber: map['jobNumber'] as String,
        status: map['status'] as String,
        quantityRequired: map['quantityRequired'] as int,
        quantityProduced: map['quantityProduced'] as int,
        progressPercentage: (map['progressPercentage'] as num).toDouble(),
      );
}

/// Issue snapshot for handover
class IssueSnapshot {
  final String issueId;
  final String title;
  final String severity;
  final String? machineName;

  const IssueSnapshot({
    required this.issueId,
    required this.title,
    required this.severity,
    this.machineName,
  });

  Map<String, dynamic> toMap() => {
        'issueId': issueId,
        'title': title,
        'severity': severity,
        'machineName': machineName,
      };

  factory IssueSnapshot.fromMap(Map<String, dynamic> map) => IssueSnapshot(
        issueId: map['issueId'] as String,
        title: map['title'] as String,
        severity: map['severity'] as String,
        machineName: map['machineName'] as String?,
      );
}

/// Task snapshot for handover
class TaskSnapshot {
  final String taskId;
  final String title;
  final String priority;
  final String? assigneeName;
  final bool isOverdue;

  const TaskSnapshot({
    required this.taskId,
    required this.title,
    required this.priority,
    this.assigneeName,
    required this.isOverdue,
  });

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'title': title,
        'priority': priority,
        'assigneeName': assigneeName,
        'isOverdue': isOverdue,
      };

  factory TaskSnapshot.fromMap(Map<String, dynamic> map) => TaskSnapshot(
        taskId: map['taskId'] as String,
        title: map['title'] as String,
        priority: map['priority'] as String,
        assigneeName: map['assigneeName'] as String?,
        isOverdue: map['isOverdue'] as bool,
      );
}

/// Quality hold snapshot for handover
class QualityHoldSnapshot {
  final String holdId;
  final String jobNumber;
  final String reason;
  final int quantity;
  final String severity;

  const QualityHoldSnapshot({
    required this.holdId,
    required this.jobNumber,
    required this.reason,
    required this.quantity,
    required this.severity,
  });

  Map<String, dynamic> toMap() => {
        'holdId': holdId,
        'jobNumber': jobNumber,
        'reason': reason,
        'quantity': quantity,
        'severity': severity,
      };

  factory QualityHoldSnapshot.fromMap(Map<String, dynamic> map) =>
      QualityHoldSnapshot(
        holdId: map['holdId'] as String,
        jobNumber: map['jobNumber'] as String,
        reason: map['reason'] as String,
        quantity: map['quantity'] as int,
        severity: map['severity'] as String,
      );
}

/// Material snapshot for handover
class MaterialSnapshot {
  final String materialId;
  final String materialName;
  final double currentStock;
  final bool isLow;

  const MaterialSnapshot({
    required this.materialId,
    required this.materialName,
    required this.currentStock,
    required this.isLow,
  });

  Map<String, dynamic> toMap() => {
        'materialId': materialId,
        'materialName': materialName,
        'currentStock': currentStock,
        'isLow': isLow,
      };

  factory MaterialSnapshot.fromMap(Map<String, dynamic> map) => MaterialSnapshot(
        materialId: map['materialId'] as String,
        materialName: map['materialName'] as String,
        currentStock: (map['currentStock'] as num).toDouble(),
        isLow: map['isLow'] as bool,
      );
}

/// Maintenance snapshot for handover
class MaintenanceSnapshot {
  final String mouldId;
  final String mouldNumber;
  final bool isDue;
  final int shotsSinceMaintenance;

  const MaintenanceSnapshot({
    required this.mouldId,
    required this.mouldNumber,
    required this.isDue,
    required this.shotsSinceMaintenance,
  });

  Map<String, dynamic> toMap() => {
        'mouldId': mouldId,
        'mouldNumber': mouldNumber,
        'isDue': isDue,
        'shotsSinceMaintenance': shotsSinceMaintenance,
      };

  factory MaintenanceSnapshot.fromMap(Map<String, dynamic> map) =>
      MaintenanceSnapshot(
        mouldId: map['mouldId'] as String,
        mouldNumber: map['mouldNumber'] as String,
        isDue: map['isDue'] as bool,
        shotsSinceMaintenance: map['shotsSinceMaintenance'] as int,
      );
}

/// Production summary for handover
class ProductionSummary {
  final int totalParts;
  final int totalScrap;
  final double scrapRate;
  final int downtimeMinutes;
  final int jobsCompleted;
  final int issuesReported;

  const ProductionSummary({
    required this.totalParts,
    required this.totalScrap,
    required this.scrapRate,
    required this.downtimeMinutes,
    required this.jobsCompleted,
    required this.issuesReported,
  });

  Map<String, dynamic> toMap() => {
        'totalParts': totalParts,
        'totalScrap': totalScrap,
        'scrapRate': scrapRate,
        'downtimeMinutes': downtimeMinutes,
        'jobsCompleted': jobsCompleted,
        'issuesReported': issuesReported,
      };

  factory ProductionSummary.fromMap(Map<String, dynamic> map) => ProductionSummary(
        totalParts: map['totalParts'] as int? ?? 0,
        totalScrap: map['totalScrap'] as int? ?? 0,
        scrapRate: (map['scrapRate'] as num?)?.toDouble() ?? 0,
        downtimeMinutes: map['downtimeMinutes'] as int? ?? 0,
        jobsCompleted: map['jobsCompleted'] as int? ?? 0,
        issuesReported: map['issuesReported'] as int? ?? 0,
      );
}
