import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/dashboard_controller.dart';

class BranchDashboardScreen extends StatefulWidget {
  const BranchDashboardScreen({super.key});

  @override
  State<BranchDashboardScreen> createState() => _BranchDashboardScreenState();
}

class _BranchDashboardScreenState extends State<BranchDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const _BillingTab(),
    const _StockTab(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle()), elevation: 0),
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsSheet(context),
        backgroundColor: Colors.green,
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
            _buildNavItem(1, Icons.receipt_outlined, Icons.receipt, 'Bills'),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              2,
              Icons.inventory_2_outlined,
              Icons.inventory_2,
              'Stock',
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
                  'Order',
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.billsList);
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.person,
                  'Customers',
                  Colors.orange,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.customersList);
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
        return 'Dashboard';
      case 1:
        return 'Bills';
      case 2:
        return 'Stock';
      case 3:
        return 'Settings';
      default:
        return 'Branch Dashboard';
    }
  }
}

// ============ DASHBOARD TAB ============
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    final dc = Get.find<DashboardController>();

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Obx(
              () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.primaryColor.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          authController.currentUser.value?.fullName[0] ?? 'U',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authController.currentUser.value?.fullName ??
                                  'User',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                authController.currentUser.value?.role.value
                                        .replaceAll('_', ' ')
                                        .toUpperCase() ??
                                    '',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Period Selector
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

            // Stats Grid
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
                    'Total Sales',
                    dc.formatCurrency(dc.totalSales.value),
                    '${dc.salesCount.value} bills',
                    Icons.currency_rupee,
                    const Color(0xFF10B981), // Secondary green
                  ),
                  _buildStatCard(
                    context,
                    'Stock Value',
                    dc.formatCurrency(dc.stockValue.value),
                    '${dc.productsWithStock.value} products',
                    Icons.inventory_2,
                    const Color(0xFF2563EB), // Primary blue
                  ),
                  _buildStatCard(
                    context,
                    'Profit',
                    dc.formatCurrency(dc.totalProfit.value),
                    '${dc.profitMargin.value.toStringAsFixed(1)}% margin',
                    Icons.trending_up,
                    dc.totalProfit.value >= 0
                        ? const Color(0xFF0891B2)
                        : const Color(0xFFEF4444), // Cyan or Red
                  ),
                  _buildStatCard(
                    context,
                    'Products',
                    '${dc.totalProducts.value}',
                    '${dc.inStockCount.value} in stock',
                    Icons.category,
                    const Color(0xFF8B5CF6), // Violet
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Secondary Stats
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildSmallStatCard(
                      context,
                      'Low Stock',
                      '${dc.lowStockCount.value}',
                      Icons.warning_amber,
                      dc.lowStockCount.value > 0 ? Colors.orange : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallStatCard(
                      context,
                      'Sold Out',
                      '${dc.soldOutCount.value}',
                      Icons.remove_circle_outline,
                      dc.soldOutCount.value > 0 ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSmallStatCard(
                      context,
                      'Expenses',
                      dc.formatCurrency(dc.totalExpenses.value),
                      Icons.arrow_downward,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Quick Actions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  context,
                  'Order',
                  Icons.shopping_cart,
                  Colors.green,
                  () => Get.toNamed(AppRoutes.billsList),
                ),
                _buildActionCard(
                  context,
                  'Customers',
                  Icons.person,
                  Colors.orange,
                  () => Get.toNamed(AppRoutes.customersList),
                ),
                _buildActionCard(
                  context,
                  'Products',
                  Icons.shopping_bag,
                  Colors.purple,
                  () => Get.toNamed(AppRoutes.productsList),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Bills
            Obx(() {
              if (dc.recentBills.isEmpty) return const SizedBox.shrink();
              return _buildRecentBillsSection(context, dc);
            }),

            // Low Stock Alert
            Obx(() {
              if (dc.lowStockProducts.isEmpty) return const SizedBox.shrink();
              return _buildLowStockSection(context, dc);
            }),
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
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
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
        ...dc.recentBills.take(3).map((bill) {
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

  Widget _buildLowStockSection(BuildContext context, DashboardController dc) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Low Stock Alert', style: theme.textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 8),
        ...dc.lowStockProducts.take(3).map((product) {
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
              subtitle: Text('Min: ${product['min_stock']}'),
              trailing: Text(
                '${product['current_quantity']} left',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSoldOut ? Colors.red : Colors.orange,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ============ BILLING TAB ============
class _BillingTab extends StatelessWidget {
  const _BillingTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
      child: Obx(() {
        if (dc.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (dc.recentBills.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_outlined,
                  size: 80,
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 24),
                Text('No Bills Yet', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 12),
                const Text('Create your first bill'),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.posBilling),
                  icon: const Icon(Icons.add),
                  label: const Text('New Bill'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: dc.recentBills.length,
          itemBuilder: (context, index) {
            final bill = dc.recentBills[index];
            final createdAt = DateTime.tryParse(bill['created_at'] ?? '');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.green),
                ),
                title: Text(
                  bill['invoice_number'] ?? 'INV-XXX',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  createdAt != null ? dateFormat.format(createdAt) : '-',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dc.formatCurrencyExact(
                        (bill['total_amount'] as num?)?.toDouble() ?? 0,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      bill['payment_mode'] ?? 'Cash',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                onTap: () => Get.snackbar('Bill', 'Bill details coming soon'),
              ),
            );
          },
        );
      }),
    );
  }
}

// ============ STOCK TAB ============
class _StockTab extends StatelessWidget {
  const _StockTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stock Summary
            Obx(
              () => GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCard(
                    context,
                    'Stock Value',
                    dc.formatCurrency(dc.stockValue.value),
                    Icons.inventory_2,
                    Colors.blue,
                  ),
                  _buildCard(
                    context,
                    'Products',
                    '${dc.totalProducts.value}',
                    Icons.category,
                    Colors.indigo,
                  ),
                  _buildCard(
                    context,
                    'Low Stock',
                    '${dc.lowStockCount.value}',
                    Icons.warning_amber,
                    Colors.orange,
                  ),
                  _buildCard(
                    context,
                    'Sold Out',
                    '${dc.soldOutCount.value}',
                    Icons.remove_circle_outline,
                    Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Text('Stock Actions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.stockIn),
                    icon: const Icon(Icons.add),
                    label: const Text('Stock In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.stockList),
                    icon: const Icon(Icons.list),
                    label: const Text('View All'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Low Stock Products
            Obx(() {
              if (dc.lowStockProducts.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 48,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(height: 12),
                        const Text('All products are well stocked!'),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Needs Attention', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...dc.lowStockProducts.map((product) {
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
                        subtitle: Text(
                          'Min: ${product['min_stock']} ${product['unit']}',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${product['current_quantity']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
              child: Icon(icon, color: color),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Operations Section
        Text('Operations', style: theme.textTheme.titleLarge),
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
          Colors.blue,
          () => Get.toNamed(AppRoutes.purchasesList),
        ),
        _buildMenuCard(
          context,
          'Stock Ledger',
          'View stock history',
          Icons.history,
          Colors.teal,
          () => Get.toNamed(AppRoutes.stockLedger),
        ),
        const SizedBox(height: 24),

        // Reports Section
        Text('Reports', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildMenuCard(
          context,
          'Sales Report',
          'View sales analytics',
          Icons.trending_up,
          Colors.green,
          () => Get.toNamed(AppRoutes.salesReport),
        ),
        _buildMenuCard(
          context,
          'Stock Report',
          'View stock analytics',
          Icons.inventory,
          Colors.orange,
          () => Get.toNamed(AppRoutes.stockReport),
        ),
        const SizedBox(height: 24),

        // Settings Section
        Text('Settings', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        _buildSettingsCard(
          context,
          'Profile',
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
          'Printer',
          'Configure printer',
          Icons.print_outlined,
          () => Get.snackbar('Printer', 'Coming soon'),
        ),
        _buildSettingsCard(
          context,
          'Help',
          'Get support',
          Icons.help_outline,
          () => Get.snackbar('Help', 'Coming soon'),
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
