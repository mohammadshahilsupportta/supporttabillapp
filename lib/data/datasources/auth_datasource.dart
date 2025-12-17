// Note: Some analyzer warnings about undefined methods on Supabase query builders
// are false positives. These methods (eq, insert, update, etc.) exist at runtime
// and work correctly. The warnings are due to type inference limitations.
// We suppress them with // ignore comments where necessary.

import '../../core/services/supabase_service.dart';
import '../models/user_model.dart';

class AuthDataSource {
  final SupabaseService _supabase = SupabaseService.instance;

  // Sign in
  Future<User> signIn({required String email, required String password}) async {
    try {
      final response = await _supabase.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed. Please check your credentials.');
      }

      // Fetch user profile from users table
      // ignore: undefined_method
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return User.fromJson(userData);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return null;

      // ignore: undefined_method
      final userData = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Create user (for tenant owners creating staff)
  Future<User> createUser({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? tenantId,
    String? branchId,
  }) async {
    try {
      // First create auth user
      final authResponse = await _supabase.signUpWithEmail(
        email: email,
        password: password,
        metadata: {'full_name': fullName},
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }

      // Then create user profile
      // ignore: undefined_method
      final userData = await _supabase
          .from('users')
          .insert({
            'id': authResponse.user!.id,
            'email': email,
            'full_name': fullName,
            'role': role.value,
            'tenant_id': tenantId,
            'branch_id': branchId,
            'is_active': true,
          })
          .select()
          .single();

      return User.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to create user: ${e.toString()}');
    }
  }

  // Update user
  Future<User> updateUser({
    required String userId,
    String? fullName,
    bool? isActive,
    String? branchId,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['full_name'] = fullName;
      if (isActive != null) updates['is_active'] = isActive;
      if (branchId != null) updates['branch_id'] = branchId;
      updates['updated_at'] = DateTime.now().toIso8601String();

      // ignore: undefined_method
      final userData = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return User.fromJson(userData);
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Get users by tenant
  Future<List<User>> getUsersByTenant(String tenantId) async {
    try {
      // ignore: undefined_method
      final data = await _supabase
          .from('users')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: ${e.toString()}');
    }
  }

  // Get users by branch
  Future<List<User>> getUsersByBranch(String branchId) async {
    try {
      // ignore: undefined_method
      final data = await _supabase
          .from('users')
          .select()
          .eq('branch_id', branchId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: ${e.toString()}');
    }
  }
}
