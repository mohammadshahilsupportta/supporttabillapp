import '../../core/services/supabase_service.dart';

class DashboardDataSource {
  final SupabaseService _supabase = SupabaseService.instance;

  // Get comprehensive dashboard stats (matching website API)
  Future<Map<String, dynamic>> getDashboardStats({
    String? branchId,
    String? tenantId,
    String period = 'today', // today, month, all
  }) async {
    try {
      print('=== getDashboardStats ===');
      print('branchId: $branchId, tenantId: $tenantId, period: $period');

      // Get date filter based on period
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);

      String? dateFilter;
      if (period == 'today') {
        dateFilter = todayStart.toIso8601String();
      } else if (period == 'month') {
        dateFilter = monthStart.toIso8601String();
      }

      // Get branch IDs for filtering
      List<String> branchIds = [];
      if (branchId != null) {
        branchIds = [branchId];
      } else if (tenantId != null) {
        final branchesData = await _supabase
            .from('branches')
            .select('id')
            .eq('tenant_id', tenantId)
            .eq('is_active', true);
        branchIds = (branchesData as List)
            .map((b) => b['id'] as String)
            .toList();

        if (branchIds.isEmpty) {
          return _emptyStats(period);
        }
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        _fetchBills(branchIds, dateFilter),
        _fetchExpenses(branchIds, dateFilter),
        _fetchPurchases(branchIds, dateFilter),
        _fetchStockData(branchIds, tenantId),
        _fetchProducts(tenantId),
      ]);

      final bills = results[0] as List<Map<String, dynamic>>;
      final expenses = results[1] as List<Map<String, dynamic>>;
      final purchases = results[2] as List<Map<String, dynamic>>;
      final stockItems = results[3] as List<Map<String, dynamic>>;
      final products = results[4] as List<Map<String, dynamic>>;

      // Calculate Sales
      double totalSales = 0;
      double billsProfit = 0;
      for (final bill in bills) {
        totalSales += (bill['total_amount'] as num?)?.toDouble() ?? 0;
        billsProfit += (bill['profit_amount'] as num?)?.toDouble() ?? 0;
      }

      // Calculate Expenses
      double totalExpenses = 0;
      for (final exp in expenses) {
        totalExpenses += (exp['amount'] as num?)?.toDouble() ?? 0;
      }

      // Calculate Purchases
      double totalPurchases = 0;
      for (final pur in purchases) {
        totalPurchases += (pur['total_amount'] as num?)?.toDouble() ?? 0;
      }

      // Filter stock to active products only
      final activeProductIds = products.map((p) => p['id'] as String).toSet();
      final activeStockItems = stockItems
          .where((item) => activeProductIds.contains(item['product_id']))
          .toList();

      // Calculate Stock Value
      double stockValue = 0;
      for (final item in activeStockItems) {
        final productId = item['product_id'];
        final product = products.firstWhere(
          (p) => p['id'] == productId,
          orElse: () => {},
        );
        if (product.isNotEmpty) {
          final price =
              (product['purchase_price'] as num?)?.toDouble() ??
              (product['selling_price'] as num?)?.toDouble() ??
              0;
          final qty = (item['quantity'] as num?)?.toInt() ?? 0;
          stockValue += qty * price;
        }
      }

      // Calculate Stock Metrics
      int lowStockCount = 0;
      int soldOutCount = 0;
      int inStockCount = 0;

      for (final item in activeStockItems) {
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final productId = item['product_id'];
        final product = products.firstWhere(
          (p) => p['id'] == productId,
          orElse: () => {},
        );

        if (product.isNotEmpty) {
          final minStock = (product['min_stock'] as num?)?.toInt() ?? 0;

          if (qty == 0) {
            soldOutCount++;
          } else if (minStock > 0 && qty <= minStock) {
            lowStockCount++;
            inStockCount++;
          } else {
            inStockCount++;
          }
        }
      }

      // Calculate Profit
      final netProfit = billsProfit - totalExpenses - totalPurchases;
      final profitMargin = totalSales > 0 ? (netProfit / totalSales) * 100 : 0;

      print(
        'Sales: $totalSales, Expenses: $totalExpenses, Purchases: $totalPurchases',
      );
      print('Stock Value: $stockValue, Products: ${products.length}');
      print('Low Stock: $lowStockCount, Sold Out: $soldOutCount');

