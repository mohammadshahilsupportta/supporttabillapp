import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/datasources/settings_datasource.dart';
import '../../../../data/datasources/stock_datasource.dart';
import '../../../../data/models/bill_model.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/stock_model.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/billing_controller.dart';
import '../../../controllers/branch_store_controller.dart';
import '../../../controllers/customer_controller.dart';
import '../../../controllers/product_controller.dart';
import '../../../controllers/stock_controller.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with SingleTickerProviderStateMixin {
  final _productSearchController = TextEditingController();
  final _overallDiscountController = TextEditingController();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();

  BillingController? _billingController;
  ProductController? _productController;
  CustomerController? _customerController;
  StockController? _stockController;
  AuthController? _authController;

  final SettingsDataSource _settingsDataSource = SettingsDataSource();
  final StockDataSource _stockDataSource = StockDataSource();

  // Cart item with additional data
  final List<CartItem> _cart = [];
  String? _selectedCustomerId;
  PaymentMode _paymentMode = PaymentMode.cash;
  double _overallDiscount = 0.0;
  Map<String, dynamic>? _settings;
  bool _isLoadingSettings = true;
  Map<String, int> _productStock = {}; // productId -> available stock
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize controllers from GetX
    _authController = Get.find<AuthController>();
    _billingController = Get.find<BillingController>();
    _productController = Get.find<ProductController>();
    _customerController = Get.find<CustomerController>();
    _stockController = Get.find<StockController>();

    _loadSettings();
    _loadStock();
    _customerController?.loadCustomers();
    _productController?.loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _productSearchController.dispose();
    _overallDiscountController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  bool get _isMobile {
    return MediaQuery.of(context).size.width < 768;
  }

  Future<void> _loadSettings() async {
    if (_authController == null) return;
    try {
      final tenantId = _authController!.tenantId;
      if (tenantId != null) {
        _settings = await _settingsDataSource.getSettings(tenantId);
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  Future<void> _loadStock() async {
    if (_stockController == null) return;
    try {
      final branchId = _effectiveBranchId;
      if (branchId != null) {
        await _stockController!.loadCurrentStock();
        // Build stock map
        for (var stock in _stockController!.currentStock) {
          _productStock[stock.productId] = stock.quantity;
        }
        // Trigger UI rebuild after stock is loaded
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Error loading stock: $e');
    }
  }

  int _getProductStock(String productId) {
    // Return actual stock, default 0 if no entry
    return _productStock[productId] ?? 0;
  }

  bool _hasStockEntry(String productId) {
    return _productStock.containsKey(productId);
  }

  // Get effective branchId - from AuthController for branch users, BranchStoreController for owner
  String? get _effectiveBranchId {
    // First try AuthController (for branch admin/staff)
    final authBranchId = _authController?.branchId;
    if (authBranchId != null) return authBranchId;

    // Fallback to BranchStoreController (for owner users with selected branch)
    if (Get.isRegistered<BranchStoreController>()) {
      final branchStore = Get.find<BranchStoreController>();
      final selectedId = branchStore.selectedBranchId.value;
      if (selectedId != null && selectedId.isNotEmpty) {
        return selectedId;
      }
    }
    return null;
  }

  List<Product> get _filteredProducts {
    if (_productController == null) return [];
    final query = _productSearchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      return _productController!.products.toList();
    }
    return _productController!.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(query) ||
              (p.sku?.toLowerCase().contains(query) ?? false),
        )
        .toList();
  }

  Map<String, dynamic>? get _selectedCustomer {
    if (_selectedCustomerId == null || _customerController == null) return null;
    return _customerController!.customers.firstWhereOrNull(
      (c) => c['id'] == _selectedCustomerId,
    );
  }

  void _calculateTotals() {
    setState(() {});
  }

  double get _subtotal {
    return _cart.fold(0.0, (sum, item) {
      return sum + (item.unitPrice * item.quantity) - (item.discount);
    });
  }

  double get _totalDiscount {
    return _cart.fold(0.0, (sum, item) => sum + item.discount) +
        _overallDiscount;
  }

  double get _gstAmount {
    if (_settings == null ||
        (_settings!['gst_enabled'] as bool? ?? false) == false ||
        (_settings!['gst_percentage'] as num? ?? 0).toDouble() == 0) {
      return 0.0;
    }

    final gstPercentage = (_settings!['gst_percentage'] as num).toDouble();
    final gstType = _settings!['gst_type'] as String? ?? 'exclusive';
    final amountAfterDiscount = _subtotal - _overallDiscount;

    if (gstType == 'inclusive') {
      return amountAfterDiscount * (gstPercentage / (100 + gstPercentage));
    } else {
      return amountAfterDiscount * (gstPercentage / 100);
    }
  }

  double get _totalAmount {
    final amountAfterDiscount = _subtotal - _overallDiscount;
    final gstType = _settings?['gst_type'] as String? ?? 'exclusive';
    if (gstType == 'exclusive') {
      return amountAfterDiscount + _gstAmount;
    }
    return amountAfterDiscount;
  }

  double get _profit {
    return _cart.fold(0.0, (sum, item) {
      final purchasePrice = item.product.purchasePrice ?? 0;
      final profitPerUnit = item.unitPrice - purchasePrice;
      return sum + (profitPerUnit * item.quantity);
    });
  }

  Future<void> _addProductToCart(Product product) async {
    final branchId = _effectiveBranchId;
    if (branchId == null) {
      Get.snackbar('Error', 'Branch not selected');
      return;
    }

    final availableStock = _getProductStock(product.id);

    if (product.stockTrackingType == StockTrackingType.serial) {
      // Open serial selection dialog
      await _showSerialSelectionDialog(product, branchId);
    } else {
      // Quantity-based product
      if (availableStock == 0) {
        Get.snackbar('Error', '${product.name} is out of stock');
        return;
      }

      final existingIndex = _cart.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (existingIndex >= 0) {
        final cartItem = _cart[existingIndex];
        if (cartItem.quantity >= cartItem.availableStock) {
          Get.snackbar(
            'Error',
            'Insufficient stock. Available: ${cartItem.availableStock}',
          );
          return;
        }
        _cart[existingIndex] = CartItem(
          product: product,
          quantity: cartItem.quantity + 1,
          unitPrice: product.sellingPrice,
          discount: cartItem.discount,
          availableStock: cartItem.availableStock,
          selectedSerials: cartItem.selectedSerials,
        );
      } else {
        _cart.add(
          CartItem(
            product: product,
            quantity: 1,
            unitPrice: product.sellingPrice,
            discount: 0,
            availableStock: availableStock,
            selectedSerials: null,
          ),
        );
      }
      _calculateTotals();
      Get.snackbar('Success', '${product.name} added to cart');
    }
  }

  Future<void> _showSerialSelectionDialog(
    Product product,
    String branchId,
  ) async {
    try {
      final serialNumbers = await _stockDataSource.getAvailableSerialNumbers(
        branchId: branchId,
        productId: product.id,
      );

      if (serialNumbers.isEmpty) {
        Get.snackbar(
          'Error',
          'No available serial numbers for ${product.name}',
        );
        return;
      }

      final existingItem = _cart.firstWhereOrNull(
        (item) => item.product.id == product.id,
      );
      final selectedSerials = existingItem?.selectedSerials ?? <String>[];

      final result = await Get.dialog<List<String>>(
        SerialSelectionDialog(
          product: product,
          serialNumbers: serialNumbers,
          selectedSerials: selectedSerials,
        ),
      );

      if (result != null && result.isNotEmpty) {
        final existingIndex = _cart.indexWhere(
          (item) => item.product.id == product.id,
        );
        final availableCount = serialNumbers.length;

        if (existingIndex >= 0) {
          _cart[existingIndex] = CartItem(
            product: product,
            quantity: result.length,
            unitPrice: _cart[existingIndex].unitPrice,
            discount: _cart[existingIndex].discount,
            availableStock: availableCount,
            selectedSerials: result,
          );
        } else {
          _cart.add(
            CartItem(
              product: product,
              quantity: result.length,
              unitPrice: product.sellingPrice,
              discount: 0,
              availableStock: availableCount,
              selectedSerials: result,
            ),
          );
        }
        _calculateTotals();
        Get.snackbar(
          'Success',
          '${result.length} ${product.name} added to cart',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load serial numbers: $e');
    }
  }

  void _updateCartItem(
    int index, {
    int? quantity,
    double? unitPrice,
    double? discount,
  }) {
    final item = _cart[index];
    final newQuantity = quantity ?? item.quantity;
    final newUnitPrice = unitPrice ?? item.unitPrice;
    final newDiscount = discount ?? item.discount;

    if (newQuantity <= 0) {
      _cart.removeAt(index);
    } else {
      if (item.product.stockTrackingType == StockTrackingType.quantity) {
        if (newQuantity > item.availableStock) {
          Get.snackbar(
            'Error',
            'Insufficient stock. Available: ${item.availableStock}',
          );
          return;
        }
      }
      _cart[index] = CartItem(
        product: item.product,
        quantity: newQuantity,
        unitPrice: newUnitPrice,
        discount: newDiscount,
        availableStock: item.availableStock,
        selectedSerials: item.selectedSerials,
      );
    }
    _calculateTotals();
  }

  void _removeFromCart(int index) {
    _cart.removeAt(index);
    _calculateTotals();
  }

  Future<void> _createOrder() async {
    if (_authController == null) return;
    final branchId = _authController!.branchId;
    if (branchId == null) {
      Get.snackbar('Error', 'Branch not selected');
      return;
    }

    if (_cart.isEmpty) {
      Get.snackbar('Error', 'Please add at least one product to cart');
      return;
    }

    // Validate cart items
    for (final item in _cart) {
      if (item.quantity <= 0) {
        Get.snackbar('Error', 'Invalid quantity for ${item.product.name}');
        return;
      }

      if (item.product.stockTrackingType == StockTrackingType.serial) {
        if (item.selectedSerials == null || item.selectedSerials!.isEmpty) {
          Get.snackbar(
            'Error',
            'Please select serial numbers for ${item.product.name}',
          );
          return;
        }
        if (item.selectedSerials!.length != item.quantity) {
          Get.snackbar('Error', 'Quantity mismatch for ${item.product.name}');
          return;
        }
      } else {
        if (item.quantity > item.availableStock) {
          Get.snackbar(
            'Error',
            'Insufficient stock for ${item.product.name}. Available: ${item.availableStock}',
          );
          return;
        }
      }
    }

    if (_billingController == null) {
      Get.snackbar('Error', 'Billing controller not available');
      return;
    }

    try {
      _billingController!.isLoading.value = true;

      // Convert cart items to bill items
      final billItems = _cart.map((item) {
        // Calculate GST for this item
        double itemGst = 0;
        if (_settings != null &&
            (_settings!['gst_enabled'] as bool? ?? false) &&
            (_settings!['gst_percentage'] as num? ?? 0).toDouble() > 0) {
          final gstPercentage = (_settings!['gst_percentage'] as num)
              .toDouble();
          final gstType = _settings!['gst_type'] as String? ?? 'exclusive';
          final itemSubtotal = (item.unitPrice * item.quantity) - item.discount;

          if (gstType == 'inclusive') {
            itemGst = itemSubtotal * (gstPercentage / (100 + gstPercentage));
          } else {
            itemGst = itemSubtotal * (gstPercentage / 100);
          }
        }

        final itemSubtotal = (item.unitPrice * item.quantity) - item.discount;
        double itemTotal = itemSubtotal;
        if (_settings?['gst_type'] == 'exclusive') {
          itemTotal += itemGst;
        }

        final purchasePrice = item.product.purchasePrice ?? 0;
        final profitPerUnit = item.unitPrice - purchasePrice;
        final itemProfit = profitPerUnit * item.quantity;

        return BillItem(
          id: '',
          billId: '',
          productId: item.product.id,
          productName: item.product.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          purchasePrice: purchasePrice,
          gstRate: (_settings?['gst_percentage'] as num?)?.toDouble() ?? 0,
          gstAmount: itemGst,
          discount: item.discount,
          profitAmount: itemProfit,
          totalAmount: itemTotal,
          serialNumbers: item.selectedSerials,
        );
      }).toList();

      // Calculate paid amount based on payment mode
      final paidAmount = _paymentMode == PaymentMode.credit
          ? 0.0
          : _totalAmount;

      final customerName = _selectedCustomer?['name'] as String?;
      final customerPhone = _selectedCustomer?['phone'] as String?;
      final finalCustomerName =
          customerName ??
          (_customerNameController.text.trim().isNotEmpty
              ? _customerNameController.text.trim()
              : null);
      final finalCustomerPhone =
          customerPhone ??
          (_customerPhoneController.text.trim().isNotEmpty
              ? _customerPhoneController.text.trim()
              : null);

      await _billingController!.createBillWithItems(
        branchId: branchId,
        items: billItems,
        customerId: _selectedCustomerId,
        customerName: finalCustomerName,
        customerPhone: finalCustomerPhone,
        subtotal: _subtotal,
        gstAmount: _gstAmount,
        discount: _totalDiscount,
        totalAmount: _totalAmount,
        profitAmount: _profit,
        paidAmount: paidAmount,
        paymentMode: _paymentMode,
      );

      Get.snackbar(
        'Success',
        'Order created successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Clear cart and reset
      _cart.clear();
      _selectedCustomerId = null;
      _customerNameController.clear();
      _customerPhoneController.clear();
      _overallDiscountController.clear();
      _overallDiscount = 0.0;
      _paymentMode = PaymentMode.cash;
      _calculateTotals();

      // Reload stock
      await _loadStock();

      // Navigate back
      Get.back();
    } catch (e) {
      Get.snackbar('Error', 'Failed to create order: ${e.toString()}');
    } finally {
      if (_billingController != null) {
        _billingController!.isLoading.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoadingSettings) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isMobile) {
      return _buildMobileLayout(theme);
    } else {
      return _buildDesktopLayout(theme);
    }
  }

  // Mobile Layout - Simple & Powerful POS UX
  Widget _buildMobileLayout(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        actions: [
          if (_cart.isNotEmpty)
            TextButton.icon(
              onPressed: () {
                _cart.clear();
                _calculateTotals();
                setState(() {});
              },
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
        ],
      ),
      body: Column(
        children: [
          // Customer Selection Bar
          _buildSimpleCustomerBar(theme),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _productSearchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _productSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _productSearchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          // Product List
          Expanded(child: _buildSimpleProductList(theme)),

          // Cart Summary Row (if items in cart)
          if (_cart.isNotEmpty) _buildCartSummaryRow(theme),

          // Checkout Bar
          if (_cart.isNotEmpty) _buildEnhancedCheckoutBar(theme),
        ],
      ),
    );
  }

  // Simple Customer Selection Bar
  Widget _buildSimpleCustomerBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Customer Icon
          Icon(Icons.person, color: theme.primaryColor, size: 24),
          const SizedBox(width: 10),

          // Customer Info
          Expanded(
            child: GestureDetector(
              onTap: _showSimpleCustomerPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCustomer != null
                            ? '${_selectedCustomer!['name']}${_selectedCustomer!['phone'] != null ? ' • ${_selectedCustomer!['phone']}' : ''}'
                            : 'Walk-in Customer',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _selectedCustomer != null
                              ? theme.primaryColor
                              : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
          ),

          // Clear customer button
          if (_selectedCustomer != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                setState(() {
                  _selectedCustomerId = null;
                  _customerNameController.clear();
                  _customerPhoneController.clear();
                });
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  // Simple Customer Picker with Search
  void _showSimpleCustomerPicker() {
    final searchController = TextEditingController();

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setBottomSheetState) {
          // Filter customers based on search query
          final searchQuery = searchController.text.toLowerCase().trim();
          final allCustomers = _customerController?.customers ?? [];
          final filteredCustomers = searchQuery.isEmpty
              ? allCustomers
              : allCustomers.where((customer) {
                  final name =
                      (customer['name'] as String?)?.toLowerCase() ?? '';
                  final phone =
                      (customer['phone'] as String?)?.toLowerCase() ?? '';
                  return name.contains(searchQuery) ||
                      phone.contains(searchQuery);
                }).toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Select Customer',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setBottomSheetState(() {});
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => setBottomSheetState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                // Walk-in option (only show when not searching)
                if (searchQuery.isEmpty) ...[
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Walk-in Customer'),
                    subtitle: const Text('No customer selected'),
                    onTap: () {
                      setState(() {
                        _selectedCustomerId = null;
                        _customerNameController.clear();
                        _customerPhoneController.clear();
                      });
                      Get.back();
                    },
                  ),
                  const Divider(),
                ],
                // Customer List
                Expanded(
                  child: filteredCustomers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.people_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                searchQuery.isNotEmpty
                                    ? 'No customers found for "$searchQuery"'
                                    : 'No customers',
                                style: TextStyle(color: Colors.grey[600]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = filteredCustomers[index];
                            final isSelected =
                                _selectedCustomerId == customer['id'];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300],
                                child: Text(
                                  (customer['name'] as String?)
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      '?',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                              title: Text(customer['name'] ?? 'Unknown'),
                              subtitle: Text(customer['phone'] ?? 'No phone'),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: Theme.of(context).primaryColor,
                                    )
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedCustomerId = customer['id'];
                                  _customerNameController.text =
                                      customer['name'] ?? '';
                                  _customerPhoneController.text =
                                      customer['phone'] ?? '';
                                });
                                Get.back();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // Cart Summary Row (replaces pills)
  Widget _buildCartSummaryRow(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.05),
        border: Border(
          top: BorderSide(color: theme.primaryColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shopping_cart, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '${_cart.fold<int>(0, (sum, item) => sum + item.quantity)} items',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.primaryColor,
            ),
          ),
          const Spacer(),
          // Show product names
          Expanded(
            flex: 2,
            child: Text(
              _cart
                  .map((item) => '${item.product.name} ×${item.quantity}')
                  .join(', '),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced Checkout Bar
  Widget _buildEnhancedCheckoutBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Order Summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedCustomer != null)
                    Text(
                      '${_selectedCustomer!['name']}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
            // Confirm Button
            ElevatedButton(
              onPressed: () => _showEnhancedCheckoutDialog(theme),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Place Order',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced Checkout Dialog
  void _showEnhancedCheckoutDialog(ThemeData theme) {
    PaymentMode selectedPaymentMode = _paymentMode;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Complete Order'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer
                  _buildDialogRow(
                    'Customer',
                    _selectedCustomer != null
                        ? _selectedCustomer!['name']
                        : 'Walk-in',
                    Icons.person,
                  ),
                  const Divider(),

                  // Items
                  _buildDialogRow(
                    'Items',
                    '${_cart.fold<int>(0, (sum, item) => sum + item.quantity)} products',
                    Icons.shopping_bag,
                  ),
                  const SizedBox(height: 8),

                  // Item breakdown
                  ...(_cart.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(left: 32, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} ×${item.quantity}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${(item.quantity * item.unitPrice).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )),

                  const Divider(),

                  // Payment Mode
                  const Text(
                    'Payment Mode',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPaymentChip(
                        PaymentMode.cash,
                        'Cash',
                        selectedPaymentMode,
                        (mode) {
                          setDialogState(() => selectedPaymentMode = mode);
                        },
                      ),
                      _buildPaymentChip(
                        PaymentMode.upi,
                        'UPI',
                        selectedPaymentMode,
                        (mode) {
                          setDialogState(() => selectedPaymentMode = mode);
                        },
                      ),
                      _buildPaymentChip(
                        PaymentMode.card,
                        'Card',
                        selectedPaymentMode,
                        (mode) {
                          setDialogState(() => selectedPaymentMode = mode);
                        },
                      ),
                    ],
                  ),

                  const Divider(),

                  // Totals
                  _buildDialogRow(
                    'Subtotal',
                    '₹${_subtotal.toStringAsFixed(2)}',
                    null,
                  ),
                  if (_gstAmount > 0)
                    _buildDialogRow(
                      'GST',
                      '₹${_gstAmount.toStringAsFixed(2)}',
                      null,
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '₹${_totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _paymentMode = selectedPaymentMode;
                  Get.back();
                  _createOrder();
                },
                child: const Text('Confirm & Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogRow(String label, String value, IconData? icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          Text(label, style: TextStyle(color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPaymentChip(
    PaymentMode mode,
    String label,
    PaymentMode selected,
    Function(PaymentMode) onTap,
  ) {
    final isSelected = mode == selected;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(mode),
    );
  }

  // Simple Product List (ListTile style)
  Widget _buildSimpleProductList(ThemeData theme) {
    return Obx(() {
      if (_productController == null) {
        return const Center(child: Text('Loading...'));
      }
      if (_productController!.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final products = _filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No products found',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildSimpleProductTile(product, theme);
        },
      );
    });
  }

  // Simple Product Tile
  Widget _buildSimpleProductTile(Product product, ThemeData theme) {
    final stock = _getProductStock(product.id);
    final isOutOfStock = stock <= 0;
    final cartItem = _cart.firstWhereOrNull((c) => c.product.id == product.id);
    final isInCart = cartItem != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      title: Text(
        product.name,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isOutOfStock ? Colors.grey : null,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isOutOfStock ? 'Out of stock' : 'Stock: $stock',
        style: TextStyle(
          color: isOutOfStock ? Colors.red[400] : Colors.grey[600],
          fontSize: 12,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price
          Text(
            '₹${product.sellingPrice.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          // Add/Quantity Control
          if (isInCart)
            _buildInlineQuantityControl(cartItem!, theme)
          else
            IconButton(
              onPressed: isOutOfStock ? null : () => _addProductToCart(product),
              icon: Icon(
                Icons.add_circle,
                color: isOutOfStock ? Colors.grey : theme.primaryColor,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  // Inline Quantity Control (for product tile)
  Widget _buildInlineQuantityControl(CartItem item, ThemeData theme) {
    final index = _cart.indexOf(item);
    return Container(
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () {
              _updateCartItem(index, quantity: item.quantity - 1);
              setState(() {});
            },
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
          Text(
            '${item.quantity}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: item.quantity >= item.availableStock
                ? null
                : () {
                    _updateCartItem(index, quantity: item.quantity + 1);
                    setState(() {});
                  },
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // Cart Pills Row
  Widget _buildCartPillsRow(ThemeData theme) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _cart.length,
        itemBuilder: (context, index) {
          final item = _cart[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Chip(
                label: Text(
                  '${item.product.name.length > 10 ? item.product.name.substring(0, 10) : item.product.name} ×${item.quantity}',
                  style: const TextStyle(fontSize: 12),
                ),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  _removeFromCart(index);
                  setState(() {});
                },
                backgroundColor: theme.primaryColor.withOpacity(0.1),
              ),
            ),
          );
        },
      ),
    );
  }

  // Simple Checkout Bar
  Widget _buildSimpleCheckoutBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cart Summary
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_cart.fold<int>(0, (sum, item) => sum + item.quantity)} items',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Confirm Button
            ElevatedButton.icon(
              onPressed: () => _showConfirmOrderDialog(theme),
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Order'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Confirm Order Dialog
  void _showConfirmOrderDialog(ThemeData theme) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirm Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items: ${_cart.fold<int>(0, (sum, item) => sum + item.quantity)}',
            ),
            const SizedBox(height: 8),
            Text('Subtotal: ₹${_subtotal.toStringAsFixed(2)}'),
            if (_gstAmount > 0) Text('GST: ₹${_gstAmount.toStringAsFixed(2)}'),
            const Divider(),
            Text(
              'Total: ₹${_totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _createOrder();
            },
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  // Mobile Customer Selection Bar
  Widget _buildMobileCustomerBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[700]!
                : Colors.grey[300]!,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: _selectedCustomer != null
                ? InkWell(
                    onTap: _showMobileCustomerSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${_selectedCustomer!['name']}${_selectedCustomer!['phone'] != null ? ' (${_selectedCustomer!['phone']})' : ''}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCustomerId = null;
                                _customerNameController.clear();
                                _customerPhoneController.clear();
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : InkWell(
                    onTap: _showMobileCustomerSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Walk-in Customer',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 32,
            child: OutlinedButton.icon(
              onPressed: () => _showAddCustomerDialog(theme),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Customer Selector Bottom Sheet
  void _showMobileCustomerSelector() {
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Select Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Walk-in Customer'),
              selected: _selectedCustomerId == null,
              onTap: () {
                setState(() {
                  _selectedCustomerId = null;
                  _customerNameController.clear();
                  _customerPhoneController.clear();
                });
                Get.back();
              },
            ),
            const Divider(),
            Expanded(
              child: Obx(() {
                if (_customerController == null) {
                  return const Center(child: Text('Loading...'));
                }
                final customers = _customerController!.customers;
                if (customers.isEmpty) {
                  return const Center(child: Text('No customers found'));
                }
                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final name = customer['name'] as String;
                    final phone = customer['phone'] as String?;
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(name),
                      subtitle: phone != null ? Text(phone) : null,
                      selected: _selectedCustomerId == customer['id'],
                      onTap: () {
                        setState(() {
                          _selectedCustomerId = customer['id'] as String;
                          _customerNameController.text = name;
                          _customerPhoneController.text = phone ?? '';
                        });
                        Get.back();
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Mobile Product Grid (2 columns)
  Widget _buildMobileProductGrid(ThemeData theme) {
    return Obx(() {
      if (_productController == null) {
        return const Center(child: Text('Product controller not available'));
      }
      if (_productController!.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final products = _filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: theme.primaryColor.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                _productSearchController.text.isEmpty
                    ? 'No products available'
                    : 'No products found',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildMobileProductCard(product, theme);
        },
      );
    });
  }

  // Mobile Product Card (Compact)
  Widget _buildMobileProductCard(Product product, ThemeData theme) {
    final availableStock = _getProductStock(product.id);
    final cartItem = _cart.firstWhereOrNull(
      (item) => item.product.id == product.id,
    );
    final isInCart = cartItem != null;
    final cartQuantity = cartItem?.quantity ?? 0;
    final isOutOfStock = availableStock == 0;
    final isMaxed = isInCart && cartQuantity >= cartItem.availableStock;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isOutOfStock || isMaxed
            ? null
            : () => _addProductToCart(product),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Price
              Text(
                '₹${product.sellingPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              // Stock and Cart Status Row
              Row(
                children: [
                  // Stock Chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOutOfStock ? 'Out' : 'Stock: $availableStock',
                      style: TextStyle(
                        fontSize: 10,
                        color: isOutOfStock
                            ? Colors.red
                            : Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Add/Cart Badge
                  if (isInCart)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isMaxed ? 'Max' : '+$cartQuantity',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (!isOutOfStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '+Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Checkout Bar
  Widget _buildMobileCheckoutBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cart Summary
            Expanded(
              child: InkWell(
                onTap: () => _showMobileCartSheet(theme),
                child: Row(
                  children: [
                    Badge(
                      label: Text('${_cart.length}'),
                      child: const Icon(Icons.shopping_cart, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_cart.length} item${_cart.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          '₹${_totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.keyboard_arrow_up, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
            // Checkout Button
            ElevatedButton(
              onPressed: _cart.isEmpty
                  ? null
                  : () => _showMobileCheckoutSheet(theme),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Checkout',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Cart Sheet
  void _showMobileCartSheet(ThemeData theme) {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cart (${_cart.length} items)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _cart.clear();
                          _calculateTotals();
                          setSheetState(() {});
                          Get.back();
                        },
                        child: const Text(
                          'Clear All',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Cart Items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return _buildMobileCartItemWithState(
                        item,
                        index,
                        theme,
                        setSheetState,
                      );
                    },
                  ),
                ),
                // Summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('₹${_subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      if (_gstAmount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GST (${(_settings?['gst_percentage'] as num?)?.toStringAsFixed(1) ?? '0'}%)',
                            ),
                            Text('₹${_gstAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '₹${_totalAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  // Mobile Cart Item with local state updater
  Widget _buildMobileCartItemWithState(
    CartItem item,
    int index,
    ThemeData theme,
    StateSetter setSheetState,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and Remove
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _removeFromCart(index);
                    setSheetState(() {});
                    setState(() {});
                    if (_cart.isEmpty) Get.back();
                  },
                  child: const Icon(Icons.close, size: 18, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quantity Controls and Total
            Row(
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          _updateCartItem(index, quantity: item.quantity - 1);
                          setSheetState(() {});
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: item.quantity >= item.availableStock
                            ? null
                            : () {
                                _updateCartItem(
                                  index,
                                  quantity: item.quantity + 1,
                                );
                                setSheetState(() {});
                                setState(() {});
                              },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: item.quantity >= item.availableStock
                                ? Colors.grey
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '× ₹${item.unitPrice.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  '₹${((item.quantity * item.unitPrice) - item.discount).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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

  // Mobile Checkout Sheet
  void _showMobileCheckoutSheet(ThemeData theme) {
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Complete Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Customer Info
                        if (_selectedCustomer != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_selectedCustomer!['name']}${_selectedCustomer!['phone'] != null ? ' • ${_selectedCustomer!['phone']}' : ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),
                        // Payment Mode
                        const Text(
                          'Payment Mode',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: PaymentMode.values.map((mode) {
                            final isSelected = _paymentMode == mode;
                            return ChoiceChip(
                              label: Text(mode.value.toUpperCase()),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setSheetState(() => _paymentMode = mode);
                                  setState(() {});
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        // Discount
                        TextField(
                          controller: _overallDiscountController,
                          decoration: const InputDecoration(
                            labelText: 'Overall Discount (₹)',
                            isDense: true,
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final discount = double.tryParse(value) ?? 0.0;
                            if (discount >= 0 && discount <= _subtotal) {
                              setSheetState(() => _overallDiscount = discount);
                              setState(() {});
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        // Order Summary
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRowSimple(
                                'Subtotal',
                                '₹${_subtotal.toStringAsFixed(2)}',
                              ),
                              if (_totalDiscount > 0)
                                _buildSummaryRowSimple(
                                  'Discount',
                                  '-₹${_totalDiscount.toStringAsFixed(2)}',
                                  color: Colors.red,
                                ),
                              if (_gstAmount > 0)
                                _buildSummaryRowSimple(
                                  'GST',
                                  '₹${_gstAmount.toStringAsFixed(2)}',
                                ),
                              const Divider(),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '₹${_totalAmount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Create Order Button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: Obx(() {
                        final isLoading =
                            _billingController?.isLoading.value ?? false;
                        return ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  Get.back();
                                  await _createOrder();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Create Order',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSummaryRowSimple(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  // Desktop Layout - Two columns
  Widget _buildDesktopLayout(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        actions: [
          if (_cart.isNotEmpty)
            IconButton(
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
                          _cart.clear();
                          _calculateTotals();
                          Get.back();
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: Row(
        children: [
          // Left Column - Customer & Products
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildCustomerSection(theme, compact: false),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _productSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search products by name or SKU...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _productSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _productSearchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(child: _buildProductsList(theme, compact: false)),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right Column - Cart & Summary
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(child: _buildCart(theme, compact: false)),
                const Divider(height: 1),
                if (_cart.isNotEmpty) _buildOrderSummary(theme, compact: false),
                if (_cart.isNotEmpty) _buildCreateOrderButton(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerSection(ThemeData theme, {required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact)
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Customer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          if (!compact) const SizedBox(height: 12),
          // Customer Dropdown
          Obx(() {
            if (_customerController == null) {
              return DropdownButtonFormField<String>(
                items: const [],
                onChanged: null,
              );
            }
            final customers = _customerController!.customers;
            return DropdownButtonFormField<String>(
              value: _selectedCustomerId,
              decoration: InputDecoration(
                hintText: 'Select customer or walk-in',
                isDense: compact,
                contentPadding: compact
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                    : null,
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Walk-in Customer'),
                ),
                ...customers.map((customer) {
                  final name = customer['name'] as String;
                  final phone = customer['phone'] as String?;
                  return DropdownMenuItem<String>(
                    value: customer['id'] as String,
                    child: Text(phone != null ? '$name ($phone)' : name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCustomerId = value;
                  if (value != null) {
                    final customer = customers.firstWhere(
                      (c) => c['id'] == value,
                    );
                    _customerNameController.text =
                        customer['name'] as String? ?? '';
                    _customerPhoneController.text =
                        customer['phone'] as String? ?? '';
                  } else {
                    _customerNameController.clear();
                    _customerPhoneController.clear();
                  }
                });
              },
            );
          }),
          const SizedBox(height: 8),
          // Add Customer Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showAddCustomerDialog(theme),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New Customer'),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, compact ? 40 : 44),
              ),
            ),
          ),
          // Selected Customer Info
          if (_selectedCustomer != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCustomer!['name'] as String? ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                            fontSize: compact ? 14 : 16,
                          ),
                        ),
                        if (_selectedCustomer!['phone'] != null)
                          Text(
                            _selectedCustomer!['phone'] as String,
                            style: TextStyle(
                              fontSize: compact ? 11 : 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddCustomerDialog(ThemeData theme) async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    await Get.dialog(
      Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Customer',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'Customer name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Phone number',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  Obx(() {
                    if (_customerController == null) {
                      return const SizedBox.shrink();
                    }
                    final isLoading = _customerController!.isLoading.value;
                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (nameController.text.trim().isEmpty) {
                                Get.snackbar(
                                  'Error',
                                  'Customer name is required',
                                );
                                return;
                              }
                              if (_customerController == null) return;
                              final success = await _customerController!
                                  .createCustomer(
                                    name: nameController.text.trim(),
                                    phone: phoneController.text.trim().isEmpty
                                        ? null
                                        : phoneController.text.trim(),
                                  );
                              if (success) {
                                Get.back();
                                Get.snackbar(
                                  'Success',
                                  'Customer added successfully',
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Customer'),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsList(ThemeData theme, {required bool compact}) {
    return Obx(() {
      if (_productController == null) {
        return const Center(child: Text('Product controller not available'));
      }
      if (_productController!.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final products = _filteredProducts;
      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: compact ? 48 : 64,
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text('No products found', style: theme.textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                _productSearchController.text.isEmpty
                    ? 'No products available'
                    : 'Try adjusting your search',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(compact ? 8 : 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final availableStock = _getProductStock(product.id);
          final cartItem = _cart.firstWhereOrNull(
            (item) => item.product.id == product.id,
          );
          final isInCart = cartItem != null;
          final cartQuantity = cartItem?.quantity ?? 0;
          final cartItemAvailableStock =
              cartItem?.availableStock ?? availableStock;

          return Card(
            margin: EdgeInsets.only(bottom: compact ? 6 : 8),
            child: ListTile(
              contentPadding: EdgeInsets.all(compact ? 8 : 12),
              title: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 14 : 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.sellingPrice.toStringAsFixed(2)} / ${product.unit}',
                    style: TextStyle(fontSize: compact ? 12 : 14),
                  ),
                  if (product.stockTrackingType == StockTrackingType.serial)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tag,
                            size: 12,
                            color: Colors.purple.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Serial',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.purple.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Stock: $availableStock ${product.unit}',
                      style: TextStyle(
                        fontSize: compact ? 11 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  if (isInCart)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'In cart: $cartQuantity',
                        style: TextStyle(
                          fontSize: compact ? 11 : 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: SizedBox(
                width: compact ? 80 : 100,
                child: ElevatedButton(
                  onPressed:
                      availableStock == 0 ||
                          (isInCart && cartQuantity >= cartItemAvailableStock)
                      ? null
                      : () => _addProductToCart(product),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isInCart
                        ? Colors.green
                        : theme.primaryColor,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 12,
                      vertical: compact ? 8 : 12,
                    ),
                  ),
                  child: Text(
                    isInCart
                        ? (cartQuantity >= cartItemAvailableStock
                              ? 'Max'
                              : '+1')
                        : availableStock == 0
                        ? 'Out'
                        : 'Add',
                    style: TextStyle(fontSize: compact ? 12 : 14),
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildCart(ThemeData theme, {required bool compact}) {
    if (_cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: compact ? 48 : 64,
              color: theme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text('Cart is empty', style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text(
              'Add products to get started',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(compact ? 8 : 16),
      itemCount: _cart.length,
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Card(
          margin: EdgeInsets.only(bottom: compact ? 6 : 8),
          child: Padding(
            padding: EdgeInsets.all(compact ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: compact ? 14 : 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.selectedSerials != null &&
                              item.selectedSerials!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${item.selectedSerials!.length} serial${item.selectedSerials!.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: compact ? 11 : 12,
                                  color: Colors.purple.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeFromCart(index),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Quantity Controls (for quantity-based products)
                if (item.product.stockTrackingType ==
                    StockTrackingType.quantity)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () =>
                            _updateCartItem(index, quantity: item.quantity - 1),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          minimumSize: const Size(36, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: TextStyle(
                            fontSize: compact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: item.quantity >= item.availableStock
                            ? null
                            : () => _updateCartItem(
                                index,
                                quantity: item.quantity + 1,
                              ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          minimumSize: const Size(36, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '× ₹${item.unitPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: compact ? 12 : 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Serial Selection Button (for serial-based products)
                if (item.product.stockTrackingType == StockTrackingType.serial)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (_authController == null) return;
                        final branchId = _authController!.branchId;
                        if (branchId != null) {
                          await _showSerialSelectionDialog(
                            item.product,
                            branchId,
                          );
                        }
                      },
                      icon: const Icon(Icons.tag, size: 16),
                      label: Text('Select Serials (${item.quantity})'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, compact ? 36 : 40),
                      ),
                    ),
                  ),
                // Price and Discount Editing
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Price (₹)',
                          isDense: compact,
                          contentPadding: EdgeInsets.all(compact ? 8 : 12),
                        ),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(
                                text: item.unitPrice.toStringAsFixed(2),
                              )
                              ..selection = TextSelection.collapsed(
                                offset: item.unitPrice
                                    .toStringAsFixed(2)
                                    .length,
                              ),
                        onChanged: (value) {
                          final newPrice =
                              double.tryParse(value) ?? item.unitPrice;
                          if (newPrice >= 0) {
                            _updateCartItem(index, unitPrice: newPrice);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Discount (₹)',
                          isDense: compact,
                          contentPadding: EdgeInsets.all(compact ? 8 : 12),
                        ),
                        keyboardType: TextInputType.number,
                        controller:
                            TextEditingController(
                                text: item.discount.toStringAsFixed(2),
                              )
                              ..selection = TextSelection.collapsed(
                                offset: item.discount.toStringAsFixed(2).length,
                              ),
                        onChanged: (value) {
                          final newDiscount =
                              double.tryParse(value) ?? item.discount;
                          if (newDiscount >= 0) {
                            _updateCartItem(index, discount: newDiscount);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: compact ? 12 : 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '₹${((item.quantity * item.unitPrice) - item.discount).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: compact ? 14 : 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderSummary(ThemeData theme, {required bool compact}) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Order Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Subtotal',
            '₹${_subtotal.toStringAsFixed(2)}',
            theme,
            compact: compact,
          ),
          if (_totalDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow(
              'Total Discount',
              '-₹${_totalDiscount.toStringAsFixed(2)}',
              theme,
              color: Colors.red,
              compact: compact,
            ),
          ],
          // Overall Discount Input
          const SizedBox(height: 8),
          TextField(
            controller: _overallDiscountController,
            decoration: InputDecoration(
              labelText: 'Overall Discount (₹)',
              isDense: compact,
              contentPadding: EdgeInsets.all(compact ? 8 : 12),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final discount = double.tryParse(value) ?? 0.0;
              if (discount >= 0 && discount <= _subtotal) {
                setState(() {
                  _overallDiscount = discount;
                });
              }
            },
          ),
          if (_gstAmount > 0) ...[
            const SizedBox(height: 6),
            _buildSummaryRow(
              'GST (${(_settings?['gst_percentage'] as num?)?.toStringAsFixed(1) ?? '0'}%)',
              '₹${_gstAmount.toStringAsFixed(2)}',
              theme,
              compact: compact,
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit:',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 14 : 16,
                ),
              ),
              Text(
                '₹${_profit.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 14 : 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Payment Mode
          Text(
            'Payment Mode',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<PaymentMode>(
            value: _paymentMode,
            decoration: InputDecoration(
              isDense: compact,
              contentPadding: EdgeInsets.all(compact ? 8 : 12),
            ),
            items: PaymentMode.values.map((mode) {
              return DropdownMenuItem<PaymentMode>(
                value: mode,
                child: Text(mode.value.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _paymentMode = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
    required bool compact,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: compact ? 13 : 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateOrderButton(ThemeData theme) {
    return Obx(() {
      if (_billingController == null) {
        return const SizedBox.shrink();
      }
      final isLoading = _billingController!.isLoading.value;
      return Container(
        padding: EdgeInsets.all(_isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: _isMobile ? 50 : 56,
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _createOrder,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.receipt),
              label: Text(
                isLoading ? 'Creating Order...' : 'Create Order',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// Cart Item Model
class CartItem {
  final Product product;
  final int quantity;
  final double unitPrice;
  final double discount;
  final int availableStock;
  final List<String>? selectedSerials;

  CartItem({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.availableStock,
    this.selectedSerials,
  });
}

// Serial Selection Dialog
class SerialSelectionDialog extends StatefulWidget {
  final Product product;
  final List<ProductSerialNumber> serialNumbers;
  final List<String> selectedSerials;

  const SerialSelectionDialog({
    super.key,
    required this.product,
    required this.serialNumbers,
    required this.selectedSerials,
  });

  @override
  State<SerialSelectionDialog> createState() => _SerialSelectionDialogState();
}

class _SerialSelectionDialogState extends State<SerialSelectionDialog> {
  late List<String> _selectedSerials;

  @override
  void initState() {
    super.initState();
    _selectedSerials = List.from(widget.selectedSerials);
  }

  void _toggleSerial(String serial) {
    setState(() {
      if (_selectedSerials.contains(serial)) {
        _selectedSerials.remove(serial);
      } else {
        _selectedSerials.add(serial);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      child: Container(
        width: isMobile ? double.infinity : 600,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Serial Numbers - ${widget.product.name}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: widget.serialNumbers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.tag,
                            size: 48,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No available serial numbers',
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: isMobile ? 2.0 : 2.5,
                      ),
                      itemCount: widget.serialNumbers.length,
                      itemBuilder: (context, index) {
                        final serial = widget.serialNumbers[index];
                        final isSelected = _selectedSerials.contains(
                          serial.serialNumber,
                        );
                        return InkWell(
                          onTap: () => _toggleSerial(serial.serialNumber),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade100
                                  : Colors.grey.shade100,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade500
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                serial.serialNumber,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.blue.shade900
                                      : Colors.grey.shade800,
                                  fontSize: isMobile ? 12 : 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_selectedSerials.isNotEmpty) ...[
              const Divider(height: 1),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${_selectedSerials.length} serial${_selectedSerials.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedSerials.map((serial) {
                        return Chip(
                          label: Text(
                            serial,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          backgroundColor: Colors.blue.shade200,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => _toggleSerial(serial),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedSerials.isEmpty
                        ? null
                        : () => Get.back(result: _selectedSerials),
                    child: Text('Add ${_selectedSerials.length} to Cart'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
