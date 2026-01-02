import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/product_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({super.key});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
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
      print('StockInScreen: StockController not found: $e');
    }
    try {
      _productController = Get.find<ProductController>();
    } catch (e) {
      print('StockInScreen: ProductController not found: $e');
    }

    // Check if product_id was passed as argument
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

    if (_stockController == null) {
      Get.snackbar('Error', 'Stock controller not available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final quantity = int.tryParse(_quantityController.text) ?? 0;

      final success = await _stockController!.addStockIn(
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
          'Added $quantity ${_selectedProduct?.unit ?? 'units'} of ${_selectedProduct?.name}',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to add stock',
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
      appBar: AppBar(title: const Text('Add Stock'), elevation: 0),
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
                    // Product Selection Card
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
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.add_box,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Stock In Form',
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

                    // Product Info Card (when product is selected)
                    if (_selectedProduct != null) ...[
                      Card(
                        color: Colors.blue.shade50,
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
                                      valueColor: Colors.blue,
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
                              'Quantity to Add',
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
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter quantity';
                                }
                                if (int.tryParse(value) == null ||
                                    int.parse(value) < 1) {
                                  return 'Quantity must be at least 1';
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
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'New Stock After Adding:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_currentStock + (int.tryParse(_quantityController.text) ?? 0)} ${_selectedProduct!.unit}',
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                    ),
                                    Text(
                                      'Current: $_currentStock + Adding: ${_quantityController.text}',
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
                                    'e.g., New purchase from supplier, Stock adjustment, etc.',
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
                            onPressed: _isLoading || _selectedProduct == null
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
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
                                : const Icon(Icons.add),
                            label: Text(_isLoading ? 'Adding...' : 'Add Stock'),
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
