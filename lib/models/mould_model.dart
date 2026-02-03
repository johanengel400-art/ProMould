/// ProMould Mould Model (Digital Mould Passport)
/// Complete mould entity with lifecycle tracking

import '../core/constants.dart';

class Mould {
  final String id;
  final String mouldNumber;
  final String name;
  final String partNumber;
  final String? partDescription;
  final String? customerId;
  final int cavities;
  final double? weight;
  final double? length;
  final double? width;
  final double? height;
  final String? material;
  final String? manufacturer;
  final DateTime? buildDate;
  final double? acquisitionCost;
  final int expectedLifeShots;
  final int maintenanceIntervalShots;
  final int? maintenanceIntervalDays;
  final MouldStatus status;
  final String? locationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Stored counters (part of Digital Mould Passport)
  final int totalLifetimeShots;
  final int shotsSinceLastMaintenance;
  final int shotsSinceLastMajorService;
  final DateTime? lastMaintenanceDate;
  final DateTime? lastMajorServiceDate;

  // Photo/drawing URLs
  final String? imageUrl;
  final String? drawingUrl;

  // Notes and documentation
  final String? notes;
  final List<String>? tags;

  Mould({
    required this.id,
    required this.mouldNumber,
    required this.name,
    required this.partNumber,
    this.partDescription,
    this.customerId,
    required this.cavities,
    this.weight,
    this.length,
    this.width,
    this.height,
    this.material,
    this.manufacturer,
    this.buildDate,
    this.acquisitionCost,
    this.expectedLifeShots = 1000000,
    this.maintenanceIntervalShots = 50000,
    this.maintenanceIntervalDays,
    this.status = MouldStatus.active,
    this.locationId,
    required this.createdAt,
    required this.updatedAt,
    this.totalLifetimeShots = 0,
    this.shotsSinceLastMaintenance = 0,
    this.shotsSinceLastMajorService = 0,
    this.lastMaintenanceDate,
    this.lastMajorServiceDate,
    this.imageUrl,
    this.drawingUrl,
    this.notes,
    this.tags,
  });

  // ============ DERIVED STATE (never stored) ============

  /// Remaining life in shots
  int get remainingLife => expectedLifeShots - totalLifetimeShots;

  /// Life percentage used
  double get lifePercentage =>
      expectedLifeShots > 0 ? (totalLifetimeShots / expectedLifeShots) * 100 : 0;

  /// Remaining life percentage
  double get remainingLifePercentage => 100 - lifePercentage;

  /// Is maintenance due based on shots
  bool get isMaintenanceDueByShots =>
      shotsSinceLastMaintenance >= maintenanceIntervalShots;

  /// Is maintenance due based on days (if configured)
  bool get isMaintenanceDueByDays {
    if (maintenanceIntervalDays == null || lastMaintenanceDate == null) {
      return false;
    }
    final daysSinceMaintenance =
        DateTime.now().difference(lastMaintenanceDate!).inDays;
    return daysSinceMaintenance >= maintenanceIntervalDays!;
  }

  /// Is maintenance due (either condition)
  bool get isMaintenanceDue => isMaintenanceDueByShots || isMaintenanceDueByDays;

  /// Maintenance due percentage (for warning at 90%)
  double get maintenanceDuePercentage => maintenanceIntervalShots > 0
      ? (shotsSinceLastMaintenance / maintenanceIntervalShots) * 100
      : 0;

  /// Is maintenance warning (approaching due)
  bool get isMaintenanceWarning =>
      maintenanceDuePercentage >= SystemThresholds.maintenanceDueWarningPercent &&
      !isMaintenanceDue;

  /// Is mould usable for production
  bool get isUsable => status.isUsable;

  /// Is mould at end of life
  bool get isEndOfLife => remainingLife <= 0;

  /// Life status
  String get lifeStatus {
    if (isEndOfLife) return 'endOfLife';
    if (lifePercentage >= 90) return 'critical';
    if (lifePercentage >= 75) return 'warning';
    if (lifePercentage >= 50) return 'moderate';
    return 'good';
  }

  /// Maintenance status
  String get maintenanceStatus {
    if (isMaintenanceDue) return 'overdue';
    if (isMaintenanceWarning) return 'warning';
    return 'ok';
  }

  // ============ METHODS ============

