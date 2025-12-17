import '../../core/services/supabase_service.dart';
import '../models/stock_model.dart';

class StockDataSource {
  final SupabaseService _supabase = SupabaseService.instance;

  // Get current stock for a branch
  Future<List<CurrentStock>> getCurrentStockByBranch(String branchId) async {
    try {
      final data = await _supabase
          .from('current_stock')
          .select('*')
          .eq('branch_id', branchId)
          .order('updated_at', ascending: false);

      return (data as List).map((json) => CurrentStock.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch current stock: ${e.toString()}');
    }
  }

  // Get current stock for all branches in a tenant
  Future<List<CurrentStock>> getCurrentStockByTenant(String tenantId) async {
    try {
      // Get all branches for this tenant first
      final branchesData = await _supabase
          .from('branches')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('is_active', true);

      if ((branchesData as List).isEmpty) {
        return [];
      }

      final branchIds = branchesData.map((b) => b['id'] as String).toList();

      final data = await _supabase
          .from('current_stock')
          .select('*')
          .inFilter('branch_id', branchIds)
          .order('updated_at', ascending: false);

      return (data as List).map((json) => CurrentStock.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch tenant stock: ${e.toString()}');
    }
  }

  // Get stock for a specific product in a branch
  Future<CurrentStock?> getProductStock(
    String branchId,
    String productId,
  ) async {
    try {
      final data = await _supabase
          .from('current_stock')
          .select()
          .eq('branch_id', branchId)
          .eq('product_id', productId)
          .maybeSingle();

      return data != null ? CurrentStock.fromJson(data) : null;
    } catch (e) {
      throw Exception('Failed to fetch product stock: ${e.toString()}');
    }
  }

  // Get stock ledger history
  Future<List<StockLedger>> getStockLedger({
    required String branchId,
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('stock_ledger')
          .select()
          .eq('branch_id', branchId);

      if (productId != null) {
        query = query.eq('product_id', productId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return (data as List).map((json) => StockLedger.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stock ledger: ${e.toString()}');
    }
  }

  // Stock In - Add stock
  Future<void> addStockIn({
    required String branchId,
    required String productId,
    required int quantity,
    String? reason,
    String? referenceId,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Call RPC function to add stock (this handles ledger + current stock update)
      await _supabase.rpc(
        'add_stock_in',
        params: {
          'p_branch_id': branchId,
          'p_product_id': productId,
          'p_quantity': quantity,
          'p_reason': reason,
          'p_reference_id': referenceId,
          'p_created_by': userId,
        },
      );
    } catch (e) {
      throw Exception('Failed to add stock: ${e.toString()}');
    }
  }

  // Stock Out - Remove stock
  Future<void> addStockOut({
    required String branchId,
    required String productId,
    required int quantity,
    String? reason,
    String? referenceId,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.rpc(
        'add_stock_out',
        params: {
          'p_branch_id': branchId,
          'p_product_id': productId,
          'p_quantity': quantity,
          'p_reason': reason,
          'p_reference_id': referenceId,
          'p_created_by': userId,
        },
      );
    } catch (e) {
      throw Exception('Failed to remove stock: ${e.toString()}');
    }
  }

  // Stock Adjustment
  Future<void> adjustStock({
    required String branchId,
    required String productId,
    required int newQuantity,
    required String reason,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.rpc(
        'adjust_stock',
        params: {
          'p_branch_id': branchId,
          'p_product_id': productId,
          'p_new_quantity': newQuantity,
          'p_reason': reason,
          'p_created_by': userId,
        },
      );
    } catch (e) {
      throw Exception('Failed to adjust stock: ${e.toString()}');
    }
  }

  // Stock Transfer between branches
  Future<void> transferStock({
    required String fromBranchId,
    required String toBranchId,
    required String productId,
    required int quantity,
    String? reason,
  }) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.rpc(
        'transfer_stock',
        params: {
          'p_from_branch_id': fromBranchId,
          'p_to_branch_id': toBranchId,
          'p_product_id': productId,
          'p_quantity': quantity,
          'p_reason': reason,
          'p_created_by': userId,
        },
      );
    } catch (e) {
      throw Exception('Failed to transfer stock: ${e.toString()}');
    }
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts(
    String branchId,
  ) async {
    try {
      final data = await _supabase.rpc(
        'get_low_stock_products',
        params: {'p_branch_id': branchId},
      );

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Failed to fetch low stock products: ${e.toString()}');
    }
  }

  // Serial Number Management

  // Get available serial numbers for a product
  Future<List<ProductSerialNumber>> getAvailableSerialNumbers({
    required String branchId,
    required String productId,
  }) async {
    try {
      final data = await _supabase
          .from('product_serial_numbers')
          .select()
          .eq('branch_id', branchId)
          .eq('product_id', productId)
          .eq('status', 'available')
          .order('serial_number', ascending: true);

      return (data as List)
          .map((json) => ProductSerialNumber.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch serial numbers: ${e.toString()}');
    }
  }

  // Add serial numbers (during purchase/stock-in)
  Future<void> addSerialNumbers({
    required String branchId,
    required String productId,
    required List<String> serialNumbers,
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

      final List<Map<String, dynamic>> serialsToInsert = serialNumbers.map((
        sn,
      ) {
        return {
          'tenant_id': branchData['tenant_id'],
          'branch_id': branchId,
          'product_id': productId,
          'serial_number': sn,
          'status': 'available',
        };
      }).toList();

      await _supabase.from('product_serial_numbers').insert(serialsToInsert);
    } catch (e) {
      throw Exception('Failed to add serial numbers: ${e.toString()}');
    }
  }

  // Mark serial numbers as sold
  Future<void> markSerialNumbersAsSold({
    required List<String> serialNumberIds,
    required String billId,
  }) async {
    try {
      await _supabase
          .from('product_serial_numbers')
          .update({
            'status': 'sold',
            'bill_id': billId,
            'sold_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', serialNumberIds);
    } catch (e) {
      throw Exception('Failed to mark serial numbers as sold: ${e.toString()}');
    }
  }
}
