// Purchase Model
class Purchase {
  final String id;
  final String tenantId;
  final String branchId;
  final String supplierName;
  final String? invoiceNumber;
  final double totalAmount;
  final String createdBy;
  final DateTime createdAt;

  // Optional joined data
  final List<PurchaseItem>? items;

  Purchase({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.supplierName,
    this.invoiceNumber,
    required this.totalAmount,
    required this.createdBy,
    required this.createdAt,
    this.items,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      supplierName: json['supplier_name'] as String,
      invoiceNumber: json['invoice_number'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
                .map(
                  (item) => PurchaseItem.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'supplier_name': supplierName,
      'invoice_number': invoiceNumber,
      'total_amount': totalAmount,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Purchase Item Model
class PurchaseItem {
  final String id;
  final String purchaseId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;

  PurchaseItem({
    required this.id,
    required this.purchaseId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
      id: json['id'] as String,
      purchaseId: json['purchase_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_amount': totalAmount,
    };
  }
}

// Customer Model
class Customer {
  final String id;
  final String tenantId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.tenantId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.gstNumber,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      gstNumber: json['gst_number'] as String?,
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
      'phone': phone,
      'email': email,
      'address': address,
      'gst_number': gstNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Expense Category Enum
enum ExpenseCategory {
  rent('rent'),
  utilities('utilities'),
  salaries('salaries'),
  marketing('marketing'),
  transport('transport'),
  maintenance('maintenance'),
  officeSupplies('office_supplies'),
  food('food'),
  other('other');

  final String value;
  const ExpenseCategory(this.value);

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => ExpenseCategory.other,
    );
  }
}

// Expense Model
class Expense {
  final String id;
  final String tenantId;
  final String branchId;
  final String category;
  final String description;
  final double amount;
  final String paymentMode;
  final DateTime expenseDate;
  final String? receiptNumber;
  final String? vendorName;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMode,
    required this.expenseDate,
    this.receiptNumber,
    this.vendorName,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: json['payment_mode'] as String,
      expenseDate: DateTime.parse(json['expense_date'] as String),
      receiptNumber: json['receipt_number'] as String?,
      vendorName: json['vendor_name'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'category': category,
      'description': description,
      'amount': amount,
      'payment_mode': paymentMode,
      'expense_date': expenseDate.toIso8601String(),
      'receipt_number': receiptNumber,
      'vendor_name': vendorName,
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
