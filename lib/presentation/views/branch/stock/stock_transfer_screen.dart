import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/product_model.dart';
import '../../../controllers/branch_controller.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';
import '../../../controllers/auth_controller.dart';

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  StockController? _stockController;
  ProductController? _productController;
  BranchController? _branchController;
  AuthController? _authController;

  String? _selectedProductId;
  String? _selectedToBranchId;
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      _stockController = Get.find<StockController>();
    } catch (e) {
      print('StockTransferScreen: StockController not found: $e');
    }
    try {
      _productController = Get.find<ProductController>();
    } catch (e) {
      print('StockTransferScreen: ProductController not found: $e');
    }
    try {
      _branchController = Get.find<BranchController>();
    } catch (e) {
      print('StockTransferScreen: BranchController not found: $e');
    }
    try {
      _authController = Get.find<AuthController>();
    } catch (e) {
      print('StockTransferScreen: AuthController not found: $e');
    }
    
    // Check if product_id was passed as argument
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null && args['product_id'] != null) {
      _selectedProductId = args['product_id'];
    }
    // Load branches if not already loaded
    if (_branchController != null && _branchController!.branches.isEmpty) {
      _branchController!.loadBranches();
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

  String? get _fromBranchName {
    if (_authController == null || _branchController == null) return null;
    final branchId = _authController!.branchId;
    if (branchId == null) return null;
    try {
      final branch = _branchController!.branches.firstWhere(
        (b) => b['id'] == branchId,
      );
      return branch['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  String? get _toBranchName {
    if (_selectedToBranchId == null || _branchController == null) return null;
    try {
      final branch = _branchController!.branches.firstWhere(
        (b) => b['id'] == _selectedToBranchId,
      );
      return branch['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _availableBranches {
    if (_authController == null || _branchController == null) return [];
    final currentBranchId = _authController!.branchId;
    return _branchController!.branches
        .where((b) =>
            b['id'] != currentBranchId && b['is_active'] == true)
        .toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      Get.snackbar('Error', 'Please select a product');
      return;
    }
    if (_selectedToBranchId == null) {
      Get.snackbar('Error', 'Please select destination branch');
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;

    if (quantity > _currentStock) {
      Get.snackbar(
        'Error',
        'Cannot transfer more than available stock ($_currentStock)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_stockController == null || _authController == null) {
      Get.snackbar('Error', 'Controllers not available');
      return;
    }

    final fromBranchId = _authController!.branchId;
    if (fromBranchId == null) {
      Get.snackbar('Error', 'Source branch not found');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _stockController!.transferStock(
        fromBranchId: fromBranchId,
        toBranchId: _selectedToBranchId!,
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
          'Transferred $quantity ${_selectedProduct?.unit ?? 'units'} to $_toBranchName',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to transfer stock',
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
        title: const Text('Transfer Stock'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: _productController == null || _branchController == null
            ? const Center(child: Text('Controllers not available'))
            : Obx(() {
                if (_productController!.isLoading.value ||
                    _branchController!.isLoading.value) {
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
                              color: Colors.purple.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.swap_horiz,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Stock Transfer Form',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transfer stock from current branch to another branch',
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
                                'Available Stock',
                                '$_currentStock ${_selectedProduct!.unit}',
                                valueColor: _currentStock > 0
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                'From Branch',
                                _fromBranchName ?? 'Current Branch',
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

              // Destination Branch Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer To Branch *',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedToBranchId,
                        decoration: InputDecoration(
                          labelText: 'Select Destination Branch',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.store),
                        ),
                        items: _availableBranches
                            .map<DropdownMenuItem<String>>((branch) {
                              return DropdownMenuItem<String>(
                                value: branch['id'] as String,
                                child: Text(
                                  branch['name'] as String? ?? 'Unknown',
                                ),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setState(() => _selectedToBranchId = value);
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select destination branch';
                          }
                          return null;
                        },
                      ),
                      if (_availableBranches.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No other branches available for transfer',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quantity Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity to Transfer',
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
                            return 'Cannot exceed available stock';
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

              // Transfer Preview
              if (_selectedProduct != null &&
                  _selectedToBranchId != null &&
                  (int.tryParse(_quantityController.text) ?? 0) > 0)
                Card(
                  color: Colors.purple.shade50,
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
                                color: Colors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.swap_horiz,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transfer Summary',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTransferRow(
                                    'From',
                                    _fromBranchName ?? 'Current Branch',
                                    Colors.red,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildTransferRow(
                                    'To',
                                    _toBranchName ?? 'Selected Branch',
                                    Colors.green,
                                  ),
                                  const SizedBox(height: 8),
                                  Divider(color: Colors.purple.shade200),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Quantity:',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '${_quantityController.text} ${_selectedProduct!.unit}',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Remaining at source:',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                      Text(
                                        '${_currentStock - (int.tryParse(_quantityController.text) ?? 0)} ${_selectedProduct!.unit}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
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
                              'e.g., Stock reallocation, Branch requirement, etc.',
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
                      onPressed: _isLoading ||
                              _selectedProduct == null ||
                              _selectedToBranchId == null ||
                              _currentStock == 0 ||
                              _availableBranches.isEmpty
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
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
                          : const Icon(Icons.swap_horiz),
                      label: Text(_isLoading ? 'Transferring...' : 'Transfer Stock'),
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

  Widget _buildTransferRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
                          Expanded(
                            child: Text(
                              value,
                              style: TextStyle(color: color),
                            ),
                          ),
      ],
    );
  }
}

