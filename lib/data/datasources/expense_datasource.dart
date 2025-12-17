import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';

class ExpenseDataSource {
  final SupabaseClient _client = SupabaseService.instance.client;

  // Get all expenses for a branch
  Future<List<Map<String, dynamic>>> getExpenses(String branchId) async {
    try {
      final response = await _client
          .from('expenses')
          .select('*')
          .eq('branch_id', branchId)
          .order('expense_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[ExpenseDataSource] Error fetching expenses: $e');
      return [];
    }
  }

  // Get expenses for tenant (all branches)
  Future<List<Map<String, dynamic>>> getExpensesByTenant(
    String tenantId,
  ) async {
    try {
      final response = await _client
          .from('expenses')
          .select('*, branches!inner(tenant_id)')
          .eq('branches.tenant_id', tenantId)
          .order('expense_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[ExpenseDataSource] Error fetching expenses by tenant: $e');
      return [];
    }
  }

  // Get expense by ID
  Future<Map<String, dynamic>?> getExpenseById(String expenseId) async {
    try {
      final response = await _client
          .from('expenses')
          .select('*')
          .eq('id', expenseId)
          .single();

      return response;
    } catch (e) {
      print('[ExpenseDataSource] Error fetching expense: $e');
      return null;
    }
  }

  // Create a new expense
  Future<Map<String, dynamic>?> createExpense({
    required String branchId,
    required String category,
    required String description,
    required double amount,
    required String paymentMode,
    required String expenseDate,
    String? receiptNumber,
    String? vendorName,
    String? notes,
    String? createdBy,
  }) async {
    try {
      final response = await _client
          .from('expenses')
          .insert({
            'branch_id': branchId,
            'category': category,
            'description': description,
            'amount': amount,
            'payment_mode': paymentMode,
            'expense_date': expenseDate,
            'receipt_number': receiptNumber,
            'vendor_name': vendorName,
            'notes': notes,
            'created_by': createdBy,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      print('[ExpenseDataSource] Error creating expense: $e');
      rethrow;
    }
  }

  // Update an expense
  Future<Map<String, dynamic>?> updateExpense(
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('expenses')
          .update(data)
          .eq('id', expenseId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('[ExpenseDataSource] Error updating expense: $e');
      rethrow;
    }
  }

  // Delete an expense
  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _client.from('expenses').delete().eq('id', expenseId);

      return true;
    } catch (e) {
      print('[ExpenseDataSource] Error deleting expense: $e');
      return false;
    }
  }

  // Get total expenses for a period
  Future<double> getTotalExpenses(
    String branchId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _client
          .from('expenses')
          .select('amount')
          .eq('branch_id', branchId);

      if (fromDate != null) {
        query = query.gte('expense_date', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('expense_date', toDate.toIso8601String());
      }

      final response = await query;

      double total = 0;
      for (var expense in response) {
        total += (expense['amount'] as num?)?.toDouble() ?? 0;
      }

      return total;
    } catch (e) {
      print('[ExpenseDataSource] Error calculating total expenses: $e');
      return 0;
    }
  }

  // Get expenses grouped by category
  Future<Map<String, double>> getExpensesByCategory(String branchId) async {
    try {
      final response = await _client
          .from('expenses')
          .select('category, amount')
          .eq('branch_id', branchId);

      Map<String, double> categoryTotals = {};
      for (var expense in response) {
        final category = expense['category'] as String? ?? 'other';
        final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      print('[ExpenseDataSource] Error getting expenses by category: $e');
      return {};
    }
  }
}
