import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class PurchaseDataSource {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get all purchases for a branch
  Future<List<Map<String, dynamic>>> getPurchases(String branchId) async {
    try {
      final response = await _client
          .from('purchases')
          .select('*, purchase_items(*)')
          .eq('branch_id', branchId)
          .order('purchase_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[PurchaseDataSource] Error fetching purchases: $e');
      return [];
    }
  }

  // Get purchases for tenant (all branches)
  Future<List<Map<String, dynamic>>> getPurchasesByTenant(
    String tenantId,
  ) async {
    try {
      final response = await _client
          .from('purchases')
          .select('*, purchase_items(*), branches!inner(tenant_id, name)')
          .eq('branches.tenant_id', tenantId)
          .order('purchase_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[PurchaseDataSource] Error fetching purchases by tenant: $e');
      return [];
    }
  }

  // Create a new purchase
  Future<Map<String, dynamic>?> createPurchase({
    required String branchId,
    required String supplierName,
    required String invoiceNumber,
    required String purchaseDate,
    required double totalAmount,
    required String paymentStatus,
    required String paymentMode,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? createdBy,
  }) async {
    try {
      // Create purchase
      final purchaseResponse = await _client
          .from('purchases')
          .insert({
            'branch_id': branchId,
            'supplier_name': supplierName,
            'invoice_number': invoiceNumber,
            'purchase_date': purchaseDate,
            'total_amount': totalAmount,
            'payment_status': paymentStatus,
            'payment_mode': paymentMode,
            'notes': notes,
            'created_by': createdBy,
          })
          .select()
          .single();

      final purchaseId = purchaseResponse['id'];

      // Create purchase items
      for (var item in items) {
        await _client.from('purchase_items').insert({
          'purchase_id': purchaseId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'total_price': item['total_price'],
        });
      }

      return purchaseResponse;
    } catch (e) {
      print('[PurchaseDataSource] Error creating purchase: $e');
      rethrow;
    }
  }

  // Get total purchases for a period
  Future<double> getTotalPurchases(
    String branchId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client
          .from('purchases')
          .select('total_amount')
          .eq('branch_id', branchId);

      if (fromDate != null) {
        query = query.gte('purchase_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('purchase_date', toDate.toIso8601String());
      }

      final response = await query;

      double total = 0;
      for (var purchase in response) {
        total += (purchase['total_amount'] as num?)?.toDouble() ?? 0;
      }

      return total;
    } catch (e) {
      print('[PurchaseDataSource] Error calculating total purchases: $e');
      return 0;
    }
  }
}
