/// ProMould Alert Model
/// Alert system with routing and escalation

import '../core/constants.dart';

class Alert {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String sourceType; // Entity type that triggered the alert
  final String sourceId; // Entity ID that triggered the alert
  final String? machineId;
  final String? jobId;
  final String? mouldId;
  final AlertStatus status;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final String? acknowledgedById;
  final DateTime? resolvedAt;
  final String? resolvedById;
  final String? resolutionNotes;
  final DateTime? snoozedUntil;
  final String? taskId; // Task created from this alert
  final Map<String, dynamic>? metadata;

  Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.sourceType,
    required this.sourceId,
    this.machineId,
    this.jobId,
    this.mouldId,
    this.status = AlertStatus.active,
    required this.createdAt,
    this.acknowledgedAt,
    this.acknowledgedById,
    this.resolvedAt,
    this.resolvedById,
    this.resolutionNotes,
    this.snoozedUntil,
    this.taskId,
    this.metadata,
  });

  // ============ DERIVED STATE ============

  /// Alert age
  Duration get age => DateTime.now().difference(createdAt);

  /// Response time (time to acknowledge)
  Duration? get responseTime {
    if (acknowledgedAt == null) return null;
    return acknowledgedAt!.difference(createdAt);
  }

  /// Resolution time (time to resolve)
  Duration? get resolutionTime {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt);
  }

  /// Is alert active
  bool get isActive => status == AlertStatus.active;

  /// Is alert snoozed
  bool get isSnoozed {
    if (status != AlertStatus.snoozed) return false;
    if (snoozedUntil == null) return false;
    return DateTime.now().isBefore(snoozedUntil!);
  }

  /// Is snooze expired (should reactivate)
  bool get isSnoozeExpired {
    if (status != AlertStatus.snoozed) return false;
    if (snoozedUntil == null) return true;
    return DateTime.now().isAfter(snoozedUntil!);
  }

  /// Is alert resolved
  bool get isResolved => status == AlertStatus.resolved;

  /// Is alert acknowledged
  bool get isAcknowledged =>
      status == AlertStatus.acknowledged || acknowledgedAt != null;

  /// Has task been created
  bool get hasTask => taskId != null;

  /// Is critical
  bool get isCritical => severity == AlertSeverity.critical;

  /// Is high priority (critical or high)
  bool get isHighPriority =>
      severity == AlertSeverity.critical || severity == AlertSeverity.high;

  // ============ METHODS ============

  /// Create a copy with updated fields
  Alert copyWith({
    String? id,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? sourceType,
    String? sourceId,
    String? machineId,
    String? jobId,
    String? mouldId,
    AlertStatus? status,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    String? acknowledgedById,
    DateTime? resolvedAt,
    String? resolvedById,
    String? resolutionNotes,
    DateTime? snoozedUntil,
    String? taskId,
    Map<String, dynamic>? metadata,
  }) {
    return Alert(
      id: id ?? this.id,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      machineId: machineId ?? this.machineId,
      jobId: jobId ?? this.jobId,
      mouldId: mouldId ?? this.mouldId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedById: acknowledgedById ?? this.acknowledgedById,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedById: resolvedById ?? this.resolvedById,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      taskId: taskId ?? this.taskId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Acknowledge the alert
  Alert acknowledge(String userId) {
    return copyWith(
      status: AlertStatus.acknowledged,
      acknowledgedAt: DateTime.now(),
      acknowledgedById: userId,
    );
  }

  /// Resolve the alert
  Alert resolve(String userId, {String? notes}) {
    return copyWith(
      status: AlertStatus.resolved,
      resolvedAt: DateTime.now(),
      resolvedById: userId,
      resolutionNotes: notes,
    );
  }

  /// Snooze the alert
  Alert snooze(Duration duration) {
    return copyWith(
      status: AlertStatus.snoozed,
      snoozedUntil: DateTime.now().add(duration),
    );
  }

  /// Reactivate snoozed alert
  Alert reactivate() {
    return copyWith(
      status: AlertStatus.active,
      snoozedUntil: null,
    );
  }

  /// Link to task
  Alert linkTask(String taskId) {
    return copyWith(taskId: taskId);
  }

  /// Auto-close the alert
  Alert autoClose() {
    return copyWith(
      status: AlertStatus.autoClosed,
      resolvedAt: DateTime.now(),
      resolutionNotes: 'Auto-closed by system',
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'severity': severity.name,
        'title': title,
        'message': message,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'machineId': machineId,
        'jobId': jobId,
        'mouldId': mouldId,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'acknowledgedAt': acknowledgedAt?.toIso8601String(),
        'acknowledgedById': acknowledgedById,
        'resolvedAt': resolvedAt?.toIso8601String(),
        'resolvedById': resolvedById,
        'resolutionNotes': resolutionNotes,
        'snoozedUntil': snoozedUntil?.toIso8601String(),
        'taskId': taskId,
        'metadata': metadata,
      };

  /// Create from map
  factory Alert.fromMap(Map<String, dynamic> map) => Alert(
        id: map['id'] as String,
        type: AlertType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => AlertType.machineDown,
        ),
        severity: AlertSeverity.values.firstWhere(
          (s) => s.name == map['severity'],
          orElse: () => AlertSeverity.medium,
        ),
        title: map['title'] as String,
        message: map['message'] as String,
        sourceType: map['sourceType'] as String,
        sourceId: map['sourceId'] as String,
        machineId: map['machineId'] as String?,
        jobId: map['jobId'] as String?,
        mouldId: map['mouldId'] as String?,
        status: AlertStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => AlertStatus.active,
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        acknowledgedAt: _parseDateTime(map['acknowledgedAt']),
        acknowledgedById: map['acknowledgedById'] as String?,
        resolvedAt: _parseDateTime(map['resolvedAt']),
        resolvedById: map['resolvedById'] as String?,
        resolutionNotes: map['resolutionNotes'] as String?,
        snoozedUntil: _parseDateTime(map['snoozedUntil']),
        taskId: map['taskId'] as String?,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'Alert($type, $severity, $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Alert && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Alert status
enum AlertStatus {
  active('Active'),
  acknowledged('Acknowledged'),
  resolved('Resolved'),
  snoozed('Snoozed'),
  autoClosed('Auto-Closed');

  final String displayName;
  const AlertStatus(this.displayName);
}

/// Alert with related entity names (for UI display)
class AlertWithContext {
  final Alert alert;
  final String? machineName;
  final String? jobNumber;
  final String? mouldNumber;
  final String? acknowledgedByName;
  final String? resolvedByName;

  AlertWithContext({
    required this.alert,
    this.machineName,
    this.jobNumber,
    this.mouldNumber,
    this.acknowledgedByName,
    this.resolvedByName,
  });

  // Convenience getters
  String get id => alert.id;
  AlertType get type => alert.type;
  AlertSeverity get severity => alert.severity;
  String get title => alert.title;
  String get message => alert.message;
  AlertStatus get status => alert.status;
  bool get isActive => alert.isActive;
  bool get isCritical => alert.isCritical;
  Duration get age => alert.age;
}

/// Alert generation rules
class AlertRule {
  final AlertType type;
  final AlertSeverity severity;
  final String titleTemplate;
  final String messageTemplate;
  final Duration? autoCloseAfter;
  final bool createTask;
  final UserRole? assignToRole;

  const AlertRule({
    required this.type,
    required this.severity,
    required this.titleTemplate,
    required this.messageTemplate,
    this.autoCloseAfter,
    this.createTask = false,
    this.assignToRole,
  });

  /// Generate alert from rule
  Alert generate({
    required String id,
    required String sourceType,
    required String sourceId,
    String? machineId,
    String? jobId,
    String? mouldId,
    Map<String, String>? templateValues,
  }) {
    var title = titleTemplate;
    var message = messageTemplate;

    // Replace template values
    if (templateValues != null) {
      for (final entry in templateValues.entries) {
        title = title.replaceAll('{${entry.key}}', entry.value);
        message = message.replaceAll('{${entry.key}}', entry.value);
      }
    }

    return Alert(
      id: id,
      type: type,
      severity: severity,
      title: title,
      message: message,
      sourceType: sourceType,
      sourceId: sourceId,
      machineId: machineId,
      jobId: jobId,
      mouldId: mouldId,
      createdAt: DateTime.now(),
    );
  }
}

/// Predefined alert rules
class AlertRules {
  static const machineDown = AlertRule(
    type: AlertType.machineDown,
    severity: AlertSeverity.critical,
    titleTemplate: 'Machine Down: {machineName}',
    messageTemplate: 'Machine {machineName} has gone down. Reason: {reason}',
    createTask: true,
    assignToRole: UserRole.setter,
  );

  static const jobCompletion = AlertRule(
    type: AlertType.jobCompletion,
    severity: AlertSeverity.medium,
    titleTemplate: 'Job Completing Soon: {jobNumber}',
    messageTemplate:
        'Job {jobNumber} on {machineName} will complete in approximately {timeRemaining}',
    autoCloseAfter: Duration(hours: 2),
  );

  static const jobOverrun = AlertRule(
    type: AlertType.jobOverrun,
    severity: AlertSeverity.high,
    titleTemplate: 'Job Overrunning: {jobNumber}',
    messageTemplate:
        'Job {jobNumber} is overrunning. ETA: {eta}, Due: {dueDate}',
    createTask: true,
    assignToRole: UserRole.productionManager,
  );

  static const highScrap = AlertRule(
    type: AlertType.highScrap,
    severity: AlertSeverity.high,
    titleTemplate: 'High Scrap Rate: {machineName}',
    messageTemplate:
        'Scrap rate on {machineName} is {scrapRate}%, exceeding threshold of {threshold}%',
    createTask: true,
    assignToRole: UserRole.qc,
  );

  static const maintenanceDue = AlertRule(
    type: AlertType.maintenanceDue,
    severity: AlertSeverity.medium,
    titleTemplate: 'Maintenance Due: {mouldNumber}',
    messageTemplate:
        'Mould {mouldNumber} is due for maintenance. Shots since last maintenance: {shots}',
    createTask: true,
    assignToRole: UserRole.setter,
  );

  static const materialShortage = AlertRule(
    type: AlertType.materialShortage,
    severity: AlertSeverity.high,
    titleTemplate: 'Material Shortage: {materialName}',
    messageTemplate:
        'Material {materialName} is running low. Current stock: {currentStock}, Required: {required}',
    createTask: true,
    assignToRole: UserRole.materialHandler,
  );

  static const qualityHold = AlertRule(
    type: AlertType.qualityHold,
    severity: AlertSeverity.high,
    titleTemplate: 'Quality Hold: {jobNumber}',
    messageTemplate:
        'Quality hold placed on job {jobNumber}. Reason: {reason}. Quantity: {quantity}',
    createTask: true,
    assignToRole: UserRole.qc,
  );
}
