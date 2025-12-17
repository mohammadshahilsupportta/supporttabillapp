import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class UserDataSource {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get all users for a tenant
  Future<List<Map<String, dynamic>>> getUsersByTenant(String tenantId) async {
    try {
      final response = await _client
          .from('users')
          .select('*, branches(name)')
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[UserDataSource] Error fetching users: $e');
      return [];
    }
  }

  // Get users for a specific branch
  Future<List<Map<String, dynamic>>> getUsersByBranch(String branchId) async {
    try {
      final response = await _client
          .from('users')
          .select('*, branches(name)')
          .eq('branch_id', branchId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[UserDataSource] Error fetching users by branch: $e');
      return [];
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('*, branches(name)')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      print('[UserDataSource] Error fetching user: $e');
      return null;
    }
  }

  // Create a new user
  Future<Map<String, dynamic>?> createUser({
    required String email,
    required String fullName,
    required String role,
    required String tenantId,
    String? branchId,
    String? phone,
  }) async {
    try {
      final response = await _client
          .from('users')
          .insert({
            'email': email,
            'full_name': fullName,
            'role': role,
            'tenant_id': tenantId,
            'branch_id': branchId,
            'phone': phone,
            'is_active': true,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('[UserDataSource] Error creating user: $e');
      rethrow;
    }
  }

  // Update user
  Future<Map<String, dynamic>?> updateUser(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('users')
          .update(data)
          .eq('id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('[UserDataSource] Error updating user: $e');
      rethrow;
    }
  }

  // Toggle user active status
  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _client
          .from('users')
          .update({'is_active': isActive})
          .eq('id', userId);

      return true;
    } catch (e) {
      print('[UserDataSource] Error toggling user status: $e');
      return false;
    }
  }

  // Get user count by role for a tenant
  Future<Map<String, int>> getUserCountByRole(String tenantId) async {
    try {
      final response = await _client
          .from('users')
          .select('role')
          .eq('tenant_id', tenantId);

      Map<String, int> roleCounts = {};
      for (var user in response) {
        final role = user['role'] as String? ?? 'unknown';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }

      return roleCounts;
    } catch (e) {
      print('[UserDataSource] Error getting user count: $e');
      return {};
    }
  }
}
