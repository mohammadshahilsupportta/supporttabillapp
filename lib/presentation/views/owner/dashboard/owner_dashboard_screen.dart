import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/branch_controller.dart';
import '../../../controllers/branch_store_controller.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../widgets/branch_switcher.dart';
import '../../../widgets/shimmer_widgets.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _selectedIndex = 0;
  bool _controllersInitialized = false;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const _BranchesTab(),
    const _ReportsTab(),
    const _SettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers immediately (not in post frame callback)
    _initializeBranchControllers();
  }

  Future<void> _initializeBranchControllers() async {
    if (_controllersInitialized) return;

    try {
      // AuthController is registered permanently in main.dart
      // Ensure other controllers exist
      if (!Get.isRegistered<BranchController>()) {
        Get.put(BranchController());
      }

      if (!Get.isRegistered<BranchStoreController>()) {
        Get.put(BranchStoreController());
      }

      if (!Get.isRegistered<DashboardController>()) {
        Get.put(DashboardController());
      }

      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user?.role.value == 'tenant_owner') {
        // Load branches immediately
        final branchController = Get.find<BranchController>();
        if (branchController.branches.isEmpty &&
            !branchController.isLoading.value) {
          await branchController.loadBranches();
        }

        // Auto-select main branch after branches are loaded
        final branchStore = Get.find<BranchStoreController>();
        await branchStore.autoSelectMainBranch();
      }

      _controllersInitialized = true;

      // Trigger rebuild if mounted
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error initializing branch controllers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(), overflow: TextOverflow.ellipsis),
        elevation: 0,
        actions: [
          // Branch switcher for tenant owners (only on dashboard tab)
          if (_selectedIndex == 0 && user?.role.value == 'tenant_owner')
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: BranchSwitcher(),
            ),
          if (_selectedIndex == 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.branchCreate),
                icon: const Icon(Icons.add_business, size: 18),
                label: const Text('Add Branch'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsSheet(context),
        backgroundColor: theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
            _buildNavItem(1, Icons.store_outlined, Icons.store, 'Branches'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              2,
              Icons.analytics_outlined,
              Icons.analytics,
              'Reports',
            ),
            _buildNavItem(
              3,
              Icons.settings_outlined,
              Icons.settings,
              'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? theme.primaryColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? theme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Quick Actions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  Icons.shopping_cart,
                  'New Bill',
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.posBilling);
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.person,
                  'Customers',
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.customersList);
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.receipt_long,
                  'Bills',
                  Colors.orange,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.billsList);
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.shopping_bag,
                  'Products',
                  Colors.purple,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.productsList);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Owner Dashboard';
      case 1:
        return 'Branches';
      case 2:
        return 'Reports';
      case 3:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }
}

