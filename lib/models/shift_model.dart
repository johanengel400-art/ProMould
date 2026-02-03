/// ProMould Shift Model
/// Shift management with schedule and assignment

class Shift {
  final String id;
  final String name;
  final String startTime; // HH:mm format
  final String endTime; // HH:mm format
  final List<int> daysOfWeek; // 1=Monday, 7=Sunday
  final ShiftStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description;
  final String? color; // For UI display

  Shift({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.daysOfWeek,
    this.status = ShiftStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.color,
  });

  // ============ DERIVED STATE ============

  /// Parse start time to minutes since midnight
  int get startMinutes {
    final parts = startTime.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Parse end time to minutes since midnight
  int get endMinutes {
    final parts = endTime.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  /// Is this an overnight shift (crosses midnight)
  bool get isOvernightShift => endMinutes < startMinutes;

  /// Shift duration in minutes
  int get durationMinutes {
    if (isOvernightShift) {
      return (24 * 60 - startMinutes) + endMinutes;
    }
    return endMinutes - startMinutes;
  }

  /// Shift duration in hours
  double get durationHours => durationMinutes / 60;

  /// Check if a given time falls within this shift
  bool isTimeInShift(DateTime time) {
    final dayOfWeek = time.weekday; // 1=Monday, 7=Sunday
    if (!daysOfWeek.contains(dayOfWeek)) return false;

    final currentMinutes = time.hour * 60 + time.minute;

    if (isOvernightShift) {
      // Shift crosses midnight
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // Normal shift
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  /// Check if this is the current shift
  bool get isCurrentShift => isTimeInShift(DateTime.now());

  /// Get shift start DateTime for a given date
  DateTime getStartDateTime(DateTime date) {
    final parts = startTime.split(':');
    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Get shift end DateTime for a given date
  DateTime getEndDateTime(DateTime date) {
    final parts = endTime.split(':');
    var endDate = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    // If overnight shift, end is next day
    if (isOvernightShift) {
      endDate = endDate.add(const Duration(days: 1));
    }

    return endDate;
  }

  /// Get time remaining in current shift (if active)
  Duration? get timeRemaining {
    if (!isCurrentShift) return null;

    final now = DateTime.now();
    final endDateTime = getEndDateTime(now);

    // Adjust for overnight shifts
    if (isOvernightShift && now.hour < endMinutes ~/ 60) {
      // We're in the early morning part of an overnight shift
      return endDateTime.difference(now);
    }

    return endDateTime.difference(now);
  }

  /// Get time elapsed in current shift (if active)
  Duration? get timeElapsed {
    if (!isCurrentShift) return null;

    final now = DateTime.now();
    var startDateTime = getStartDateTime(now);

    // Adjust for overnight shifts
    if (isOvernightShift && now.hour < endMinutes ~/ 60) {
      // We're in the early morning part of an overnight shift
      startDateTime = startDateTime.subtract(const Duration(days: 1));
    }

    return now.difference(startDateTime);
  }

  // ============ METHODS ============

  /// Create a copy with updated fields
  Shift copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    List<int>? daysOfWeek,
    ShiftStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? color,
  }) {
    return Shift(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      description: description ?? this.description,
      color: color ?? this.color,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'daysOfWeek': daysOfWeek,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'description': description,
        'color': color,
      };

  /// Create from map
  factory Shift.fromMap(Map<String, dynamic> map) => Shift(
        id: map['id'] as String,
        name: map['name'] as String,
        startTime: map['startTime'] as String,
        endTime: map['endTime'] as String,
        daysOfWeek: (map['daysOfWeek'] as List?)?.cast<int>() ?? [1, 2, 3, 4, 5],
        status: ShiftStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => ShiftStatus.active,
        ),
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        description: map['description'] as String?,
        color: map['color'] as String?,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'Shift($name, $startTime-$endTime)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Shift && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Shift status
enum ShiftStatus {
  active('Active'),
  inactive('Inactive');

  final String displayName;
  const ShiftStatus(this.displayName);
}

/// User shift assignment
class ShiftAssignment {
  final String id;
  final String userId;
  final String userName;
  final String shiftId;
  final String shiftName;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;
  final DateTime createdAt;
  final String? createdById;
  final String? notes;

  ShiftAssignment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.shiftId,
    required this.shiftName,
    required this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
    required this.createdAt,
    this.createdById,
    this.notes,
  });

  /// Is assignment currently effective
  bool get isCurrentlyEffective {
    if (!isActive) return false;
    final now = DateTime.now();
    if (now.isBefore(effectiveFrom)) return false;
    if (effectiveTo != null && now.isAfter(effectiveTo!)) return false;
    return true;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'shiftId': shiftId,
        'shiftName': shiftName,
        'effectiveFrom': effectiveFrom.toIso8601String(),
        'effectiveTo': effectiveTo?.toIso8601String(),
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'createdById': createdById,
        'notes': notes,
      };

  factory ShiftAssignment.fromMap(Map<String, dynamic> map) => ShiftAssignment(
        id: map['id'] as String,
        userId: map['userId'] as String,
        userName: map['userName'] as String,
        shiftId: map['shiftId'] as String,
        shiftName: map['shiftName'] as String,
        effectiveFrom: DateTime.parse(map['effectiveFrom'] as String),
        effectiveTo: map['effectiveTo'] != null
            ? DateTime.parse(map['effectiveTo'] as String)
            : null,
        isActive: map['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(map['createdAt'] as String),
        createdById: map['createdById'] as String?,
        notes: map['notes'] as String?,
      );
}

/// Shift swap request
class ShiftSwapRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterShiftId;
  final String targetUserId;
  final String targetUserName;
  final String targetShiftId;
  final DateTime swapDate;
  final ShiftSwapStatus status;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final String? approvedById;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? reason;
  final String? rejectionReason;

  ShiftSwapRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterShiftId,
    required this.targetUserId,
    required this.targetUserName,
    required this.targetShiftId,
    required this.swapDate,
    this.status = ShiftSwapStatus.pending,
    required this.requestedAt,
    this.respondedAt,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
    this.reason,
    this.rejectionReason,
  });

  /// Is request pending
  bool get isPending => status == ShiftSwapStatus.pending;

  /// Is request approved
  bool get isApproved => status == ShiftSwapStatus.approved;

  Map<String, dynamic> toMap() => {
        'id': id,
        'requesterId': requesterId,
        'requesterName': requesterName,
        'requesterShiftId': requesterShiftId,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
        'targetShiftId': targetShiftId,
        'swapDate': swapDate.toIso8601String(),
        'status': status.name,
        'requestedAt': requestedAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        'approvedById': approvedById,
        'approvedByName': approvedByName,
        'approvedAt': approvedAt?.toIso8601String(),
        'reason': reason,
        'rejectionReason': rejectionReason,
      };

  factory ShiftSwapRequest.fromMap(Map<String, dynamic> map) => ShiftSwapRequest(
        id: map['id'] as String,
        requesterId: map['requesterId'] as String,
        requesterName: map['requesterName'] as String,
        requesterShiftId: map['requesterShiftId'] as String,
        targetUserId: map['targetUserId'] as String,
        targetUserName: map['targetUserName'] as String,
        targetShiftId: map['targetShiftId'] as String,
        swapDate: DateTime.parse(map['swapDate'] as String),
        status: ShiftSwapStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => ShiftSwapStatus.pending,
        ),
        requestedAt: DateTime.parse(map['requestedAt'] as String),
        respondedAt: map['respondedAt'] != null
            ? DateTime.parse(map['respondedAt'] as String)
            : null,
        approvedById: map['approvedById'] as String?,
        approvedByName: map['approvedByName'] as String?,
        approvedAt: map['approvedAt'] != null
            ? DateTime.parse(map['approvedAt'] as String)
            : null,
        reason: map['reason'] as String?,
        rejectionReason: map['rejectionReason'] as String?,
      );
}

/// Shift swap status
enum ShiftSwapStatus {
  pending('Pending'),
  accepted('Accepted by Target'),
  approved('Approved'),
  rejected('Rejected'),
  cancelled('Cancelled');

  final String displayName;
  const ShiftSwapStatus(this.displayName);
}

/// Default shift configurations
class DefaultShifts {
  static Shift dayShift() => Shift(
        id: 'day',
        name: 'Day Shift',
        startTime: '06:00',
        endTime: '18:00',
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#4CAF50',
      );

  static Shift nightShift() => Shift(
        id: 'night',
        name: 'Night Shift',
        startTime: '18:00',
        endTime: '06:00',
        daysOfWeek: [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#2196F3',
      );

  static List<Shift> get all => [dayShift(), nightShift()];
}
