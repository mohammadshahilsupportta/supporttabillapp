import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/product_model.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';

class StockAdjustScreen extends StatefulWidget {
  const StockAdjustScreen({super.key});

  @override
  State<StockAdjustScreen> createState() => _StockAdjustScreenState();
}

class _StockAdjustScreenState extends State<StockAdjustScreen> {
  final _formKey = GlobalKey<FormState>();
  StockController? _stockController;
  ProductController? _productController;

  String? _selectedProductId;
  final _newQuantityController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      _stockController = Get.find<StockController>();
    } catch (e) {
      print('StockAdjustScreen: StockController not found: $e');
    }
    try {
      _productController = Get.find<ProductController>();
    } catch (e) {
      print('StockAdjustScreen: ProductController not found: $e');
    }
    
    // Check if product_id was passed as argument
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['product_id'] != null) {
      _selectedProductId = args['product_id'];
      _loadCurrentStock();
    }
  }

  Future<void> _loadCurrentStock() async {
    if (_selectedProductId != null && _stockController != null) {
      try {
        await _stockController!.loadCurrentStock();
        final currentQty = _currentStock;
        _newQuantityController.text = currentQty.toString();
      } catch (e) {
        print('Error loading current stock: $e');
      }
    }
  }

  @override
  void dispose() {
    _newQuantityController.dispose();
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

  int? get _newQuantity {
    final text = _newQuantityController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  int get _difference {
    final newQty = _newQuantity ?? _currentStock;
    return newQty - _currentStock;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      Get.snackbar('Error', 'Please select a product');
      return;
    }

    final newQty = _newQuantity;
    if (newQty == null || newQty < 0) {
      Get.snackbar('Error', 'Please enter a valid quantity');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      Get.snackbar('Error', 'Please provide a reason for adjustment');
      return;
    }

    if (_stockController == null) {
      Get.snackbar('Error', 'Stock controller not available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _stockController!.adjustStock(
        productId: _selectedProductId!,
        newQuantity: newQty,
        reason: _reasonController.text.trim(),
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Stock adjusted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to adjust stock',
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
      appBar: AppBar(
        title: const Text('Adjust Stock'),
        elevation: 0,
      ),
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
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.tune,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Stock Adjustment Form',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Correct stock discrepancies and update inventory',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Product Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedProductId,
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
                                  '${product.name} ${product.sku != null ? "(${product.sku})" : ""}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProductId = value;
                            _loadCurrentStock();
                          });
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

              // New Quantity Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Stock Quantity *',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _newQuantityController,
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
                          helperText: 'Enter the correct stock quantity',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter new quantity';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          if (int.parse(value) < 0) {
                            return 'Quantity cannot be negative';
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

              // Adjustment Preview
              if (_selectedProduct != null && _newQuantity != null)
                Card(
                  color: _difference == 0
                      ? Colors.grey.shade50
                      : _difference > 0
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _difference == 0
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : _difference > 0
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _difference == 0
                                    ? Icons.check_circle
                                    : _difference > 0
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                color: _difference == 0
                                    ? Colors.grey
                                    : _difference > 0
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _difference == 0
                                        ? 'No Change'
                                        : _difference > 0
                                            ? 'Stock Will Increase'
                                            : 'Stock Will Decrease',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _difference == 0
                                          ? Colors.grey[700]
                                          : _difference > 0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Current: $_currentStock → New: ${_newQuantity} ${_selectedProduct!.unit}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (_difference != 0)
                                    Text(
                                      'Difference: ${_difference > 0 ? '+' : ''}$_difference ${_selectedProduct!.unit}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: _difference > 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Reason Card (Required for adjustment)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Reason for Adjustment *',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(Required)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'e.g., Physical count correction, Damaged items found, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Reason is required for stock adjustment';
                          }
                          return null;
                        },
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
                        backgroundColor: Colors.orange,
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
                          : const Icon(Icons.check),
                      label: Text(_isLoading ? 'Adjusting...' : 'Adjust Stock'),
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

