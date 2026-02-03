/// ProMould Machine Model
/// Complete machine entity with live counter support

import '../core/constants.dart';

class Machine {
  final String id;
  final String name;
  final String machineNumber;
  final String? type;
  final String? manufacturer;
  final String? model;
  final String? serialNumber;
  final double? tonnage;
  final double? clampForce;
  final double? shotSize;
  final double? platenWidth;
  final double? platenHeight;
  final double? tieBarSpacing;
  final double? maxMouldWeight;
  final String floorId;
  final MachineStatus status;
  final DateTime? statusChangedAt;
  final String? statusReason;
  final DateTime? installationDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Stored counter (reconcilable)
  final int totalLifetimeShots;

  // Machine parameters (stored)
  final Map<String, dynamic>? parameters;

  // Photo/image URL
  final String? imageUrl;

  Machine({
    required this.id,
    required this.name,
    required this.machineNumber,
    this.type,
    this.manufacturer,
    this.model,
    this.serialNumber,
    this.tonnage,
    this.clampForce,
    this.shotSize,
    this.platenWidth,
    this.platenHeight,
    this.tieBarSpacing,
    this.maxMouldWeight,
    required this.floorId,
    this.status = MachineStatus.idle,
    this.statusChangedAt,
    this.statusReason,
    this.installationDate,
    required this.createdAt,
    required this.updatedAt,
    this.totalLifetimeShots = 0,
    this.parameters,
    this.imageUrl,
  });

  /// Check if machine is productive
  bool get isProductive => status.isProductive;

  /// Check if machine is available for new jobs
  bool get isAvailable => status.isAvailable;

  /// Check if machine requires attention
  bool get requiresAttention => status.requiresAttention;

  /// Get status duration
  Duration? get statusDuration {
    if (statusChangedAt == null) return null;
    return DateTime.now().difference(statusChangedAt!);
  }

