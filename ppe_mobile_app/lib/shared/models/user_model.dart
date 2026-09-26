import '../../core/utils/json.dart';

enum UserRole {
  worker('WORKER'),
  supervisor('SUPERVISOR'),
  storeKeeper('STORE_KEEPER'),
  ehs('EHS'),
  admin('ADMIN');

  const UserRole(this.apiValue);
  final String apiValue;

  static UserRole fromApi(String? value) => UserRole.values.firstWhere((r) => r.apiValue == value, orElse: () => UserRole.worker);

  /// Can approve requisitions (backend `IsSupervisorOrHigher`).
  bool get canApprove => this == supervisor || this == ehs || this == admin;

  /// Can operate the store: prepare, issue, receive, adjust (backend `IsStoreOrHigher`).
  bool get isStore => this == storeKeeper || this == ehs || this == admin;

  /// Can edit PPE master data such as quota / lifespan / reorder point.
  bool get canManageMasterData => this == ehs || this == admin;

  bool get canViewAudit => this == ehs || this == admin;
  bool get isAdmin => this == admin;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.employeeId,
    required this.displayName,
    required this.role,
    this.username = '',
    this.phoneNumber = '',
    this.department = '',
    this.locale = 'TH',
    this.supervisorId,
    this.supervisorName,
    this.isActive = true,
    this.permissions = const [],
  });

  final int id;
  final String employeeId;
  final String username;
  final String displayName;
  final String phoneNumber;
  final String department;
  final String locale;
  final UserRole role;
  final int? supervisorId;
  final String? supervisorName;
  final bool isActive;
  final List<String> permissions;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: asInt(json['id']),
        employeeId: asString(json['employee_id']),
        username: asString(json['username']),
        displayName: asString(json['display_name']),
        phoneNumber: asString(json['phone_number']),
        department: asString(json['department']),
        locale: asString(json['locale'], 'TH'),
        role: UserRole.fromApi(json['role'] as String?),
        supervisorId: asIntOrNull(json['supervisor']),
        supervisorName: json['supervisor_name'] as String?,
        isActive: json['is_active'] != false,
        permissions: (json['permissions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'username': username,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'department': department,
        'locale': locale,
        'role': role.apiValue,
        'supervisor': supervisorId,
        'supervisor_name': supervisorName,
        'is_active': isActive,
        'permissions': permissions,
      };

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => String.fromCharCode(p.runes.first)).join().toUpperCase();
  }
}
