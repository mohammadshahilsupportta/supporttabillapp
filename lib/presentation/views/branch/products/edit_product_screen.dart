import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/models/product_model.dart';
import '../../../../data/datasources/product_datasource.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';
import '../../../controllers/branch_controller.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/branch_store_controller.dart';

class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductDataSource _productDataSource = ProductDataSource();
  ProductController? _productController;
  StockController? _stockController;
  BranchController? _branchController;

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _minStockController;
  late TextEditingController _descriptionController;

  late String _unit;
  String? _categoryId;
  String? _brandId;
  late StockTrackingType _stockTrackingType;
  late bool _isActive;
  bool _isLoading = false;
  bool _isLoadingProduct = true;

  Product? _product;
  bool _returnToDetails = false;
  BuildContext? _context;

  // Stock entry state
  bool _addStockOnUpdate = false;
  String? _selectedBranchId;
  final TextEditingController _initialQuantityController = TextEditingController();
  final List<TextEditingController> _serialNumberControllers = [TextEditingController()];

  // Full unit names (match website UNITS list)
  final List<String> _units = [
    'Pieces',
    'Kg',
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

  @override
  void initState() {
    super.initState();
    try {
      _productController = Get.find<ProductController>();
    } catch (e) {
      print('EditProductScreen: ProductController not found: $e');
    }
    try {
      _stockController = Get.find<StockController>();
    } catch (e) {
      print('EditProductScreen: StockController not found: $e');
    }
    try {
      _branchController = Get.find<BranchController>();
    } catch (e) {
      print('EditProductScreen: BranchController not found: $e');
    }
    _loadProduct().then((_) {
      _initializeBranchSelection();
    });
  }

  void _initializeBranchSelection() {
    // Set default branch to main branch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_branchController != null && _branchController!.branches.isNotEmpty) {
        final mainBranch = _branchController!.branches.firstWhereOrNull(
          (b) => b['is_main'] == true && b['is_active'] == true,
        );
        if (mainBranch != null) {
          setState(() {
            _selectedBranchId = mainBranch['id'];
          });
        } else {
          // If no main branch, use first active branch
          final firstActiveBranch = _branchController!.branches.firstWhereOrNull(
            (b) => b['is_active'] == true,
          );
          if (firstActiveBranch != null) {
            setState(() {
              _selectedBranchId = firstActiveBranch['id'];
            });
          }
        }
      }
    });
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoadingProduct = true;
    });

    // Try to get ID from arguments first (more reliable)
    String? productId;
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      if (args['productId'] != null) {
        productId = args['productId'] as String;
      }
      if (args['returnToDetails'] == true) {
        _returnToDetails = true;
        print('EditProductScreen: returnToDetails flag set to true in _loadProduct');
      }
    }
    
    // If not in arguments, try parameters
    if (productId == null || productId.isEmpty) {
      productId = Get.parameters['id'];
    }
    
    // If still not found, extract from route path
    if (productId == null || productId.isEmpty || productId == ':id') {
      final currentRoute = Get.currentRoute;
      print('EditProductScreen: Current route: $currentRoute');
      
      // Extract ID from route path like /branch/products/edit/{id}
      final routeParts = currentRoute.split('/');
      if (routeParts.length > 0) {
        // The ID should be the last part of the path
        final lastPart = routeParts.last;
        if (lastPart.isNotEmpty && lastPart != 'edit' && lastPart != ':id') {
          productId = lastPart;
        }
      }
    }
    
    print('EditProductScreen: Loading product with ID: $productId');
    print('EditProductScreen: All parameters: ${Get.parameters}');
    print('EditProductScreen: Arguments: ${Get.arguments}');
    print('EditProductScreen: Current route: ${Get.currentRoute}');
    
    if (productId == null || productId.isEmpty || productId == ':id') {
      print('EditProductScreen: Product ID is null, empty, or invalid');
      setState(() {
        _isLoadingProduct = false;
      });
      return;
    }

    try {
      // Fetch product directly from database
      print('EditProductScreen: Fetching product from database...');
      _product = await _productDataSource.getProductById(productId);
      print('EditProductScreen: Product loaded: ${_product?.name}');
    } catch (e) {
      print('EditProductScreen: Error loading product from database: $e');
      // Try to find in products list as fallback
      if (_productController != null) {
        print('EditProductScreen: Trying to find product in products list...');
        _product = _productController!.products.firstWhereOrNull(
          (p) => p.id == productId,
        );
        if (_product != null) {
          print('EditProductScreen: Product found in list: ${_product?.name}');
        } else {
          print('EditProductScreen: Product not found in list either');
        }
      }
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
      text: (_product?.minStock ?? 0).toString(),
    );
    _descriptionController = TextEditingController(
      text: _product?.description ?? '',
    );
    _unit = _product?.unit ?? 'Pieces';
    _categoryId = _product?.categoryId;
    _brandId = _product?.brandId;
    _stockTrackingType = _product?.stockTrackingType ?? StockTrackingType.quantity;
    _isActive = _product?.isActive ?? true;

    // Update UI after loading
    if (mounted) {
      setState(() {
        _isLoadingProduct = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _minStockController.dispose();
    _descriptionController.dispose();
    _initialQuantityController.dispose();
    for (var controller in _serialNumberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSerialNumberField() {
    setState(() {
      _serialNumberControllers.add(TextEditingController());
    });
  }

  void _removeSerialNumberField(int index) {
    if (_serialNumberControllers.length > 1) {
      setState(() {
        _serialNumberControllers[index].dispose();
        _serialNumberControllers.removeAt(index);
      });
    }
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
        'min_stock': int.tryParse(_minStockController.text) ?? 0,
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'category_id': _categoryId,
        'brand_id': _brandId,
        'stock_tracking_type': _stockTrackingType.value,
        'is_active': _isActive,
      };

      if (_productController == null) {
        Get.snackbar('Error', 'Product controller not available');
        setState(() => _isLoading = false);
        return;
      }

      final success = await _productController!.updateProduct(
        _product!.id,
        updates,
      );

      if (!success) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Track if stock was added to avoid duplicate snackbars
      bool stockAdded = false;
      int? stockQuantityAdded;
      
      // Add stock if requested
      if (_addStockOnUpdate && _selectedBranchId != null) {
        if (_stockTrackingType == StockTrackingType.quantity) {
          // Add quantity-based stock
          if (_initialQuantityController.text.isNotEmpty) {
            final quantity = int.tryParse(_initialQuantityController.text);
            if (quantity != null && quantity > 0) {
              try {
                if (_stockController != null) {
                  stockAdded = await _stockController!.addStockIn(
                    productId: _product!.id,
                    quantity: quantity,
                    reason: 'Stock entry after product update',
                    branchId: _selectedBranchId,
                  );
                  if (stockAdded) {
                    stockQuantityAdded = quantity;
                  }
                }
              } catch (stockError) {
                Get.snackbar(
                  'Warning',
                  'Product updated but failed to add stock: ${stockError.toString()}',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                );
              }
            }
          }
        } else if (_stockTrackingType == StockTrackingType.serial) {
          // Add serial numbers
          final validSerials = _serialNumberControllers
              .map((c) => c.text.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (validSerials.isNotEmpty) {
            // Note: Serial number addition would need to be implemented
            // For now, we'll just show a message
            stockAdded = true; // Mark as added to skip general message
          }
        }
      }

      // Show a single success message - combined if stock was added, otherwise just product update
      // Close any existing snackbars first to avoid duplicates
      try {
        Get.closeAllSnackbars();
      } catch (_) {
        // Ignore if no snackbars are open
      }
      
      // Small delay to ensure previous snackbar is closed
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (stockAdded && stockQuantityAdded != null) {
        // Show combined message for product update + stock addition
        Get.snackbar(
          'Success',
          'Product "${_nameController.text.trim()}" updated and $stockQuantityAdded units added to stock!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else if (stockAdded && _stockTrackingType == StockTrackingType.serial) {
        // Serial number case
        Get.snackbar(
          'Success',
          'Product "${_nameController.text.trim()}" updated. Serial number addition feature coming soon.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      } else if (!_addStockOnUpdate ||
          (_stockTrackingType == StockTrackingType.quantity &&
              _initialQuantityController.text.isEmpty) ||
          (_stockTrackingType == StockTrackingType.serial &&
              _serialNumberControllers
                  .where((c) => c.text.trim().isNotEmpty)
                  .isEmpty)) {
        // General success message when no stock was added
        Get.snackbar(
          'Success',
          'Product "${_nameController.text.trim()}" updated successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }

      // Navigate back after successful update
      // ALWAYS navigate back - check returnToDetails to determine where to go
      print('EditProductScreen: About to navigate back. _returnToDetails = $_returnToDetails');
      
      // Reset loading state before navigation
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // Small delay to ensure snackbar is shown
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (_returnToDetails) {
        // Pop back to product details screen with refresh flag
        print('EditProductScreen: Popping back to product details screen');
        // Try Navigator.pop first if context is available, then fallback to Get.back()
        bool navigated = false;
        if (mounted && _context != null) {
          try {
            Navigator.of(_context!).pop('refresh');
            navigated = true;
            print('EditProductScreen: Navigator.pop(refresh) called successfully');
          } catch (e) {
            print('EditProductScreen: Navigator.pop failed: $e');
          }
        }
        // Fallback to Get.back() if Navigator.pop didn't work
        if (!navigated) {
          try {
            Get.back(result: 'refresh');
            navigated = true;
            print('EditProductScreen: Get.back(result: refresh) called successfully');
          } catch (e) {
            print('EditProductScreen: Get.back() also failed: $e');
          }
        }
        if (!navigated) {
          print('EditProductScreen: ERROR - All navigation methods failed!');
        }
      } else {
        // Refresh product data before navigating back to products list
        print('EditProductScreen: Returning to products list');
        if (_productController != null) {
          await _productController!.loadProducts();
        }
        if (_stockController != null) {
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
          await _stockController!.loadCurrentStock(branchId: branchId);
        }
        // Use Get.back() which works with GetX navigation
        if (mounted) {
          Get.back();
        }
      }
    } catch (e) {
      print('EditProductScreen: ERROR in _submit: $e');
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _context = context; // Store context for navigation
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Show loading state while fetching product
    if (_isLoadingProduct) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if product not found after loading
    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Product')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Product not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'The product may have been deleted or you may not have access to it.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Card
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
                        hintText: 'e.g., Samsung Galaxy S23',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      style: const TextStyle(fontSize: 16),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Product name is required';
                        }
                        if (value.length > 255) {
                          return 'Name is too long';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // SKU and Unit in a row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _skuController,
                            decoration: InputDecoration(
                              labelText: 'SKU',
                              hintText: 'e.g., SAM-GAL-S23-128',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.qr_code),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _unit,
                            decoration: InputDecoration(
                              labelText: 'Unit *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.straighten,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                            ),
                            iconEnabledColor: theme.colorScheme.onSurface,
                            iconDisabledColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                            dropdownColor: theme.colorScheme.surface,
                            isExpanded: true,
                            selectedItemBuilder: (BuildContext context) {
                              return _units.map((unit) {
                                return Container(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList();
                            },
                            items: _units.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(
                                  unit,
                                  style: TextStyle(
                                    color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => _unit = value);
                            },
                            validator: (value) =>
                                value == null ? 'Unit is required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Catalogue Information Card
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
                          'Catalogue Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _categoryId,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.category_outlined),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                              isExpanded: true,
                              selectedItemBuilder: (BuildContext context) {
                                return [
                                  Text(
                                    'No Category',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  ...(_productController?.categories ?? [])
                                      .where((c) => c.isActive)
                                      .map(
                                        (c) => Align(
                                          alignment: AlignmentDirectional.centerStart,
                                          child: Text(
                                            c.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                ];
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'No Category',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                ...(_productController?.categories ?? [])
                                    .where((c) => c.isActive)
                                    .map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c.id,
                                        child: Text(
                                          c.name,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged: (value) {
                                setState(() => _categoryId = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _brandId,
                              decoration: InputDecoration(
                                labelText: 'Brand',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: const Icon(Icons.branding_watermark),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                              isExpanded: true,
                              selectedItemBuilder: (BuildContext context) {
                                return [
                                  Text(
                                    'No Brand',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  ...(_productController?.brands ?? [])
                                      .where((b) => b.isActive)
                                      .map(
                                        (b) => Align(
                                          alignment: AlignmentDirectional.centerStart,
                                          child: Text(
                                            b.name,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                ];
                              },
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(
                                    'No Brand',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                ...(_productController?.brands ?? [])
                                    .where((b) => b.isActive)
                                    .map(
                                      (b) => DropdownMenuItem<String>(
                                        value: b.id,
                                        child: Text(
                                          b.name,
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                              onChanged: (value) {
                                setState(() => _brandId = value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pricing Information Card
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
                            Icons.trending_up,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pricing Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Selling Price and Purchase Price in a row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _sellingPriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Selling Price *',
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixText: '₹ ',
                            ),
                            style: const TextStyle(fontSize: 16),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Selling price is required';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Selling price must be greater than 0';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Purchase Price',
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixText: '₹ ',
                              helperText: 'Cost price for profit calculation',
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Minimum Stock
                    TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Minimum Stock',
                        hintText: '0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.warning_amber),
                        helperText: 'Alert when stock falls below this level',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stock Tracking Card
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
                            Icons.format_list_numbered,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Stock Tracking',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    DropdownButtonFormField<StockTrackingType>(
                      value: _stockTrackingType,
                      decoration: InputDecoration(
                        labelText: 'Stock Tracking Type *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.inventory),
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                      isExpanded: true,
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_bag, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Quantity (Count)',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code, size: 20, color: Colors.purple),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Serial Numbers',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ];
                      },
                      items: [
                        DropdownMenuItem(
                          value: StockTrackingType.quantity,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.shopping_bag, size: 20, color: Colors.blue),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Quantity (Count)',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: StockTrackingType.serial,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code, size: 20, color: Colors.purple),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Serial Numbers',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _stockTrackingType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how to track inventory for this product. Quantity tracks total count, Serial Numbers tracks each item individually.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Add Stock Entry Card (Optional)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_box,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Add Stock (Optional)',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _addStockOnUpdate,
                              onChanged: (value) {
                                setState(() => _addStockOnUpdate = value ?? false);
                              },
                            ),
                            const Text('Add stock now'),
                          ],
                        ),
                      ],
                    ),

                    if (_addStockOnUpdate) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Branch Selection
                            Obx(
                              () => DropdownButtonFormField<String>(
                                value: _selectedBranchId,
                                decoration: InputDecoration(
                                  labelText: 'Branch *',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.store),
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                isExpanded: true,
                                selectedItemBuilder: (BuildContext context) {
                                  return (_branchController?.branches ?? [])
                                      .where((b) => b['is_active'] == true)
                                      .map((branch) {
                                    return Align(
                                      alignment: AlignmentDirectional.centerStart,
                                      child: Text(
                                        '${branch['name']} (${branch['code']})',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList();
                                },
                                items: (_branchController?.branches ?? [])
                                    .where((b) => b['is_active'] == true)
                                    .map((branch) {
                                  return DropdownMenuItem<String>(
                                    value: branch['id'],
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '${branch['name']} (${branch['code']})',
                                            style: TextStyle(
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (branch['is_main'] == true) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.yellow.shade100,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Main',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.yellow.shade800,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedBranchId = value);
                                },
                                validator: _addStockOnUpdate
                                    ? (value) => value == null
                                        ? 'Branch is required'
                                        : null
                                    : null,
                              ),
                            ),

                            // Quantity-based stock entry
                            if (_stockTrackingType == StockTrackingType.quantity) ...[
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _initialQuantityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Quantity to Add *',
                                  hintText: 'Enter quantity to add',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: const Icon(Icons.add_shopping_cart),
                                ),
                                style: const TextStyle(fontSize: 16),
                                validator: _addStockOnUpdate
                                    ? (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Quantity is required';
                                        }
                                        final qty = int.tryParse(value);
                                        if (qty == null || qty <= 0) {
                                          return 'Quantity must be greater than 0';
                                        }
                                        return null;
                                      }
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter the number of units to add to stock',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],

                            // Serial number-based stock entry
                            if (_stockTrackingType == StockTrackingType.serial) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Serial Numbers *',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(
                                _serialNumberControllers.length,
                                (index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _serialNumberControllers[index],
                                          decoration: InputDecoration(
                                            hintText: 'Serial number ${index + 1}',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            prefixIcon: const Icon(Icons.qr_code),
                                          ),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      if (_serialNumberControllers.length > 1) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle),
                                          color: Colors.red,
                                          onPressed: () => _removeSerialNumberField(index),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _addSerialNumberField,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Another Serial Number'),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter individual serial numbers for each item',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Product description, features, specifications...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    // Product Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Product Status',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Active products are visible in billing and stock management',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<bool>(
                            value: _isActive,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: true,
                                child: Text(
                                  'Active',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: false,
                                child: Text(
                                  'Inactive',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _isActive = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Update Product',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
