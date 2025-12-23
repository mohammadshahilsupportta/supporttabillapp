import 'package:get/get.dart';

import '../../data/datasources/customer_datasource.dart';
import 'auth_controller.dart';

class CustomerController extends GetxController {
  final CustomerDataSource _dataSource = CustomerDataSource();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> customers = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> allCustomers = <Map<String, dynamic>>[].obs; // Store all customers for stats
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString statusFilter = 'all'.obs; // 'all', 'active', 'inactive'

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
        // Always load all customers for statistics
        allCustomers.value = await _dataSource.getCustomersByTenant(tenantId);
        
        // Apply status filter
        _applyFilters();
      } else {
        allCustomers.value = [];
        customers.value = [];
      }
    } catch (e) {
      print('[CustomerController] Error loading customers: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _applyFilters() {
    var filtered = List<Map<String, dynamic>>.from(allCustomers);

    // Apply status filter
    if (statusFilter.value == 'active') {
      filtered = filtered.where((c) => c['is_active'] == true).toList();
    } else if (statusFilter.value == 'inactive') {
      filtered = filtered.where((c) => c['is_active'] != true).toList();
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((c) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        final phone = (c['phone'] ?? '').toString().toLowerCase();
        final email = (c['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || phone.contains(query) || email.contains(query);
      }).toList();
    }

    customers.value = filtered;
  }

  Future<void> searchCustomers(String query) async {
    searchQuery.value = query;
    _applyFilters();
  }

  void setStatusFilter(String filter) {
    statusFilter.value = filter;
    _applyFilters();
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

  Future<bool> deleteCustomer(String customerId) async {
    try {
      isLoading.value = true;
      await _dataSource.deleteCustomer(customerId);
      await loadCustomers();
      return true;
    } catch (e) {
      print('[CustomerController] Error deleting customer: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshCustomers() async {
    await loadCustomers();
  }

  int get totalCustomers => allCustomers.length;
  int get activeCustomers =>
      allCustomers.where((c) => c['is_active'] == true).length;
  int get inactiveCustomers =>
      allCustomers.where((c) => c['is_active'] != true).length;
}
