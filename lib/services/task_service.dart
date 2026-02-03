/// ProMould Task Service
/// Task management with bounded escalation engine

import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/task_model.dart';
import '../models/alert_model.dart';
import 'log_service.dart';
import 'sync_service.dart';
import 'audit_service.dart';
import 'alert_service.dart';

class TaskService {
  static const _uuid = Uuid();
  static Box? _tasksBox;
  static Box? _usersBox;
  static Timer? _escalationTimer;

  /// Initialize the task service
  static Future<void> initialize() async {
    _tasksBox = await Hive.openBox(HiveBoxes.tasks);
    _usersBox = await Hive.openBox(HiveBoxes.users);
    LogService.info('TaskService initialized');
  }

  /// Start the escalation engine
  static void startEscalationEngine({
    Duration checkInterval = const Duration(minutes: 1),
  }) {
    _escalationTimer?.cancel();
    _escalationTimer = Timer.periodic(checkInterval, (_) => _runEscalationCheck());
    LogService.info('Escalation engine started');
  }

  /// Stop the escalation engine
  static void stopEscalationEngine() {
    _escalationTimer?.cancel();
    _escalationTimer = null;
    LogService.info('Escalation engine stopped');
  }

  /// Run escalation check on all open tasks
  static Future<void> _runEscalationCheck() async {
    if (_tasksBox == null) return;

    for (final key in _tasksBox!.keys) {
      final map = _tasksBox!.get(key);
      if (map == null) continue;

      final task = Task.fromMap(Map<String, dynamic>.from(map));

      // Check if task should be escalated
      if (task.shouldAutoEscalate) {
        await _escalateTask(task);
      }
    }
  }

  /// Escalate a task to the next level
  static Future<Task?> _escalateTask(Task task) async {
    if (!task.canEscalate) return null;

    final nextLevel = task.escalationLevel + 1;
    final escalatedTo = await _getEscalationTarget(task, nextLevel);

    if (escalatedTo == null) {
      // Max escalation reached - create critical alert
      await AlertService.generateAlert(
        type: AlertType.taskOverdue,
        severity: AlertSeverity.critical,
        title: 'Task Escalation Limit Reached',
        message:
            'Task "${task.title}" has reached maximum escalation level without resolution.',
        sourceType: 'Task',
        sourceId: task.id,
        machineId: task.machineId,
        jobId: task.jobId,
      );

      LogService.warning('Task escalation limit reached: ${task.id}');
      return null;
    }

    final escalated = task.escalate(
      escalatedToId: escalatedTo['id'] as String,
      reason: 'Auto-escalated due to overdue threshold',
    );

    await _tasksBox?.put(task.id, escalated.toMap());
    await SyncService.push(HiveBoxes.tasks, task.id, escalated.toMap());

    await AuditService.logEscalation(
      entityType: 'Task',
      entityId: task.id,
      fromLevel: task.escalationLevel,
      toLevel: nextLevel,
      escalatedTo: escalatedTo['name'] as String,
      reason: 'Auto-escalated due to overdue threshold',
    );

    LogService.info(
        'Task escalated: ${task.id} to level $nextLevel (${escalatedTo['name']})');

    return escalated;
  }

  /// Get escalation target for a given level
  static Future<Map<String, dynamic>?> _getEscalationTarget(
    Task task,
    int level,
  ) async {
    if (_usersBox == null) return null;

    // Escalation path:
    // Level 1: Assigned user's role peers
    // Level 2: Setter (if not already)
    // Level 3: Production Manager
    // Level 4+: Stop (bounded escalation)

    if (level > SystemThresholds.maxEscalationLevel) {
      return null; // Bounded escalation - stop here
    }

    UserRole targetRole;
    switch (level) {
      case 1:
        // Escalate to same role or setter
        targetRole = task.assigneeRole ?? UserRole.setter;
        break;
      case 2:
        // Escalate to setter
        targetRole = UserRole.setter;
        break;
      case 3:
        // Escalate to production manager
        targetRole = UserRole.productionManager;
        break;
      default:
        return null;
    }

    // Find an available user with the target role
    for (final map in _usersBox!.values) {
      final userData = Map<String, dynamic>.from(map);
      final userRole = userData['role'] as String?;

      if (userRole == targetRole.name) {
        // Don't escalate to the same person
        if (userData['id'] != task.assigneeId) {
          return {
            'id': userData['id'],
            'name': '${userData['firstName']} ${userData['lastName']}',
          };
        }
      }
    }

    // If no user found at this level, try next level
    if (level < SystemThresholds.maxEscalationLevel) {
      return _getEscalationTarget(task, level + 1);
    }

    return null;
  }

