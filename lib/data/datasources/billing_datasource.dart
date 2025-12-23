import '../../core/services/supabase_service.dart';
import '../models/bill_model.dart';

class BillingDataSource {
  final SupabaseService _supabase = SupabaseService.instance;

  // Get bills by branch
  Future<List<Bill>> getBillsByBranch({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('bills').select().eq('branch_id', branchId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List).map((json) => Bill.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch bills: ${e.toString()}');
    }
  }

  // Get bills by tenant (for tenant owners to see all branches)
  Future<List<Bill>> getBillsByTenant({
    required String tenantId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('bills').select().eq('tenant_id', tenantId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List).map((json) => Bill.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch bills: ${e.toString()}');
    }
  }

  // Get bill by ID with items
  Future<Bill> getBillById(String billId) async {
    try {
      final billData = await _supabase
          .from('bills')
          .select()
          .eq('id', billId)
          .single();

      // Fetch items separately with error handling
      List<BillItem> items = [];
      try {
        print('[BillDetail] Fetching bill items for bill_id: $billId');
        final itemsData = await _supabase
            .from('bill_items')
            .select()
            .eq('bill_id', billId);

        print('[BillDetail] Items data received. Type: ${itemsData.runtimeType}, Count: ${(itemsData as List).length}');
        
        items = (itemsData as List)
            .map((json) {
              try {
                return BillItem.fromJson(json as Map<String, dynamic>);
              } catch (parseError) {
                print('[BillDetail] Error parsing bill item: $parseError');
                print('[BillDetail] Item JSON: $json');
                rethrow;
              }
            })
            .toList();
        print('[BillDetail] Successfully parsed ${items.length} items');
      } catch (itemsError) {
        // If items fetch fails, log the error but continue with empty items list
        print('[BillDetail] Error fetching bill items: $itemsError');
        print('[BillDetail] Error type: ${itemsError.runtimeType}');
        items = [];
      }

      final bill = Bill.fromJson(billData);
      return bill.copyWith(items: items);
    } catch (e) {
      throw Exception('Failed to fetch bill: ${e.toString()}');
    }
  }

  // Create bill (POS billing)
  Future<Bill> createBill({
    required String branchId,
    required List<BillItem> items,
    String? customerId,
    String? customerName,
    String? customerPhone,
    required double subtotal,
    required double gstAmount,
    required double discount,
    required double totalAmount,
    required double profitAmount,
    double? paidAmount,
    required PaymentMode paymentMode,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get tenant from branch
      final branchData = await _supabase
          .from('branches')
          .select('tenant_id')
          .eq('id', branchId)
          .single();

      final tenantId = branchData['tenant_id'];

      // Generate invoice number
      final invoiceNumber = await _generateInvoiceNumber(branchId);

      // Calculate due amount
      final dueAmount = paidAmount != null ? totalAmount - paidAmount : 0.0;

      // Create bill
      final billData = await _supabase
          .from('bills')
          .insert({
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
            'created_by': userId,
          })
          .select()
          .single();

      final bill = Bill.fromJson(billData);

      // Create bill items
      final itemsToInsert = items.map((item) {
        return {
          'bill_id': bill.id,
          'product_id': item.productId,
          'product_name': item.productName,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'purchase_price': item.purchasePrice,
          'gst_rate': item.gstRate,
          'gst_amount': item.gstAmount,
          'discount': item.discount,
          'profit_amount': item.profitAmount,
          'total_amount': item.totalAmount,
          'serial_numbers': item.serialNumbers,
        };
      }).toList();

      await _supabase.from('bill_items').insert(itemsToInsert);

      // Update stock for each item (create stock ledger entry)
      for (final item in items) {
        await _supabase.rpc(
          'add_stock_out',
          params: {
            'p_branch_id': branchId,
            'p_product_id': item.productId,
            'p_quantity': item.quantity,
            'p_reason': 'Billing',
            'p_reference_id': bill.id,
            'p_created_by': userId,
          },
        );
      }

      return bill;
    } catch (e) {
      throw Exception('Failed to create bill: ${e.toString()}');
    }
  }

  // Generate invoice number
  Future<String> _generateInvoiceNumber(String branchId) async {
    try {
      // Get branch code
      final branchData = await _supabase
          .from('branches')
          .select('code')
          .eq('id', branchId)
          .single();

      final branchCode = branchData['code'];

      // Get count of bills today for this branch
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final billsToday = await _supabase
          .from('bills')
          .select()
          .eq('branch_id', branchId)
          .gte('created_at', startOfDay.toIso8601String());

      final billNumber = ((billsToday as List).length + 1).toString().padLeft(
        4,
        '0',
      );
      final dateStr =
          '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      return '$branchCode-$dateStr-$billNumber';
    } catch (e) {
      // Fallback to timestamp if generation fails
      return 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Add payment to existing bill
  Future<PaymentTransaction> addPayment({
    required String billId,
    required double amount,
    required PaymentMode paymentMode,
    String? notes,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Get bill details
      final billData = await _supabase
          .from('bills')
          .select('tenant_id, branch_id, due_amount')
          .eq('id', billId)
          .single();

      // Create payment transaction
      final paymentData = await _supabase
          .from('payment_transactions')
          .insert({
            'bill_id': billId,
            'tenant_id': billData['tenant_id'],
            'branch_id': billData['branch_id'],
            'amount': amount,
            'payment_mode': paymentMode.value,
            'transaction_date': DateTime.now().toIso8601String(),
            'notes': notes,
            'created_by': userId,
          })
          .select()
          .single();

      // Update bill paid and due amounts
      final currentPaidAmount = billData['paid_amount'] ?? 0.0;
      final newPaidAmount = currentPaidAmount + amount;
      final newDueAmount = (billData['due_amount'] ?? 0.0) - amount;

      await _supabase
          .from('bills')
          .update({'paid_amount': newPaidAmount, 'due_amount': newDueAmount})
          .eq('id', billId);

      return PaymentTransaction.fromJson(paymentData);
    } catch (e) {
      throw Exception('Failed to add payment: ${e.toString()}');
    }
  }

  // Get payments for a bill
  Future<List<PaymentTransaction>> getPaymentsByBill(String billId) async {
    try {
      final data = await _supabase
          .from('payment_transactions')
          .select()
          .eq('bill_id', billId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((json) => PaymentTransaction.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch payments: ${e.toString()}');
    }
  }

  // Get sales statistics
  Future<Map<String, dynamic>> getSalesStats({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('bills')
          .select('total_amount, profit_amount, created_at')
          .eq('branch_id', branchId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query;

      double totalSales = 0;
      double totalProfit = 0;
      int billCount = (data as List).length;

      for (final bill in data) {
        totalSales += (bill['total_amount'] as num).toDouble();
        totalProfit += (bill['profit_amount'] as num).toDouble();
      }

      return {
        'total_sales': totalSales,
        'total_profit': totalProfit,
        'bill_count': billCount,
        'average_bill_value': billCount > 0 ? totalSales / billCount : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to fetch sales stats: ${e.toString()}');
    }
  }

  // Get product-wise sales report
  Future<List<Map<String, dynamic>>> getProductSalesReport({
    required String branchId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get bill IDs in date range
      var billQuery = _supabase
          .from('bills')
          .select('id')
          .eq('branch_id', branchId);

      if (startDate != null) {
        billQuery = billQuery.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        billQuery = billQuery.lte('created_at', endDate.toIso8601String());
      }

      final bills = await billQuery;
      final billIds = (bills as List).map((b) => b['id']).toList();

      if (billIds.isEmpty) return [];

      // Get bill items for these bills
      final items = await _supabase
          .from('bill_items')
          .select()
          .inFilter('bill_id', billIds);

      // Aggregate by product
      final Map<String, Map<String, dynamic>> productStats = {};

      for (final item in items as List) {
        final productId = item['product_id'] as String;
        final productName = item['product_name'] as String;
        final quantity = item['quantity'] as int;
        final totalAmount = (item['total_amount'] as num).toDouble();
        final profitAmount = (item['profit_amount'] as num).toDouble();

        if (productStats.containsKey(productId)) {
          productStats[productId]!['total_quantity'] += quantity;
          productStats[productId]!['total_amount'] += totalAmount;
          productStats[productId]!['total_profit'] += profitAmount;
        } else {
          productStats[productId] = {
            'product_id': productId,
            'product_name': productName,
            'total_quantity': quantity,
            'total_amount': totalAmount,
            'total_profit': profitAmount,
          };
        }
      }

      return productStats.values.toList()..sort(
        (a, b) => (b['total_amount'] as double).compareTo(
          a['total_amount'] as double,
        ),
      );
    } catch (e) {
      throw Exception('Failed to fetch product sales report: ${e.toString()}');
    }
  }
}

// Extension to add copyWith method to Bill
extension BillExtension on Bill {
  Bill copyWith({
    String? id,
    String? tenantId,
    String? branchId,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double? subtotal,
    double? gstAmount,
    double? discount,
    double? totalAmount,
    double? profitAmount,
    double? paidAmount,
    double? dueAmount,
    PaymentMode? paymentMode,
    String? createdBy,
    DateTime? createdAt,
    List<BillItem>? items,
  }) {
    return Bill(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      branchId: branchId ?? this.branchId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      profitAmount: profitAmount ?? this.profitAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
    );
  }
}
