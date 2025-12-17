import 'package:get/get.dart';

import '../../data/datasources/branch_datasource.dart';
import 'auth_controller.dart';

class BranchController extends GetxController {
  final BranchDataSource _dataSource = BranchDataSource();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> branches = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadBranches();
  }

  Future<void> loadBranches() async {
    try {
      isLoading.value = true;

      final tenantId = _authController.currentUser.value?.tenantId;

      if (tenantId != null) {
        branches.value = await _dataSource.getBranchesByTenant(tenantId);
      } else {
        branches.value = [];
      }
    } catch (e) {
      print('[BranchController] Error loading branches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createBranch({
    required String name,
    required String code,
    String? address,
    String? phone,
    String? email,
    String? city,
    String? state,
    String? pincode,
  }) async {
    try {
      isLoading.value = true;

      final tenantId = _authController.currentUser.value?.tenantId;

      if (tenantId == null) {
        throw Exception('Tenant not found');
      }

      await _dataSource.createBranch(
        tenantId: tenantId,
        name: name,
        code: code,
        address: address,
        phone: phone,
        email: email,
        city: city,
        state: state,
        pincode: pincode,
      );

      await loadBranches();
      return true;
    } catch (e) {
      print('[BranchController] Error creating branch: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> toggleBranchStatus(String branchId, bool isActive) async {
    try {
      final success = await _dataSource.toggleBranchStatus(branchId, isActive);
      if (success) {
        await loadBranches();
      }
      return success;
    } catch (e) {
      print('[BranchController] Error toggling branch status: $e');
      return false;
    }
  }

  Future<void> refreshBranches() async {
    await loadBranches();
  }

  int get totalBranches => branches.length;
  int get activeBranches =>
      branches.where((b) => b['is_active'] == true).length;
  int get inactiveBranches =>
      branches.where((b) => b['is_active'] != true).length;
}