  /// Create a copy with updated fields
  Machine copyWith({
    String? id,
    String? name,
    String? machineNumber,
    String? type,
    String? manufacturer,
    String? model,
    String? serialNumber,
    double? tonnage,
    double? clampForce,
    double? shotSize,
    double? platenWidth,
    double? platenHeight,
    double? tieBarSpacing,
    double? maxMouldWeight,
    String? floorId,
    MachineStatus? status,
    DateTime? statusChangedAt,
    String? statusReason,
    DateTime? installationDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalLifetimeShots,
    Map<String, dynamic>? parameters,
    String? imageUrl,
  }) {
    return Machine(
      id: id ?? this.id,
      name: name ?? this.name,
      machineNumber: machineNumber ?? this.machineNumber,
      type: type ?? this.type,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      serialNumber: serialNumber ?? this.serialNumber,
      tonnage: tonnage ?? this.tonnage,
      clampForce: clampForce ?? this.clampForce,
      shotSize: shotSize ?? this.shotSize,
      platenWidth: platenWidth ?? this.platenWidth,
      platenHeight: platenHeight ?? this.platenHeight,
      tieBarSpacing: tieBarSpacing ?? this.tieBarSpacing,
      maxMouldWeight: maxMouldWeight ?? this.maxMouldWeight,
      floorId: floorId ?? this.floorId,
      status: status ?? this.status,
      statusChangedAt: statusChangedAt ?? this.statusChangedAt,
      statusReason: statusReason ?? this.statusReason,
      installationDate: installationDate ?? this.installationDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      totalLifetimeShots: totalLifetimeShots ?? this.totalLifetimeShots,
      parameters: parameters ?? this.parameters,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'machineNumber': machineNumber,
        'type': type,
        'manufacturer': manufacturer,
        'model': model,
        'serialNumber': serialNumber,
        'tonnage': tonnage,
        'clampForce': clampForce,
        'shotSize': shotSize,
        'platenWidth': platenWidth,
        'platenHeight': platenHeight,
        'tieBarSpacing': tieBarSpacing,
        'maxMouldWeight': maxMouldWeight,
        'floorId': floorId,
        'status': status.name,
        'statusChangedAt': statusChangedAt?.toIso8601String(),
        'statusReason': statusReason,
        'installationDate': installationDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'totalLifetimeShots': totalLifetimeShots,
        'parameters': parameters,
        'imageUrl': imageUrl,
      };

  /// Create from map
  factory Machine.fromMap(Map<String, dynamic> map) => Machine(
        id: map['id'] as String,
        name: map['name'] as String? ?? 'Unknown',
        machineNumber: map['machineNumber'] as String? ?? map['id'] as String,
        type: map['type'] as String?,
        manufacturer: map['manufacturer'] as String?,
        model: map['model'] as String?,
        serialNumber: map['serialNumber'] as String?,
        tonnage: _parseDouble(map['tonnage']),
        clampForce: _parseDouble(map['clampForce']),
        shotSize: _parseDouble(map['shotSize']),
        platenWidth: _parseDouble(map['platenWidth']),
        platenHeight: _parseDouble(map['platenHeight']),
        tieBarSpacing: _parseDouble(map['tieBarSpacing']),
        maxMouldWeight: _parseDouble(map['maxMouldWeight']),
        floorId: map['floorId'] as String? ?? 'default',
        status: _parseStatus(map['status']),
        statusChangedAt: _parseDateTime(map['statusChangedAt']),
        statusReason: map['statusReason'] as String?,
        installationDate: _parseDateTime(map['installationDate']),
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        totalLifetimeShots: map['totalLifetimeShots'] as int? ?? 0,
        parameters: map['parameters'] as Map<String, dynamic>?,
        imageUrl: map['imageUrl'] as String?,
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

  static MachineStatus _parseStatus(dynamic value) {
    if (value == null) return MachineStatus.idle;
    if (value is MachineStatus) return value;
    if (value is String) {
      // Handle legacy status names
      switch (value.toLowerCase()) {
        case 'running':
        case 'active':
          return MachineStatus.running;
        case 'idle':
        case 'available':
          return MachineStatus.idle;
        case 'down':
        case 'breakdown':
        case 'broken':
          return MachineStatus.down;
        case 'setup':
        case 'changeover':
          return MachineStatus.setup;
        case 'maintenance':
        case 'pm':
          return MachineStatus.maintenance;
        default:
          return MachineStatus.values.firstWhere(
            (s) => s.name == value,
            orElse: () => MachineStatus.idle,
          );
      }
    }
    return MachineStatus.idle;
  }

  @override
  String toString() => 'Machine($name, $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Machine && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Machine with derived state (for UI display)
/// This class adds computed properties that should never be stored
class MachineWithState {
  final Machine machine;

  // Derived from current job assignment
  final String? currentJobId;
  final String? currentJobNumber;

  // Derived from current mould assignment
  final String? currentMouldId;
  final String? currentMouldNumber;

  // Derived from machine assignment
  final String? currentOperatorId;
  final String? currentOperatorName;

  // Derived from job progress
  final int? liveCounter;
  final int? partsProduced;
  final int? targetQuantity;
  final double? progressPercentage;

  // Derived from cycle time
  final double? currentCycleTime;
  final double? targetCycleTime;
  final double? cycleTimeVariance;

  // Derived from scrap
  final int? scrapCount;
  final double? scrapRate;

  // Derived from OEE calculation
  final double? oee;
  final double? availability;
  final double? performance;
  final double? quality;

  // Derived from health calculation
  final int? healthScore;
  final String? healthGrade;

  // Derived from ETA calculation
  final DateTime? eta;
  final bool? isOverrunning;

  // Derived from downtime
  final int? downtimeMinutes;
  final double? downtimeRate;

  MachineWithState({
    required this.machine,
    this.currentJobId,
    this.currentJobNumber,
    this.currentMouldId,
    this.currentMouldNumber,
    this.currentOperatorId,
    this.currentOperatorName,
    this.liveCounter,
    this.partsProduced,
    this.targetQuantity,
    this.progressPercentage,
    this.currentCycleTime,
    this.targetCycleTime,
    this.cycleTimeVariance,
    this.scrapCount,
    this.scrapRate,
    this.oee,
    this.availability,
    this.performance,
    this.quality,
    this.healthScore,
    this.healthGrade,
    this.eta,
    this.isOverrunning,
    this.downtimeMinutes,
    this.downtimeRate,
  });

  // Convenience getters
  String get id => machine.id;
  String get name => machine.name;
  MachineStatus get status => machine.status;
  String get floorId => machine.floorId;

  /// Get scrap rate status color
  String get scrapRateStatus {
    if (scrapRate == null) return 'unknown';
    if (scrapRate! < SystemThresholds.scrapExcellent) return 'excellent';
    if (scrapRate! < SystemThresholds.scrapAcceptable) return 'acceptable';
    if (scrapRate! < SystemThresholds.scrapConcerning) return 'concerning';
    return 'critical';
  }

  /// Get OEE status
  String get oeeStatus {
    if (oee == null) return 'unknown';
    if (oee! >= SystemThresholds.oeeWorldClass) return 'worldClass';
    if (oee! >= SystemThresholds.oeeGood) return 'good';
    if (oee! >= SystemThresholds.oeeFair) return 'fair';
    return 'poor';
  }

  /// Get health status
  String get healthStatus {
    if (healthScore == null) return 'unknown';
    if (healthScore! >= SystemThresholds.healthExcellent) return 'excellent';
    if (healthScore! >= SystemThresholds.healthGood) return 'good';
    if (healthScore! >= SystemThresholds.healthFair) return 'fair';
    return 'poor';
  }
}
