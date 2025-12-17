import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';

class ProductsListScreen extends StatelessWidget {
  const ProductsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productController = Get.put(ProductController());
    final stockController = Get.put(StockController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context, productController);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context, productController);
            },
          ),
        ],
      ),
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (productController.filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text('No products found', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Products will appear here',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => productController.loadProducts(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: productController.filteredProducts.length,
            itemBuilder: (context, index) {
              final product = productController.filteredProducts[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.primaryColor,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (product.category != null)
                        Text(
                          product.category!.name,
                          style: theme.textTheme.bodySmall,
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '₹${product.sellingPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${product.unit}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if (product.gstRate > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'GST ${product.gstRate}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Show stock quantity
                      FutureBuilder<int>(
                        future: stockController.getProductStockQuantity(
                          product.id,
                        ),
                        builder: (context, snapshot) {
                          final stock = snapshot.data ?? 0;
                          final isLowStock = stock <= product.minStock;

                          return Row(
                            children: [
                              Icon(
                                Icons.inventory_outlined,
                                size: 14,
                                color: isLowStock ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: $stock ${product.unit}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isLowStock ? Colors.red : null,
                                  fontWeight: isLowStock
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                              if (isLowStock) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Low Stock',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'stock',
                        child: Row(
                          children: [
                            Icon(Icons.inventory_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Manage Stock'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'view') {
                        _showProductDetails(context, product);
                      } else if (value == 'stock') {
                        Get.toNamed('/branch/stock', arguments: product.id);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add product screen
          Get.snackbar(
            'Coming Soon',
            'Add product feature will be available soon',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  void _showSearchDialog(BuildContext context, ProductController controller) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Products'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter product name or SKU',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            controller.searchProducts(value);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.searchProducts(searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context, ProductController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('By Category'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show category selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.branding_watermark_outlined),
              title: const Text('By Brand'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show brand selection
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear Filters'),
              onTap: () {
                controller.clearFilters();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetails(BuildContext context, product) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(product.name, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              _buildDetailRow('SKU', product.sku ?? 'N/A'),
              _buildDetailRow('Unit', product.unit),
              _buildDetailRow('Selling Price', '₹${product.sellingPrice}'),
              _buildDetailRow(
                'Purchase Price',
                '₹${product.purchasePrice ?? 0}',
              ),
              _buildDetailRow('GST Rate', '${product.gstRate}%'),
              _buildDetailRow('Min Stock', '${product.minStock}'),
              if (product.category != null)
                _buildDetailRow('Category', product.category!.name),
              if (product.brand != null)
                _buildDetailRow('Brand', product.brand!.name),
              if (product.description != null &&
                  product.description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(product.description!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
