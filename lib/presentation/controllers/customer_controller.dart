import 'package:get/get.dart';

import '../../data/datasources/customer_datasource.dart';
import 'auth_controller.dart';

class CustomerController extends GetxController {
  final CustomerDataSource _dataSource = CustomerDataSource();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> customers = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      isLoading.value = true;

      final tenantId = _authController.currentUser.value?.tenantId;

      if (tenantId != null) {
        customers.value = await _dataSource.getCustomersByTenant(tenantId);
      } else {
        customers.value = [];
      }
    } catch (e) {
      print('[CustomerController] Error loading customers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> searchCustomers(String query) async {
    searchQuery.value = query;

    if (query.isEmpty) {
      await loadCustomers();
      return;
    }

    try {
      isLoading.value = true;
      final tenantId = _authController.currentUser.value?.tenantId;

      if (tenantId != null) {
        customers.value = await _dataSource.searchCustomers(tenantId, query);
      }
    } catch (e) {
      print('[CustomerController] Error searching: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
  }) async {
    try {
      isLoading.value = true;

      final tenantId = _authController.currentUser.value?.tenantId;

      if (tenantId == null) {
        throw Exception('Tenant not found');
      }

      await _dataSource.createCustomer(
        tenantId: tenantId,
        name: name,
        phone: phone,
        email: email,
        address: address,
        gstNumber: gstNumber,
      );

      await loadCustomers();
      return true;
    } catch (e) {
      print('[CustomerController] Error creating customer: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateCustomer(
    String customerId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _dataSource.updateCustomer(customerId, data);
      await loadCustomers();
      return true;
    } catch (e) {
      print('[CustomerController] Error updating customer: $e');
      return false;
    }
  }

  Future<void> refreshCustomers() async {
    await loadCustomers();
  }

  int get totalCustomers => customers.length;
  int get activeCustomers =>
      customers.where((c) => c['is_active'] == true).length;
}
