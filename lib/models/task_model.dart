/// ProMould Task Model
/// Task management with escalation support

import '../core/constants.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final TaskType type;
  final TaskPriority priority;
  final TaskStatus status;
  final TaskSource source;
  final String? sourceId; // ID of the entity that created this task
  final String? assigneeId;
  final UserRole? assigneeRole; // Fallback if no specific user
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completedById;
  final String? notes;

  // Escalation tracking
  final int escalationLevel; // 0-3
  final DateTime? escalatedAt;
  final String? escalatedToId;
  final String? escalationReason;

  // Related entities
  final String? machineId;
  final String? mouldId;
  final String? jobId;

  // Metadata
  final Map<String, dynamic>? metadata;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.type,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    required this.source,
    this.sourceId,
    this.assigneeId,
    this.assigneeRole,
    this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    this.startedAt,
    this.completedAt,
    this.completedById,
    this.notes,
    this.escalationLevel = 0,
    this.escalatedAt,
    this.escalatedToId,
    this.escalationReason,
    this.machineId,
    this.mouldId,
    this.jobId,
    this.metadata,
  });

  // ============ DERIVED STATE ============

  /// Is task open (not completed or cancelled)
  bool get isOpen => status.isOpen;

  /// Is task overdue
  bool get isOverdue {
    if (dueAt == null) return false;
    if (!isOpen) return false;
    return DateTime.now().isAfter(dueAt!);
  }

  /// Time until due
  Duration? get timeUntilDue {
    if (dueAt == null) return null;
    return dueAt!.difference(DateTime.now());
  }

  /// Time overdue
  Duration? get timeOverdue {
    if (!isOverdue) return null;
    return DateTime.now().difference(dueAt!);
  }

  /// Task duration (if completed)
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Can be escalated
  bool get canEscalate =>
      isOpen && escalationLevel < SystemThresholds.maxEscalationLevel;

  /// Should auto-escalate based on time
  bool get shouldAutoEscalate {
    if (!canEscalate) return false;
    if (dueAt == null) return false;

    final threshold = priority.escalationThreshold;
    final timeOverdue = this.timeOverdue;
    if (timeOverdue == null) return false;

    return timeOverdue > threshold;
  }

  /// Is assigned to a specific user
  bool get isAssigned => assigneeId != null;

  /// Is assigned to a role (not specific user)
  bool get isRoleAssigned => assigneeId == null && assigneeRole != null;

  // ============ METHODS ============

  /// Create a copy with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    TaskPriority? priority,
    TaskStatus? status,
    TaskSource? source,
    String? sourceId,
    String? assigneeId,
    UserRole? assigneeRole,
    DateTime? dueAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completedById,
    String? notes,
    int? escalationLevel,
    DateTime? escalatedAt,
    String? escalatedToId,
    String? escalationReason,
    String? machineId,
    String? mouldId,
    String? jobId,
    Map<String, dynamic>? metadata,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeRole: assigneeRole ?? this.assigneeRole,
      dueAt: dueAt ?? this.dueAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completedById: completedById ?? this.completedById,
      notes: notes ?? this.notes,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      escalatedAt: escalatedAt ?? this.escalatedAt,
      escalatedToId: escalatedToId ?? this.escalatedToId,
      escalationReason: escalationReason ?? this.escalationReason,
      machineId: machineId ?? this.machineId,
      mouldId: mouldId ?? this.mouldId,
      jobId: jobId ?? this.jobId,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Assign to user
  Task assign(String userId) {
    return copyWith(
      assigneeId: userId,
      assigneeRole: null,
      status: TaskStatus.assigned,
    );
  }

  /// Assign to role
  Task assignToRole(UserRole role) {
    return copyWith(
      assigneeId: null,
      assigneeRole: role,
      status: TaskStatus.assigned,
    );
  }

  /// Start the task
  Task start() {
    return copyWith(
      status: TaskStatus.inProgress,
      startedAt: DateTime.now(),
    );
  }

  /// Complete the task
  Task complete(String completedById, {String? notes}) {
    return copyWith(
      status: TaskStatus.complete,
      completedAt: DateTime.now(),
      completedById: completedById,
      notes: notes ?? this.notes,
    );
  }

  /// Block the task
  Task block({String? reason}) {
    return copyWith(
      status: TaskStatus.blocked,
      notes: reason ?? notes,
    );
  }

  /// Cancel the task
  Task cancel() {
    return copyWith(
      status: TaskStatus.cancelled,
      completedAt: DateTime.now(),
    );
  }

  /// Escalate the task
  Task escalate({required String escalatedToId, String? reason}) {
    return copyWith(
      escalationLevel: escalationLevel + 1,
      escalatedAt: DateTime.now(),
      escalatedToId: escalatedToId,
      escalationReason: reason,
      assigneeId: escalatedToId,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.name,
        'priority': priority.name,
        'status': status.name,
        'source': source.name,
        'sourceId': sourceId,
        'assigneeId': assigneeId,
        'assigneeRole': assigneeRole?.name,
        'dueAt': dueAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'completedById': completedById,
        'notes': notes,
        'escalationLevel': escalationLevel,
        'escalatedAt': escalatedAt?.toIso8601String(),
        'escalatedToId': escalatedToId,
        'escalationReason': escalationReason,
        'machineId': machineId,
        'mouldId': mouldId,
        'jobId': jobId,
        'metadata': metadata,
      };

  /// Create from map
  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        type: TaskType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => TaskType.other,
        ),
        priority: TaskPriority.values.firstWhere(
          (p) => p.name == map['priority'],
          orElse: () => TaskPriority.medium,
        ),
        status: TaskStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => TaskStatus.pending,
        ),
        source: TaskSource.values.firstWhere(
          (s) => s.name == map['source'],
          orElse: () => TaskSource.manual,
        ),
        sourceId: map['sourceId'] as String?,
        assigneeId: map['assigneeId'] as String?,
        assigneeRole: map['assigneeRole'] != null
            ? UserRole.values.firstWhere(
                (r) => r.name == map['assigneeRole'],
                orElse: () => UserRole.operator,
              )
            : null,
        dueAt: _parseDateTime(map['dueAt']),
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        startedAt: _parseDateTime(map['startedAt']),
        completedAt: _parseDateTime(map['completedAt']),
        completedById: map['completedById'] as String?,
        notes: map['notes'] as String?,
        escalationLevel: map['escalationLevel'] as int? ?? 0,
        escalatedAt: _parseDateTime(map['escalatedAt']),
        escalatedToId: map['escalatedToId'] as String?,
        escalationReason: map['escalationReason'] as String?,
        machineId: map['machineId'] as String?,
        mouldId: map['mouldId'] as String?,
        jobId: map['jobId'] as String?,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'Task($title, $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Task types
