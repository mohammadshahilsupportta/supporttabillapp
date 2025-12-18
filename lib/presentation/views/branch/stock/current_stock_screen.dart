import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/stock_controller.dart';

class CurrentStockScreen extends StatelessWidget {
  const CurrentStockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(StockController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadCurrentStock(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stock Statistics
          Obx(() {
            final totalProducts = controller.currentStock.length;
            final lowStockCount = controller.currentStock
                .where((stock) => stock.quantity < 10)
                .length;

            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Products',
                      totalProducts.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Low Stock',
                      lowStockCount.toString(),
                      Icons.warning,
                      Colors.red,
                      theme,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Stock List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.currentStock.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_outlined,
                        size: 64,
                        color: theme.primaryColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stock available',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add products to see stock levels',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadCurrentStock(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.currentStock.length,
                  itemBuilder: (context, index) {
                    final stock = controller.currentStock[index];
                    final product = stock.product;
                    final minStock = product?.minStock ?? 0;
                    final isLowStock = stock.quantity > 0 && minStock > 0 && stock.quantity <= minStock;
                    final isSoldOut = stock.quantity == 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSoldOut
                                ? Colors.grey.withValues(alpha: 0.1)
                                : isLowStock
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: isSoldOut
                                ? Colors.grey
                                : isLowStock
                                    ? Colors.red
                                    : Colors.green,
                          ),
                        ),
                        title: Text(
                          product?.name ?? 'Product ID: ${stock.productId}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product != null) ...[
                              if (product.sku != null)
                                Text(
                                  'SKU: ${product.sku}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              Text(
                                'Unit: ${product.unit}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Updated: ${stock.updatedAt.toString().split(' ')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            if (isSoldOut)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Sold Out',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            else if (isLowStock)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Low Stock Alert!',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${stock.quantity}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isSoldOut
                                    ? Colors.grey
                                    : isLowStock
                                        ? Colors.red
                                        : Colors.green,
                              ),
                            ),
                            Text(
                              isSoldOut ? 'sold out' : 'in stock',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () {
                          _showStockActions(context, stock, controller);
                        },
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showStockActionMenu(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Stock Action'),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStockActions(
    BuildContext context,
    dynamic stock,
    StockController controller,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stock.product?.name ?? 'Product: ${stock.productId}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Stock In'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  AppRoutes.stockIn,
                  arguments: {'product_id': stock.productId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Stock Out'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  AppRoutes.stockOut,
                  arguments: {'product_id': stock.productId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: Colors.orange),
              title: const Text('Adjust Stock'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  AppRoutes.stockAdjust,
                  arguments: {'product_id': stock.productId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.purple),
              title: const Text('Transfer Stock'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(
                  AppRoutes.stockTransfer,
                  arguments: {'product_id': stock.productId},
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('View Ledger'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.stockLedger);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStockActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Stock Actions',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Stock In'),
              subtitle: const Text('Add stock to inventory'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.stockIn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Stock Out'),
              subtitle: const Text('Remove stock from inventory'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.stockOut);
              },
            ),
            ListTile(
              leading: const Icon(Icons.tune, color: Colors.orange),
              title: const Text('Adjust Stock'),
              subtitle: const Text('Correct stock discrepancies'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.stockAdjust);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.purple),
              title: const Text('Stock Transfer'),
              subtitle: const Text('Transfer between branches'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed(AppRoutes.stockTransfer);
              },
            ),
          ],
        ),
      ),
    );
  }
}

