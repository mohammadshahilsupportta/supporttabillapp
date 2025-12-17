import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';

class ProductsListScreen extends StatefulWidget {
  const ProductsListScreen({super.key});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> {
  final productController = Get.put(ProductController());
  final stockController = Get.put(StockController());

  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedBrandId;
  String _statusFilter = 'all'; // all | active | inactive

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = _getFilteredProducts();

        if (filtered.isEmpty) {
          // If there are no products at all from backend, show the original empty state.
          if (productController.products.isEmpty) {
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
                  Text(
                    'No products found',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Products will appear here',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // There are products, but current search/filters returned zero.
          // Keep user on same screen with filters and a simple message.
          return RefreshIndicator(
            onRefresh: () => productController.loadProducts(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilterBar(context, theme),
                const SizedBox(height: 24),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 60,
                        color: Colors.grey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No products match your search or filters',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => productController.loadProducts(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildFilterBar(context, theme);
              }
              final product = filtered[index - 1];

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
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.isActive ? 'Active' : 'Inactive',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: product.isActive
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      // SKU + Category / Brand row
                      Row(
                        children: [
                          if (product.sku != null &&
                              (product.sku ?? '').isNotEmpty) ...[
                            Icon(
                              Icons.qr_code_2,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                product.sku!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (product.category != null ||
                              product.brand != null) ...[
                            if (product.sku != null &&
                                (product.sku ?? '').isNotEmpty)
                              const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                [
                                  if (product.category != null)
                                    product.category!.name,
                                  if (product.brand != null)
                                    product.brand!.name,
                                ].join(' • '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
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
                          final isLowStock =
                              product.minStock > 0 && stock <= product.minStock;
                          final isSoldOut = stock == 0;

                          return Row(
                            children: [
                              Icon(
                                isSoldOut
                                    ? Icons.report_gmailerrorred_outlined
                                    : Icons.inventory_outlined,
                                size: 14,
                                color: isSoldOut
                                    ? Colors.red
                                    : isLowStock
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stock: $stock ${product.unit}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isSoldOut
                                      ? Colors.red
                                      : isLowStock
                                      ? Colors.orange
                                      : null,
                                  fontWeight: (isLowStock || isSoldOut)
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                              if (isLowStock && !isSoldOut) ...[
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
                                    'Low Stock',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                              if (isSoldOut) ...[
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
                                    'Sold Out',
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
          Get.toNamed(AppRoutes.createProduct);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  /// Apply search + category/brand/status filters to controller.products.
  List<dynamic> _getFilteredProducts() {
    final all = productController.products;
    final query = _searchQuery.trim().toLowerCase();

    return all.where((p) {
      // Search filter (name, sku, description)
      if (query.isNotEmpty) {
        final inName = p.name.toLowerCase().contains(query);
        final inSku = (p.sku ?? '').toLowerCase().contains(query);
        final inDesc = (p.description ?? '').toLowerCase().contains(query);
        if (!inName && !inSku && !inDesc) return false;
      }

      // Category filter
      if (_selectedCategoryId != null &&
          _selectedCategoryId!.isNotEmpty &&
          p.categoryId != _selectedCategoryId) {
        return false;
      }

      // Brand filter
      if (_selectedBrandId != null &&
          _selectedBrandId!.isNotEmpty &&
          p.brandId != _selectedBrandId) {
        return false;
      }

      // Status filter
      if (_statusFilter == 'active' && !p.isActive) return false;
      if (_statusFilter == 'inactive' && p.isActive) return false;

      return true;
    }).toList();
  }

  /// Build the always-visible search + filter bar at the top, matching website UX.
  Widget _buildFilterBar(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field (backend search)
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search products by name, SKU or description...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            productController.searchProducts(value);
          },
        ),
        const SizedBox(height: 12),

        // Category filter
        Obx(
          () => DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Categories'),
              ),
              ...productController.categories
                  .where((c) => c.isActive)
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(c.name),
                    ),
                  ),
            ],
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Brand filter
        Obx(
          () => DropdownButtonFormField<String>(
            value: _selectedBrandId,
            decoration: const InputDecoration(
              labelText: 'Brand',
              prefixIcon: Icon(Icons.branding_watermark_outlined),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('All Brands'),
              ),
              ...productController.brands
                  .where((b) => b.isActive)
                  .map(
                    (b) => DropdownMenuItem<String>(
                      value: b.id,
                      child: Text(b.name),
                    ),
                  ),
            ],
            onChanged: (value) {
              setState(() => _selectedBrandId = value);
            },
          ),
        ),
        const SizedBox(height: 8),

        // Status filter
        DropdownButtonFormField<String>(
          value: _statusFilter,
          decoration: const InputDecoration(
            labelText: 'Status',
            prefixIcon: Icon(Icons.toggle_on_outlined),
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All')),
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _statusFilter = value);
            }
          },
        ),
        const SizedBox(height: 16),
      ],
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
