/// ProMould Alert Service
/// Rule-based alert generation and management

import 'dart:async';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/alert_model.dart';
import 'log_service.dart';
import 'sync_service.dart';
import 'audit_service.dart';

class AlertService {
  static const _uuid = Uuid();
  static Box? _alertsBox;
  static Timer? _checkTimer;

  // Alert deduplication - prevent duplicate alerts within time window
  static final Map<String, DateTime> _recentAlerts = {};
  static const _deduplicationWindow = Duration(minutes: 5);

  /// Initialize the alert service
  static Future<void> initialize() async {
    _alertsBox = await Hive.openBox(HiveBoxes.alerts);
    LogService.info('AlertService initialized');
  }

  /// Start periodic alert checking
  static void startPeriodicCheck({Duration interval = const Duration(seconds: 30)}) {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(interval, (_) => _runAlertChecks());
    LogService.info('Alert periodic check started');
  }

  /// Stop periodic alert checking
  static void stopPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
    LogService.info('Alert periodic check stopped');
  }

  /// Run all alert checks
  static Future<void> _runAlertChecks() async {
    // Clean up old deduplication entries
    _cleanupDeduplication();

    // Reactivate expired snoozed alerts
    await _reactivateExpiredSnoozes();

    // Auto-close old alerts
    await _autoCloseOldAlerts();
  }

  /// Clean up old deduplication entries
  static void _cleanupDeduplication() {
    final now = DateTime.now();
    _recentAlerts.removeWhere(
        (_, time) => now.difference(time) > _deduplicationWindow);
  }

  /// Reactivate expired snoozed alerts
  static Future<void> _reactivateExpiredSnoozes() async {
    if (_alertsBox == null) return;

    for (final key in _alertsBox!.keys) {
      final map = _alertsBox!.get(key);
      if (map == null) continue;

      final alert = Alert.fromMap(Map<String, dynamic>.from(map));
      if (alert.isSnoozeExpired) {
        final reactivated = alert.reactivate();
        await _alertsBox!.put(key, reactivated.toMap());
        await SyncService.push(HiveBoxes.alerts, key.toString(), reactivated.toMap());
        LogService.info('Alert reactivated from snooze: ${alert.id}');
      }
    }
  }

  /// Auto-close old resolved alerts
  static Future<void> _autoCloseOldAlerts() async {
    // Implementation for auto-closing alerts based on rules
    // This would be configured per alert type
  }

  // ============ ALERT CRUD ============

  /// Get all active alerts
  static List<Alert> getActiveAlerts() {
    if (_alertsBox == null) return [];

    return _alertsBox!.values
        .map((map) => Alert.fromMap(Map<String, dynamic>.from(map)))
        .where((alert) => alert.isActive || alert.isSnoozed)
        .toList()
      ..sort((a, b) {
        // Sort by severity first, then by creation time
        final severityCompare = a.severity.level.compareTo(b.severity.level);
        if (severityCompare != 0) return severityCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  /// Get alerts by type
  static List<Alert> getAlertsByType(AlertType type) {
    if (_alertsBox == null) return [];

    return _alertsBox!.values
        .map((map) => Alert.fromMap(Map<String, dynamic>.from(map)))
        .where((alert) => alert.type == type)
        .toList();
  }

  /// Get alerts for a machine
  static List<Alert> getAlertsForMachine(String machineId) {
    if (_alertsBox == null) return [];

    return _alertsBox!.values
        .map((map) => Alert.fromMap(Map<String, dynamic>.from(map)))
        .where((alert) => alert.machineId == machineId && alert.isActive)
        .toList();
  }

  /// Get alerts for a job
  static List<Alert> getAlertsForJob(String jobId) {
    if (_alertsBox == null) return [];

    return _alertsBox!.values
        .map((map) => Alert.fromMap(Map<String, dynamic>.from(map)))
        .where((alert) => alert.jobId == jobId && alert.isActive)
        .toList();
  }

  /// Get alert by ID
  static Alert? getAlert(String id) {
    if (_alertsBox == null) return null;

    final map = _alertsBox!.get(id);
    if (map == null) return null;

    return Alert.fromMap(Map<String, dynamic>.from(map));
  }

  /// Get alert count by severity
  static Map<AlertSeverity, int> getAlertCountBySeverity() {
    final alerts = getActiveAlerts();
    final counts = <AlertSeverity, int>{};

    for (final severity in AlertSeverity.values) {
      counts[severity] = alerts.where((a) => a.severity == severity).length;
    }

    return counts;
  }

  /// Get total active alert count
  static int get activeAlertCount => getActiveAlerts().length;

  /// Get critical alert count
  static int get criticalAlertCount =>
      getActiveAlerts().where((a) => a.isCritical).length;

  // ============ ALERT GENERATION ============

  /// Generate an alert from a rule
  static Future<Alert?> generateAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String message,
    required String sourceType,
    required String sourceId,
    String? machineId,
    String? jobId,
    String? mouldId,
    Map<String, dynamic>? metadata,
    bool createTask = false,
    UserRole? assignToRole,
  }) async {
    // Check for deduplication
    final dedupeKey = '$type-$sourceId';
    if (_recentAlerts.containsKey(dedupeKey)) {
      LogService.debug('Alert deduplicated: $dedupeKey');
      return null;
    }

    final alert = Alert(
      id: _uuid.v4(),
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
      metadata: metadata,
    );

    await _alertsBox?.put(alert.id, alert.toMap());
    await SyncService.push(HiveBoxes.alerts, alert.id, alert.toMap());

    // Mark as recently created for deduplication
    _recentAlerts[dedupeKey] = DateTime.now();

    await AuditService.logCreate(
      entityType: 'Alert',
      entityId: alert.id,
      data: {'type': type.name, 'severity': severity.name, 'title': title},
    );

    LogService.info('Alert generated: ${alert.type.displayName} - ${alert.title}');

    // Create task if configured
    if (createTask && assignToRole != null) {
      // Task creation would be handled by TaskService
      // This is a placeholder for the integration
    }

    return alert;
  }

  /// Generate alert using predefined rule
  static Future<Alert?> generateFromRule({
    required AlertRule rule,
    required String sourceType,
    required String sourceId,
    String? machineId,
    String? jobId,
    String? mouldId,
    Map<String, String>? templateValues,
  }) async {
    final alert = rule.generate(
      id: _uuid.v4(),
      sourceType: sourceType,
      sourceId: sourceId,
      machineId: machineId,
      jobId: jobId,
      mouldId: mouldId,
      templateValues: templateValues,
    );

    await _alertsBox?.put(alert.id, alert.toMap());
    await SyncService.push(HiveBoxes.alerts, alert.id, alert.toMap());

    _recentAlerts['${rule.type}-$sourceId'] = DateTime.now();

    LogService.info('Alert generated from rule: ${alert.type.displayName}');

    return alert;
  }

  // ============ SPECIFIC ALERT GENERATORS ============

  /// Generate machine down alert
  static Future<Alert?> alertMachineDown({
    required String machineId,
    required String machineName,
    required String reason,
  }) async {
    return generateFromRule(
      rule: AlertRules.machineDown,
      sourceType: 'Machine',
      sourceId: machineId,
      machineId: machineId,
      templateValues: {
        'machineName': machineName,
        'reason': reason,
      },
    );
  }

  /// Generate job completion warning alert
  static Future<Alert?> alertJobCompletingSoon({
    required String jobId,
    required String jobNumber,
    required String machineId,
    required String machineName,
    required String timeRemaining,
  }) async {
    return generateFromRule(
      rule: AlertRules.jobCompletion,
      sourceType: 'Job',
      sourceId: jobId,
      machineId: machineId,
      jobId: jobId,
      templateValues: {
        'jobNumber': jobNumber,
        'machineName': machineName,
        'timeRemaining': timeRemaining,
      },
    );
  }

  /// Generate job overrun alert
  static Future<Alert?> alertJobOverrun({
    required String jobId,
    required String jobNumber,
    required String eta,
    required String dueDate,
  }) async {
    return generateFromRule(
      rule: AlertRules.jobOverrun,
      sourceType: 'Job',
      sourceId: jobId,
      jobId: jobId,
      templateValues: {
        'jobNumber': jobNumber,
        'eta': eta,
        'dueDate': dueDate,
      },
    );
  }

  /// Generate high scrap rate alert
  static Future<Alert?> alertHighScrapRate({
    required String machineId,
    required String machineName,
    required double scrapRate,
    required double threshold,
  }) async {
    return generateFromRule(
      rule: AlertRules.highScrap,
      sourceType: 'Machine',
      sourceId: machineId,
      machineId: machineId,
      templateValues: {
        'machineName': machineName,
        'scrapRate': scrapRate.toStringAsFixed(1),
        'threshold': threshold.toStringAsFixed(1),
      },
    );
  }

  /// Generate maintenance due alert
  static Future<Alert?> alertMaintenanceDue({
    required String mouldId,
    required String mouldNumber,
    required int shotsSinceMaintenance,
  }) async {
    return generateFromRule(
      rule: AlertRules.maintenanceDue,
      sourceType: 'Mould',
      sourceId: mouldId,
      mouldId: mouldId,
      templateValues: {
        'mouldNumber': mouldNumber,
        'shots': shotsSinceMaintenance.toString(),
      },
    );
  }

  /// Generate material shortage alert
  static Future<Alert?> alertMaterialShortage({
    required String materialId,
    required String materialName,
    required double currentStock,
    required double required,
  }) async {
    return generateFromRule(
      rule: AlertRules.materialShortage,
      sourceType: 'Material',
      sourceId: materialId,
      templateValues: {
        'materialName': materialName,
        'currentStock': currentStock.toStringAsFixed(1),
        'required': required.toStringAsFixed(1),
      },
    );
  }

  /// Generate quality hold alert
  static Future<Alert?> alertQualityHold({
    required String holdId,
    required String jobId,
    required String jobNumber,
    required String reason,
    required int quantity,
  }) async {
    return generateFromRule(
      rule: AlertRules.qualityHold,
      sourceType: 'QualityHold',
      sourceId: holdId,
      jobId: jobId,
      templateValues: {
        'jobNumber': jobNumber,
        'reason': reason,
        'quantity': quantity.toString(),
      },
    );
  }

  // ============ ALERT ACTIONS ============

  /// Acknowledge an alert
  static Future<Alert?> acknowledgeAlert(String alertId, String userId) async {
    final alert = getAlert(alertId);
    if (alert == null) return null;

    final acknowledged = alert.acknowledge(userId);
    await _alertsBox?.put(alertId, acknowledged.toMap());
    await SyncService.push(HiveBoxes.alerts, alertId, acknowledged.toMap());

    await AuditService.logUpdate(
      entityType: 'Alert',
      entityId: alertId,
      beforeValue: {'status': alert.status.name},
      afterValue: {'status': acknowledged.status.name},
      metadata: {'acknowledgedBy': userId},
    );

    LogService.info('Alert acknowledged: $alertId');
    return acknowledged;
  }

  /// Resolve an alert
  static Future<Alert?> resolveAlert(
    String alertId,
    String userId, {
    String? notes,
  }) async {
    final alert = getAlert(alertId);
    if (alert == null) return null;

    final resolved = alert.resolve(userId, notes: notes);
    await _alertsBox?.put(alertId, resolved.toMap());
    await SyncService.push(HiveBoxes.alerts, alertId, resolved.toMap());

    await AuditService.logUpdate(
      entityType: 'Alert',
      entityId: alertId,
      beforeValue: {'status': alert.status.name},
      afterValue: {'status': resolved.status.name, 'notes': notes},
      metadata: {'resolvedBy': userId},
    );

    LogService.info('Alert resolved: $alertId');
    return resolved;
  }

  /// Snooze an alert
  static Future<Alert?> snoozeAlert(
    String alertId,
    Duration duration,
  ) async {
    final alert = getAlert(alertId);
    if (alert == null) return null;

    final snoozed = alert.snooze(duration);
    await _alertsBox?.put(alertId, snoozed.toMap());
    await SyncService.push(HiveBoxes.alerts, alertId, snoozed.toMap());

    LogService.info('Alert snoozed for ${duration.inMinutes} minutes: $alertId');
    return snoozed;
  }

  /// Link alert to task
  static Future<Alert?> linkAlertToTask(String alertId, String taskId) async {
    final alert = getAlert(alertId);
    if (alert == null) return null;

    final linked = alert.linkTask(taskId);
    await _alertsBox?.put(alertId, linked.toMap());
    await SyncService.push(HiveBoxes.alerts, alertId, linked.toMap());

    LogService.info('Alert linked to task: $alertId -> $taskId');
    return linked;
  }

  /// Auto-resolve alerts for a source when condition clears
  static Future<void> autoResolveForSource(
    String sourceType,
    String sourceId,
    AlertType type,
  ) async {
    if (_alertsBox == null) return;

    for (final key in _alertsBox!.keys) {
      final map = _alertsBox!.get(key);
      if (map == null) continue;

      final alert = Alert.fromMap(Map<String, dynamic>.from(map));
      if (alert.sourceType == sourceType &&
          alert.sourceId == sourceId &&
          alert.type == type &&
          alert.isActive) {
        final autoClosed = alert.autoClose();
        await _alertsBox!.put(key, autoClosed.toMap());
        await SyncService.push(HiveBoxes.alerts, key.toString(), autoClosed.toMap());
        LogService.info('Alert auto-resolved: ${alert.id}');
      }
    }
  }

  // ============ ALERT STATISTICS ============

  /// Get alert statistics
  static AlertStatistics getStatistics({DateTime? since}) {
    if (_alertsBox == null) return AlertStatistics.empty();

    final alerts = _alertsBox!.values
        .map((map) => Alert.fromMap(Map<String, dynamic>.from(map)))
        .where((a) => since == null || a.createdAt.isAfter(since))
        .toList();

    final active = alerts.where((a) => a.isActive).length;
    final acknowledged = alerts.where((a) => a.isAcknowledged).length;
    final resolved = alerts.where((a) => a.isResolved).length;

    final responseTimes = alerts
        .where((a) => a.responseTime != null)
        .map((a) => a.responseTime!.inMinutes)
        .toList();

    final avgResponseTime = responseTimes.isEmpty
        ? 0.0
        : responseTimes.reduce((a, b) => a + b) / responseTimes.length;

    final resolutionTimes = alerts
        .where((a) => a.resolutionTime != null)
        .map((a) => a.resolutionTime!.inMinutes)
        .toList();

    final avgResolutionTime = resolutionTimes.isEmpty
        ? 0.0
        : resolutionTimes.reduce((a, b) => a + b) / resolutionTimes.length;

    return AlertStatistics(
      total: alerts.length,
      active: active,
      acknowledged: acknowledged,
      resolved: resolved,
      averageResponseTimeMinutes: avgResponseTime,
      averageResolutionTimeMinutes: avgResolutionTime,
      byType: _countByType(alerts),
      bySeverity: _countBySeverity(alerts),
    );
  }

  static Map<AlertType, int> _countByType(List<Alert> alerts) {
    final counts = <AlertType, int>{};
    for (final type in AlertType.values) {
      counts[type] = alerts.where((a) => a.type == type).length;
    }
    return counts;
  }

  static Map<AlertSeverity, int> _countBySeverity(List<Alert> alerts) {
    final counts = <AlertSeverity, int>{};
    for (final severity in AlertSeverity.values) {
      counts[severity] = alerts.where((a) => a.severity == severity).length;
    }
    return counts;
  }
}

/// Alert statistics
class AlertStatistics {
  final int total;
  final int active;
  final int acknowledged;
  final int resolved;
  final double averageResponseTimeMinutes;
  final double averageResolutionTimeMinutes;
  final Map<AlertType, int> byType;
  final Map<AlertSeverity, int> bySeverity;

  AlertStatistics({
    required this.total,
    required this.active,
    required this.acknowledged,
    required this.resolved,
    required this.averageResponseTimeMinutes,
    required this.averageResolutionTimeMinutes,
    required this.byType,
    required this.bySeverity,
  });

  factory AlertStatistics.empty() => AlertStatistics(
        total: 0,
        active: 0,
        acknowledged: 0,
        resolved: 0,
        averageResponseTimeMinutes: 0,
        averageResolutionTimeMinutes: 0,
        byType: {},
        bySeverity: {},
      );
}
