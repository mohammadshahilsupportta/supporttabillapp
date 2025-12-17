// Stock Tracking Type Enum
enum StockTrackingType {
  quantity('quantity'),
  serial('serial');

  final String value;
  const StockTrackingType(this.value);

  static StockTrackingType fromString(String value) {
    return StockTrackingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StockTrackingType.quantity,
    );
  }
}

// Category Model
class Category {
  final String id;
  final String tenantId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.tenantId,
    required this.name,
    this.code,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
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
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Brand Model
class Brand {
  final String id;
  final String tenantId;
  final String name;
  final String? code;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Brand({
    required this.id,
    required this.tenantId,
    required this.name,
    this.code,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
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
      'description': description,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Product Model
class Product {
  final String id;
  final String tenantId;
  final String? categoryId;
  final String? brandId;
  final String name;
  final String? sku;
  final String unit;
  final double sellingPrice;
  final double? purchasePrice;
  final double gstRate;
  final int minStock;
  final String? description;
  final StockTrackingType stockTrackingType;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data (optional)
  final Category? category;
  final Brand? brand;

  Product({
    required this.id,
    required this.tenantId,
    this.categoryId,
    this.brandId,
    required this.name,
    this.sku,
    required this.unit,
    required this.sellingPrice,
    this.purchasePrice,
    required this.gstRate,
    required this.minStock,
    this.description,
    required this.stockTrackingType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.brand,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      categoryId: json['category_id'] as String?,
      brandId: json['brand_id'] as String?,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      unit: json['unit'] as String,
      sellingPrice: (json['selling_price'] as num).toDouble(),
      purchasePrice: json['purchase_price'] != null
          ? (json['purchase_price'] as num).toDouble()
          : null,
      gstRate: (json['gst_rate'] as num).toDouble(),
      minStock: json['min_stock'] as int? ?? 0,
      description: json['description'] as String?,
      stockTrackingType: StockTrackingType.fromString(
        json['stock_tracking_type'] as String? ?? 'quantity',
      ),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      category: json['category'] != null
          ? Category.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      brand: json['brand'] != null
          ? Brand.fromJson(json['brand'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'category_id': categoryId,
      'brand_id': brandId,
      'name': name,
      'sku': sku,
      'unit': unit,
      'selling_price': sellingPrice,
      'purchase_price': purchasePrice,
      'gst_rate': gstRate,
      'min_stock': minStock,
      'description': description,
      'stock_tracking_type': stockTrackingType.value,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
