import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/branch_store_controller.dart';
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
  void initState() {
    super.initState();
    // Load stock for the appropriate branch
    _loadStockForCurrentBranch();
    
    // Listen to branch changes for tenant owners
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    if (user?.role.value == 'tenant_owner') {
      try {
        if (Get.isRegistered<BranchStoreController>()) {
          final branchStore = Get.find<BranchStoreController>();
          // Reload stock when branch changes
          ever(branchStore.selectedBranchId, (branchId) {
            if (branchId != null) {
              _loadStockForCurrentBranch();
            }
          });
        }
      } catch (_) {
        // BranchStoreController not available
      }
    }
  }

  Future<void> _loadStockForCurrentBranch() async {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    
    String? branchId;
    if (user?.role.value == 'tenant_owner') {
      // For tenant owners, use selected branch
      try {
        if (Get.isRegistered<BranchStoreController>()) {
          final branchStore = Get.find<BranchStoreController>();
          branchId = branchStore.selectedBranchId.value;
        }
      } catch (_) {
        // BranchStoreController not available
      }
    } else {
      // For branch users, use their branch
      branchId = authController.branchId;
    }
    
    await stockController.loadCurrentStock(branchId: branchId);
  }

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
            onRefresh: () async {
              await productController.loadProducts();
              await _loadStockForCurrentBranch();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildFilterBar(context, theme),
                const SizedBox(height: 12),
                _buildStatisticsCards(context, theme),
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
          onRefresh: () async {
            await productController.loadProducts();
            await stockController.loadCurrentStock();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildFilterBar(context, theme),
                    const SizedBox(height: 12),
                    _buildStatisticsCards(context, theme),
                    const SizedBox(height: 12),
                  ],
                );
              }

              final product = filtered[index - 1];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with product name and active/inactive switch
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product icon
                          Container(
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
                          const SizedBox(width: 12),
                          // Product name
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
                          // Active/Inactive Toggle Switch at top right
                          FutureBuilder<int>(
                            future: _getProductStockQuantity(product.id),
                            builder: (context, stockSnapshot) {
                              final stock = stockSnapshot.data ?? 0;
                              final canActivate = stock > 0 || product.isActive;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: product.isActive,
                                    onChanged: canActivate
                                        ? (bool newValue) async {
                                            await productController
                                                .toggleProductActive(
                                                  product.id,
                                                  newValue,
                                                  currentStock: stock,
                                                );
                                          }
                                        : null,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    product.isActive ? 'Active' : 'Inactive',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: product.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Product details
                      Column(
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
                            future: _getProductStockQuantity(product.id),
                            builder: (context, snapshot) {
                              final stock = snapshot.data ?? 0;
                              final isLowStock =
                                  product.minStock > 0 &&
                                  stock <= product.minStock;
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
                                        color: Colors.orange.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Low Stock',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                                        color: Colors.red.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Sold Out',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
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
                          // Actions row
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.visibility_outlined,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text('View Details'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'stock',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.inventory_outlined,
                                          size: 20,
                                        ),
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
                                    Get.toNamed(
                                      '/branch/stock',
                                      arguments: product.id,
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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

  /// Get stock quantity for a product (handles tenant owners with selected branch)
  Future<int> _getProductStockQuantity(String productId) async {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    
    String? branchId;
    if (user?.role.value == 'tenant_owner') {
      // For tenant owners, use selected branch
      try {
        if (Get.isRegistered<BranchStoreController>()) {
          final branchStore = Get.find<BranchStoreController>();
          branchId = branchStore.selectedBranchId.value;
        }
      } catch (_) {
        // BranchStoreController not available
      }
    } else {
      // For branch users, use their branch
      branchId = authController.branchId;
    }
    
    return await stockController.getProductStockQuantity(productId, branchId: branchId);
  }

  /// Calculate product statistics
  Map<String, int> _calculateStatistics() {
    final allProducts = productController.products;
    final stockMap = <String, int>{};

    // Get the appropriate branch ID for filtering stock
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    String? targetBranchId;
    
    if (user?.role.value == 'tenant_owner') {
      try {
        if (Get.isRegistered<BranchStoreController>()) {
          final branchStore = Get.find<BranchStoreController>();
          targetBranchId = branchStore.selectedBranchId.value;
        }
      } catch (_) {
        // BranchStoreController not available
      }
    } else {
      targetBranchId = authController.branchId;
    }

    // Create a map of productId -> quantity from current stock
    // Filter by branch if we have a target branch
    for (final stock in stockController.currentStock) {
      if (targetBranchId == null || stock.branchId == targetBranchId) {
        // For tenant owners, only count stock from selected branch
        // For branch users, only count their branch stock
        stockMap[stock.productId] = stock.quantity;
      }
    }

    int totalProducts = allProducts.length;
    int activeProducts = allProducts.where((p) => p.isActive).length;
    int lowStockProducts = 0;
    int soldOutProducts = 0;

    for (final product in allProducts) {
      final quantity = stockMap[product.id] ?? 0;

      if (quantity == 0) {
        soldOutProducts++;
      } else if (product.minStock > 0 && quantity <= product.minStock) {
        lowStockProducts++;
      }
    }

    return {
      'total': totalProducts,
      'active': activeProducts,
      'lowStock': lowStockProducts,
      'soldOut': soldOutProducts,
    };
  }

  /// Build compact statistics cards in horizontal scrollable row
  Widget _buildStatisticsCards(BuildContext context, ThemeData theme) {
    return Obx(() {
      final stats = _calculateStatistics();

      return SizedBox(
        height: 80,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            const SizedBox(width: 4),
            // Total Products
            _buildCompactStatCard(
              context: context,
              theme: theme,
              title: 'Total',
              value: stats['total']!.toString(),
              borderColor: Colors.blue,
              icon: Icons.inventory_2_outlined,
            ),
            const SizedBox(width: 8),
            // Active Products
            _buildCompactStatCard(
              context: context,
              theme: theme,
              title: 'Active',
              value: stats['active']!.toString(),
              borderColor: Colors.green,
              icon: Icons.check_circle_outline,
              valueColor: Colors.green,
            ),
            const SizedBox(width: 8),
            // Low Stock
            _buildCompactStatCard(
              context: context,
              theme: theme,
              title: 'Low Stock',
              value: stats['lowStock']!.toString(),
              borderColor: stats['lowStock']! > 0
                  ? Colors.orange
                  : Colors.orange.shade300,
              icon: Icons.warning_amber_rounded,
              valueColor: Colors.orange,
              highlightBackground: stats['lowStock']! > 0,
            ),
            const SizedBox(width: 8),
            // Sold Out
            _buildCompactStatCard(
              context: context,
              theme: theme,
              title: 'Sold Out',
              value: stats['soldOut']!.toString(),
              borderColor: stats['soldOut']! > 0
                  ? Colors.red
                  : Colors.red.shade300,
              icon: Icons.cancel_outlined,
              valueColor: Colors.red,
              highlightBackground: stats['soldOut']! > 0,
            ),
            const SizedBox(width: 4),
          ],
        ),
      );
    });
  }

  /// Build compact horizontal statistic card
  Widget _buildCompactStatCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String value,
    required Color borderColor,
    required IconData icon,
    Color? valueColor,
    bool highlightBackground = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: highlightBackground
            ? borderColor.withValues(alpha: isDark ? 0.2 : 0.08)
            : isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor.withValues(alpha: isDark ? 0.7 : 0.5),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: borderColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.grey.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? theme.textTheme.titleLarge?.color,
                fontSize: 18,
                height: 1.1,
              ),
            ),
          ],
        ),
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

  /// Build compact search + filter bar in single row
  Widget _buildFilterBar(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Search field (backend search) - full width
            TextField(
              decoration: InputDecoration(
                hintText: 'Search products...',
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
                productController.searchProducts(value);
              },
            ),
            const SizedBox(height: 10),
            // Filters in single row
            Row(
              children: [
                // Category filter - compact
                Expanded(
                  child: Obx(
                    () => Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? theme.colorScheme.outline
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          isDense: true,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.grey.shade600,
                          ),
                          hint: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 14,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Category',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedCategoryId = value);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Brand filter - compact
                Expanded(
                  child: Obx(
                    () => Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? theme.colorScheme.outline
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHighest
                            : Colors.grey.shade50,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBrandId,
                          isDense: true,
                          isExpanded: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : Colors.grey.shade600,
                          ),
                          hint: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.branding_watermark_outlined,
                                size: 14,
                                color: isDark
                                    ? theme.colorScheme.onSurfaceVariant
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Brand',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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
                                    child: Text(
                                      b.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedBrandId = value);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Status filter - compact
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? theme.colorScheme.outline
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      color: isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey.shade50,
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _statusFilter,
                        isDense: true,
                        isExpanded: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          size: 18,
                          color: isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : Colors.grey.shade600,
                        ),
                        hint: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.toggle_on_outlined,
                              size: 14,
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Status',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Active'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Inactive'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _statusFilter = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
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
