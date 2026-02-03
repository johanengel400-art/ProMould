/// ProMould Material Model
/// Material management with stock tracking

import '../core/constants.dart';

class Material {
  final String id;
  final String materialCode;
  final String name;
  final String? description;
  final MaterialType type;
  final String? grade;
  final String? supplierId;
  final String? supplierName;
  final String unitOfMeasure;
  final double costPerUnit;
  final double minimumStock;
  final double maximumStock;
  final double reorderPoint;
  final MaterialStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Storage location
  final String? locationId;
  final String? locationName;

  // Notes and metadata
  final String? notes;
  final Map<String, dynamic>? metadata;

  Material({
    required this.id,
    required this.materialCode,
    required this.name,
    this.description,
    required this.type,
    this.grade,
    this.supplierId,
    this.supplierName,
    required this.unitOfMeasure,
    this.costPerUnit = 0,
    this.minimumStock = 0,
    this.maximumStock = 0,
    this.reorderPoint = 0,
    this.status = MaterialStatus.active,
    required this.createdAt,
    required this.updatedAt,
    this.locationId,
    this.locationName,
    this.notes,
    this.metadata,
  });

  // ============ NOTE: Stock is DERIVED, not stored here ============
  // Current stock is calculated from StockMovement records
  // This ensures single source of truth

  /// Create a copy with updated fields
  Material copyWith({
    String? id,
    String? materialCode,
    String? name,
    String? description,
    MaterialType? type,
    String? grade,
    String? supplierId,
    String? supplierName,
    String? unitOfMeasure,
    double? costPerUnit,
    double? minimumStock,
    double? maximumStock,
    double? reorderPoint,
    MaterialStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? locationId,
    String? locationName,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return Material(
      id: id ?? this.id,
      materialCode: materialCode ?? this.materialCode,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      grade: grade ?? this.grade,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      minimumStock: minimumStock ?? this.minimumStock,
      maximumStock: maximumStock ?? this.maximumStock,
      reorderPoint: reorderPoint ?? this.reorderPoint,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'materialCode': materialCode,
        'name': name,
        'description': description,
        'type': type.name,
        'grade': grade,
        'supplierId': supplierId,
        'supplierName': supplierName,
        'unitOfMeasure': unitOfMeasure,
        'costPerUnit': costPerUnit,
        'minimumStock': minimumStock,
        'maximumStock': maximumStock,
        'reorderPoint': reorderPoint,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'locationId': locationId,
        'locationName': locationName,
        'notes': notes,
        'metadata': metadata,
      };

  /// Create from map
  factory Material.fromMap(Map<String, dynamic> map) => Material(
        id: map['id'] as String,
        materialCode: map['materialCode'] as String? ?? map['id'] as String,
        name: map['name'] as String? ?? 'Unknown',
        description: map['description'] as String?,
        type: MaterialType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => MaterialType.resin,
        ),
        grade: map['grade'] as String?,
        supplierId: map['supplierId'] as String?,
        supplierName: map['supplierName'] as String?,
        unitOfMeasure: map['unitOfMeasure'] as String? ?? 'kg',
        costPerUnit: (map['costPerUnit'] as num?)?.toDouble() ?? 0,
        minimumStock: (map['minimumStock'] as num?)?.toDouble() ?? 0,
        maximumStock: (map['maximumStock'] as num?)?.toDouble() ?? 0,
        reorderPoint: (map['reorderPoint'] as num?)?.toDouble() ?? 0,
        status: MaterialStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => MaterialStatus.active,
        ),
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        locationId: map['locationId'] as String?,
        locationName: map['locationName'] as String?,
        notes: map['notes'] as String?,
        metadata: map['metadata'] as Map<String, dynamic>?,
      );

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'Material($materialCode, $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Material && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// Material type
enum MaterialType {
  resin('Resin'),
  colorant('Colorant'),
  additive('Additive'),
  packaging('Packaging'),
  consumable('Consumable'),
  other('Other');

  final String displayName;
  const MaterialType(this.displayName);
}

/// Material status
enum MaterialStatus {
  active('Active'),
  inactive('Inactive'),
  discontinued('Discontinued'),
  onHold('On Hold');

  final String displayName;
  const MaterialStatus(this.displayName);
}

/// Material with derived stock state (for UI display)
class MaterialWithStock {
  final Material material;
  final double currentStock;
  final double reservedStock;
  final double availableStock;

  MaterialWithStock({
    required this.material,
    required this.currentStock,
    this.reservedStock = 0,
  }) : availableStock = currentStock - reservedStock;

  // Convenience getters
  String get id => material.id;
  String get name => material.name;
  String get materialCode => material.materialCode;
  double get minimumStock => material.minimumStock;
  double get reorderPoint => material.reorderPoint;

  /// Is stock low (at or below reorder point)
  bool get isLowStock => currentStock <= material.reorderPoint;

  /// Is stock critical (at or below minimum)
  bool get isCriticalStock => currentStock <= material.minimumStock;

  /// Is out of stock
  bool get isOutOfStock => currentStock <= 0;

