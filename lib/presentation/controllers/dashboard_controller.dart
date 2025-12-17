import 'package:get/get.dart';

import '../../data/datasources/dashboard_datasource.dart';
import 'auth_controller.dart';

class DashboardController extends GetxController {
  final DashboardDataSource _dataSource = DashboardDataSource();

  // Loading state
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Period filter (today, month, all)
  final selectedPeriod = 'today'.obs;

  // ========== SALES STATS ==========
  final totalSales = 0.0.obs;
  final salesCount = 0.obs;

  // ========== EXPENSES STATS ==========
  final totalExpenses = 0.0.obs;
  final expensesCount = 0.obs;

  // ========== PURCHASES STATS ==========
  final totalPurchases = 0.0.obs;
  final purchasesCount = 0.obs;

  // ========== STOCK STATS ==========
  final stockValue = 0.0.obs;
  final totalProducts = 0.obs;
  final productsWithStock = 0.obs;
  final inStockCount = 0.obs;
  final lowStockCount = 0.obs;
  final soldOutCount = 0.obs;

  // ========== PROFIT STATS ==========
  final totalProfit = 0.0.obs;
  final profitMargin = 0.0.obs;
  final profitFromSales = 0.0.obs;

  // ========== LISTS ==========
  final branches = <Map<String, dynamic>>[].obs;
  final users = <Map<String, dynamic>>[].obs;
  final recentBills = <Map<String, dynamic>>[].obs;
  final lowStockProducts = <Map<String, dynamic>>[].obs;
  final branchWiseSales = <Map<String, dynamic>>[].obs;

  // Superadmin specific
  final tenantCount = 0.obs;
  final userCount = 0.obs;
  final branchCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    // Small delay to ensure AuthController has loaded user data
    Future.delayed(const Duration(milliseconds: 500), () {
      loadStats();
    });

