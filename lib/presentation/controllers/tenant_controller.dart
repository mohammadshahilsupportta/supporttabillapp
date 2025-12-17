import 'package:get/get.dart';

import '../../data/datasources/tenant_datasource.dart';

class TenantController extends GetxController {
  final TenantDataSource _dataSource = TenantDataSource();

  final RxList<Map<String, dynamic>> tenants = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadTenants();
  }

  Future<void> loadTenants() async {
    try {
      isLoading.value = true;
      tenants.value = await _dataSource.getAllTenants();
    } catch (e) {
      print('[TenantController] Error loading tenants: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>?> getTenantById(String tenantId) async {
    try {
      return await _dataSource.getTenantById(tenantId);
    } catch (e) {
      print('[TenantController] Error getting tenant: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getTenantStats(String tenantId) async {
    return await _dataSource.getTenantStats(tenantId);
  }

  Future<bool> createTenant({
    required String name,
    required String businessName,
    String? email,
    String? phone,
    String? address,
    String? gstNumber,
    String? subscriptionPlan,
  }) async {
    try {
      isLoading.value = true;

      await _dataSource.createTenant(
        name: name,
        businessName: businessName,
        email: email,
        phone: phone,
        address: address,
        gstNumber: gstNumber,
        subscriptionPlan: subscriptionPlan,
      );

      await loadTenants();
      return true;
    } catch (e) {
      print('[TenantController] Error creating tenant: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateTenant(String tenantId, Map<String, dynamic> data) async {
    try {
      await _dataSource.updateTenant(tenantId, data);
      await loadTenants();
      return true;
    } catch (e) {
      print('[TenantController] Error updating tenant: $e');
      return false;
    }
  }

  Future<bool> toggleTenantStatus(String tenantId, bool isActive) async {
    try {
      final success = await _dataSource.toggleTenantStatus(tenantId, isActive);
      if (success) {
        await loadTenants();
      }
      return success;
    } catch (e) {
      print('[TenantController] Error toggling tenant status: $e');
      return false;
    }
  }

  Future<void> refreshTenants() async {
    await loadTenants();
  }

  int get totalTenants => tenants.length;
  int get activeTenants => tenants.where((t) => t['is_active'] == true).length;
  int get inactiveTenants =>
      tenants.where((t) => t['is_active'] != true).length;
}
