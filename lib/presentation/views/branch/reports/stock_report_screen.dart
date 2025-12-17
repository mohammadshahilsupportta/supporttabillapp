import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/stock_controller.dart';

class StockReportScreen extends StatelessWidget {
  const StockReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sc = Get.find<StockController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Report'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => sc.loadCurrentStock(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => Get.snackbar('Coming Soon', 'Export feature'),
          ),
        ],
      ),
      body: Obx(() {
        if (sc.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final stocks = sc.currentStock;

        // Calculate statistics
        int totalProducts = stocks.length;
        int inStock = 0;
        int lowStock = 0;
        int outOfStock = 0;

        for (var stock in stocks) {
          final qty = stock.quantity;
          // Use a default min stock value since we don't have product info here
          const minStockDefault = 5;

          if (qty == 0) {
            outOfStock++;
          } else if (qty <= minStockDefault) {
            lowStock++;
          } else {
            inStock++;
          }
        }

        return RefreshIndicator(
          onRefresh: () => sc.loadCurrentStock(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Products',
                      '$totalProducts',
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Items',
                      stocks
                          .fold<int>(0, (sum, s) => sum + s.quantity)
                          .toString(),
                      Icons.numbers,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'In Stock',
                      '$inStock',
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Low Stock',
                      '$lowStock',
                      Icons.warning,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryCard(
                      'Out of Stock',
                      '$outOfStock',
                      Icons.error,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stock Status Distribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Status Distribution',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildProgressBar(
                        'In Stock',
                        inStock,
                        totalProducts,
                        Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildProgressBar(
                        'Low Stock',
                        lowStock,
                        totalProducts,
                        Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      _buildProgressBar(
                        'Out of Stock',
                        outOfStock,
                        totalProducts,
                        Colors.red,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (lowStock > 0 || outOfStock > 0)
                Card(
                  color: theme.brightness == Brightness.dark
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.warning,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Stock Alerts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stocks
                              .where((s) => s.quantity <= 5)
                              .take(5)
                              .length,
                          itemBuilder: (context, index) {
                            final alertStocks = stocks
                                .where((s) => s.quantity <= 5)
                                .toList();
                            if (index >= alertStocks.length)
                              return const SizedBox.shrink();
                            final stock = alertStocks[index];
                            final isOutOfStock = stock.quantity == 0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isOutOfStock
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.orange.withValues(alpha: 0.1),
                                child: Icon(
                                  isOutOfStock ? Icons.error : Icons.warning,
                                  color: isOutOfStock
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                              title: Text(
                                'Product #${stock.productId.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                isOutOfStock
                                    ? 'Out of stock'
                                    : 'Low stock alert',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isOutOfStock
                                      ? Colors.red
                                      : Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${stock.quantity}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (lowStock + outOfStock > 5)
                          TextButton(
                            onPressed: () => Get.toNamed('/branch/stock'),
                            child: const Text('View All'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Stock List
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'All Stock Items',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.toNamed('/branch/stock'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (stocks.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2,
                                  size: 48,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No stock items found',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stocks.take(10).length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final stock = stocks[index];
                            final isLow = stock.quantity <= 5;
                            final isOut = stock.quantity == 0;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Product #${stock.productId.substring(0, 8)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Branch: ${stock.branchId.substring(0, 8)}',
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isOut
                                      ? Colors.red.withValues(alpha: 0.1)
                                      : isLow
                                      ? Colors.orange.withValues(alpha: 0.1)
                                      : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${stock.quantity}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isOut
                                        ? Colors.red
                                        : isLow
                                        ? Colors.orange
                                        : Colors.green,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? value / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('$value (${(percentage * 100).toStringAsFixed(0)}%)'),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