  /// Create a copy with updated fields
  Mould copyWith({
    String? id,
    String? mouldNumber,
    String? name,
    String? partNumber,
    String? partDescription,
    String? customerId,
    int? cavities,
    double? weight,
    double? length,
    double? width,
    double? height,
    String? material,
    String? manufacturer,
    DateTime? buildDate,
    double? acquisitionCost,
    int? expectedLifeShots,
    int? maintenanceIntervalShots,
    int? maintenanceIntervalDays,
    MouldStatus? status,
    String? locationId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalLifetimeShots,
    int? shotsSinceLastMaintenance,
    int? shotsSinceLastMajorService,
    DateTime? lastMaintenanceDate,
    DateTime? lastMajorServiceDate,
    String? imageUrl,
    String? drawingUrl,
    String? notes,
    List<String>? tags,
  }) {
    return Mould(
      id: id ?? this.id,
      mouldNumber: mouldNumber ?? this.mouldNumber,
      name: name ?? this.name,
      partNumber: partNumber ?? this.partNumber,
      partDescription: partDescription ?? this.partDescription,
      customerId: customerId ?? this.customerId,
      cavities: cavities ?? this.cavities,
      weight: weight ?? this.weight,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      material: material ?? this.material,
      manufacturer: manufacturer ?? this.manufacturer,
      buildDate: buildDate ?? this.buildDate,
      acquisitionCost: acquisitionCost ?? this.acquisitionCost,
      expectedLifeShots: expectedLifeShots ?? this.expectedLifeShots,
      maintenanceIntervalShots:
          maintenanceIntervalShots ?? this.maintenanceIntervalShots,
      maintenanceIntervalDays:
          maintenanceIntervalDays ?? this.maintenanceIntervalDays,
      status: status ?? this.status,
      locationId: locationId ?? this.locationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      totalLifetimeShots: totalLifetimeShots ?? this.totalLifetimeShots,
      shotsSinceLastMaintenance:
          shotsSinceLastMaintenance ?? this.shotsSinceLastMaintenance,
      shotsSinceLastMajorService:
          shotsSinceLastMajorService ?? this.shotsSinceLastMajorService,
      lastMaintenanceDate: lastMaintenanceDate ?? this.lastMaintenanceDate,
      lastMajorServiceDate: lastMajorServiceDate ?? this.lastMajorServiceDate,
      imageUrl: imageUrl ?? this.imageUrl,
      drawingUrl: drawingUrl ?? this.drawingUrl,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
    );
  }

  /// Add shots to the mould (called when production is logged)
  Mould addShots(int shots) {
    return copyWith(
      totalLifetimeShots: totalLifetimeShots + shots,
      shotsSinceLastMaintenance: shotsSinceLastMaintenance + shots,
      shotsSinceLastMajorService: shotsSinceLastMajorService + shots,
    );
  }

