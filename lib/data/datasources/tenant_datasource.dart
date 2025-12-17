import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class TenantDataSource {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get all tenants
  Future<List<Map<String, dynamic>>> getAllTenants() async {
    try {
      final response = await _client
          .from('tenants')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[TenantDataSource] Error fetching tenants: $e');
      return [];
    }
  }

  // Get tenant by ID
  Future<Map<String, dynamic>?> getTenantById(String tenantId) async {
    try {
      final response = await _client
          .from('tenants')
          .select('*')
          .eq('id', tenantId)
          .single();

      return response;
    } catch (e) {
      print('[TenantDataSource] Error fetching tenant: $e');
      return null;
    }
  }

  // Get tenant stats
  Future<Map<String, dynamic>> getTenantStats(String tenantId) async {
    try {
      // Get branch count
      final branchResponse = await _client
          .from('branches')
          .select('id')
          .eq('tenant_id', tenantId);

      // Get user count
      final userResponse = await _client
          .from('users')
          .select('id')
          .eq('tenant_id', tenantId);

      // Get product count
      final productResponse = await _client
          .from('products')
          .select('id')
          .eq('tenant_id', tenantId);

      return {
        'branch_count': branchResponse.length,
        'user_count': userResponse.length,
        'product_count': productResponse.length,
      };
    } catch (e) {
      print('[TenantDataSource] Error getting tenant stats: $e');
      return {'branch_count': 0, 'user_count': 0, 'product_count': 0};
    }
  }

  // Create a new tenant
  Future<Map<String, dynamic>?> createTenant({
    required String name,
    required String businessName,
    String? email,
    String? phone,
    String? address,
    String? gstNumber,
    String? subscriptionPlan,
  }) async {
    try {
      final response = await _client
          .from('tenants')
          .insert({
            'name': name,
            'business_name': businessName,
            'email': email,
            'phone': phone,
            'address': address,
            'gst_number': gstNumber,
            'subscription_plan': subscriptionPlan ?? 'basic',
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('[TenantDataSource] Error creating tenant: $e');
      rethrow;
    }
  }

  // Update tenant
  Future<Map<String, dynamic>?> updateTenant(
    String tenantId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('tenants')
          .update(data)
          .eq('id', tenantId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('[TenantDataSource] Error updating tenant: $e');
      rethrow;
    }
  }

  // Toggle tenant active status
  Future<bool> toggleTenantStatus(String tenantId, bool isActive) async {
    try {
      await _client
          .from('tenants')
          .update({'is_active': isActive})
          .eq('id', tenantId);

      return true;
    } catch (e) {
      print('[TenantDataSource] Error toggling tenant status: $e');
      return false;
    }
  }
}
