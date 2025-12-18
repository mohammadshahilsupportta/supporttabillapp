import 'product_model.dart';

// Stock Transaction Type Enum
enum StockTransactionType {
  stockIn('stock_in'),
  stockOut('stock_out'),
  adjustment('adjustment'),
  transferIn('transfer_in'),
  transferOut('transfer_out'),
  billing('billing');

  final String value;
  const StockTransactionType(this.value);

  static StockTransactionType fromString(String value) {
    return StockTransactionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => StockTransactionType.stockIn,
    );
  }
}

// Serial Number Status Enum
enum SerialStatus {
  available('available'),
  sold('sold'),
  damaged('damaged'),
  returned('returned');

  final String value;
  const SerialStatus(this.value);

  static SerialStatus fromString(String value) {
    return SerialStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SerialStatus.available,
    );
  }
}

// Stock Ledger Model
class StockLedger {
  final String id;
  final String tenantId;
  final String branchId;
  final String productId;
  final StockTransactionType transactionType;
  final int quantity;
  final int previousStock;
  final int currentStock;
  final String? referenceId;
  final String? reason;
  final String createdBy;
  final DateTime createdAt;

  StockLedger({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.productId,
    required this.transactionType,
    required this.quantity,
    required this.previousStock,
    required this.currentStock,
    this.referenceId,
    this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  factory StockLedger.fromJson(Map<String, dynamic> json) {
    return StockLedger(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      transactionType: StockTransactionType.fromString(
        json['transaction_type'] as String,
      ),
      quantity: json['quantity'] as int,
      previousStock: json['previous_stock'] as int,
      currentStock: json['current_stock'] as int,
      referenceId: json['reference_id'] as String?,
      reason: json['reason'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'transaction_type': transactionType.value,
      'quantity': quantity,
      'previous_stock': previousStock,
      'current_stock': currentStock,
      'reference_id': referenceId,
      'reason': reason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Current Stock Model
class CurrentStock {
  final String id;
  final String tenantId;
  final String branchId;
  final String productId;
  final int quantity;
  final DateTime updatedAt;
  final Product? product; // Optional joined product data

  CurrentStock({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.productId,
    required this.quantity,
    required this.updatedAt,
    this.product,
  });

  factory CurrentStock.fromJson(Map<String, dynamic> json) {
    Product? product;
    if (json['product'] != null) {
      try {
        product = Product.fromJson(json['product'] as Map<String, dynamic>);
      } catch (e) {
        // If product parsing fails, leave it as null
        print('Error parsing product in CurrentStock: $e');
      }
    }

    return CurrentStock(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      product: product,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'quantity': quantity,
      'updated_at': updatedAt.toIso8601String(),
      if (product != null) 'product': product!.toJson(),
    };
  }
}

// Product Serial Number Model
class ProductSerialNumber {
  final String id;
  final String tenantId;
  final String branchId;
  final String productId;
  final String serialNumber;
  final SerialStatus status;
  final String? billId;
  final DateTime? soldAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductSerialNumber({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.productId,
    required this.serialNumber,
    required this.status,
    this.billId,
    this.soldAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductSerialNumber.fromJson(Map<String, dynamic> json) {
    return ProductSerialNumber(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      serialNumber: json['serial_number'] as String,
      status: SerialStatus.fromString(json['status'] as String),
      billId: json['bill_id'] as String?,
      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'product_id': productId,
      'serial_number': serialNumber,
      'status': status.value,
      'bill_id': billId,
      'sold_at': soldAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
