import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../data/models/bill_model.dart';
import '../../../../../../data/models/product_model.dart';
import '../../../controllers/billing_controller.dart';
import '../../../controllers/product_controller.dart';

class POSBillingScreen extends StatefulWidget {
  const POSBillingScreen({super.key});

  @override
  State<POSBillingScreen> createState() => _POSBillingScreenState();
}

class _POSBillingScreenState extends State<POSBillingScreen> {
  final searchController = TextEditingController();
  final customerNameController = TextEditingController();
  final customerPhoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billingController = Get.put(BillingController());
    final productController = Get.put(ProductController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill'),
        actions: [
          Obx(
            () => billingController.cartItems.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Clear Cart'),
                          content: const Text(
                            'Are you sure you want to clear the cart?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                billingController.clearCart();
                                Get.back();
                              },
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Products Section (Left)
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                productController.clearFilters();
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      productController.searchProducts(value);
                    },
                  ),
                ),

                // Products Grid
                Expanded(
                  child: Obx(() {
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
                              size: 64,
                              color: theme.primaryColor.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products found',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: productController.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product =
                            productController.filteredProducts[index];
                        return _buildProductCard(
                          product,
                          billingController,
                          theme,
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),

          // Divider
          Container(width: 1, color: Colors.grey[300]),

          // Cart Section (Right)
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Customer Info
                _buildCustomerSection(theme),

                Divider(color: Colors.grey[300]),

                // Cart Items
                Expanded(
                  child: Obx(() {
                    if (billingController.cartItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: theme.primaryColor.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Cart is empty',
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add products to cart',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: billingController.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = billingController.cartItems[index];
                        return _buildCartItem(item, billingController, theme);
                      },
                    );
                  }),
                ),

                Divider(color: Colors.grey[300]),

                // Cart Summary
                _buildCartSummary(billingController, theme),

                // Payment Button
                _buildPaymentButton(billingController, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    Product product,
    BillingController controller,
    ThemeData theme,
  ) {
    return Card(
      child: InkWell(
        onTap: () => controller.addToCart(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Icon(
                    Icons.inventory_2,
                    size: 48,
                    color: theme.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₹${product.sellingPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (product.gstRate > 0)
                Text(
                  'GST ${product.gstRate}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Details',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: customerNameController,
            decoration: const InputDecoration(
              hintText: 'Customer Name (Optional)',
              prefixIcon: Icon(Icons.person_outline),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: customerPhoneController,
            decoration: const InputDecoration(
              hintText: 'Phone Number (Optional)',
              prefixIcon: Icon(Icons.phone_outlined),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(
    BillItem item,
    BillingController controller,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => controller.removeFromCart(item.productId),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 16),
                        onPressed: () {
                          controller.updateQuantity(
                            item.productId,
                            item.quantity - 1,
                          );
                        },
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 16),
                        onPressed: () {
                          controller.updateQuantity(
                            item.productId,
                            item.quantity + 1,
                          );
                        },
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹${item.totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BillingController controller, ThemeData theme) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow(
              'Subtotal',
              '₹${controller.subtotal.value.toStringAsFixed(2)}',
              theme,
            ),
            const SizedBox(height: 8),
            _buildSummaryRow(
              'Tax (GST)',
              '₹${controller.gstAmount.value.toStringAsFixed(2)}',
              theme,
            ),
            if (controller.discount.value > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Discount',
                '-₹${controller.discount.value.toStringAsFixed(2)}',
                theme,
                color: Colors.red,
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₹${controller.totalAmount.value.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentButton(BillingController controller, ThemeData theme) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed:
                controller.cartItems.isEmpty || controller.isLoading.value
                ? null
                : () async {
                    final success = await controller.createBill(
                      customerName: customerNameController.text.isEmpty
                          ? null
                          : customerNameController.text,
                      customerPhone: customerPhoneController.text.isEmpty
                          ? null
                          : customerPhoneController.text,
                    );

                    if (success) {
                      customerNameController.clear();
                      customerPhoneController.clear();
                      searchController.clear();

                      Get.snackbar(
                        'Success',
                        'Bill created successfully!',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    }
                  },
            icon: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.payment),
            label: Text(
              controller.isLoading.value ? 'Processing...' : 'Complete Payment',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    customerNameController.dispose();
    customerPhoneController.dispose();
    super.dispose();
  }
}
