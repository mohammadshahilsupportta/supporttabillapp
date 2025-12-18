import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class BranchDataSource {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get all branches for a tenant
  Future<List<Map<String, dynamic>>> getBranchesByTenant(
    String tenantId,
  ) async {
    try {
      final response = await _client
          .from('branches')
          .select('*')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[BranchDataSource] Error fetching branches: $e');
      return [];
    }
  }

  // Get branch by ID
  Future<Map<String, dynamic>?> getBranchById(String branchId) async {
    try {
      final response = await _client
          .from('branches')
          .select('*')
          .eq('id', branchId)
          .single();

      return response;
    } catch (e) {
      print('[BranchDataSource] Error fetching branch: $e');
      return null;
    }
  }

  // Create a new branch
  Future<Map<String, dynamic>?> createBranch({
    required String tenantId,
    required String name,
    required String code,
    String? address,
    String? phone,
  }) async {
    try {
      final response = await _client
          .from('branches')
          .insert({
            'tenant_id': tenantId,
            'name': name,
            'code': code,
            'address': address,
            'phone': phone,
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } on PostgrestException catch (e) {
      print('[BranchDataSource] Error creating branch: $e');
      // Handle unique violation on branch code (same as website API)
      if (e.code == '23505' ||
          e.message.toLowerCase().contains('duplicate key') ||
          e.message.toLowerCase().contains('code')) {
        throw Exception('BRANCH_CODE_ALREADY_EXISTS');
      }
      rethrow;
    } catch (e) {
      print('[BranchDataSource] Error creating branch (unknown): $e');
      rethrow;
    }
  }

  // Update branch
  Future<Map<String, dynamic>?> updateBranch(
    String branchId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('branches')
          .update(data)
          .eq('id', branchId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('[BranchDataSource] Error updating branch: $e');
      rethrow;
    }
  }

  // Toggle branch active status
  Future<bool> toggleBranchStatus(String branchId, bool isActive) async {
    try {
      await _client
          .from('branches')
          .update({'is_active': isActive})
          .eq('id', branchId);

      return true;
    } catch (e) {
      print('[BranchDataSource] Error toggling branch status: $e');
      return false;
    }
  }

  // Delete branch
  Future<bool> deleteBranch(String branchId) async {
    try {
      await _client.from('branches').delete().eq('id', branchId);
      return true;
    } catch (e) {
      print('[BranchDataSource] Error deleting branch: $e');
      rethrow;
    }
  }

  // Get branch stats (user count, sales, etc.)
  Future<Map<String, dynamic>> getBranchStats(String branchId) async {
    try {
      // Get user count
      final userResponse = await _client
          .from('users')
          .select('id')
          .eq('branch_id', branchId);

      // Get today's sales
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final salesResponse = await _client
          .from('bills')
          .select('total_amount')
          .eq('branch_id', branchId)
          .gte('created_at', startOfDay.toIso8601String());

      double todaySales = 0;
      for (var bill in salesResponse) {
        todaySales += (bill['total_amount'] as num?)?.toDouble() ?? 0;
      }

      return {'user_count': userResponse.length, 'today_sales': todaySales};
    } catch (e) {
      print('[BranchDataSource] Error getting branch stats: $e');
      return {'user_count': 0, 'today_sales': 0.0};
    }
  }
}
