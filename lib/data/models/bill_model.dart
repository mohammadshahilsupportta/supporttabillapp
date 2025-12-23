import 'dart:convert';

// Payment Mode Enum
enum PaymentMode {
  cash('cash'),
  card('card'),
  upi('upi'),
  credit('credit'),
  bankTransfer('bank_transfer');

  final String value;
  const PaymentMode(this.value);

  static PaymentMode fromString(String value) {
    return PaymentMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => PaymentMode.cash,
    );
  }
}

// Bill Model
class Bill {
  final String id;
  final String tenantId;
  final String branchId;
  final String invoiceNumber;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final double subtotal;
  final double gstAmount;
  final double discount;
  final double totalAmount;
  final double profitAmount;
  final double? paidAmount;
  final double? dueAmount;
  final PaymentMode paymentMode;
  final String createdBy;
  final DateTime createdAt;

  // Optional joined data
  final List<BillItem>? items;

  Bill({
    required this.id,
    required this.tenantId,
    required this.branchId,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.subtotal,
    required this.gstAmount,
    required this.discount,
    required this.totalAmount,
    required this.profitAmount,
    this.paidAmount,
    this.dueAmount,
    required this.paymentMode,
    required this.createdBy,
    required this.createdAt,
    this.items,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      gstAmount: (json['gst_amount'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      profitAmount: (json['profit_amount'] as num).toDouble(),
      paidAmount: json['paid_amount'] != null
          ? (json['paid_amount'] as num).toDouble()
          : null,
      dueAmount: json['due_amount'] != null
          ? (json['due_amount'] as num).toDouble()
          : null,
      paymentMode: PaymentMode.fromString(json['payment_mode'] as String),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'subtotal': subtotal,
      'gst_amount': gstAmount,
      'discount': discount,
      'total_amount': totalAmount,
      'profit_amount': profitAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_mode': paymentMode.value,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Bill Item Model
class BillItem {
  final String id;
  final String billId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double? purchasePrice;
  final double gstRate;
  final double gstAmount;
  final double discount;
  final double profitAmount;
  final double totalAmount;
  final List<String>? serialNumbers;

  BillItem({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    this.purchasePrice,
    required this.gstRate,
    required this.gstAmount,
    required this.discount,
    required this.profitAmount,
    required this.totalAmount,
    this.serialNumbers,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    // Handle serial_numbers - can be JSON string or List
    List<String>? serialNumbers;
    if (json['serial_numbers'] != null) {
      if (json['serial_numbers'] is String) {
        try {
          // Try to parse JSON string
          final parsed = jsonDecode(json['serial_numbers'] as String);
          if (parsed is List) {
            serialNumbers = parsed.cast<String>();
          }
        } catch (_) {
          // If parsing fails, ignore
        }
      } else if (json['serial_numbers'] is List) {
        serialNumbers = List<String>.from(json['serial_numbers'] as List);
      }
    }

    return BillItem(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      purchasePrice: json['purchase_price'] != null
          ? (json['purchase_price'] as num).toDouble()
          : null,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gst_amount'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      profitAmount: (json['profit_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num).toDouble(),
      serialNumbers: serialNumbers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'purchase_price': purchasePrice,
      'gst_rate': gstRate,
      'gst_amount': gstAmount,
      'discount': discount,
      'profit_amount': profitAmount,
      'total_amount': totalAmount,
      'serial_numbers': serialNumbers,
    };
  }
}

// Payment Transaction Model
class PaymentTransaction {
  final String id;
  final String billId;
  final String tenantId;
  final String branchId;
  final double amount;
  final PaymentMode paymentMode;
  final DateTime transactionDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;

  PaymentTransaction({
    required this.id,
    required this.billId,
    required this.tenantId,
    required this.branchId,
    required this.amount,
    required this.paymentMode,
    required this.transactionDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      tenantId: json['tenant_id'] as String,
      branchId: json['branch_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMode: PaymentMode.fromString(json['payment_mode'] as String),
      transactionDate: DateTime.parse(json['transaction_date'] as String),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'tenant_id': tenantId,
      'branch_id': branchId,
      'amount': amount,
      'payment_mode': paymentMode.value,
      'transaction_date': transactionDate.toIso8601String(),
      'notes': notes,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