    // Listen to user changes
    ever(Get.find<AuthController>().currentUser, (user) {
      if (user != null && !isLoading.value) {
        print('User changed, reloading stats...');
        loadStats();
      }
    });
  }

  // Change period and reload stats
  void changePeriod(String period) {
    selectedPeriod.value = period;
    loadStats();
  }

  // Load appropriate stats based on user role
  Future<void> loadStats() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      print('=== DashboardController.loadStats ===');
      print('User: ${user?.fullName}');
      print('Role: ${user?.role.value}');
      print('Tenant ID: ${user?.tenantId}');
      print('Branch ID: ${user?.branchId}');
      print('Period: ${selectedPeriod.value}');

      if (user == null) {
        print('ERROR: User is null, cannot load stats');
        return;
      }

      switch (user.role.value) {
        case 'superadmin':
          await loadSuperadminStats();
          break;
        case 'tenant_owner':
          await loadTenantOwnerStats();
          break;
        case 'branch_admin':
        case 'branch_staff':
          await loadBranchStats();
          break;
        default:
          print('Unknown role: ${user.role.value}');
      }
    } catch (e) {
      errorMessage.value = e.toString();
      print('Dashboard stats error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Load tenant owner stats (comprehensive)
  Future<void> loadTenantOwnerStats() async {
    try {
      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;

      if (tenantId == null) {
        throw Exception('Tenant ID not found');
      }

      print('Loading tenant owner stats for: $tenantId');

      // Load comprehensive dashboard stats
      final stats = await _dataSource.getDashboardStats(
        tenantId: tenantId,
        period: selectedPeriod.value,
      );

      _updateStatsFromData(stats);

      // Load additional data
      await Future.wait([
        _loadBranches(tenantId),
        _loadUsers(tenantId),
        _loadRecentBills(tenantId: tenantId),
        _loadBranchWiseSales(tenantId),
        _loadLowStockProducts(tenantId: tenantId),
      ]);

      print('Tenant owner stats loaded successfully');
    } catch (e) {
      print('loadTenantOwnerStats error: $e');
      rethrow;
    }
  }

  // Load branch stats (comprehensive)
  Future<void> loadBranchStats() async {
    try {
      final authController = Get.find<AuthController>();
      final branchId = authController.branchId;
      final tenantId = authController.tenantId;

      if (branchId == null) {
        throw Exception('Branch ID not found');
      }

      print('Loading branch stats for: $branchId');

      // Load comprehensive dashboard stats
      final stats = await _dataSource.getDashboardStats(
        branchId: branchId,
        tenantId: tenantId,
        period: selectedPeriod.value,
      );

      _updateStatsFromData(stats);

      // Load additional data
      await Future.wait([
        _loadRecentBills(branchId: branchId),
        _loadLowStockProducts(branchId: branchId, tenantId: tenantId),
      ]);

      print('Branch stats loaded successfully');
    } catch (e) {
      print('loadBranchStats error: $e');
      rethrow;
    }
  }

  // Load superadmin stats
  Future<void> loadSuperadminStats() async {
    try {
      final stats = await _dataSource.getSuperadminStats();

      tenantCount.value = stats['tenant_count'] ?? 0;
      userCount.value = stats['user_count'] ?? 0;
      branchCount.value = stats['branch_count'] ?? 0;
      totalSales.value = (stats['today_sales'] as num?)?.toDouble() ?? 0.0;

      // Load recent bills
      await _loadRecentBills();

      print('Superadmin stats loaded successfully');
    } catch (e) {
      print('loadSuperadminStats error: $e');
      rethrow;
    }
  }

  // Update stats from data
  void _updateStatsFromData(Map<String, dynamic> stats) {
    // Sales
    final sales = stats['sales'] as Map<String, dynamic>? ?? {};
    totalSales.value = (sales['total'] as num?)?.toDouble() ?? 0.0;
    salesCount.value = (sales['count'] as num?)?.toInt() ?? 0;

    // Expenses
    final expenses = stats['expenses'] as Map<String, dynamic>? ?? {};
    totalExpenses.value = (expenses['total'] as num?)?.toDouble() ?? 0.0;
    expensesCount.value = (expenses['count'] as num?)?.toInt() ?? 0;

    // Purchases
    final purchases = stats['purchases'] as Map<String, dynamic>? ?? {};
    totalPurchases.value = (purchases['total'] as num?)?.toDouble() ?? 0.0;
    purchasesCount.value = (purchases['count'] as num?)?.toInt() ?? 0;

    // Stock
    final stock = stats['stock'] as Map<String, dynamic>? ?? {};
    stockValue.value = (stock['total_value'] as num?)?.toDouble() ?? 0.0;
    totalProducts.value = (stock['total_products'] as num?)?.toInt() ?? 0;
    productsWithStock.value =
        (stock['products_with_stock'] as num?)?.toInt() ?? 0;
    inStockCount.value = (stock['in_stock'] as num?)?.toInt() ?? 0;
    lowStockCount.value = (stock['low_stock'] as num?)?.toInt() ?? 0;
    soldOutCount.value = (stock['sold_out'] as num?)?.toInt() ?? 0;

    // Profit
    final profit = stats['profit'] as Map<String, dynamic>? ?? {};
    totalProfit.value = (profit['total'] as num?)?.toDouble() ?? 0.0;
    profitMargin.value = (profit['margin'] as num?)?.toDouble() ?? 0.0;
    profitFromSales.value = (profit['from_sales'] as num?)?.toDouble() ?? 0.0;
  }

  // Load branches
  Future<void> _loadBranches(String tenantId) async {
    try {
      branches.value = await _dataSource.getBranchesByTenant(tenantId);
      branchCount.value = branches.length;
    } catch (e) {
      print('Error loading branches: $e');
    }
  }

  // Load users
  Future<void> _loadUsers(String tenantId) async {
    try {
      users.value = await _dataSource.getUsersByTenant(tenantId);
      userCount.value = users.length;
    } catch (e) {
      print('Error loading users: $e');
    }
  }

  // Load recent bills
  Future<void> _loadRecentBills({String? tenantId, String? branchId}) async {
    try {
      recentBills.value = await _dataSource.getRecentBills(
        tenantId: tenantId,
        branchId: branchId,
        limit: 10,
      );
    } catch (e) {
      print('Error loading recent bills: $e');
    }
  }

  // Load branch-wise sales
  Future<void> _loadBranchWiseSales(String tenantId) async {
    try {
      branchWiseSales.value = await _dataSource.getBranchWiseSales(tenantId);
    } catch (e) {
      print('Error loading branch sales: $e');
    }
  }

  // Load low stock products
  Future<void> _loadLowStockProducts({
    String? tenantId,
    String? branchId,
  }) async {
    try {
      lowStockProducts.value = await _dataSource.getLowStockProducts(
        tenantId: tenantId,
        branchId: branchId,
        limit: 20,
      );
    } catch (e) {
      print('Error loading low stock: $e');
    }
  }

  // Refresh stats
  Future<void> refreshStats() async {
    await loadStats();
  }

  // Format currency (short format)
  String formatCurrency(double amount) {
    if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  // Format currency (exact)
  String formatCurrencyExact(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Format currency (Indian format with commas)
  String formatCurrencyIndian(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final result = <String>[];
    int count = 0;

    for (int i = parts.length - 1; i >= 0; i--) {
      result.insert(0, parts[i]);
      count++;
      if (count == 3 && i > 0) {
        result.insert(0, ',');
        count = 0;
      } else if (count == 2 &&
          result.where((c) => c == ',').length >= 1 &&
          i > 0) {
        result.insert(0, ',');
        count = 0;
      }
    }

    return '₹${result.join('')}';
  }

  // Get period display name
  String get periodDisplayName {
    switch (selectedPeriod.value) {
      case 'today':
        return 'Today';
      case 'month':
        return 'This Month';
      case 'all':
        return 'All Time';
      default:
        return 'Today';
    }
  }
}
