/// ProMould User Model
/// Complete user entity with role-based access control

import '../core/constants.dart';

class User {
  final String id;
  final String username;
  final String passwordHash;
  final String email;
  final String? phone;
  final String firstName;
  final String lastName;
  final UserRole role;
  final UserStatus status;
  final String? shiftId;
  final String? floorId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final Map<String, dynamic>? preferences;
  final List<String>? certifications;
  final Map<String, dynamic>? skills;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.status = UserStatus.active,
    this.shiftId,
    this.floorId,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    this.preferences,
    this.certifications,
    this.skills,
  });

  /// Full display name
  String get fullName => '$firstName $lastName';

  /// Check if user is currently locked out
  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  /// Check if user can log in
  bool get canLogin => status == UserStatus.active && !isLocked;

  /// Check if user has a specific permission level
  bool canAccess(int requiredLevel) => role.canAccess(requiredLevel);

  /// Check if user can manage another user
  bool canManage(User other) => role.canManage(other.role);

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    UserRole? role,
    UserStatus? status,
    String? shiftId,
    String? floorId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    int? failedLoginAttempts,
    DateTime? lockedUntil,
    Map<String, dynamic>? preferences,
    List<String>? certifications,
    Map<String, dynamic>? skills,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      shiftId: shiftId ?? this.shiftId,
      floorId: floorId ?? this.floorId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      preferences: preferences ?? this.preferences,
      certifications: certifications ?? this.certifications,
      skills: skills ?? this.skills,
    );
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'passwordHash': passwordHash,
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.name,
        'status': status.name,
        'shiftId': shiftId,
        'floorId': floorId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'failedLoginAttempts': failedLoginAttempts,
        'lockedUntil': lockedUntil?.toIso8601String(),
        'preferences': preferences,
        'certifications': certifications,
        'skills': skills,
      };

  /// Create from map
  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as String,
        username: map['username'] as String,
        passwordHash: map['passwordHash'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String?,
        firstName: map['firstName'] as String? ?? '',
        lastName: map['lastName'] as String? ?? '',
        role: _parseRole(map['role']),
        status: _parseStatus(map['status']),
        shiftId: map['shiftId'] as String?,
        floorId: map['floorId'] as String?,
        createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
        lastLoginAt: _parseDateTime(map['lastLoginAt']),
        failedLoginAttempts: map['failedLoginAttempts'] as int? ?? 0,
        lockedUntil: _parseDateTime(map['lockedUntil']),
        preferences: map['preferences'] as Map<String, dynamic>?,
        certifications: (map['certifications'] as List?)?.cast<String>(),
        skills: map['skills'] as Map<String, dynamic>?,
      );

  static UserRole _parseRole(dynamic value) {
    if (value == null) return UserRole.operator;
    if (value is UserRole) return value;
    if (value is String) {
      // Handle legacy role names
      switch (value.toLowerCase()) {
        case 'admin':
        case 'productionmanager':
        case 'production_manager':
          return UserRole.productionManager;
        case 'setter':
          return UserRole.setter;
        case 'operator':
          return UserRole.operator;
        case 'materialhandler':
        case 'material_handler':
          return UserRole.materialHandler;
        case 'qc':
        case 'quality':
        case 'qualitycontrol':
          return UserRole.qc;
        default:
          return UserRole.values.firstWhere(
            (r) => r.name == value,
            orElse: () => UserRole.operator,
          );
      }
    }
    if (value is int) {
      // Handle legacy level-based roles
      switch (value) {
        case 4:
          return UserRole.productionManager;
        case 3:
          return UserRole.setter;
        case 2:
          return UserRole.operator;
        default:
          return UserRole.operator;
      }
    }
    return UserRole.operator;
  }

  static UserStatus _parseStatus(dynamic value) {
    if (value == null) return UserStatus.active;
    if (value is UserStatus) return value;
    if (value is String) {
      return UserStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => UserStatus.active,
      );
    }
    return UserStatus.active;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'User($username, $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is User && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

/// User status
enum UserStatus {
  active('Active'),
  inactive('Inactive'),
  locked('Locked'),
  pending('Pending Activation');

  final String displayName;
  const UserStatus(this.displayName);
}

/// User session
class UserSession {
  final String sessionId;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? deviceInfo;
  final String? ipAddress;
  final bool isActive;

  UserSession({
    required this.sessionId,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    this.deviceInfo,
    this.ipAddress,
    this.isActive = true,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'deviceInfo': deviceInfo,
        'ipAddress': ipAddress,
        'isActive': isActive,
      };

  factory UserSession.fromMap(Map<String, dynamic> map) => UserSession(
        sessionId: map['sessionId'] as String,
        userId: map['userId'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        expiresAt: DateTime.parse(map['expiresAt'] as String),
        deviceInfo: map['deviceInfo'] as String?,
        ipAddress: map['ipAddress'] as String?,
        isActive: map['isActive'] as bool? ?? true,
      );
}
