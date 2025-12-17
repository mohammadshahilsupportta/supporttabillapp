import 'package:get/get.dart';

import '../../data/datasources/user_datasource.dart';
import 'auth_controller.dart';

class UserController extends GetxController {
  final UserDataSource _dataSource = UserDataSource();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, int> roleCounts = <String, int>{}.obs;

  // Role labels
  static const Map<String, String> roleLabels = {
    'tenantOwner': 'Owner',
    'branchAdmin': 'Branch Admin',
    'branchStaff': 'Staff',
    'superadmin': 'Super Admin',
  };

  @override
  void onInit() {
    super.onInit();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      isLoading.value = true;

      final tenantId = _authController.currentUser.value?.tenantId;

      if (tenantId != null) {
        users.value = await _dataSource.getUsersByTenant(tenantId);
        _calculateRoleCounts();
      } else {
        users.value = [];
      }
    } catch (e) {
      print('[UserController] Error loading users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateRoleCounts() {
    Map<String, int> counts = {};
    for (var user in users) {
      final role = user['role'] as String? ?? 'unknown';
      counts[role] = (counts[role] ?? 0) + 1;
    }
    roleCounts.value = counts;
  }

  Future<bool> createUser({
    required String email,
    required String fullName,
    required String role,
    String? branchId,
    String? phone,
  }) async {
    try {
      isLoading.value = true;

      final tenantId = _authController.currentUser.value?.tenantId;

      if (tenantId == null) {
        throw Exception('Tenant not found');
      }

      await _dataSource.createUser(
        email: email,
        fullName: fullName,
        role: role,
        tenantId: tenantId,
        branchId: branchId,
        phone: phone,
      );

      await loadUsers();
      return true;
    } catch (e) {
      print('[UserController] Error creating user: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    try {
      final success = await _dataSource.toggleUserStatus(userId, isActive);
      if (success) {
        await loadUsers();
      }
      return success;
    } catch (e) {
      print('[UserController] Error toggling user status: $e');
      return false;
    }
  }

  Future<void> refreshUsers() async {
    await loadUsers();
  }

  String getRoleLabel(String? role) {
    return roleLabels[role ?? ''] ?? role ?? 'Unknown';
  }

  int get totalUsers => users.length;
  int get activeUsers => users.where((u) => u['is_active'] == true).length;
  int get inactiveUsers => users.where((u) => u['is_active'] != true).length;
}