  // ============ TASK CRUD ============

  /// Get all tasks
  static List<Task> getAllTasks() {
    if (_tasksBox == null) return [];

    return _tasksBox!.values
        .map((map) => Task.fromMap(Map<String, dynamic>.from(map)))
        .toList()
      ..sort((a, b) {
        // Sort by priority first, then by due date
        final priorityCompare = a.priority.level.compareTo(b.priority.level);
        if (priorityCompare != 0) return priorityCompare;

        if (a.dueAt == null && b.dueAt == null) return 0;
        if (a.dueAt == null) return 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
      });
  }

  /// Get open tasks
  static List<Task> getOpenTasks() {
    return getAllTasks().where((t) => t.isOpen).toList();
  }

  /// Get tasks for a user
  static List<Task> getTasksForUser(String userId) {
    return getAllTasks()
        .where((t) => t.assigneeId == userId && t.isOpen)
        .toList();
  }

  /// Get tasks for a role
  static List<Task> getTasksForRole(UserRole role) {
    return getAllTasks()
        .where((t) => t.assigneeRole == role && t.assigneeId == null && t.isOpen)
        .toList();
  }

  /// Get overdue tasks
  static List<Task> getOverdueTasks() {
    return getAllTasks().where((t) => t.isOverdue).toList();
  }

  /// Get task by ID
  static Task? getTask(String id) {
    if (_tasksBox == null) return null;

    final map = _tasksBox!.get(id);
    if (map == null) return null;

    return Task.fromMap(Map<String, dynamic>.from(map));
  }

  /// Get tasks for a machine
  static List<Task> getTasksForMachine(String machineId) {
    return getAllTasks()
        .where((t) => t.machineId == machineId && t.isOpen)
        .toList();
  }

  /// Get tasks for a mould
  static List<Task> getTasksForMould(String mouldId) {
    return getAllTasks()
        .where((t) => t.mouldId == mouldId && t.isOpen)
        .toList();
  }

  /// Get tasks for a job
  static List<Task> getTasksForJob(String jobId) {
    return getAllTasks().where((t) => t.jobId == jobId && t.isOpen).toList();
  }

  // ============ TASK CREATION ============

  /// Create a new task
  static Future<Task> createTask({
    required String title,
    String? description,
    required TaskType type,
    TaskPriority priority = TaskPriority.medium,
    required TaskSource source,
    String? sourceId,
    String? assigneeId,
    UserRole? assigneeRole,
    DateTime? dueAt,
    String? machineId,
    String? mouldId,
    String? jobId,
    Map<String, dynamic>? metadata,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      type: type,
      priority: priority,
      status: assigneeId != null ? TaskStatus.assigned : TaskStatus.pending,
      source: source,
      sourceId: sourceId,
      assigneeId: assigneeId,
      assigneeRole: assigneeRole,
      dueAt: dueAt ?? _calculateDefaultDueDate(priority),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      machineId: machineId,
      mouldId: mouldId,
      jobId: jobId,
      metadata: metadata,
    );

    await _tasksBox?.put(task.id, task.toMap());
    await SyncService.push(HiveBoxes.tasks, task.id, task.toMap());

    await AuditService.logCreate(
      entityType: 'Task',
      entityId: task.id,
      data: task.toMap(),
    );

    LogService.info('Task created: ${task.title}');
    return task;
  }

  /// Create task from alert
  static Future<Task> createTaskFromAlert(
    Alert alert, {
    String? assigneeId,
    UserRole? assigneeRole,
  }) async {
    final task = await createTask(
      title: alert.title,
      description: alert.message,
      type: _mapAlertTypeToTaskType(alert.type),
      priority: _mapAlertSeverityToTaskPriority(alert.severity),
      source: TaskSource.alert,
      sourceId: alert.id,
      assigneeId: assigneeId,
      assigneeRole: assigneeRole,
      machineId: alert.machineId,
      mouldId: alert.mouldId,
      jobId: alert.jobId,
    );

    // Link alert to task
    await AlertService.linkAlertToTask(alert.id, task.id);

    return task;
  }

