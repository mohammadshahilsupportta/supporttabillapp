import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/product_model.dart';
import '../../../controllers/product_controller.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  ProductController? _productController;

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _minStockController;
  late TextEditingController _descriptionController;

  late String _unit;
  String? _categoryId;
  String? _brandId;
  late double _gstRate;
  late bool _isActive;
  bool _isLoading = false;

  Product? _product;

  final List<String> _units = [
    'pcs',
    'kg',
    'g',
    'l',
    'ml',
    'box',
    'pack',
    'dozen',
  ];
  final List<double> _gstRates = [0, 5, 12, 18, 28];

  @override
  void initState() {
    super.initState();
    try {
      _productController = Get.find<ProductController>();
    } catch (e) {
      print('EditProductScreen: ProductController not found: $e');
    }
    _loadProduct();
  }

  void _loadProduct() {
    if (_productController == null) return;
    final productId = Get.parameters['id'];
    if (productId != null) {
      _product = _productController!.products.firstWhereOrNull(
        (p) => p.id == productId,
      );
    }

    // Initialize with product data or defaults
    _nameController = TextEditingController(text: _product?.name ?? '');
    _skuController = TextEditingController(text: _product?.sku ?? '');
    _sellingPriceController = TextEditingController(
      text: _product?.sellingPrice.toStringAsFixed(2) ?? '',
    );
    _purchasePriceController = TextEditingController(
      text: _product?.purchasePrice?.toStringAsFixed(2) ?? '',
    );
    _minStockController = TextEditingController(
      text: (_product?.minStock ?? 5).toString(),
    );
    _descriptionController = TextEditingController(
      text: _product?.description ?? '',
    );
    _unit = _product?.unit ?? 'pcs';
    _categoryId = _product?.categoryId;
    _brandId = _product?.brandId;
    _gstRate = _product?.gstRate ?? 0;
    _isActive = _product?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_product == null) return;

    setState(() => _isLoading = true);

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'sku': _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : null,
        'unit': _unit,
        'selling_price': double.parse(_sellingPriceController.text),
        'purchase_price': _purchasePriceController.text.isNotEmpty
            ? double.parse(_purchasePriceController.text)
            : null,
        'gst_rate': _gstRate,
        'min_stock': int.tryParse(_minStockController.text) ?? 5,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'category_id': _categoryId,
        'brand_id': _brandId,
        'is_active': _isActive,
      };

      if (_productController == null) {
        Get.snackbar('Error', 'Product controller not available');
        return;
      }
      final success = await _productController!.updateProduct(
        _product!.id,
        updates,
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'Product updated successfully',
          backgroundColor: Colors.green,
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

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const Center(child: Text('Product not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        elevation: 0,
        actions: [
          if (_product != null)
            IconButton(
              icon: const Icon(Icons.delete),
              color: Colors.red,
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Card
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
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.shopping_bag,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Basic Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        labelText: 'SKU / Barcode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.straighten),
                      ),
                      items: _units
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing Card
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
                            Icons.currency_rupee,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pricing',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Selling Price *',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Required';
                        if (double.tryParse(value!) == null ||
                            double.parse(value) <= 0)
                          return 'Invalid price';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Purchase Price',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<double>(
                      value: _gstRate,
                      decoration: InputDecoration(
                        labelText: 'GST Rate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.percent),
                      ),
                      items: _gstRates
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text('${r.toInt()}%'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _gstRate = v!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stock & Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock & Status',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minimum Stock Level',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.warning_amber),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Product Active'),
                      subtitle: const Text(
                        'Inactive products won\'t appear in billing',
                      ),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'Saving...' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${_product?.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_productController == null) {
                Get.snackbar('Error', 'Product controller not available');
                return;
              }
              final success = await _productController!.deleteProduct(
                _product!.id,
              );
              if (success) {
                Get.back();
                Get.snackbar(
                  'Success',
                  'Product deleted',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