      return {
        'sales': {'total': totalSales, 'count': bills.length},
        'expenses': {'total': totalExpenses, 'count': expenses.length},
        'purchases': {'total': totalPurchases, 'count': purchases.length},
        'stock': {
          'total_value': stockValue,
          'total_products': products.length,
          'products_with_stock': activeStockItems.length,
          'in_stock': inStockCount,
          'low_stock': lowStockCount,
          'sold_out': soldOutCount,
        },
        'profit': {
          'total': netProfit,
          'margin': profitMargin,
          'from_sales': billsProfit,
        },
        'period': period,
      };
    } catch (e) {
      print('getDashboardStats error: $e');
      throw Exception('Failed to fetch dashboard stats: ${e.toString()}');
    }
  }

  Map<String, dynamic> _emptyStats(String period) {
    return {
      'sales': {'total': 0.0, 'count': 0},
      'expenses': {'total': 0.0, 'count': 0},
      'purchases': {'total': 0.0, 'count': 0},
      'stock': {
        'total_value': 0.0,
        'total_products': 0,
        'products_with_stock': 0,
        'in_stock': 0,
        'low_stock': 0,
        'sold_out': 0,
      },
      'profit': {'total': 0.0, 'margin': 0.0, 'from_sales': 0.0},
      'period': period,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchBills(
    List<String> branchIds,
    String? dateFilter,
  ) async {
    if (branchIds.isEmpty) return [];

    var query = _supabase
        .from('bills')
        .select('total_amount, profit_amount, created_at');

    query = query.inFilter('branch_id', branchIds);

    if (dateFilter != null) {
      query = query.gte('created_at', dateFilter);
    }

    final data = await query;
    return List<Map<String, dynamic>>.from(data as List);
  }

  Future<List<Map<String, dynamic>>> _fetchExpenses(
    List<String> branchIds,
    String? dateFilter,
  ) async {
    if (branchIds.isEmpty) return [];

    try {
      var query = _supabase
          .from('expenses')
          .select('amount, expense_date, created_at');

      query = query.inFilter('branch_id', branchIds);

      if (dateFilter != null) {
        query = query.gte('expense_date', dateFilter);
      }

      final data = await query;
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPurchases(
    List<String> branchIds,
    String? dateFilter,
  ) async {
    if (branchIds.isEmpty) return [];

    try {
      var query = _supabase
          .from('purchases')
          .select('total_amount, created_at');

      query = query.inFilter('branch_id', branchIds);

      if (dateFilter != null) {
        query = query.gte('created_at', dateFilter);
      }

      final data = await query;
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      print('Error fetching purchases: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchStockData(
    List<String> branchIds,
    String? tenantId,
  ) async {
    if (branchIds.isEmpty) return [];

    try {
      var query = _supabase
          .from('current_stock')
          .select('quantity, product_id');

      query = query.inFilter('branch_id', branchIds);

      final data = await query;
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      print('Error fetching stock: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProducts(String? tenantId) async {
    if (tenantId == null) return [];

    try {
      final data = await _supabase
          .from('products')
          .select('id, purchase_price, selling_price, min_stock')
          .eq('tenant_id', tenantId)
          .eq('is_active', true);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      print('Error fetching products: $e');
      return [];
    }
  }

  // Get tenant statistics (simplified for backward compatibility)
  Future<Map<String, dynamic>> getTenantStats(String tenantId) async {
    try {
      final stats = await getDashboardStats(
        tenantId: tenantId,
        period: 'today',
      );

      // Get branches count
      final branchesData = await _supabase
          .from('branches')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('is_active', true);

      // Get users count
      final usersData = await _supabase
          .from('users')
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('is_active', true);

      return {
        'branch_count': (branchesData as List).length,
        'product_count': stats['stock']['total_products'],
        'user_count': (usersData as List).length,
        'today_sales': stats['sales']['total'],
        ...stats,
      };
    } catch (e) {
      throw Exception('Failed to fetch tenant stats: ${e.toString()}');
    }
  }

  // Get branch statistics
  Future<Map<String, dynamic>> getBranchStats(String branchId) async {
    try {
      // Get branch's tenant ID
      final branchInfo = await _supabase
          .from('branches')
          .select('tenant_id')
          .eq('id', branchId)
          .single();

      final tenantId = branchInfo['tenant_id'] as String;

      final stats = await getDashboardStats(
        branchId: branchId,
        tenantId: tenantId,
        period: 'today',
      );

      return {
        'today_sales': stats['sales']['total'],
        'bill_count': stats['sales']['count'],
        'product_count': stats['stock']['total_products'],
        'low_stock_count': stats['stock']['low_stock'],
        ...stats,
      };
    } catch (e) {
      throw Exception('Failed to fetch branch stats: ${e.toString()}');
    }
  }

  // Get all branches for tenant
  Future<List<Map<String, dynamic>>> getBranchesByTenant(
    String tenantId,
  ) async {
    try {
      final data = await _supabase
          .from('branches')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      throw Exception('Failed to fetch branches: ${e.toString()}');
    }
  }

  // Get users for tenant
  Future<List<Map<String, dynamic>>> getUsersByTenant(String tenantId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('id, full_name, email, role, is_active, branch_id')
          .eq('tenant_id', tenantId)
          .order('full_name', ascending: true);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get superadmin statistics
  Future<Map<String, dynamic>> getSuperadminStats() async {
    try {
      // Get tenants count
      final tenantsData = await _supabase
          .from('tenants')
          .select('id')
          .eq('is_active', true);

      final tenantCount = (tenantsData as List).length;

      // Get total users count
      final usersData = await _supabase
          .from('users')
          .select('id')
          .eq('is_active', true);

      final userCount = (usersData as List).length;

      // Get total branches count
      final branchesData = await _supabase
          .from('branches')
          .select('id')
          .eq('is_active', true);

      final branchCount = (branchesData as List).length;

      // Get today's total sales
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final billsData = await _supabase
          .from('bills')
          .select('total_amount')
          .gte('created_at', startOfDay.toIso8601String());

      double todaySales = 0;
      for (final bill in billsData as List) {
        todaySales += (bill['total_amount'] as num?)?.toDouble() ?? 0;
      }

      return {
        'tenant_count': tenantCount,
        'user_count': userCount,
        'branch_count': branchCount,
        'today_sales': todaySales,
      };
    } catch (e) {
      throw Exception('Failed to fetch superadmin stats: ${e.toString()}');
    }
  }

  // Get recent bills
  Future<List<Map<String, dynamic>>> getRecentBills({
    String? tenantId,
    String? branchId,
    int limit = 10,
  }) async {
    try {
      var query = _supabase
          .from('bills')
          .select(
            'id, invoice_number, customer_name, total_amount, payment_mode, created_at, branch_id',
          );

      if (branchId != null) {
        query = query.eq('branch_id', branchId);
      } else if (tenantId != null) {
        query = query.eq('tenant_id', tenantId);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      print('Error fetching recent bills: $e');
      return [];
    }
  }

  // Get branch-wise sales for tenant owner
  Future<List<Map<String, dynamic>>> getBranchWiseSales(String tenantId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final branches = await getBranchesByTenant(tenantId);
      final branchSales = <Map<String, dynamic>>[];

      for (final branch in branches) {
        final branchId = branch['id'] as String;
        final branchName = branch['name'] as String? ?? 'Unknown';

        final billsData = await _supabase
            .from('bills')
            .select('total_amount')
            .eq('branch_id', branchId)
            .gte('created_at', startOfDay.toIso8601String());

        double sales = 0;
        for (final bill in billsData as List) {
          sales += (bill['total_amount'] as num?)?.toDouble() ?? 0;
        }

        branchSales.add({
          'branch_id': branchId,
          'branch_name': branchName,
          'is_main': branch['is_main'] ?? false,
          'is_active': branch['is_active'] ?? true,
          'today_sales': sales,
        });
      }

      return branchSales;
    } catch (e) {
      print('Error fetching branch sales: $e');
      return [];
    }
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts({
    String? tenantId,
    String? branchId,
    int limit = 20,
  }) async {
    try {
      if (branchId == null && tenantId == null) return [];

      // Get products
      List<Map<String, dynamic>> products = [];
      if (tenantId != null) {
        final data = await _supabase
            .from('products')
            .select('id, name, min_stock, unit')
            .eq('tenant_id', tenantId)
            .eq('is_active', true);
        products = List<Map<String, dynamic>>.from(data as List);
      }

      // Get stock
      var stockQuery = _supabase
          .from('current_stock')
          .select('quantity, product_id, branch_id');

      if (branchId != null) {
        stockQuery = stockQuery.eq('branch_id', branchId);
      }

      final stockData = await stockQuery;

      final lowStock = <Map<String, dynamic>>[];
      for (final stock in stockData as List) {
        final quantity = (stock['quantity'] as num?)?.toInt() ?? 0;
        final productId = stock['product_id'];

        final product = products.firstWhere(
          (p) => p['id'] == productId,
          orElse: () => {},
        );

        if (product.isNotEmpty) {
          final minStock = (product['min_stock'] as num?)?.toInt() ?? 10;
          if (quantity <= minStock) {
            lowStock.add({
              'product_id': productId,
              'product_name': product['name'] ?? 'Unknown',
              'current_quantity': quantity,
              'min_stock': minStock,
              'unit': product['unit'] ?? 'pcs',
              'is_sold_out': quantity == 0,
            });
          }
        }
      }

      // Sort by most critical (sold out first, then lowest quantity)
      lowStock.sort((a, b) {
        if (a['is_sold_out'] && !b['is_sold_out']) return -1;
        if (!a['is_sold_out'] && b['is_sold_out']) return 1;
        return (a['current_quantity'] as int).compareTo(
          b['current_quantity'] as int,
        );
      });

      return lowStock.take(limit).toList();
    } catch (e) {
      print('Error fetching low stock: $e');
      return [];
    }
  }
}
