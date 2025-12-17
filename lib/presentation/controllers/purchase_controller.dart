import 'package:get/get.dart';

import '../../data/datasources/purchase_datasource.dart';
import 'auth_controller.dart';

class PurchaseController extends GetxController {
  final PurchaseDataSource _dataSource = PurchaseDataSource();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> purchases = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalPurchases = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadPurchases();
  }

  Future<void> loadPurchases() async {
    try {
      isLoading.value = true;

      final branchId = _authController.currentUser.value?.branchId;
      final tenantId = _authController.currentUser.value?.tenantId;
      final role = _authController.currentUser.value?.role.value;

      if (role == 'tenantOwner' && tenantId != null) {
        purchases.value = await _dataSource.getPurchasesByTenant(tenantId);
      } else if (branchId != null) {
        purchases.value = await _dataSource.getPurchases(branchId);
      } else {
        purchases.value = [];
      }

      // Calculate totals
      _calculateTotals();
    } catch (e) {
      print('[PurchaseController] Error loading purchases: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateTotals() {
    double total = 0;
    for (var purchase in purchases) {
      total += (purchase['total_amount'] as num?)?.toDouble() ?? 0;
    }
    totalPurchases.value = total;
  }

  Future<bool> createPurchase({
    required String supplierName,
    required String invoiceNumber,
    required String purchaseDate,
    required double totalAmount,
    required String paymentStatus,
    required String paymentMode,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      isLoading.value = true;

      final branchId = _authController.currentUser.value?.branchId;
      final userId = _authController.currentUser.value?.id;

      if (branchId == null) {
        throw Exception('Branch not found');
      }

      await _dataSource.createPurchase(
        branchId: branchId,
        supplierName: supplierName,
        invoiceNumber: invoiceNumber,
        purchaseDate: purchaseDate,
        totalAmount: totalAmount,
        paymentStatus: paymentStatus,
        paymentMode: paymentMode,
        items: items,
        notes: notes,
        createdBy: userId,
      );

      await loadPurchases();
      return true;
    } catch (e) {
      print('[PurchaseController] Error creating purchase: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshPurchases() async {
    await loadPurchases();
  }

  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}
