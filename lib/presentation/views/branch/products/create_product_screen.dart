import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/product_controller.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/product_model.dart' show StockTrackingType;

class CreateProductScreen extends StatefulWidget {
  const CreateProductScreen({super.key});

  @override
  State<CreateProductScreen> createState() => _CreateProductScreenState();
}

class _CreateProductScreenState extends State<CreateProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final productController = Get.find<ProductController>();

  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  final _descriptionController = TextEditingController();

  String _unit = 'Pieces';
  String? _categoryId;
  String? _brandId;
  double _gstRate = 0;
   // 'quantity' | 'serial' – matches website stock_tracking_type
  String _stockTrackingType = 'quantity';
  bool _isActive = true;
  bool _isLoading = false;

  // Full unit names (match website UNITS list)
  final List<String> _units = [
    'Pieces',
    'Kilograms',
    'Grams',
    'Liters',
    'ML',
    'Box',
    'Pack',
    'Dozen',
    'Meters',
    'Feet',
    'Sq. Feet',
    'Sq. Meters',
  ];
  final List<double> _gstRates = [0, 5, 12, 18, 28];

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

    setState(() => _isLoading = true);

    try {
      final success = await productController.createProductFromData(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim().isNotEmpty
            ? _skuController.text.trim()
            : null,
        unit: _unit,
        sellingPrice: double.parse(_sellingPriceController.text),
        purchasePrice: _purchasePriceController.text.isNotEmpty
            ? double.parse(_purchasePriceController.text)
            : null,
        gstRate: _gstRate,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        categoryId: _categoryId,
        brandId: _brandId,
        stockTrackingType: _stockTrackingType == 'serial'
            ? StockTrackingType.serial
            : StockTrackingType.quantity,
        isActive: _isActive,
      );

      if (success) {
        // Controller already shows a success message; navigate to products list.
        Get.offNamed(AppRoutes.productsList);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product'), elevation: 0),
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

                    // Product Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name *',
                        hintText: 'Enter product name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // SKU
                    TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        labelText: 'SKU / Barcode (Optional)',
                        hintText: 'Enter SKU or barcode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.qr_code),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Unit Dropdown
                    DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.straighten),
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _unit = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Catalogue Card (Category & Brand) - match website behaviour
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
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.category,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Catalogue',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => Column(
                        children: [
                          // Category dropdown
                          DropdownButtonFormField<String>(
                            value: _categoryId,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon:
                                  const Icon(Icons.category_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No Category'),
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
                              setState(() => _categoryId = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          // Brand dropdown
                          DropdownButtonFormField<String>(
                            value: _brandId,
                            decoration: InputDecoration(
                              labelText: 'Brand',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon:
                                  const Icon(Icons.branding_watermark),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No Brand'),
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
                              setState(() => _brandId = value);
                            },
                          ),
                        ],
                      ),
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

                    // Selling Price
                    TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Selling Price *',
                        hintText: '0.00',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter selling price';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Please enter a valid price';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Purchase Price
                    TextFormField(
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Purchase Price (Optional)',
                        hintText: '0.00',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        helperText: 'Cost price for profit calculation',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // GST Rate
                    DropdownButtonFormField<double>(
                      value: _gstRate,
                      decoration: InputDecoration(
                        labelText: 'GST Rate',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.percent),
                      ),
                      items: _gstRates.map((rate) {
                        return DropdownMenuItem<double>(
                          value: rate,
                          child: Text('${rate.toInt()}%'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _gstRate = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stock Settings Card
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
                            Icons.inventory,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Stock Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Min Stock
                    TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minimum Stock Level',
                        hintText: '5',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.warning_amber),
                        helperText: 'Alert when stock falls below this level',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stock Tracking Type
                    DropdownButtonFormField<String>(
                      value: _stockTrackingType,
                      decoration: InputDecoration(
                        labelText: 'Stock Tracking Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.format_list_numbered),
                        helperText:
                            'Quantity: simple count, Serial: track each piece',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'quantity',
                          child: Text('Quantity based'),
                        ),
                        DropdownMenuItem(
                          value: 'serial',
                          child: Text('Serial number based'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _stockTrackingType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Active Switch
                    SwitchListTile(
                      title: const Text('Product Active'),
                      subtitle: const Text(
                        'Inactive products won\'t appear in billing',
                      ),
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description (Optional)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Enter product description...',
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

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
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
                label: Text(
                  _isLoading ? 'Creating...' : 'Create Product',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
}
