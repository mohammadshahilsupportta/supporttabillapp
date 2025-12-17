import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/services/storage_service.dart';
import '../../data/datasources/auth_datasource.dart';
import '../../data/models/user_model.dart';

class AuthController extends GetxController {
  // Data source
  final AuthDataSource _authDataSource = AuthDataSource();
  final StorageService _storage = StorageService.instance;

  // Observables
  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  // Check if user is already logged in
  Future<void> checkAuthStatus() async {
    try {
      isLoading.value = true;

      final userId = _storage.userId;
      print('=== AuthController.checkAuthStatus ===');
      print('Stored userId: $userId');

      if (userId != null) {
        final user = await _authDataSource.getCurrentUser();
        print('User from DB: ${user?.fullName}');
        print('User tenantId: ${user?.tenantId}');
        print('User branchId: ${user?.branchId}');
        print('User role: ${user?.role.value}');

        if (user != null) {
          currentUser.value = user;
          isAuthenticated.value = true;

          // Navigate to appropriate dashboard based on role
          _navigateBasedOnRole(user.role);
        } else {
          print('User not found in database, clearing auth data');
          await _storage.clearAuthData();
          isAuthenticated.value = false;
        }
      } else {
        print('No stored userId, user not logged in');
      }
    } catch (e) {
      print('Auth check error: $e');
      isAuthenticated.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Sign in
  Future<bool> signIn({required String email, required String password}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      print('=== AuthController.signIn ===');
      print('Email: $email');

      final user = await _authDataSource.signIn(
        email: email,
        password: password,
      );

      print('Login successful!');
      print('User: ${user.fullName}');
      print('User ID: ${user.id}');
      print('User Role: ${user.role.value}');
      print('Tenant ID: ${user.tenantId}');
      print('Branch ID: ${user.branchId}');

      // Save to local storage
      _storage.userId = user.id;
      _storage.userRole = user.role.value;
      _storage.tenantId = user.tenantId;
      _storage.branchId = user.branchId;

      // Update state
      currentUser.value = user;
      isAuthenticated.value = true;

      // Navigate based on role
      _navigateBasedOnRole(user.role);

      return true;
    } catch (e) {
      print('Login error: $e');
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'Login Failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      isLoading.value = true;

      await _authDataSource.signOut();
      await _storage.clearAuthData();

      currentUser.value = null;
      isAuthenticated.value = false;

      Get.offAllNamed(AppRoutes.login);

      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Navigate based on user role
  void _navigateBasedOnRole(UserRole role) {
    // Get the target route based on role
    String targetRoute;
    switch (role) {
      case UserRole.superadmin:
        targetRoute = AppRoutes.superadminDashboard;
        break;
      case UserRole.tenantOwner:
        targetRoute = AppRoutes.ownerDashboard;
        break;
      case UserRole.branchAdmin:
      case UserRole.branchStaff:
        targetRoute = AppRoutes.branchDashboard;
        break;
    }

    // Only navigate if we're not already on the target route
    // This prevents infinite navigation loops
    if (Get.currentRoute != targetRoute) {
      Get.offAllNamed(targetRoute);
    }
  }

  // Role checks
  bool get isSuperAdmin => currentUser.value?.role == UserRole.superadmin;
  bool get isTenantOwner => currentUser.value?.role == UserRole.tenantOwner;
  bool get isBranchAdmin => currentUser.value?.role == UserRole.branchAdmin;
  bool get isBranchStaff => currentUser.value?.role == UserRole.branchStaff;

  // Get current tenant ID
  String? get tenantId => currentUser.value?.tenantId;

  // Get current branch ID
  String? get branchId => currentUser.value?.branchId;

  // Check if user has permission for a feature
  bool hasPermission(String feature) {
    if (currentUser.value == null) return false;

    final role = currentUser.value!.role;

    switch (feature) {
      case 'manage_tenants':
        return role == UserRole.superadmin;
      case 'manage_branches':
        return role == UserRole.superadmin || role == UserRole.tenantOwner;
      case 'manage_products':
        return role == UserRole.superadmin || role == UserRole.tenantOwner;
      case 'manage_users':
        return role != UserRole.branchStaff;
      case 'billing':
        return role == UserRole.branchAdmin || role == UserRole.branchStaff;
      case 'stock_management':
        return role == UserRole.branchAdmin || role == UserRole.branchStaff;
      case 'reports':
        return true; // All users can view reports
      default:
        return false;
    }
  }
}
