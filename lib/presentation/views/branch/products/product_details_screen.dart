import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/product_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/branch_store_controller.dart';
import '../../../controllers/branch_controller.dart';
import '../../../../core/routes/app_routes.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _productId;
  bool _isLoading = false;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // Get product ID from route parameters or arguments
    _productId = Get.parameters['id'] ?? Get.arguments?['productId'];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Defer refresh until after build completes to avoid setState during build
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _refreshData();
        }
      });
    }
  }

  Future<void> _refreshData() async {
    if (_productId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final productController = Get.find<ProductController>();
      final stockController = Get.find<StockController>();
      
      // Refresh products and stock
      await productController.loadProducts();
      
      // Get branch ID for stock refresh
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      String? branchId;
      if (user?.role.value == 'tenant_owner') {
        try {
          final branchStore = Get.find<BranchStoreController>();
          branchId = branchStore.selectedBranchId.value;
        } catch (_) {
          // BranchStoreController not available
        }
      } else {
        branchId = authController.branchId;
      }
      
      await stockController.loadCurrentStock(branchId: branchId);
    } catch (e) {
      print('Error refreshing product details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productController = Get.find<ProductController>();
    final stockController = Get.find<StockController>();
    
    // Get product ID
    if (_productId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found')),
      );
    }

    // Find the product
    final product = productController.products.firstWhereOrNull(
      (p) => p.id == _productId,
    );

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: Center(
          child: _isLoading 
            ? const CircularProgressIndicator()
            : const Text('Product not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
              ],
            ),
            const SizedBox(height: 24),

            // Stock Information Card
            FutureBuilder<int>(
              future: _getProductStockQuantity(stockController, product.id),
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
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Stock',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$stock ${product.unit}',
                                  style: theme.textTheme.headlineSmall?.copyWith(
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
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Min Stock',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${product.minStock} ${product.unit}',
                                  style: theme.textTheme.titleMedium?.copyWith(
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
                              color: (isSoldOut ? Colors.red : Colors.orange)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSoldOut
                                      ? Icons.error_outline
                                      : Icons.warning_amber_rounded,
                                  color: isSoldOut ? Colors.red : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isSoldOut
                                        ? 'Product is out of stock'
                                        : 'Stock is below minimum threshold',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isSoldOut ? Colors.red : Colors.orange,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                    if (product.category != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        theme,
                        'Category',
                        product.category!.name,
                        Icons.category_outlined,
                      ),
                    ],
                    if (product.brand != null) ...[
                      const Divider(height: 24),
                      _buildDetailRow(
                        theme,
                        'Brand',
                        product.brand!.name,
                        Icons.branding_watermark_outlined,
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(
                          Icons.toggle_on,
                          color: product.isActive ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Status',
                            style: theme.textTheme.bodyMedium?.copyWith(
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
                            color: (product.isActive ? Colors.green : Colors.grey)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.isActive ? 'Active' : 'Inactive',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: product.isActive ? Colors.green : Colors.grey,
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
            if (product.description != null && product.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              // Description Card
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
                            style: theme.textTheme.titleMedium?.copyWith(
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
            ],
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // Navigate to edit screen and wait for result
                      final result = await Get.toNamed(
                        AppRoutes.editProduct.replaceAll(':id', product.id),
                        arguments: {
                          'productId': product.id,
                          'returnToDetails': true, // Flag to return to details screen
                        },
                      );
                      // If result is 'refresh', refresh the data after build completes
                      if (result == 'refresh' && mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _refreshData();
                          }
                        });
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Product'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showManageStockDialog(context, product, stockController, productController);
                    },
                    icon: const Icon(Icons.inventory_outlined),
                    label: const Text('Manage Stock'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<int> _getProductStockQuantity(
    StockController stockController,
    String productId,
  ) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;

      String? branchId;
      if (user?.role.value == 'tenant_owner') {
        try {
          final branchStore = Get.find<BranchStoreController>();
          branchId = branchStore.selectedBranchId.value;
        } catch (_) {
          // BranchStoreController not available
        }
      } else {
        branchId = authController.branchId;
      }

      return await stockController.getProductStockQuantity(
        productId,
        branchId: branchId,
      );
    } catch (e) {
      return 0;
    }
  }

  void _showManageStockDialog(
    BuildContext context,
    Product product,
    StockController stockController,
    ProductController productController,
  ) {
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
    _getProductStockQuantity(stockController, product.id).then((stock) {
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
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
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
                                        style: theme.textTheme.bodySmall?.copyWith(
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
                                          style: theme.textTheme.bodyLarge?.copyWith(
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
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Main',
                                            style: theme.textTheme.bodySmall?.copyWith(
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
                              future: _getProductStockQuantity(
                                stockController,
                                product.id,
                              ),
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
                                      mainAxisAlignment: MainAxisAlignment.center,
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
                                            borderRadius: BorderRadius.circular(30),
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
                                                    : theme.colorScheme.onSurface,
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
                                              style: theme.textTheme.displaySmall
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
                                            if (adjustedQuantity != currentQuantity) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                adjustedQuantity > currentQuantity
                                                    ? '+${adjustedQuantity - currentQuantity} from $currentQuantity'
                                                    : '${adjustedQuantity - currentQuantity} from $currentQuantity',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: Colors.blue.shade600,
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
                                            borderRadius: BorderRadius.circular(30),
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
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Adjustment Amount Input
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Adjustment Amount',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        TextField(
                                          controller: adjustmentAmountController,
                                          keyboardType: TextInputType.number,
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
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
                                            style: theme.textTheme.bodySmall?.copyWith(
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
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: product.stockTrackingType ==
                                    StockTrackingType.quantity
                                ? FutureBuilder<int>(
                                    future: _getProductStockQuantity(
                                      stockController,
                                      product.id,
                                    ),
                                    builder: (context, snapshot) {
                                      final currentQty = snapshot.data ?? 0;
                                      final difference =
                                          adjustedQuantity - currentQty;

                                      return ElevatedButton(
                                        onPressed: (branchId == null ||
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
                                                  bool success = false;
                                                  if (difference > 0) {
                                                    // Stock In
                                                    success = await stockController
                                                        .addStockIn(
                                                          productId: product.id,
                                                          quantity: difference,
                                                          reason:
                                                              'Stock adjustment from product details',
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
                                                            SnackPosition.BOTTOM,
                                                      );
                                                      return;
                                                    }
                                                    success = await stockController
                                                        .addStockOut(
                                                          productId: product.id,
                                                          quantity: difference.abs(),
                                                          reason:
                                                              'Stock adjustment from product details',
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
                                                    // Refresh the product details screen
                                                    Get.forceAppUpdate();
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
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
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

