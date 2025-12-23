import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class CustomerDataSource {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get all customers for a tenant
  Future<List<Map<String, dynamic>>> getCustomersByTenant(
    String tenantId, {
    bool? isActive,
  }) async {
    try {
      var query = _client
          .from('customers')
          .select('*')
          .eq('tenant_id', tenantId);

      // Apply status filter if provided
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[CustomerDataSource] Error fetching customers: $e');
      return [];
    }
  }

  // Get customer by ID
  Future<Map<String, dynamic>?> getCustomerById(String customerId) async {
    try {
      final response = await _client
          .from('customers')
          .select('*')
          .eq('id', customerId)
          .single();

      return response;
    } catch (e) {
      print('[CustomerDataSource] Error fetching customer: $e');
      return null;
    }
  }

  // Search customers
  Future<List<Map<String, dynamic>>> searchCustomers(
    String tenantId,
    String query, {
    bool? isActive,
  }) async {
    try {
      var searchQuery = _client
          .from('customers')
          .select('*')
          .eq('tenant_id', tenantId)
          .or('name.ilike.%$query%,phone.ilike.%$query%,email.ilike.%$query%');

      // Apply status filter if provided
      if (isActive != null) {
        searchQuery = searchQuery.eq('is_active', isActive);
      }

      final response = await searchQuery.order('name');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[CustomerDataSource] Error searching customers: $e');
      return [];
    }
  }

  // Create a new customer
  Future<Map<String, dynamic>?> createCustomer({
    required String tenantId,
    required String name,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
  }) async {
    try {
      final response = await _client
          .from('customers')
          .insert({
            'tenant_id': tenantId,
            'name': name,
            'phone': phone,
            'email': email,
            'address': address,
            'gst_number': gstNumber,
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('[CustomerDataSource] Error creating customer: $e');
      rethrow;
    }
  }

  // Update customer
  Future<Map<String, dynamic>?> updateCustomer(
    String customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('customers')
          .update(data)
          .eq('id', customerId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('[CustomerDataSource] Error updating customer: $e');
      rethrow;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(String customerId) async {
    try {
      // Check if customer has associated bills
      final billsResponse = await _client
          .from('bills')
          .select('id')
          .eq('customer_id', customerId)
          .limit(1);

      if (billsResponse.isNotEmpty) {
        throw Exception(
            'Cannot delete customer with associated bills. Deactivate instead.');
      }

      final response = await _client
          .from('customers')
          .delete()
          .eq('id', customerId);

      return true;
    } catch (e) {
      print('[CustomerDataSource] Error deleting customer: $e');
      rethrow;
    }
  }

  // Get customer stats (total purchases, amount spent)
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final billsResponse = await _client
          .from('bills')
          .select('total_amount')
          .eq('customer_id', customerId);

      int totalBills = billsResponse.length;
      double totalSpent = 0;
      for (var bill in billsResponse) {
        totalSpent += (bill['total_amount'] as num?)?.toDouble() ?? 0;
      }

      return {'total_bills': totalBills, 'total_spent': totalSpent};
    } catch (e) {
      print('[CustomerDataSource] Error getting customer stats: $e');
      return {'total_bills': 0, 'total_spent': 0.0};
    }
  }
}
