import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
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
    // Schedule loadBranches after initialization to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadBranches();
    });
  }

  Future<void> loadBranches() async {
    try {
      isLoading.value = true;

      final tenantId = _authController.currentUser.value?.tenantId;

      final loadedBranches = tenantId != null
          ? await _dataSource.getBranchesByTenant(tenantId)
          : <Map<String, dynamic>>[];

      // Update branches value after async operation completes
      // Use WidgetsBinding to ensure this doesn't happen during build
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        branches.value = loadedBranches;
      } else {
        // If we're in a build phase, defer the update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          branches.value = loadedBranches;
        });
      }
    } catch (e) {
      print('[BranchController] Error loading branches: $e');
      // Set empty list on error to prevent null issues
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        branches.value = [];
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          branches.value = [];
        });
      }
    } finally {
      if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.idle) {
        isLoading.value = false;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          isLoading.value = false;
        });
      }
    }
  }

  Future<bool> createBranch({
    required String name,
    required String code,
    String? address,
    String? phone,
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
      );

      await loadBranches();
      return true;
    } on Exception catch (e) {
      print('[BranchController] Error creating branch: $e');
      // Re-throw so UI can show specific error (e.g., duplicate code)
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBranch({
    required String branchId,
    required String name,
    required String code,
    String? address,
    String? phone,
    bool? isMain,
  }) async {
    try {
      isLoading.value = true;

      final Map<String, dynamic> updateData = {
        'name': name,
        'code': code,
        'address': address,
        'phone': phone,
      };

      if (isMain != null) {
        updateData['is_main'] = isMain;
      }

      await _dataSource.updateBranch(branchId, updateData);
      await loadBranches();
      return true;
    } on Exception catch (e) {
      print('[BranchController] Error updating branch: $e');
      rethrow;
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

  Future<bool> deleteBranch(String branchId) async {
    try {
      await _dataSource.deleteBranch(branchId);
      await loadBranches();
      return true;
    } catch (e) {
      print('[BranchController] Error deleting branch: $e');
      return false;
    }
  }

  int get totalBranches => branches.length;
  int get activeBranches =>
      branches.where((b) => b['is_active'] == true).length;
  int get inactiveBranches =>
      branches.where((b) => b['is_active'] != true).length;
}
