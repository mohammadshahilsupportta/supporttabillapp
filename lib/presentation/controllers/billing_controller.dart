import 'package:get/get.dart';

import '../../data/datasources/billing_datasource.dart';
import '../../data/models/bill_model.dart';
import '../../data/models/product_model.dart';
import 'auth_controller.dart';

class BillingController extends GetxController {
  final BillingDataSource _dataSource = BillingDataSource();

  // Observables
  final bills = <Bill>[].obs;
  final cartItems = <BillItem>[].obs;
  final isLoading = false.obs;
  final selectedPaymentMode = PaymentMode.cash.obs;

  // Cart totals
  final subtotal = 0.0.obs;
  final gstAmount = 0.0.obs;
  final totalAmount = 0.0.obs;
  final discount = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadBills();
  }

  // Load bills
  Future<void> loadBills() async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final branchId = authController.branchId;
      final tenantId = authController.tenantId;

      // For branch users, load bills for their branch
      if (branchId != null) {
        bills.value = await _dataSource.getBillsByBranch(
          branchId: branchId,
          limit: 100,
        );
      }
      // For tenant owners without a specific branch, load all bills
      else if (tenantId != null) {
        bills.value = await _dataSource.getBillsByTenant(
          tenantId: tenantId,
          limit: 100,
        );
      }
      // No access to bills
      else {
        bills.value = [];
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load bills: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  // Add product to cart
  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = cartItems.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      // Update quantity if product already in cart
      final existing = cartItems[existingIndex];
      final newQty = existing.quantity + quantity;
      final newGstAmount =
          (existing.unitPrice * newQty * existing.gstRate) / 100;
      final newTotal = (existing.unitPrice * newQty) + newGstAmount;

      cartItems[existingIndex] = BillItem(
        id: existing.id,
        billId: existing.billId,
        productId: existing.productId,
        productName: existing.productName,
        quantity: newQty,
        unitPrice: existing.unitPrice,
        purchasePrice: existing.purchasePrice,
        gstRate: existing.gstRate,
        gstAmount: newGstAmount,
        discount: 0,
        profitAmount: 0,
        totalAmount: newTotal,
      );
    } else {
      // Add new item to cart
      final itemGstAmount =
          (product.sellingPrice * quantity * product.gstRate) / 100;
      final itemTotal = (product.sellingPrice * quantity) + itemGstAmount;

      cartItems.add(
        BillItem(
          id: '',
          billId: '',
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          unitPrice: product.sellingPrice,
          purchasePrice: product.purchasePrice,
          gstRate: product.gstRate,
          gstAmount: itemGstAmount,
          discount: 0,
          profitAmount: 0,
          totalAmount: itemTotal,
        ),
      );
    }

    _calculateTotals();
  }

  // Update item quantity
  void updateQuantity(String productId, int quantity) {
    final index = cartItems.indexWhere((item) => item.productId == productId);

    if (index >= 0) {
      if (quantity <= 0) {
        cartItems.removeAt(index);
      } else {
        final item = cartItems[index];
        final newGstAmount = (item.unitPrice * quantity * item.gstRate) / 100;
        final newTotal = (item.unitPrice * quantity) + newGstAmount;

        cartItems[index] = BillItem(
          id: item.id,
          billId: item.billId,
          productId: item.productId,
          productName: item.productName,
          quantity: quantity,
          unitPrice: item.unitPrice,
          purchasePrice: item.purchasePrice,
          gstRate: item.gstRate,
          gstAmount: newGstAmount,
          discount: 0,
          profitAmount: 0,
          totalAmount: newTotal,
        );
      }

      _calculateTotals();
    }
  }

  // Remove item from cart
  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item.productId == productId);
    _calculateTotals();
  }

  // Clear cart
  void clearCart() {
    cartItems.clear();
    _calculateTotals();
  }

  // Calculate totals
  void _calculateTotals() {
    double sub = 0;
    double gst = 0;

    for (var item in cartItems) {
      sub += item.unitPrice * item.quantity;
      gst += item.gstAmount;
    }

    subtotal.value = sub;
    gstAmount.value = gst;
    totalAmount.value = sub + gst - discount.value;
  }

  // Apply discount
  void applyDiscount(double discountAmount) {
    discount.value = discountAmount;
    _calculateTotals();
  }

  // Create bill
  Future<bool> createBill({String? customerName, String? customerPhone}) async {
    if (cartItems.isEmpty) {
      Get.snackbar('Error', 'Cart is empty');
      return false;
    }

    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final branchId = authController.branchId;
      final userId = authController.currentUser.value?.id;

      if (branchId == null || userId == null) {
        throw Exception('Branch or user not found');
      }

      await _dataSource.createBill(
        branchId: branchId,
        items: cartItems,
        customerName: customerName,
        customerPhone: customerPhone,
        subtotal: subtotal.value,
        gstAmount: gstAmount.value,
        discount: discount.value,
        totalAmount: totalAmount.value,
        profitAmount: 0, // Calculate based on purchase prices
        paidAmount: totalAmount.value,
        paymentMode: selectedPaymentMode.value,
      );

      Get.snackbar(
        'Success',
        'Bill created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Clear cart after successful bill
      clearCart();

      // Reload bills
      await loadBills();

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to create bill: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get bill by ID
  Future<Bill?> getBillById(String billId) async {
    try {
      return await _dataSource.getBillById(billId);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load bill: ${e.toString()}');
      return null;
    }
  }

  // Get today's sales
  Future<Map<String, dynamic>> getTodaySales() async {
    try {
      final authController = Get.find<AuthController>();
      final branchId = authController.branchId;

      if (branchId == null) return {};

      return await _dataSource.getSalesStats(
        branchId: branchId,
        startDate: DateTime.now().subtract(const Duration(hours: 24)),
        endDate: DateTime.now(),
      );
    } catch (e) {
      return {};
    }
  }

  // Change payment mode
  void setPaymentMode(PaymentMode mode) {
    selectedPaymentMode.value = mode;
  }
}