  /// Record maintenance performed
  Mould recordMaintenance({bool isMajorService = false}) {
    return copyWith(
      shotsSinceLastMaintenance: 0,
      lastMaintenanceDate: DateTime.now(),
      shotsSinceLastMajorService:
          isMajorService ? 0 : shotsSinceLastMajorService,
      lastMajorServiceDate: isMajorService ? DateTime.now() : lastMajorServiceDate,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'mouldNumber': mouldNumber,
        'name': name,
        'partNumber': partNumber,
        'partDescription': partDescription,
        'customerId': customerId,
        'cavities': cavities,
        'weight': weight,
        'length': length,
        'width': width,
        'height': height,
        'material': material,
        'manufacturer': manufacturer,
        'buildDate': buildDate?.toIso8601String(),
        'acquisitionCost': acquisitionCost,
        'expectedLifeShots': expectedLifeShots,
        'maintenanceIntervalShots': maintenanceIntervalShots,
        'maintenanceIntervalDays': maintenanceIntervalDays,
        'status': status.name,
        'locationId': locationId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'totalLifetimeShots': totalLifetimeShots,
        'shotsSinceLastMaintenance': shotsSinceLastMaintenance,
        'shotsSinceLastMajorService': shotsSinceLastMajorService,
        'lastMaintenanceDate': lastMaintenanceDate?.toIso8601String(),
        'lastMajorServiceDate': lastMajorServiceDate?.toIso8601String(),
        'imageUrl': imageUrl,
        'drawingUrl': drawingUrl,
        'notes': notes,
        'tags': tags,
      };

  /// Create from map
  factory Mould.fromMap(Map<String, dynamic> map) => Mould(
        id: map['id'] as String,
        mouldNumber: map['mouldNumber'] as String? ?? map['id'] as String,
        name: map['name'] as String? ?? 'Unknown',
        partNumber: map['partNumber'] as String? ?? '',
        partDescription: map['partDescription'] as String?,
        customerId: map['customerId'] as String?,
        cavities: map['cavities'] as int? ?? 1,
        weight: _parseDouble(map['weight']),
        length: _parseDouble(map['length']),
        width: _parseDouble(map['width']),
        height: _parseDouble(map['height']),
        material: map['material'] as String?,
        manufacturer: map['manufacturer'] as String?,
        buildDate: _parseDateTime(map['buildDate']),
        acquisitionCost: _parseDouble(map['acquisitionCost']),
        expectedLifeShots: map['expectedLifeShots'] as int? ?? 1000000,
        maintenanceIntervalShots: map['maintenanceIntervalShots'] as int? ?? 50000,
        maintenanceIntervalDays: map['maintenanceIntervalDays'] as int?,
        status: _parseStatus(map['status']),
        locationId: map['locationId'] as String?,
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        totalLifetimeShots: map['totalLifetimeShots'] as int? ?? 0,
        shotsSinceLastMaintenance: map['shotsSinceLastMaintenance'] as int? ?? 0,
        shotsSinceLastMajorService: map['shotsSinceLastMajorService'] as int? ?? 0,
        lastMaintenanceDate: _parseDateTime(map['lastMaintenanceDate']),
        lastMajorServiceDate: _parseDateTime(map['lastMajorServiceDate']),
        imageUrl: map['imageUrl'] as String?,
        drawingUrl: map['drawingUrl'] as String?,
        notes: map['notes'] as String?,
        tags: (map['tags'] as List?)?.cast<String>(),
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

  static MouldStatus _parseStatus(dynamic value) {
    if (value == null) return MouldStatus.active;
    if (value is MouldStatus) return value;
    if (value is String) {
      return MouldStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => MouldStatus.active,
      );
    }
    return MouldStatus.active;
  }

  @override
  String toString() => 'Mould($mouldNumber, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Mould && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Mould maintenance record
class MouldMaintenanceRecord {
  final String id;
  final String mouldId;
  final DateTime performedAt;
  final String performedById;
  final String performedByName;
  final bool isMajorService;
  final int shotsBefore;
  final String? notes;
  final List<String>? partsReplaced;
  final double? cost;
  final Duration? duration;

  MouldMaintenanceRecord({
    required this.id,
    required this.mouldId,
    required this.performedAt,
    required this.performedById,
    required this.performedByName,
    this.isMajorService = false,
    required this.shotsBefore,
    this.notes,
    this.partsReplaced,
    this.cost,
    this.duration,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'mouldId': mouldId,
        'performedAt': performedAt.toIso8601String(),
        'performedById': performedById,
        'performedByName': performedByName,
        'isMajorService': isMajorService,
        'shotsBefore': shotsBefore,
        'notes': notes,
        'partsReplaced': partsReplaced,
        'cost': cost,
        'durationMinutes': duration?.inMinutes,
      };

  factory MouldMaintenanceRecord.fromMap(Map<String, dynamic> map) =>
      MouldMaintenanceRecord(
        id: map['id'] as String,
        mouldId: map['mouldId'] as String,
        performedAt: DateTime.parse(map['performedAt'] as String),
        performedById: map['performedById'] as String,
        performedByName: map['performedByName'] as String,
        isMajorService: map['isMajorService'] as bool? ?? false,
        shotsBefore: map['shotsBefore'] as int,
        notes: map['notes'] as String?,
        partsReplaced: (map['partsReplaced'] as List?)?.cast<String>(),
        cost: map['cost'] as double?,
        duration: map['durationMinutes'] != null
            ? Duration(minutes: map['durationMinutes'] as int)
            : null,
      );
}

/// Mould-Machine compatibility record
class MouldMachineCompatibility {
  final String id;
  final String mouldId;
  final String machineId;
  final bool isCompatible;
  final String? incompatibilityReason;
  final DateTime verifiedAt;
  final String verifiedById;

  MouldMachineCompatibility({
    required this.id,
    required this.mouldId,
    required this.machineId,
    required this.isCompatible,
    this.incompatibilityReason,
    required this.verifiedAt,
    required this.verifiedById,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'mouldId': mouldId,
        'machineId': machineId,
        'isCompatible': isCompatible,
        'incompatibilityReason': incompatibilityReason,
        'verifiedAt': verifiedAt.toIso8601String(),
        'verifiedById': verifiedById,
      };

  factory MouldMachineCompatibility.fromMap(Map<String, dynamic> map) =>
      MouldMachineCompatibility(
        id: map['id'] as String,
        mouldId: map['mouldId'] as String,
        machineId: map['machineId'] as String,
        isCompatible: map['isCompatible'] as bool,
        incompatibilityReason: map['incompatibilityReason'] as String?,
        verifiedAt: DateTime.parse(map['verifiedAt'] as String),
        verifiedById: map['verifiedById'] as String,
      );
}