  /// Calculate default due date based on priority
  static DateTime _calculateDefaultDueDate(TaskPriority priority) {
    return DateTime.now().add(priority.escalationThreshold * 2);
  }

  /// Map alert type to task type
  static TaskType _mapAlertTypeToTaskType(AlertType alertType) {
    switch (alertType) {
      case AlertType.machineDown:
        return TaskType.machineIssue;
      case AlertType.maintenanceDue:
        return TaskType.maintenance;
      case AlertType.mouldChangeDue:
        return TaskType.mouldChange;
      case AlertType.qualityHold:
      case AlertType.highScrap:
        return TaskType.qualityIssue;
      case AlertType.materialShortage:
        return TaskType.materialRequest;
      default:
        return TaskType.other;
    }
  }

  /// Map alert severity to task priority
  static TaskPriority _mapAlertSeverityToTaskPriority(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return TaskPriority.critical;
      case AlertSeverity.high:
        return TaskPriority.high;
      case AlertSeverity.medium:
        return TaskPriority.medium;
      case AlertSeverity.low:
        return TaskPriority.low;
    }
  }

  // ============ TASK ACTIONS ============

  /// Assign task to user
  static Future<Task?> assignTask(String taskId, String userId) async {
    final task = getTask(taskId);
    if (task == null) return null;

    final assigned = task.assign(userId);
    await _tasksBox?.put(taskId, assigned.toMap());
    await SyncService.push(HiveBoxes.tasks, taskId, assigned.toMap());

    await AuditService.logAssignment(
      entityType: 'Task',
      entityId: taskId,
      assignedTo: userId,
      previousAssignee: task.assigneeId,
    );

    LogService.info('Task assigned: $taskId to $userId');
    return assigned;
  }

  /// Assign task to role
  static Future<Task?> assignTaskToRole(String taskId, UserRole role) async {
    final task = getTask(taskId);
    if (task == null) return null;

    final assigned = task.assignToRole(role);
    await _tasksBox?.put(taskId, assigned.toMap());
    await SyncService.push(HiveBoxes.tasks, taskId, assigned.toMap());

    await AuditService.logAssignment(
      entityType: 'Task',
      entityId: taskId,
      assignedTo: role.displayName,
      previousAssignee: task.assigneeId,
    );

    LogService.info('Task assigned to role: $taskId to ${role.displayName}');
    return assigned;
  }

  /// Start a task
  static Future<Task?> startTask(String taskId) async {
    final task = getTask(taskId);
    if (task == null) return null;

    final started = task.start();
    await _tasksBox?.put(taskId, started.toMap());
    await SyncService.push(HiveBoxes.tasks, taskId, started.toMap());

    await AuditService.logStatusChange(
      entityType: 'Task',
      entityId: taskId,
      fromStatus: task.status.name,
      toStatus: started.status.name,
    );

    LogService.info('Task started: $taskId');
    return started;
  }

  /// Complete a task
  static Future<Task?> completeTask(
    String taskId,
    String completedById, {
    String? notes,
  }) async {
    final task = getTask(taskId);
    if (task == null) return null;

    final completed = task.complete(completedById, notes: notes);
    await _tasksBox?.put(taskId, completed.toMap());
    await SyncService.push(HiveBoxes.tasks, taskId, completed.toMap());

    await AuditService.logStatusChange(
      entityType: 'Task',
      entityId: taskId,
      fromStatus: task.status.name,
      toStatus: completed.status.name,
      metadata: {'completedBy': completedById, 'notes': notes},
    );

    // If task was created from alert, resolve the alert
    if (task.source == TaskSource.alert && task.sourceId != null) {
      await AlertService.resolveAlert(task.sourceId!, completedById,
          notes: 'Resolved via task completion');
    }

    LogService.info('Task completed: $taskId');
    return completed;
  }

  /// Block a task
  static Future<Task?> blockTask(String taskId, {String? reason}) async {
    final task = getTask(taskId);
    if (task == null) return null;

    final blocked = task.block(reason: reason);
    await _tasksBox?.put(taskId, blocked.toMap());
    await SyncService.push(HiveBoxes.tasks, taskId, blocked.toMap());

    await AuditService.logStatusChange(
      entityType: 'Task',
      entityId: taskId,
      fromStatus: task.status.name,
      toStatus: blocked.status.name,
      reason: reason,
    );

    LogService.info('Task blocked: $taskId');
    return blocked;
  }

  /// Cancel a task
  static Future<Task?> cancelTask(String taskId) async {
    final task = getTask(taskId);
    if (task == null) return null;

    final cancelled = task.cancel();
    await _tasksBox?.put(taskId, cancelled.toMap());
    await SyncService.push(HiveBoxes.tasks, taskId, cancelled.toMap());

    await AuditService.logStatusChange(
      entityType: 'Task',
      entityId: taskId,
      fromStatus: task.status.name,
      toStatus: cancelled.status.name,
    );

    LogService.info('Task cancelled: $taskId');
    return cancelled;
  }

  /// Manually escalate a task
  static Future<Task?> escalateTaskManually(
    String taskId,
    String escalatedToId, {
    String? reason,
  }) async {
    final task = getTask(taskId);
    if (task == null) return null;

    if (!task.canEscalate) {
      LogService.warning('Task cannot be escalated: $taskId');
      return null;
    }

    final escalated = task.escalate(
      escalatedToId: escalatedToId,
      reason: reason ?? 'Manually escalated',
    );

    await _tasksBox?.put(taskId, escalated.toMap());
    await SyncService.push(HiveBoxes.tasks, taskId, escalated.toMap());

    await AuditService.logEscalation(
      entityType: 'Task',
      entityId: taskId,
      fromLevel: task.escalationLevel,
      toLevel: escalated.escalationLevel,
      escalatedTo: escalatedToId,
      reason: reason ?? 'Manually escalated',
    );

    LogService.info('Task manually escalated: $taskId');
    return escalated;
  }

  // ============ TASK STATISTICS ============

  /// Get task statistics
  static TaskStatistics getStatistics({String? userId}) {
    var tasks = getAllTasks();

    if (userId != null) {
      tasks = tasks.where((t) => t.assigneeId == userId).toList();
    }

    final open = tasks.where((t) => t.isOpen).length;
    final overdue = tasks.where((t) => t.isOverdue).length;
    final completed = tasks.where((t) => t.status == TaskStatus.complete).length;

    final completedTasks =
        tasks.where((t) => t.status == TaskStatus.complete && t.duration != null);
    final avgDuration = completedTasks.isEmpty
        ? 0.0
        : completedTasks.map((t) => t.duration!.inMinutes).reduce((a, b) => a + b) /
            completedTasks.length;

    return TaskStatistics(
      total: tasks.length,
      open: open,
      overdue: overdue,
      completed: completed,
      averageDurationMinutes: avgDuration,
      byType: _countByType(tasks),
      byPriority: _countByPriority(tasks),
    );
  }

  static Map<TaskType, int> _countByType(List<Task> tasks) {
    final counts = <TaskType, int>{};
    for (final type in TaskType.values) {
      counts[type] = tasks.where((t) => t.type == type).length;
    }
    return counts;
  }

  static Map<TaskPriority, int> _countByPriority(List<Task> tasks) {
    final counts = <TaskPriority, int>{};
    for (final priority in TaskPriority.values) {
      counts[priority] = tasks.where((t) => t.priority == priority).length;
    }
    return counts;
  }
}

/// Task statistics
class TaskStatistics {
  final int total;
  final int open;
  final int overdue;
  final int completed;
  final double averageDurationMinutes;
  final Map<TaskType, int> byType;
  final Map<TaskPriority, int> byPriority;

  TaskStatistics({
    required this.total,
    required this.open,
    required this.overdue,
    required this.completed,
    required this.averageDurationMinutes,
    required this.byType,
    required this.byPriority,
  });

  /// Completion rate
  double get completionRate => total > 0 ? (completed / total) * 100 : 0;

  /// On-time rate (completed tasks that weren't overdue)
  double get onTimeRate {
    if (completed == 0) return 0;
    // This would need more data to calculate properly
    return 100 - (overdue / total * 100);
  }
}