// ============ COMPREHENSIVE DASHBOARD TAB ============
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Only initialize once, and schedule after frame to avoid build conflicts
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_initialized) {
          _initializeBranchSelection();
        }
      });
    }
  }

  Future<void> _initializeBranchSelection() async {
    if (_initialized) return;

    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      if (user?.role.value == 'tenant_owner') {
        // Ensure controllers are initialized
        if (!Get.isRegistered<BranchStoreController>() ||
            !Get.isRegistered<BranchController>()) {
          return;
        }

        final branchStore = Get.find<BranchStoreController>();
        final branchController = Get.find<BranchController>();

        // Only load branches if not already loaded
        if (branchController.branches.isEmpty &&
            !branchController.isLoading.value) {
          await branchController.loadBranches();
        }

        // Auto-select main branch if not already selected
        if (branchStore.selectedBranchId.value == null) {
          await branchStore.autoSelectMainBranch();
        }
      }

      if (mounted) {
        _initialized = true;
      }
    } catch (e) {
      print('Error initializing branch selection: $e');
      if (mounted) {
        _initialized =
            true; // Mark as initialized even on error to prevent retries
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== BRANCH INFO BANNER ==========
            // Wrap in Obx to make it reactive to branch changes
            if (user?.role.value == 'tenant_owner')
              Obx(() {
                Map<String, dynamic>? currentBranch;
                try {
                  if (Get.isRegistered<BranchStoreController>() &&
                      Get.isRegistered<BranchController>()) {
                    final branchStore = Get.find<BranchStoreController>();
                    final branchController = Get.find<BranchController>();

                    // Get current branch reactively
                    final selectedId = branchStore.selectedBranchId.value;
                    if (selectedId != null &&
                        branchController.branches.isNotEmpty) {
                      try {
                        currentBranch = branchController.branches.firstWhere(
                          (b) =>
                              b['id'] == selectedId && b['is_active'] == true,
                          orElse: () => <String, dynamic>{},
                        );
                        if (currentBranch.isEmpty) {
                          currentBranch = null;
                        }
                      } catch (_) {
                        currentBranch = null;
                      }
                    }
                  }
                } catch (_) {
                  // Controllers not available
                  currentBranch = null;
                }

                if (currentBranch == null || currentBranch.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.store, color: theme.primaryColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Viewing: ${currentBranch['name'] ?? 'Branch'}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                if (currentBranch['is_main'] == true) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Main Branch',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'All data shown for this branch only',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Obx(() {
                        if (dc.isLoading.value) {
                          return ShimmerWidgets.shimmerWrapper(
                            context: context,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                    ],
                  ),
                );
              }),

            // ========== PERIOD SELECTOR ==========
            Obx(() {
              if (dc.isLoading.value) {
                return ShimmerWidgets.shimmerPeriodSelector(context);
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Viewing: ${dc.periodDisplayName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    DropdownButton<String>(
                      value: dc.selectedPeriod.value,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'today', child: Text('Today')),
                        DropdownMenuItem(
                          value: 'month',
                          child: Text('This Month'),
                        ),
                        DropdownMenuItem(value: 'all', child: Text('All Time')),
                      ],
                      onChanged: (val) => dc.changePeriod(val ?? 'today'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // ========== PRIMARY METRICS - Sales & Stock ==========
            Obx(() {
              if (dc.isLoading.value) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerWidgets.shimmerWrapper(
                      context: context,
                      child: Container(
                        height: 24,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShimmerWidgets.shimmerDashboardGrid(context),
                    const SizedBox(height: 24),
                    ShimmerWidgets.shimmerWrapper(
                      context: context,
                      child: Container(
                        height: 24,
                        width: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShimmerWidgets.shimmerSecondaryGrid(context),
                    const SizedBox(height: 24),
                    ShimmerWidgets.shimmerQuickActionsSection(context),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales & Stock', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.4,
                    children: [
                      _buildStatCard(
                        context,
                        'Total Sales (${dc.periodDisplayName})',
                        dc.formatCurrencyIndian(dc.totalSales.value),
                        '${dc.salesCount.value} bills',
                        Icons.currency_rupee,
                        const Color(0xFF10B981), // Secondary green
                      ),
                      _buildStatCard(
                        context,
                        'Stock Value',
                        dc.formatCurrencyIndian(dc.stockValue.value),
                        '${dc.productsWithStock.value} products',
                        Icons.inventory_2,
                        const Color(0xFF2563EB), // Primary blue
                      ),
                      _buildStatCard(
                        context,
                        'Profit (${dc.periodDisplayName})',
                        dc.formatCurrencyIndian(dc.totalProfit.value),
                        '${dc.profitMargin.value.toStringAsFixed(1)}% margin',
                        Icons.trending_up,
                        dc.totalProfit.value >= 0
                            ? const Color(0xFF0891B2)
                            : const Color(0xFFEF4444), // Cyan or Red
                      ),
                      _buildStatCard(
                        context,
                        'Active Products',
                        '${dc.totalProducts.value}',
                        '${dc.inStockCount.value} in stock',
                        Icons.category,
                        const Color(0xFF8B5CF6), // Violet
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ========== SECONDARY METRICS ==========
                  Text(
                    'Stock Status & Financials',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.5,
                    children: [
                      _buildSmallStatCard(
                        context,
                        'Low Stock',
                        '${dc.lowStockCount.value}',
                        'Need restocking',
                        Icons.warning_amber,
                        dc.lowStockCount.value > 0
                            ? Colors.yellow.shade700
                            : Colors.grey,
                        dc.lowStockCount.value > 0
                            ? Colors.yellow.shade50
                            : null,
                      ),
                      _buildSmallStatCard(
                        context,
                        'Sold Out',
                        '${dc.soldOutCount.value}',
                        'Out of stock',
                        Icons.remove_circle_outline,
                        dc.soldOutCount.value > 0 ? Colors.red : Colors.grey,
                        dc.soldOutCount.value > 0 ? Colors.red.shade50 : null,
                      ),
                      _buildSmallStatCard(
                        context,
                        'Expenses',
                        dc.formatCurrency(dc.totalExpenses.value),
                        '${dc.expensesCount.value} entries',
                        Icons.arrow_downward,
                        Colors.orange,
                        null,
                      ),
                      _buildSmallStatCard(
                        context,
                        'Purchases',
                        dc.formatCurrency(dc.totalPurchases.value),
                        '${dc.purchasesCount.value} orders',
                        Icons.arrow_upward,
                        Colors.indigo,
                        null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ========== QUICK ACTIONS - Primary Focus ==========
                  if (dc.totalSales.value > 0)
                    _buildQuickActionsSection(context, dc)
                  else
                    const SizedBox.shrink(),
                ],
              );
            }),
            const SizedBox(height: 24),

            // ========== LOW STOCK ALERT ==========
            Obx(() {
              if (dc.lowStockCount.value == 0 && dc.soldOutCount.value == 0) {
                return const SizedBox.shrink();
              }
              return _buildLowStockAlert(context, dc);
            }),

            // ========== BRANCH-WISE SALES ==========
            Obx(() {
              if (dc.branchWiseSales.isEmpty) return const SizedBox.shrink();
              return _buildBranchWiseSalesSection(context, dc);
            }),

            // ========== RECENT BILLS ==========
            Obx(() {
              if (dc.recentBills.isEmpty) return const SizedBox.shrink();
              return _buildRecentBillsSection(context, dc);
            }),

            // ========== LOW STOCK PRODUCTS ==========
            Obx(() {
              if (dc.lowStockProducts.isEmpty) return const SizedBox.shrink();
              return _buildLowStockProductsSection(context, dc);
            }),

            // ========== BRANCHES & STAFF SECTION ==========
            Obx(() => _buildBranchesAndStaffSection(context, dc)),

            const SizedBox(height: 80), // Extra space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 2 : 1,
      color: isDark ? color.withValues(alpha: 0.15) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
          width: isDark ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? null : theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStatCard(
    BuildContext context,
    String title,
    String value,
    String description,
    IconData icon,
    Color color,
    Color? backgroundColor,
  ) {
    final theme = Theme.of(context);
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(
    BuildContext context,
    DashboardController dc,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Obx(
          () => GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              // Sales & Billing Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shopping_cart,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sales & Billing',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dc.formatCurrencyIndian(dc.totalSales.value),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade600,
                                      ),
                                ),
                                Text(
                                  '${dc.salesCount.value} bills this ${dc.periodDisplayName.toLowerCase()}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.productsList),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('View Products'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.createProduct),
                                  child: const Text('Add Product'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Stock Management Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock Management',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dc.formatCurrencyIndian(dc.stockValue.value),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade600,
                                      ),
                                ),
                                Text(
                                  'Total stock value',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.productsList),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('View Catalogue'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.createProduct),
                                  child: const Text('Add Product'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Profit & Expenses Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            color: Colors.purple.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Profit & Expenses',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dc.formatCurrencyIndian(dc.totalProfit.value),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: dc.totalProfit.value >= 0
                                            ? Colors.green.shade600
                                            : Colors.red.shade600,
                                      ),
                                ),
                                Text(
                                  '${dc.profitMargin.value.toStringAsFixed(1)}% profit margin',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.branchDetails),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple.shade600,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('View Branches'),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.branchCreate),
                                  child: const Text('Add Branch'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockAlert(BuildContext context, DashboardController dc) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.orange.withValues(alpha: 0.15)
            : Colors.yellow.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.orange.withValues(alpha: 0.3)
              : Colors.yellow.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: theme.brightness == Brightness.dark
                ? Colors.orange
                : Colors.yellow.shade700,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.brightness == Brightness.dark
                        ? Colors.orange.shade200
                        : Colors.yellow.shade800,
                  ),
                ),
                Text(
                  'You have ${dc.lowStockCount.value} low stock and ${dc.soldOutCount.value} sold out products.',
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark
                        ? Colors.orange.shade200
                        : Colors.yellow.shade800,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Get.toNamed(AppRoutes.stockList),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchWiseSalesSection(
    BuildContext context,
    DashboardController dc,
  ) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Branch Performance', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        ...dc.branchWiseSales
            .take(3)
            .map(
              (branch) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.store, color: theme.primaryColor),
                  ),
                  title: Row(
                    children: [
                      Text(branch['branch_name'] ?? 'Branch'),
                      if (branch['is_main'] == true) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Main',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: const Text("Today's Sales"),
                  trailing: Text(
                    dc.formatCurrency(
                      (branch['today_sales'] as num?)?.toDouble() ?? 0,
                    ),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecentBillsSection(
    BuildContext context,
    DashboardController dc,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, hh:mm a');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Bills', style: theme.textTheme.titleLarge),
            TextButton(
              onPressed: () => Get.toNamed(AppRoutes.billsList),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...dc.recentBills.take(5).map((bill) {
          final createdAt = DateTime.tryParse(bill['created_at'] ?? '');
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.receipt, color: Colors.green),
              ),
              title: Text(bill['invoice_number'] ?? 'INV-XXX'),
              subtitle: Text(
                createdAt != null ? dateFormat.format(createdAt) : '-',
              ),
              trailing: Text(
                dc.formatCurrencyExact(
                  (bill['total_amount'] as num?)?.toDouble() ?? 0,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLowStockProductsSection(
    BuildContext context,
    DashboardController dc,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Low Stock Products', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 8),
        ...dc.lowStockProducts.take(5).map((product) {
          final isSoldOut = product['is_sold_out'] == true;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isSoldOut
                ? (theme.brightness == Brightness.dark
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.red.shade50)
                : (theme.brightness == Brightness.dark
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.yellow.shade50),
            child: ListTile(
              leading: Icon(
                isSoldOut ? Icons.remove_circle : Icons.warning,
                color: isSoldOut ? Colors.red : Colors.orange,
              ),
              title: Text(product['product_name'] ?? 'Product'),
              subtitle: Text('Min: ${product['min_stock']} ${product['unit']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product['current_quantity']}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSoldOut ? Colors.red : Colors.orange,
                    ),
                  ),
                  Text(
                    isSoldOut ? 'Sold Out' : 'Low',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBranchesAndStaffSection(
    BuildContext context,
    DashboardController dc,
  ) {
    final theme = Theme.of(context);
    BranchController? branchController;
    AuthController? authController;

    try {
      if (Get.isRegistered<BranchController>()) {
        branchController = Get.find<BranchController>();
      }
    } catch (e) {
      print('_buildBranchesAndStaffSection: BranchController error: $e');
    }

    try {
      if (Get.isRegistered<AuthController>()) {
        authController = Get.find<AuthController>();
      }
    } catch (e) {
      print('_buildBranchesAndStaffSection: AuthController error: $e');
    }

    final tenantId = authController?.tenantId;

    if (branchController == null || authController == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            // Branches Card
            Expanded(
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Branches (${branchController.branches.length})',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Switch to branches tab
                              final parent = context
                                  .findAncestorStateOfType<
                                    _OwnerDashboardScreenState
                                  >();
                              if (parent != null) {
                                parent.setState(() {
                                  parent._selectedIndex = 1;
                                });
                              }
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (branchController.branches.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'No branches yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ...branchController.branches.take(3).map((branch) {
                          final isActive = branch['is_active'] == true;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    branch['name'] ?? 'Unknown',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.green.shade100
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isActive
                                          ? Colors.green.shade800
                                          : Colors.grey.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Staff Card
            Expanded(
              child: Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 18,
                                  color: theme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Staff (${dc.userCount.value})',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.toNamed(AppRoutes.usersList),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (dc.users.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'No staff members yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        )
                      else
                        ...dc.users
                            .where(
                              (u) =>
                                  u['tenant_id'] == tenantId &&
                                  u['role'] != 'tenant_owner',
                            )
                            .take(3)
                            .map((member) {
                              final isActive = member['is_active'] == true;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member['full_name'] ?? 'Unknown',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Colors.green.shade100
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isActive
                                              ? Colors.green.shade800
                                              : Colors.grey.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============ BRANCHES TAB ============
class _BranchesTab extends StatefulWidget {
  const _BranchesTab();

  @override
  State<_BranchesTab> createState() => _BranchesTabState();
}

class _BranchesTabState extends State<_BranchesTab> {
  BranchController? _branchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize controller safely
    try {
      if (Get.isRegistered<BranchController>()) {
        _branchController = Get.find<BranchController>();
      } else {
        _branchController = Get.put(BranchController());
      }
    } catch (e) {
      print('_BranchesTab: Error getting BranchController: $e');
    }

    // Defer loading to avoid build conflicts
    // Only load if branches are empty and not already loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _branchController != null &&
          _branchController!.branches.isEmpty &&
          !_branchController!.isLoading.value) {
        // Use Future.microtask to ensure this runs after the current frame
        Future.microtask(() {
          if (mounted && _branchController != null) {
            _branchController!.loadBranches();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_branchController == null) {
      return ShimmerWidgets.shimmerDashboard(context);
    }

    return Obx(() {
      if (_branchController!.isLoading.value) {
        return ShimmerWidgets.shimmerDashboard(context);
      }

      final filtered = _getFilteredBranches();

      return RefreshIndicator(
        onRefresh: () async {
          if (_branchController != null) {
            await _branchController!.loadBranches();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Search bar
            Card(
              elevation: 1,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search branches by name, code, or address...',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.grey.shade600,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? theme.colorScheme.outline
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark
                            ? theme.colorScheme.outline
                            : Colors.grey.shade300,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey.shade50,
                    hintStyle: TextStyle(
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.grey.shade600,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Statistics cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    theme: theme,
                    title: 'Total',
                    value: _branchController!.totalBranches.toString(),
                    icon: Icons.store_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    theme: theme,
                    title: 'Active',
                    value: _branchController!.activeBranches.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    theme: theme,
                    title: 'Inactive',
                    value: _branchController!.inactiveBranches.toString(),
                    icon: Icons.cancel_outlined,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Branches list or empty state
            if (filtered.isEmpty)
              _buildEmptyState(context, theme, _searchQuery.isNotEmpty)
            else
              _buildBranchesGrid(context, theme, filtered),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ThemeData theme,
    bool isSearch,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'No branches found' : 'No branches yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearch
                  ? 'Try adjusting your search'
                  : 'Get started by adding your first branch',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (!isSearch) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.branchCreate),
                icon: const Icon(Icons.add_business),
                label: const Text('Add Branch'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBranchesGrid(
    BuildContext context,
    ThemeData theme,
    List<Map<String, dynamic>> branches,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 2.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: branches.length,
      itemBuilder: (context, index) {
        final branch = branches[index];
        final isActive = branch['is_active'] == true;
        final isMain = branch['is_main'] == true;

        return InkWell(
          onTap: () => Get.toNamed(AppRoutes.branchDetails, arguments: branch),
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with name and icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.store, size: 20, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          branch['name'] ?? 'Unknown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Status badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Active/Inactive badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.cancel,
                              size: 12,
                              color: isActive ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isActive ? 'Active' : 'Inactive',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.green : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Main branch badge
                      if (isMain)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Main Branch',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      // Code badge
                      if (branch['code'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            branch['code'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Address and phone
                  if (branch['address'] != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branch['address'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (branch['phone'] != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            branch['phone'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredBranches() {
    if (_branchController == null) return [];
    final all = _branchController!.branches;
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return all;

    return all.where((branch) {
      final name = (branch['name'] ?? '').toString().toLowerCase();
      final code = (branch['code'] ?? '').toString().toLowerCase();
      final address = (branch['address'] ?? '').toString().toLowerCase();

      return name.contains(query) ||
          code.contains(query) ||
          address.contains(query);
    }).toList();
  }
}

// ============ REPORTS TAB ============
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Reports', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),

          // Summary Cards
          Obx(
            () => GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildReportCard(
                  context,
                  'Monthly Revenue',
                  dc.formatCurrency(dc.totalSales.value),
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildReportCard(
                  context,
                  'Total Bills',
                  '${dc.salesCount.value}',
                  Icons.receipt_long,
                  Colors.blue,
                ),
                _buildReportCard(
                  context,
                  'Profit',
                  dc.formatCurrency(dc.totalProfit.value),
                  Icons.calculate,
                  Colors.purple,
                ),
                _buildReportCard(
                  context,
                  'Branches',
                  '${dc.branchCount.value}',
                  Icons.store,
                  Colors.orange,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Report Options
          Text('Generate Reports', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildReportOption(
            context,
            'Sales Report',
            'View detailed sales analytics',
            Icons.bar_chart,
            () => Get.snackbar('Coming Soon', 'Sales report'),
          ),
          _buildReportOption(
            context,
            'Stock Report',
            'View inventory status',
            Icons.inventory_2,
            () => Get.snackbar('Coming Soon', 'Stock report'),
          ),
          _buildReportOption(
            context,
            'GST Report',
            'View GST collections',
            Icons.account_balance,
            () => Get.snackbar('Coming Soon', 'GST report'),
          ),
          _buildReportOption(
            context,
            'Profit/Loss Report',
            'View business performance',
            Icons.trending_up,
            () => Get.snackbar('Coming Soon', 'P&L report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(title, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

// ============ SETTINGS TAB ============
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Team Section
        Text('Team & Management', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Obx(
          () => _buildMenuCard(
            context,
            'Users',
            '${dc.userCount.value} Users',
            Icons.people,
            Colors.blue,
            () => Get.toNamed(AppRoutes.usersList),
          ),
        ),
        _buildMenuCard(
          context,
          'Customers',
          'Manage customers',
          Icons.person_outline,
          Colors.teal,
          () => Get.toNamed(AppRoutes.customersList),
        ),
        const SizedBox(height: 24),

        // Catalogue Section
        Text('Catalogue', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          'Products',
          'Manage products',
          Icons.shopping_bag,
          Colors.purple,
          () => Get.toNamed(AppRoutes.productsList),
        ),
        _buildMenuCard(
          context,
          'Categories',
          'Product categories',
          Icons.category,
          Colors.indigo,
          () => Get.toNamed(AppRoutes.categoriesList),
        ),
        _buildMenuCard(
          context,
          'Brands',
          'Product brands',
          Icons.branding_watermark,
          Colors.orange,
          () => Get.toNamed(AppRoutes.brandsList),
        ),
        const SizedBox(height: 24),

        // Operations Section
        Text('Operations', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          'Stock',
          'View current stock',
          Icons.inventory_2,
          Colors.cyan,
          () => Get.toNamed(AppRoutes.stockList),
        ),
        _buildMenuCard(
          context,
          'Expenses',
          'Track expenses',
          Icons.money_off,
          Colors.red,
          () => Get.toNamed(AppRoutes.expensesList),
        ),
        _buildMenuCard(
          context,
          'Purchases',
          'Manage purchases',
          Icons.shopping_cart,
          Colors.green,
          () => Get.toNamed(AppRoutes.purchasesList),
        ),
        _buildMenuCard(
          context,
          'Bills',
          'View all bills',
          Icons.receipt_long,
          Colors.deepPurple,
          () => Get.toNamed(AppRoutes.billsList),
        ),
        const SizedBox(height: 24),

        // Settings Section
        Text('Settings', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildSettingsCard(
          context,
          'Profile Settings',
          'Manage your profile',
          Icons.person_outline,
          () => Get.toNamed(AppRoutes.profileEdit),
        ),
        _buildSettingsCard(
          context,
          'App Settings',
          'Configure app',
          Icons.settings_outlined,
          () => Get.toNamed(AppRoutes.settings),
        ),
        _buildSettingsCard(
          context,
          'Business Settings',
          'Configure business',
          Icons.business_outlined,
          () => Get.snackbar('Business', 'Coming soon'),
        ),
        _buildSettingsCard(
          context,
          'Notifications',
          'Configure alerts',
          Icons.notifications_outlined,
          () => Get.snackbar('Notifications', 'Coming soon'),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () => Get.find<AuthController>().signOut(),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
