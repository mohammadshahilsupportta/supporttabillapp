import 'package:get/get.dart';

import '../../core/config/app_config.dart';
import '../../core/services/storage_service.dart';
import 'auth_controller.dart';
import 'branch_controller.dart';

/// Branch Store Controller - Manages selected branch state for tenant owners
/// Similar to website's branchStore.ts
class BranchStoreController extends GetxController {
  final StorageService _storage = StorageService.instance;

  // Selected branch ID (persisted)
  final selectedBranchId = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadSelectedBranch();
  }

  /// Load selected branch from storage
  void _loadSelectedBranch() {
    try {
      final stored = _storage.read<String>(AppConfig.keySelectedBranchId);
      if (stored != null && stored.isNotEmpty) {
        selectedBranchId.value = stored;
      }
    } catch (e) {
      print('Error loading selected branch: $e');
    }
  }

  /// Set selected branch (persists to storage)
  Future<void> setSelectedBranch(String? branchId) async {
    if (branchId == selectedBranchId.value) return;

    selectedBranchId.value = branchId;
    try {
      if (branchId != null) {
        await _storage.write(AppConfig.keySelectedBranchId, branchId);
      } else {
        await _storage.remove(AppConfig.keySelectedBranchId);
      }
    } catch (e) {
      print('Error saving selected branch: $e');
    }
  }

  /// Clear selected branch
  Future<void> clearSelectedBranch() async {
    selectedBranchId.value = null;
    try {
      await _storage.remove(AppConfig.keySelectedBranchId);
    } catch (e) {
      print('Error clearing selected branch: $e');
    }
  }

  /// Get current branch info
  Map<String, dynamic>? get currentBranch {
    if (selectedBranchId.value == null) return null;

    try {
      if (!Get.isRegistered<BranchController>()) return null;
      final branchController = Get.find<BranchController>();
      return branchController.branches.firstWhere(
        (b) => b['id'] == selectedBranchId.value,
        orElse: () => {},
      );
    } catch (_) {
      return null;
    }
  }

  /// Auto-select main branch if no branch is selected
  Future<void> autoSelectMainBranch() async {
    try {
      // Check if AuthController is available
      if (!Get.isRegistered<AuthController>()) return;
      
      final authController = Get.find<AuthController>();
      
      // Only for tenant owners
      if (authController.currentUser.value?.role.value != 'tenant_owner') {
        return;
      }

      // If already selected, verify it's valid
      if (selectedBranchId.value != null) {
        // Validate existing selection
        if (!Get.isRegistered<BranchController>()) return;
        final branchController = Get.find<BranchController>();
        final branches = branchController.branches;
        final isValid = branches.any((b) => 
          b['id'] == selectedBranchId.value && b['is_active'] == true
        );
        if (isValid) return; // Already have a valid selection
        // If invalid, clear and continue to auto-select
        selectedBranchId.value = null;
      }

      if (!Get.isRegistered<BranchController>()) return;
      final branchController = Get.find<BranchController>();
      final branches = branchController.branches;

      if (branches.isEmpty) return;

      // Find main active branch
      final mainBranch = branches.firstWhere(
        (b) => b['is_main'] == true && b['is_active'] == true,
        orElse: () => <String, dynamic>{},
      );

      if (mainBranch.isNotEmpty) {
        await setSelectedBranch(mainBranch['id'] as String);
        return;
      }

      // If no main branch, use first active branch
      final firstActive = branches.firstWhere(
        (b) => b['is_active'] == true,
        orElse: () => <String, dynamic>{},
      );

      if (firstActive.isNotEmpty) {
        await setSelectedBranch(firstActive['id'] as String);
      }
    } catch (e) {
      print('Error auto-selecting branch: $e');
    }
  }
}