  /// Stock status
  String get stockStatus {
    if (isOutOfStock) return 'outOfStock';
    if (isCriticalStock) return 'critical';
    if (isLowStock) return 'low';
    return 'ok';
  }

  /// Days of stock remaining (based on average consumption)
  int? daysOfStock(double averageDailyConsumption) {
    if (averageDailyConsumption <= 0) return null;
    return (availableStock / averageDailyConsumption).floor();
  }
}

/// Stock movement record (append-only ledger)
class StockMovement {
  final String id;
  final String materialId;
  final StockMovementType type;
  final double quantity; // Positive for in, negative for out
  final double balanceAfter; // Running balance after this movement
  final DateTime timestamp;
  final String userId;
  final String userName;

  // Reference to related entity
  final String? jobId;
  final String? jobNumber;
  final String? machineId;
  final String? machineName;

  // Batch/lot tracking
  final String? batchNumber;
  final String? lotNumber;
  final DateTime? expiryDate;

  // Notes and reason
  final String? reason;
  final String? notes;

  // For adjustments - requires approval
  final String? approvedById;
  final String? approvedByName;
  final DateTime? approvedAt;

  StockMovement({
    required this.id,
    required this.materialId,
    required this.type,
    required this.quantity,
    required this.balanceAfter,
    required this.timestamp,
    required this.userId,
    required this.userName,
    this.jobId,
    this.jobNumber,
    this.machineId,
    this.machineName,
    this.batchNumber,
    this.lotNumber,
    this.expiryDate,
    this.reason,
    this.notes,
    this.approvedById,
    this.approvedByName,
    this.approvedAt,
  });

  /// Is this an inbound movement
  bool get isInbound => quantity > 0;

  /// Is this an outbound movement
  bool get isOutbound => quantity < 0;

  /// Absolute quantity
  double get absoluteQuantity => quantity.abs();

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'type': type.name,
        'quantity': quantity,
        'balanceAfter': balanceAfter,
        'timestamp': timestamp.toIso8601String(),
        'userId': userId,
        'userName': userName,
        'jobId': jobId,
        'jobNumber': jobNumber,
        'machineId': machineId,
        'machineName': machineName,
        'batchNumber': batchNumber,
        'lotNumber': lotNumber,
        'expiryDate': expiryDate?.toIso8601String(),
        'reason': reason,
        'notes': notes,
        'approvedById': approvedById,
        'approvedByName': approvedByName,
        'approvedAt': approvedAt?.toIso8601String(),
      };

  /// Create from map
  factory StockMovement.fromMap(Map<String, dynamic> map) => StockMovement(
        id: map['id'] as String,
        materialId: map['materialId'] as String,
        type: StockMovementType.values.firstWhere(
          (t) => t.name == map['type'],
          orElse: () => StockMovementType.adjustment,
        ),
        quantity: (map['quantity'] as num).toDouble(),
        balanceAfter: (map['balanceAfter'] as num).toDouble(),
        timestamp: DateTime.parse(map['timestamp'] as String),
        userId: map['userId'] as String,
        userName: map['userName'] as String,
        jobId: map['jobId'] as String?,
        jobNumber: map['jobNumber'] as String?,
        machineId: map['machineId'] as String?,
        machineName: map['machineName'] as String?,
        batchNumber: map['batchNumber'] as String?,
        lotNumber: map['lotNumber'] as String?,
        expiryDate: map['expiryDate'] != null
            ? DateTime.parse(map['expiryDate'] as String)
            : null,
        reason: map['reason'] as String?,
        notes: map['notes'] as String?,
        approvedById: map['approvedById'] as String?,
        approvedByName: map['approvedByName'] as String?,
        approvedAt: map['approvedAt'] != null
            ? DateTime.parse(map['approvedAt'] as String)
            : null,
      );
}

/// Stock movement types
enum StockMovementType {
  receipt('Receipt', true), // Goods received
  issue('Issue', false), // Issued to production
  return_('Return', true), // Returned from production
  adjustment('Adjustment', null), // Inventory adjustment (can be +/-)
  transfer('Transfer', null), // Transfer between locations
  scrap('Scrap', false), // Scrapped material
  sample('Sample', false), // Sample taken
  initialStock('Initial Stock', true); // Opening balance

  final String displayName;
  final bool? isInbound; // true = in, false = out, null = either
  const StockMovementType(this.displayName, this.isInbound);
}

/// Material batch/lot
class MaterialBatch {
  final String id;
  final String materialId;
  final String batchNumber;
  final String? lotNumber;
  final double quantity;
  final double remainingQuantity;
  final DateTime receivedDate;
  final DateTime? expiryDate;
  final String? supplierBatchNumber;
  final String? certificateUrl;
  final BatchStatus status;
  final String? notes;

  MaterialBatch({
    required this.id,
    required this.materialId,
    required this.batchNumber,
    this.lotNumber,
    required this.quantity,
    required this.remainingQuantity,
    required this.receivedDate,
    this.expiryDate,
    this.supplierBatchNumber,
    this.certificateUrl,
    this.status = BatchStatus.available,
    this.notes,
  });

