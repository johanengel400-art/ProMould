/// ProMould Shift Service
/// Manages shifts, assignments, and current shift detection

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/shift_model.dart';
import 'audit_service.dart';
import 'log_service.dart';
import 'sync_service.dart';

class ShiftService {
  static const _uuid = Uuid();
  static Box? _shiftsBox;
  static Box? _assignmentsBox;

  // Cache for current shift detection
  static Shift? _cachedCurrentShift;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 1);

  /// Initialize the shift service
  static Future<void> initialize() async {
    _shiftsBox = await Hive.openBox(HiveBoxes.shifts);
    _assignmentsBox = await Hive.openBox(HiveBoxes.assignments);

    // Ensure default shifts exist
    await _ensureDefaultShifts();

    LogService.info('ShiftService initialized');
  }

  /// Ensure default shifts exist
  static Future<void> _ensureDefaultShifts() async {
    if (_shiftsBox == null) return;

    if (_shiftsBox!.isEmpty) {
      for (final shift in DefaultShifts.all) {
        await _shiftsBox!.put(shift.id, shift.toMap());
        await SyncService.push(HiveBoxes.shifts, shift.id, shift.toMap());
      }
      LogService.info('Default shifts created');
    }
  }

  // ============ SHIFT CRUD ============

  /// Get all shifts
  static List<Shift> getAllShifts() {
    if (_shiftsBox == null) return [];

    return _shiftsBox!.values
        .map((map) => Shift.fromMap(Map<String, dynamic>.from(map)))
        .where((shift) => shift.status == ShiftStatus.active)
        .toList();
  }

  /// Get shift by ID
  static Shift? getShift(String id) {
    if (_shiftsBox == null) return null;

    final map = _shiftsBox!.get(id);
    if (map == null) return null;

    return Shift.fromMap(Map<String, dynamic>.from(map));
  }

  /// Create a new shift
  static Future<Shift> createShift({
    required String name,
    required String startTime,
    required String endTime,
    required List<int> daysOfWeek,
    String? description,
    String? color,
  }) async {
    final shift = Shift(
      id: _uuid.v4(),
      name: name,
      startTime: startTime,
      endTime: endTime,
      daysOfWeek: daysOfWeek,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      description: description,
      color: color,
    );

    await _shiftsBox?.put(shift.id, shift.toMap());
    await SyncService.push(HiveBoxes.shifts, shift.id, shift.toMap());

    await AuditService.logCreate(
      entityType: 'Shift',
      entityId: shift.id,
      data: shift.toMap(),
    );

    LogService.info('Shift created: ${shift.name}');
    return shift;
  }

  /// Update a shift
  static Future<Shift> updateShift(Shift shift) async {
    final oldMap = _shiftsBox?.get(shift.id);
    final updatedShift = shift.copyWith(updatedAt: DateTime.now());

    await _shiftsBox?.put(shift.id, updatedShift.toMap());
    await SyncService.push(HiveBoxes.shifts, shift.id, updatedShift.toMap());

    if (oldMap != null) {
      await AuditService.logUpdate(
        entityType: 'Shift',
        entityId: shift.id,
        beforeValue: Map<String, dynamic>.from(oldMap),
        afterValue: updatedShift.toMap(),
      );
    }

    // Clear cache
    _cachedCurrentShift = null;

    LogService.info('Shift updated: ${shift.name}');
    return updatedShift;
  }

  /// Deactivate a shift
  static Future<void> deactivateShift(String id) async {
    final shift = getShift(id);
    if (shift == null) return;

    final updatedShift = shift.copyWith(status: ShiftStatus.inactive);
    await updateShift(updatedShift);

    LogService.info('Shift deactivated: ${shift.name}');
  }

  // ============ CURRENT SHIFT DETECTION ============

  /// Get the current shift
  static Shift? getCurrentShift() {
    // Check cache
    if (_cachedCurrentShift != null &&
        _cacheTime != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration) {
      return _cachedCurrentShift;
    }

    final shifts = getAllShifts();
    final now = DateTime.now();

    for (final shift in shifts) {
      if (shift.isTimeInShift(now)) {
        _cachedCurrentShift = shift;
        _cacheTime = DateTime.now();
        return shift;
      }
    }

    _cachedCurrentShift = null;
    _cacheTime = DateTime.now();
    return null;
  }

  /// Get current shift ID
  static String? getCurrentShiftId() => getCurrentShift()?.id;

  /// Get current shift name
  static String getCurrentShiftName() => getCurrentShift()?.name ?? 'No Shift';

  /// Check if we're currently in a shift
  static bool isInShift() => getCurrentShift() != null;

  /// Get time remaining in current shift
  static Duration? getTimeRemainingInShift() => getCurrentShift()?.timeRemaining;

  /// Get time elapsed in current shift
  static Duration? getTimeElapsedInShift() => getCurrentShift()?.timeElapsed;

  // ============ SHIFT ASSIGNMENTS ============

  /// Assign user to shift
  static Future<ShiftAssignment> assignUserToShift({
    required String userId,
    required String userName,
    required String shiftId,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    String? createdById,
    String? notes,
  }) async {
    final shift = getShift(shiftId);
    if (shift == null) {
      throw ArgumentError('Shift not found: $shiftId');
    }

    // Deactivate any existing active assignments for this user
    await _deactivateUserAssignments(userId);

    final assignment = ShiftAssignment(
      id: _uuid.v4(),
      userId: userId,
      userName: userName,
      shiftId: shiftId,
      shiftName: shift.name,
      effectiveFrom: effectiveFrom,
      effectiveTo: effectiveTo,
      createdAt: DateTime.now(),
      createdById: createdById,
      notes: notes,
    );

    await _assignmentsBox?.put(assignment.id, assignment.toMap());
    await SyncService.push(
        HiveBoxes.assignments, assignment.id, assignment.toMap());

    await AuditService.logAssignment(
      entityType: 'ShiftAssignment',
      entityId: assignment.id,
      assignedTo: '$userName -> ${shift.name}',
      metadata: {'userId': userId, 'shiftId': shiftId},
    );

    LogService.info('User $userName assigned to shift ${shift.name}');
    return assignment;
  }

  /// Deactivate all active assignments for a user
  static Future<void> _deactivateUserAssignments(String userId) async {
    if (_assignmentsBox == null) return;

    for (final key in _assignmentsBox!.keys) {
      final map = _assignmentsBox!.get(key);
      if (map == null) continue;

      final assignment =
          ShiftAssignment.fromMap(Map<String, dynamic>.from(map));
      if (assignment.userId == userId && assignment.isActive) {
        final updated = ShiftAssignment(
          id: assignment.id,
          userId: assignment.userId,
          userName: assignment.userName,
          shiftId: assignment.shiftId,
          shiftName: assignment.shiftName,
          effectiveFrom: assignment.effectiveFrom,
          effectiveTo: DateTime.now(),
          isActive: false,
          createdAt: assignment.createdAt,
          createdById: assignment.createdById,
          notes: assignment.notes,
        );

        await _assignmentsBox!.put(key, updated.toMap());
        await SyncService.push(HiveBoxes.assignments, key.toString(), updated.toMap());
      }
    }
  }

  /// Get current shift assignment for user
  static ShiftAssignment? getUserShiftAssignment(String userId) {
    if (_assignmentsBox == null) return null;

    for (final map in _assignmentsBox!.values) {
      final assignment =
          ShiftAssignment.fromMap(Map<String, dynamic>.from(map));
      if (assignment.userId == userId && assignment.isCurrentlyEffective) {
        return assignment;
      }
    }

    return null;
  }

  /// Get all users assigned to a shift
  static List<ShiftAssignment> getShiftAssignments(String shiftId) {
    if (_assignmentsBox == null) return [];

    return _assignmentsBox!.values
        .map((map) => ShiftAssignment.fromMap(Map<String, dynamic>.from(map)))
        .where((a) => a.shiftId == shiftId && a.isCurrentlyEffective)
        .toList();
  }

  /// Check if user is on their assigned shift
  static bool isUserOnShift(String userId) {
    final assignment = getUserShiftAssignment(userId);
    if (assignment == null) return false;

    final shift = getShift(assignment.shiftId);
    if (shift == null) return false;

    return shift.isCurrentShift;
  }

  // ============ SHIFT SUMMARY ============

  /// Get shift summary for current shift
  static ShiftSummary getCurrentShiftSummary() {
    final shift = getCurrentShift();
    if (shift == null) {
      return ShiftSummary.empty();
    }

    return ShiftSummary(
      shiftId: shift.id,
      shiftName: shift.name,
      startTime: shift.getStartDateTime(DateTime.now()),
      endTime: shift.getEndDateTime(DateTime.now()),
      timeElapsed: shift.timeElapsed ?? Duration.zero,
      timeRemaining: shift.timeRemaining ?? Duration.zero,
      assignedUsers: getShiftAssignments(shift.id).length,
    );
  }
}

