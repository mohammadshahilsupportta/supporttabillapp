// Tenant (Shop) Model
class Tenant {
  final String id;
  final String name;
  final String code;
  final String email;
  final String phone;
  final String address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tenant({
    required this.id,
    required this.name,
    required this.code,
    required this.email,
    required this.phone,
    required this.address,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'email': email,
      'phone': phone,
      'address': address,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Branch Model
class Branch {
  final String id;
  final String tenantId;
  final String name;
  final String code;
  final String address;
  final String phone;
  final bool isActive;
  final bool isMain;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
    required this.address,
    required this.phone,
    required this.isActive,
    required this.isMain,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      isActive: json['is_active'] as bool? ?? true,
      isMain: json['is_main'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'name': name,
      'code': code,
      'address': address,
      'phone': phone,
      'is_active': isActive,
      'is_main': isMain,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
