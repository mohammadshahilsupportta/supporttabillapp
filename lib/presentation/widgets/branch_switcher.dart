import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/branch_controller.dart';
import '../controllers/branch_store_controller.dart';
import '../controllers/dashboard_controller.dart';

/// Branch Switcher Widget - Similar to website's BranchSwitcher.tsx
/// Only shows for tenant owners
class BranchSwitcher extends StatefulWidget {
  const BranchSwitcher({super.key});

  @override
  State<BranchSwitcher> createState() => _BranchSwitcherState();
}

class _BranchSwitcherState extends State<BranchSwitcher> {
  bool _initialized = false;
  bool _autoSelectAttempted = false;
  bool _cleanupScheduled = false;

  @override
  void initState() {
    super.initState();
    // Schedule initialization after first frame to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeControllers();
    });
  }

  Future<void> _initializeControllers() async {
    if (!mounted || _initialized) return;
    
    try {
      // Ensure BranchController exists
      if (!Get.isRegistered<BranchController>()) {
        Get.put(BranchController());
      }

      // Ensure BranchStoreController exists
      if (!Get.isRegistered<BranchStoreController>()) {
        Get.put(BranchStoreController());
      }

      final branchController = Get.find<BranchController>();
      final branchStore = Get.find<BranchStoreController>();

      // Wait for branches to load if they're currently loading
      if (branchController.isLoading.value) {
        // Wait for loading to complete
        await Future.delayed(const Duration(milliseconds: 100));
        // Poll until loading is complete (with timeout)
        int attempts = 0;
        while (branchController.isLoading.value && attempts < 50 && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
      }

      // Load branches if needed (only if not already loading)
      if (branchController.branches.isEmpty && !branchController.isLoading.value) {
        await branchController.loadBranches();
      }

      // Auto-select main branch only once during initialization
      if (!_autoSelectAttempted && Get.isRegistered<BranchStoreController>()) {
        _autoSelectAttempted = true;
        // Schedule auto-select after a small delay to ensure branches are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          try {
            await branchStore.autoSelectMainBranch();
          } catch (e) {
            print('Auto-select error: $e');
          }
        });
      }

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('BranchSwitcher init error: $e');
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check auth synchronously first (outside Obx) to avoid unnecessary builds
    if (!Get.isRegistered<AuthController>()) {
      return const SizedBox.shrink();
    }

    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;

    // Only show switcher for tenant owners (check outside Obx)
    if (user?.role.value != 'tenant_owner' || user?.tenantId == null) {
      return const SizedBox.shrink();
    }

    // Check if controllers are registered (outside Obx)
    if (!Get.isRegistered<BranchController>() || 
        !Get.isRegistered<BranchStoreController>()) {
      if (!_initialized) {
        return _buildLoadingIndicator(context);
      }
      return const SizedBox.shrink();
    }

    final branchController = Get.find<BranchController>();
    final branchStore = Get.find<BranchStoreController>();

    // Use Obx only for reactive values that need to trigger rebuilds
    return Obx(() {
      try {
        // Show loading indicator while branches are being loaded
        if (branchController.isLoading.value) {
          return _buildLoadingIndicator(context);
        }

        // Get active branches (reactive to branchController.branches)
        final branches = branchController.branches
            .where((b) => b['is_active'] == true)
            .toList();

        // If no branches, show a compact placeholder
        if (branches.isEmpty) {
          return _buildNoBranchesIndicator(context);
        }

        // Get selected ID from store (reactive to selectedBranchId)
        final selectedId = branchStore.selectedBranchId.value;

        // Build list of valid branch IDs
        final validBranchIds = branches.map((b) => b['id'] as String).toList();

        // Validate that selectedId exists in the branches list
        final validSelectedId = selectedId != null && validBranchIds.contains(selectedId)
            ? selectedId
            : null;

        // If selected branch is invalid, clear it (but do it safely after build)
        if (selectedId != null && validSelectedId == null && _initialized && !_cleanupScheduled) {
          _cleanupScheduled = true;
          // Schedule cleanup after build completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _cleanupScheduled = false;
            if (mounted && Get.isRegistered<BranchStoreController>()) {
              final store = Get.find<BranchStoreController>();
              if (store.selectedBranchId.value == selectedId) {
                store.clearSelectedBranch();
                // Try to auto-select again if nothing is selected
                if (branches.isNotEmpty) {
                  store.autoSelectMainBranch();
                }
              }
            }
          });
        }

        // Check if dashboard is loading
        DashboardController? dashboardController;
        bool isDataLoading = false;
        try {
          if (Get.isRegistered<DashboardController>()) {
            dashboardController = Get.find<DashboardController>();
            isDataLoading = dashboardController.isLoading.value;
          }
        } catch (_) {
          // Dashboard controller not available
        }

        // Build dropdown items
        final dropdownItems = <DropdownMenuItem<String>>[];
        for (final branch in branches) {
          final branchId = branch['id'] as String;
          final branchName = branch['name'] as String? ?? 'Unknown';
          final isMainBranch = branch['is_main'] == true;

          dropdownItems.add(DropdownMenuItem<String>(
            value: branchId,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.store,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    branchName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isMainBranch) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Main',
                      style: TextStyle(
                        fontSize: 8,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (branchId == validSelectedId) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ],
            ),
          ));
        }

        // CRITICAL: selectedItemBuilder MUST return same number of items as dropdownItems
        final selectedItemBuilders = <Widget>[];
        for (final branch in branches) {
          final branchName = branch['name'] as String? ?? 'Unknown';
          final isMainBranch = branch['is_main'] == true;

          selectedItemBuilders.add(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDataLoading)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  )
                else ...[
                  Flexible(
                    child: Text(
                      branchName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (isMainBranch) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Main',
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          constraints: const BoxConstraints(maxWidth: 160),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: DropdownButton<String>(
                  value: validSelectedId,
                  underline: const SizedBox(),
                  isDense: true,
                  isExpanded: true,
                  hint: Text(
                    'Select',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: Theme.of(context).primaryColor,
                  ),
                  items: dropdownItems,
                  selectedItemBuilder: (context) => selectedItemBuilders,
                  onChanged: isDataLoading
                      ? null
                      : (branchId) {
                          if (branchId == null || branchId == validSelectedId) {
                            return;
                          }
                          _handleBranchChange(
                            branchStore,
                            dashboardController,
                            branchId,
                            branches,
                          );
                        },
                ),
              ),
            ],
          ),
        );
      } catch (e) {
        print('BranchSwitcher build error: $e');
        return const SizedBox.shrink();
      }
    });
  }

  Widget _buildLoadingIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildNoBranchesIndicator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.store,
              size: 14,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'No Branches',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBranchChange(
    BranchStoreController branchStore,
    DashboardController? dashboardController,
    String branchId,
    List<Map<String, dynamic>> branches,
  ) async {
    if (dashboardController?.isLoading.value == true) {
      Get.snackbar(
        'Please Wait',
        'Please wait for data to finish loading',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final selectedBranch = branches.firstWhere(
      (b) => b['id'] == branchId,
      orElse: () => <String, dynamic>{},
    );

    if (selectedBranch.isEmpty) return;

    try {
      await branchStore.setSelectedBranch(branchId);

      // Reload dashboard stats for new branch
      if (dashboardController != null) {
        await dashboardController.loadStats();
      }

      Get.snackbar(
        'Branch Switched',
        'Switched to ${selectedBranch['name']}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to switch branch: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