/// Shift summary for display
class ShiftSummary {
  final String? shiftId;
  final String shiftName;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration timeElapsed;
  final Duration timeRemaining;
  final int assignedUsers;

  // Production metrics (to be populated by other services)
  int totalParts;
  int totalScrap;
  double scrapRate;
  int downtimeMinutes;
  int jobsCompleted;
  int issuesReported;

  ShiftSummary({
    this.shiftId,
    required this.shiftName,
    this.startTime,
    this.endTime,
    required this.timeElapsed,
    required this.timeRemaining,
    required this.assignedUsers,
    this.totalParts = 0,
    this.totalScrap = 0,
    this.scrapRate = 0,
    this.downtimeMinutes = 0,
    this.jobsCompleted = 0,
    this.issuesReported = 0,
  });

  factory ShiftSummary.empty() => ShiftSummary(
        shiftName: 'No Active Shift',
        timeElapsed: Duration.zero,
        timeRemaining: Duration.zero,
        assignedUsers: 0,
      );

  /// Progress percentage through shift
  double get progressPercentage {
    final total = timeElapsed + timeRemaining;
    if (total.inMinutes == 0) return 0;
    return (timeElapsed.inMinutes / total.inMinutes) * 100;
  }

  /// Format elapsed time
  String get elapsedFormatted {
    final hours = timeElapsed.inHours;
    final minutes = timeElapsed.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  /// Format remaining time
  String get remainingFormatted {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