  /// Is batch expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// Is batch expiring soon (within 30 days)
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }

  /// Is batch depleted
  bool get isDepleted => remainingQuantity <= 0;

  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'batchNumber': batchNumber,
        'lotNumber': lotNumber,
        'quantity': quantity,
        'remainingQuantity': remainingQuantity,
        'receivedDate': receivedDate.toIso8601String(),
        'expiryDate': expiryDate?.toIso8601String(),
        'supplierBatchNumber': supplierBatchNumber,
        'certificateUrl': certificateUrl,
        'status': status.name,
        'notes': notes,
      };

  factory MaterialBatch.fromMap(Map<String, dynamic> map) => MaterialBatch(
        id: map['id'] as String,
        materialId: map['materialId'] as String,
        batchNumber: map['batchNumber'] as String,
        lotNumber: map['lotNumber'] as String?,
        quantity: (map['quantity'] as num).toDouble(),
        remainingQuantity: (map['remainingQuantity'] as num).toDouble(),
        receivedDate: DateTime.parse(map['receivedDate'] as String),
        expiryDate: map['expiryDate'] != null
            ? DateTime.parse(map['expiryDate'] as String)
            : null,
        supplierBatchNumber: map['supplierBatchNumber'] as String?,
        certificateUrl: map['certificateUrl'] as String?,
        status: BatchStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => BatchStatus.available,
        ),
        notes: map['notes'] as String?,
      );
}

/// Batch status
enum BatchStatus {
  available('Available'),
  onHold('On Hold'),
  quarantine('Quarantine'),
  depleted('Depleted'),
  expired('Expired'),
  rejected('Rejected');

  final String displayName;
  const BatchStatus(this.displayName);
}

/// Material issue request
class MaterialIssueRequest {
  final String id;
  final String materialId;
  final String materialName;
  final double quantityRequested;
  final double? quantityIssued;
  final String jobId;
  final String jobNumber;
  final String machineId;
  final String machineName;
  final String requestedById;
  final String requestedByName;
  final DateTime requestedAt;
  final IssueRequestStatus status;
  final String? issuedById;
  final String? issuedByName;
  final DateTime? issuedAt;
  final String? notes;
  final String? rejectionReason;

  MaterialIssueRequest({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.quantityRequested,
    this.quantityIssued,
    required this.jobId,
    required this.jobNumber,
    required this.machineId,
    required this.machineName,
    required this.requestedById,
    required this.requestedByName,
    required this.requestedAt,
    this.status = IssueRequestStatus.pending,
    this.issuedById,
    this.issuedByName,
    this.issuedAt,
    this.notes,
    this.rejectionReason,
  });

  /// Is request pending
  bool get isPending => status == IssueRequestStatus.pending;

  /// Is request fulfilled
  bool get isFulfilled => status == IssueRequestStatus.fulfilled;

  /// Is request partially fulfilled
  bool get isPartiallyFulfilled => status == IssueRequestStatus.partiallyFulfilled;

  Map<String, dynamic> toMap() => {
        'id': id,
        'materialId': materialId,
        'materialName': materialName,
        'quantityRequested': quantityRequested,
        'quantityIssued': quantityIssued,
        'jobId': jobId,
        'jobNumber': jobNumber,
        'machineId': machineId,
        'machineName': machineName,
        'requestedById': requestedById,
        'requestedByName': requestedByName,
        'requestedAt': requestedAt.toIso8601String(),
        'status': status.name,
        'issuedById': issuedById,
        'issuedByName': issuedByName,
        'issuedAt': issuedAt?.toIso8601String(),
        'notes': notes,
        'rejectionReason': rejectionReason,
      };

  factory MaterialIssueRequest.fromMap(Map<String, dynamic> map) =>
      MaterialIssueRequest(
        id: map['id'] as String,
        materialId: map['materialId'] as String,
        materialName: map['materialName'] as String,
        quantityRequested: (map['quantityRequested'] as num).toDouble(),
        quantityIssued: (map['quantityIssued'] as num?)?.toDouble(),
        jobId: map['jobId'] as String,
        jobNumber: map['jobNumber'] as String,
        machineId: map['machineId'] as String,
        machineName: map['machineName'] as String,
        requestedById: map['requestedById'] as String,
        requestedByName: map['requestedByName'] as String,
        requestedAt: DateTime.parse(map['requestedAt'] as String),
        status: IssueRequestStatus.values.firstWhere(
          (s) => s.name == map['status'],
          orElse: () => IssueRequestStatus.pending,
        ),
        issuedById: map['issuedById'] as String?,
        issuedByName: map['issuedByName'] as String?,
        issuedAt: map['issuedAt'] != null
            ? DateTime.parse(map['issuedAt'] as String)
            : null,
        notes: map['notes'] as String?,
        rejectionReason: map['rejectionReason'] as String?,
      );
}

/// Issue request status
enum IssueRequestStatus {
  pending('Pending'),
  fulfilled('Fulfilled'),
  partiallyFulfilled('Partially Fulfilled'),
  rejected('Rejected'),
  cancelled('Cancelled');

  final String displayName;
  const IssueRequestStatus(this.displayName);
}
