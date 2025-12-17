import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/dashboard_controller.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const _BranchesTab(),
    const _ReportsTab(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () =>
                Get.snackbar('Notifications', 'No new notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthController>().signOut(),
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
      onTap: () => setState(() => _selectedIndex = index),
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
                  Icons.inventory_2,
                  'Stock',
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.stockList);
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
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== PERIOD SELECTOR ==========
            Obx(
              () => Container(
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
              ),
            ),
            const SizedBox(height: 16),

            // ========== LOADING INDICATOR ==========
            Obx(() {
              if (dc.isLoading.value) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),

            // ========== PRIMARY METRICS - Sales & Stock ==========
            Text('Sales & Stock', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Obx(
              () => GridView.count(
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
            ),
            const SizedBox(height: 24),

            // ========== SECONDARY METRICS ==========
            Text(
              'Stock Status & Financials',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Obx(
              () => GridView.count(
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
                    dc.lowStockCount.value > 0 ? Colors.yellow.shade50 : null,
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
            ),
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
}

// ============ BRANCHES TAB ============
class _BranchesTab extends StatelessWidget {
  const _BranchesTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();

    return Obx(() {
      if (dc.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (dc.branches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.store_outlined,
                size: 80,
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text('No Branches', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text('Add branches to manage your business'),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () =>
                    Get.snackbar('Coming Soon', 'Add branch feature'),
                icon: const Icon(Icons.add),
                label: const Text('Add Branch'),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => dc.refreshStats(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: dc.branches.length,
          itemBuilder: (context, index) {
            final branch = dc.branches[index];
            final branchSale = dc.branchWiseSales.firstWhere(
              (s) => s['branch_id'] == branch['id'],
              orElse: () => {'today_sales': 0.0},
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.store, color: theme.primaryColor),
                ),
                title: Row(
                  children: [
                    Text(
                      branch['name'] ?? 'Branch',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                subtitle: Text(branch['address'] ?? 'No address'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dc.formatCurrency(
                        (branchSale['today_sales'] as num?)?.toDouble() ?? 0,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text('Today', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
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
