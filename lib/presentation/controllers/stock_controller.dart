import 'package:get/get.dart';

import '../../data/datasources/stock_datasource.dart';
import '../../data/models/stock_model.dart';
import 'auth_controller.dart';
import 'branch_store_controller.dart';

class StockController extends GetxController {
  final StockDataSource _dataSource = StockDataSource();

  // Observables
  final currentStock = <CurrentStock>[].obs;
  final stockLedger = <StockLedger>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Form fields for stock operations
  final selectedProductId = Rxn<String>();
  final quantity = 0.obs;
  final reason = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentStock();
  }

  // Load current stock for the branch
  Future<void> loadCurrentStock({String? branchId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      final userBranchId = branchId ?? authController.branchId;
      final tenantId = authController.tenantId;
      final user = authController.currentUser.value;

      // For tenant owners, use selected branch from BranchStoreController
      String? targetBranchId = userBranchId;
      if (user?.role.value == 'tenant_owner' && userBranchId == null) {
        try {
          if (Get.isRegistered<BranchStoreController>()) {
            final branchStore = Get.find<BranchStoreController>();
            targetBranchId = branchStore.selectedBranchId.value;
          }
        } catch (_) {
          // BranchStoreController not available
        }
      }

      // For branch users, load stock for their branch
      if (targetBranchId != null) {
        currentStock.value = await _dataSource.getCurrentStockByBranch(
          targetBranchId,
        );
      }
      // For tenant owners without a specific branch, load stock from all branches
      else if (tenantId != null) {
        currentStock.value = await _dataSource.getCurrentStockByTenant(
          tenantId,
        );
      }
      // No access to stock
      else {
        currentStock.value = [];
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load stock ledger history
  Future<void> loadStockLedger({String? productId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      final branchId = authController.branchId;

      if (branchId == null) {
        throw Exception('Branch ID not found');
      }

      stockLedger.value = await _dataSource.getStockLedger(
        branchId: branchId,
        productId: productId,
        limit: 100,
      );
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Stock In - Add stock
  Future<bool> addStockIn({
    required String productId,
    required int quantity,
    String? reason,
    String? branchId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      String? targetBranchId = branchId ?? authController.branchId;

      // For tenant owners, use selected branch from BranchStoreController
      if (user?.role.value == 'tenant_owner' && targetBranchId == null) {
        try {
          if (Get.isRegistered<BranchStoreController>()) {
            final branchStore = Get.find<BranchStoreController>();
            targetBranchId = branchStore.selectedBranchId.value;
          }
        } catch (_) {
          // BranchStoreController not available
        }
      }

      if (targetBranchId == null) {
        throw Exception('Branch ID not found. Please select a branch.');
      }

      await _dataSource.addStockIn(
        branchId: targetBranchId,
        productId: productId,
        quantity: quantity,
        reason: reason,
      );

      Get.snackbar(
        'Success',
        'Stock added successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reload stock
      await loadCurrentStock(branchId: targetBranchId);

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Stock Out - Remove stock
  Future<bool> addStockOut({
    required String productId,
    required int quantity,
    String? reason,
    String? branchId,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      String? targetBranchId = branchId ?? authController.branchId;

      // For tenant owners, use selected branch from BranchStoreController
      if (user?.role.value == 'tenant_owner' && targetBranchId == null) {
        try {
          if (Get.isRegistered<BranchStoreController>()) {
            final branchStore = Get.find<BranchStoreController>();
            targetBranchId = branchStore.selectedBranchId.value;
          }
        } catch (_) {
          // BranchStoreController not available
        }
      }

      if (targetBranchId == null) {
        throw Exception('Branch ID not found. Please select a branch.');
      }

      await _dataSource.addStockOut(
        branchId: targetBranchId,
        productId: productId,
        quantity: quantity,
        reason: reason,
      );

      Get.snackbar(
        'Success',
        'Stock removed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reload stock
      await loadCurrentStock(branchId: targetBranchId);

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Stock Adjustment
  Future<bool> adjustStock({
    required String productId,
    required int newQuantity,
    required String reason,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final authController = Get.find<AuthController>();
      final branchId = authController.branchId;

      if (branchId == null) {
        throw Exception('Branch ID not found');
      }

      await _dataSource.adjustStock(
        branchId: branchId,
        productId: productId,
        newQuantity: newQuantity,
        reason: reason,
      );

      Get.snackbar(
        'Success',
        'Stock adjusted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reload stock
      await loadCurrentStock();

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Stock Transfer between branches
  Future<bool> transferStock({
    required String fromBranchId,
    required String toBranchId,
    required String productId,
    required int quantity,
    String? reason,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _dataSource.transferStock(
        fromBranchId: fromBranchId,
        toBranchId: toBranchId,
        productId: productId,
        quantity: quantity,
        reason: reason,
      );

      Get.snackbar(
        'Success',
        'Stock transferred successfully',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Reload stock
      await loadCurrentStock();

      return true;
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get low stock products
  Future<List<Map<String, dynamic>>> getLowStockProducts() async {
    try {
      final authController = Get.find<AuthController>();
      final branchId = authController.branchId;

      if (branchId == null) {
        throw Exception('Branch ID not found');
      }

      return await _dataSource.getLowStockProducts(branchId);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    }
  }

  // Get stock for specific product
  Future<int> getProductStockQuantity(String productId, {String? branchId}) async {
    try {
      final authController = Get.find<AuthController>();
      final user = authController.currentUser.value;
      String? targetBranchId = branchId ?? authController.branchId;

      // For tenant owners, use selected branch from BranchStoreController
      if (user?.role.value == 'tenant_owner' && targetBranchId == null) {
        try {
          if (Get.isRegistered<BranchStoreController>()) {
            final branchStore = Get.find<BranchStoreController>();
            targetBranchId = branchStore.selectedBranchId.value;
          }
        } catch (_) {
          // BranchStoreController not available
        }
      }

      if (targetBranchId == null) return 0;

      final stock = await _dataSource.getProductStock(targetBranchId, productId);
      return stock?.quantity ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
