import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/product_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';

class StockOutScreen extends StatefulWidget {
  const StockOutScreen({super.key});

  @override
  State<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends State<StockOutScreen> {
  final _formKey = GlobalKey<FormState>();
  StockController? _stockController;
  ProductController? _productController;

  String? _selectedProductId;
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      _stockController = Get.find<StockController>();
    } catch (e) {
      print('StockOutScreen: StockController not found: $e');
    }
    try {
      _productController = Get.find<ProductController>();
    } catch (e) {
      print('StockOutScreen: ProductController not found: $e');
    }

    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['product_id'] != null) {
      _selectedProductId = args['product_id'];
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Product? get _selectedProduct {
    if (_selectedProductId == null || _productController == null) return null;
    try {
      return _productController!.products.firstWhere(
        (p) => p.id == _selectedProductId,
      );
    } catch (e) {
      return null;
    }
  }

  int get _currentStock {
    if (_selectedProductId == null || _stockController == null) return 0;
    try {
      final stockItem = _stockController!.currentStock.firstWhere(
        (s) => s.productId == _selectedProductId,
      );
      return stockItem.quantity;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      Get.snackbar('Error', 'Please select a product');
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;

    if (quantity > _currentStock) {
      Get.snackbar(
        'Error',
        'Cannot remove more than available stock ($_currentStock)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_stockController == null) {
      Get.snackbar('Error', 'Stock controller not available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _stockController!.addStockOut(
        productId: _selectedProductId!,
        quantity: quantity,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Removed $quantity ${_selectedProduct?.unit ?? 'units'} of ${_selectedProduct?.name}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to remove stock',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Remove Stock'), elevation: 0),
      body: Form(
        key: _formKey,
        child: _productController == null
            ? const Center(child: Text('Product controller not available'))
            : Obx(() {
                if (_productController!.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Card
                    Card(
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
                                    Icons.remove_circle,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Stock Out Form',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Product Dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedProductId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Select Product *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.inventory_2),
                              ),
                              items: _productController!.products
                                  .where((p) => p.isActive)
                                  .map<DropdownMenuItem<String>>((product) {
                                    return DropdownMenuItem<String>(
                                      value: product.id,
                                      child: Text(
                                        '${product.name}${product.sku != null ? " (${product.sku})" : ""}',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    );
                                  })
                                  .toList(),
                              onChanged: (value) {
                                setState(() => _selectedProductId = value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a product';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Product Info Card
                    if (_selectedProduct != null) ...[
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      'Product Name',
                                      _selectedProduct!.name,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      'Unit',
                                      _selectedProduct!.unit,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoItem(
                                      'Current Stock',
                                      '$_currentStock ${_selectedProduct!.unit}',
                                      valueColor: _currentStock > 0
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildInfoItem(
                                      'Selling Price',
                                      '₹${_selectedProduct!.sellingPrice.toStringAsFixed(2)}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quantity Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity to Remove',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                suffixText: _selectedProduct?.unit ?? 'units',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                helperText: _selectedProduct != null
                                    ? 'Max: $_currentStock ${_selectedProduct!.unit}'
                                    : null,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                final qty = int.tryParse(value);
                                if (qty == null || qty < 1) {
                                  return 'Quantity must be at least 1';
                                }
                                if (qty > _currentStock) {
                                  return 'Cannot exceed current stock';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New Stock Preview
                    if (_selectedProduct != null &&
                        (int.tryParse(_quantityController.text) ?? 0) > 0)
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Stock After Removing:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_currentStock - (int.tryParse(_quantityController.text) ?? 0)} ${_selectedProduct!.unit}',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade700,
                                          ),
                                    ),
                                    Text(
                                      'Current: $_currentStock - Removing: ${_quantityController.text}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Reason Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reason (Optional)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _reasonController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText:
                                    'e.g., Damaged goods, Expired items, Wastage, etc.',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignLabelWithHint: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ||
                                    _selectedProduct == null ||
                                    _currentStock == 0
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.remove),
                            label: Text(
                              _isLoading ? 'Removing...' : 'Remove Stock',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              }),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
