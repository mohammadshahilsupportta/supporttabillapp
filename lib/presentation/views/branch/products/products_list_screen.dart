import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/product_model.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/branch_controller.dart';
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
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showProductDetails(context, product),
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
                                color: theme.primaryColor.withValues(
                                  alpha: 0.1,
                                ),
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
                                // Auto-inactive logic: If stock is 0, product should be inactive (for display)
                                final shouldBeInactive = stock == 0;
                                final effectiveIsActive = shouldBeInactive
                                    ? false
                                    : product.isActive;
                                // Can only activate if stock > 0
                                final canActivate = stock > 0;

                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: effectiveIsActive,
                                      onChanged: canActivate
                                          ? (bool newValue) async {
                                              // Prevent enabling if stock is 0
                                              if (newValue && stock == 0) {
                                                Get.snackbar(
                                                  'Error',
                                                  'Cannot activate product with zero stock. Please add stock first.',
                                                  snackPosition:
                                                      SnackPosition.BOTTOM,
                                                );
                                                return;
                                              }
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
                                      effectiveIsActive ? 'Active' : 'Inactive',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: effectiveIsActive
                                                ? Colors.green
                                                : Colors.grey,
                                          ),
                                    ),
                                    if (shouldBeInactive &&
                                        !product.isActive) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          'Auto',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.orange,
                                                fontSize: 9,
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
                                      color: Colors.orange.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'GST ${product.gstRate}%',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: isSoldOut
                                                ? Colors.red
                                                : isLowStock
                                                ? Colors.orange
                                                : null,
                                            fontWeight:
                                                (isLowStock || isSoldOut)
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                      _showManageStockSheet(context, product);
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

    return await stockController.getProductStockQuantity(
      productId,
      branchId: branchId,
    );
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
    int activeProducts = 0; // Count effective active (stock > 0)
    int lowStockProducts = 0;
    int soldOutProducts = 0;

    for (final product in allProducts) {
      final quantity = stockMap[product.id] ?? 0;
      // Auto-inactive logic: If stock is 0, product should be inactive (for display)
      final shouldBeInactive = quantity == 0;
      final effectiveIsActive = shouldBeInactive ? false : product.isActive;

      if (quantity == 0) {
        soldOutProducts++;
      } else if (product.minStock > 0 && quantity <= product.minStock) {
        lowStockProducts++;
      }

      // Count as active only if effectively active (stock > 0 and isActive)
      if (effectiveIsActive) {
        activeProducts++;
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

  /// Show manage stock dialog for a specific product (matching website design)
  void _showManageStockSheet(BuildContext context, dynamic product) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final TextEditingController adjustmentAmountController =
        TextEditingController(text: '1');
    int adjustedQuantity = 0;
    int currentQuantity = 0;
    bool isLoading = true;

    // Get branch info
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    String? branchId;
    Map<String, dynamic>? branchData;

    if (user?.role.value == 'tenant_owner') {
      try {
        if (Get.isRegistered<BranchStoreController>()) {
          final branchStore = Get.find<BranchStoreController>();
          branchId = branchStore.selectedBranchId.value;
        }
        if (Get.isRegistered<BranchController>()) {
          final branchController = Get.find<BranchController>();
          if (branchId != null) {
            branchData = branchController.branches.firstWhereOrNull(
              (b) => b['id'] == branchId,
            );
          }
        }
      } catch (_) {
        branchId = null;
      }
    } else {
      branchId = authController.branchId;
    }

    // Load current stock
    _getProductStockQuantity(product.id).then((stock) {
      currentQuantity = stock;
      adjustedQuantity = stock;
      isLoading = false;
    });

    bool isSaving = false;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Manage Stock',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Product Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (product.sku != null &&
                                    product.sku!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'SKU: ${product.sku}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                                if (product.stockTrackingType ==
                                    StockTrackingType.serial) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.tag,
                                        size: 12,
                                        color: Colors.purple.shade600,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Serial Number Tracking',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: Colors.purple.shade600,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Branch Section
                      if (branchId != null && branchData != null) ...[
                        Builder(
                          builder: (context) {
                            final branch = branchData!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Branch',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          branch['name'] ?? '',
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade900,
                                              ),
                                        ),
                                      ),
                                      if (branch['is_main'] == true) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.yellow.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Main',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.yellow.shade800,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ] else if (user?.role.value == 'tenant_owner')
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            border: Border.all(
                              color: Colors.yellow.shade200,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Please select a branch from the header to manage stock.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.yellow.shade800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      if (branchId != null &&
                          product.stockTrackingType ==
                              StockTrackingType.quantity) ...[
                        const SizedBox(height: 16),

                        // Adjust Stock Quantity Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Adjust Stock Quantity',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<int>(
                              future: _getProductStockQuantity(product.id),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  currentQuantity = snapshot.data ?? 0;
                                  if (adjustedQuantity == 0) {
                                    adjustedQuantity = currentQuantity;
                                  }
                                }

                                return Column(
                                  children: [
                                    // Quantity controls
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // Decrement Button
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isLoading
                                                ? null
                                                : () {
                                                    final decrementAmount =
                                                        int.tryParse(
                                                          adjustmentAmountController
                                                              .text,
                                                        ) ??
                                                        1;
                                                    setModalState(() {
                                                      adjustedQuantity =
                                                          (adjustedQuantity -
                                                                  decrementAmount)
                                                              .clamp(0, 999999);
                                                    });
                                                  },
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.grey.shade700
                                                      : Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: Icon(
                                                Icons.remove,
                                                size: 20,
                                                color: adjustedQuantity <= 0
                                                    ? Colors.grey.shade400
                                                    : theme
                                                          .colorScheme
                                                          .onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Quantity Display
                                        Column(
                                          children: [
                                            Text(
                                              adjustedQuantity.toString(),
                                              style: theme
                                                  .textTheme
                                                  .displaySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 32,
                                                  ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.unit,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                            if (adjustedQuantity !=
                                                currentQuantity) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                adjustedQuantity >
                                                        currentQuantity
                                                    ? '+${adjustedQuantity - currentQuantity} from $currentQuantity'
                                                    : '${adjustedQuantity - currentQuantity} from $currentQuantity',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          Colors.blue.shade600,
                                                      fontSize: 12,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(width: 16),

                                        // Increment Button
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isLoading
                                                ? null
                                                : () {
                                                    final incrementAmount =
                                                        int.tryParse(
                                                          adjustmentAmountController
                                                              .text,
                                                        ) ??
                                                        1;
                                                    setModalState(() {
                                                      adjustedQuantity =
                                                          adjustedQuantity +
                                                          incrementAmount;
                                                    });
                                                  },
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: isDark
                                                      ? Colors.grey.shade700
                                                      : Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(30),
                                              ),
                                              child: Icon(
                                                Icons.add,
                                                size: 20,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Adjustment Amount Input
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Adjustment Amount',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: Colors.grey.shade500,
                                                fontSize: 12,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller:
                                              adjustmentAmountController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 10,
                                                ),
                                            hintText: '1',
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Center(
                                          child: Text(
                                            'Amount to add/subtract per click',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 12,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child:
                                product.stockTrackingType ==
                                    StockTrackingType.quantity
                                ? FutureBuilder<int>(
                                    future: _getProductStockQuantity(
                                      product.id,
                                    ),
                                    builder: (context, snapshot) {
                                      final currentQty = snapshot.data ?? 0;
                                      final difference =
                                          adjustedQuantity - currentQty;

                                      return ElevatedButton(
                                        onPressed:
                                            (branchId == null ||
                                                difference == 0 ||
                                                adjustedQuantity < 0 ||
                                                isSaving)
                                            ? null
                                            : () async {
                                                if (branchId == null) {
                                                  Get.snackbar(
                                                    'Error',
                                                    'Please select a branch first',
                                                    snackPosition:
                                                        SnackPosition.BOTTOM,
                                                  );
                                                  return;
                                                }

                                                if (difference == 0) {
                                                  Get.snackbar(
                                                    'Info',
                                                    'No changes to save',
                                                    snackPosition:
                                                        SnackPosition.BOTTOM,
                                                  );
                                                  Navigator.of(ctx).pop();
                                                  return;
                                                }

                                                // Set loading state
                                                setModalState(() {
                                                  isSaving = true;
                                                });

                                                try {
                                                  final stockController =
                                                      Get.find<
                                                        StockController
                                                      >();

                                                  bool success = false;
                                                  if (difference > 0) {
                                                    // Stock In
                                                    success = await stockController
                                                        .addStockIn(
                                                          productId: product.id,
                                                          quantity: difference,
                                                          reason:
                                                              'Stock adjustment from products page',
                                                          branchId: branchId,
                                                        );
                                                  } else {
                                                    // Stock Out
                                                    if (adjustedQuantity < 0) {
                                                      setModalState(() {
                                                        isSaving = false;
                                                      });
                                                      Get.snackbar(
                                                        'Error',
                                                        'Stock cannot be negative',
                                                        snackPosition:
                                                            SnackPosition
                                                                .BOTTOM,
                                                      );
                                                      return;
                                                    }
                                                    success = await stockController
                                                        .addStockOut(
                                                          productId: product.id,
                                                          quantity: difference
                                                              .abs(),
                                                          reason:
                                                              'Stock adjustment from products page',
                                                          branchId: branchId,
                                                        );
                                                  }

                                                  if (success) {
                                                    // Refresh products + stock
                                                    await productController
                                                        .loadProducts();
                                                    await stockController
                                                        .loadCurrentStock(
                                                          branchId: branchId,
                                                        );
                                                    Navigator.of(ctx).pop();
                                                  } else {
                                                    // Reset loading state on error
                                                    setModalState(() {
                                                      isSaving = false;
                                                    });
                                                  }
                                                } catch (e) {
                                                  // Reset loading state on error
                                                  setModalState(() {
                                                    isSaving = false;
                                                  });
                                                }
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        child: isSaving
                                            ? SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text('Save'),
                                      );
                                    },
                                  )
                                : ElevatedButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: const Text('Done'),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showProductDetails(BuildContext context, dynamic product) {
    // Navigate to product details screen instead of showing bottom sheet
    Get.toNamed(
      AppRoutes.productDetails.replaceAll(':id', product.id),
      arguments: {'productId': product.id},
    );
  }

  // Removed: _showProductDetailsBottomSheet - now using full screen navigation
  void _showProductDetailsBottomSheet_UNUSED(
    BuildContext context,
    dynamic product,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : Colors.grey.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: theme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (product.sku != null && product.sku!.isNotEmpty)
                            Text(
                              'SKU: ${product.sku}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stock Information Card
                      FutureBuilder<int>(
                        future: _getProductStockQuantity(product.id),
                        builder: (context, snapshot) {
                          final stock = snapshot.data ?? 0;
                          final isLowStock =
                              product.minStock > 0 && stock <= product.minStock;
                          final isSoldOut = stock == 0;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSoldOut
                                    ? Colors.red.shade300
                                    : isLowStock
                                    ? Colors.orange.shade300
                                    : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.inventory_2_outlined,
                                        color: isSoldOut
                                            ? Colors.red
                                            : isLowStock
                                            ? Colors.orange
                                            : theme.primaryColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stock Information',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Stock',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$stock ${product.unit}',
                                            style: theme.textTheme.headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: isSoldOut
                                                      ? Colors.red
                                                      : isLowStock
                                                      ? Colors.orange
                                                      : theme.primaryColor,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Min Stock',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Colors.grey.shade600,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${product.minStock} ${product.unit}',
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (isLowStock || isSoldOut) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            (isSoldOut
                                                    ? Colors.red
                                                    : Colors.orange)
                                                .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSoldOut
                                                ? Icons.error_outline
                                                : Icons.warning_amber_rounded,
                                            color: isSoldOut
                                                ? Colors.red
                                                : Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              isSoldOut
                                                  ? 'Product is out of stock'
                                                  : 'Stock is below minimum threshold',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    color: isSoldOut
                                                        ? Colors.red
                                                        : Colors.orange,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Basic Information Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Basic Information',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                theme,
                                'Unit',
                                product.unit,
                                Icons.straighten,
                              ),
                              const Divider(height: 24),
                              if (product.category != null)
                                _buildDetailRow(
                                  theme,
                                  'Category',
                                  product.category!.name,
                                  Icons.category_outlined,
                                ),
                              if (product.category != null)
                                const Divider(height: 24),
                              if (product.brand != null)
                                _buildDetailRow(
                                  theme,
                                  'Brand',
                                  product.brand!.name,
                                  Icons.branding_watermark_outlined,
                                ),
                              if (product.brand != null)
                                const Divider(height: 24),
                              Row(
                                children: [
                                  Icon(
                                    Icons.toggle_on,
                                    color: product.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Status',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (product.isActive
                                                  ? Colors.green
                                                  : Colors.grey)
                                              .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      product.isActive ? 'Active' : 'Inactive',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: product.isActive
                                                ? Colors.green
                                                : Colors.grey,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pricing Information Card
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.currency_rupee_outlined,
                                    color: theme.primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pricing Information',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDetailRow(
                                theme,
                                'Selling Price',
                                '₹${product.sellingPrice.toStringAsFixed(2)}',
                                Icons.sell_outlined,
                                Colors.green,
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                theme,
                                'Purchase Price',
                                '₹${(product.purchasePrice ?? 0).toStringAsFixed(2)}',
                                Icons.shopping_cart_outlined,
                              ),
                              const Divider(height: 24),
                              _buildDetailRow(
                                theme,
                                'GST Rate',
                                '${product.gstRate}%',
                                Icons.receipt_long_outlined,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description Card
                      if (product.description != null &&
                          product.description!.isNotEmpty)
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      color: theme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Description',
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  product.description!,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                // Close the bottom sheet first
                                Navigator.of(context).pop();
                                // Wait a bit to ensure bottom sheet is closed
                                await Future.delayed(
                                  const Duration(milliseconds: 300),
                                );
                                // Navigate to edit screen
                                await Get.toNamed(
                                  AppRoutes.editProduct.replaceAll(
                                    ':id',
                                    product.id,
                                  ),
                                  arguments: {'productId': product.id},
                                );
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Product'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showManageStockSheet(context, product);
                              },
                              icon: const Icon(Icons.inventory_outlined),
                              label: const Text('Manage Stock'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    String value, [
    IconData? icon,
    Color? valueColor,
  ]) {
    final effectiveValueColor = valueColor ?? theme.textTheme.bodyMedium?.color;
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: effectiveValueColor,
          ),
        ),
      ],
    );
  }
}