enum TaskType {
  maintenance('Maintenance'),
  mouldChange('Mould Change'),
  qualityIssue('Quality Issue'),
  machineIssue('Machine Issue'),
  materialRequest('Material Request'),
  checklist('Checklist'),
  inspection('Inspection'),
  calibration('Calibration'),
  other('Other');

  final String displayName;
  const TaskType(this.displayName);
}

/// Task source (what created the task)
enum TaskSource {
  alert('Alert'),
  issue('Issue'),
  checklist('Checklist'),
  maintenance('Maintenance'),
  qualityHold('Quality Hold'),
  manual('Manual');

  final String displayName;
  const TaskSource(this.displayName);
}

/// Task with assignee details (for UI display)
class TaskWithAssignee {
  final Task task;
  final String? assigneeName;
  final String? assigneeRole;
  final String? machineName;
  final String? mouldName;
  final String? jobNumber;

  TaskWithAssignee({
    required this.task,
    this.assigneeName,
    this.assigneeRole,
    this.machineName,
    this.mouldName,
    this.jobNumber,
  });

  // Convenience getters
  String get id => task.id;
  String get title => task.title;
  TaskStatus get status => task.status;
  TaskPriority get priority => task.priority;
  bool get isOverdue => task.isOverdue;
  bool get isOpen => task.isOpen;
}
