import 'package:get_storage/get_storage.dart';

import '../config/app_config.dart';

class StorageService {
  static StorageService? _instance;
  late GetStorage _box;

  StorageService._();

  static StorageService get instance {
    _instance ??= StorageService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    await GetStorage.init();
    instance._box = GetStorage();
  }

  // Auth Token
  String? get authToken => _box.read<String>(AppConfig.keyAuthToken);
  set authToken(String? value) => _box.write(AppConfig.keyAuthToken, value);

  // User ID
  String? get userId => _box.read<String>(AppConfig.keyUserId);
  set userId(String? value) => _box.write(AppConfig.keyUserId, value);

  // User Role
  String? get userRole => _box.read<String>(AppConfig.keyUserRole);
  set userRole(String? value) => _box.write(AppConfig.keyUserRole, value);

  // Tenant ID
  String? get tenantId => _box.read<String>(AppConfig.keyTenantId);
  set tenantId(String? value) => _box.write(AppConfig.keyTenantId, value);

  // Branch ID
  String? get branchId => _box.read<String>(AppConfig.keyBranchId);
  set branchId(String? value) => _box.write(AppConfig.keyBranchId, value);

  // Theme Mode
  String? get themeMode => _box.read<String>(AppConfig.keyThemeMode);
  set themeMode(String? value) => _box.write(AppConfig.keyThemeMode, value);

  // Generic methods
  T? read<T>(String key) => _box.read<T>(key);

  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
  }

  Future<void> remove(String key) async {
    await _box.remove(key);
  }

  Future<void> clear() async {
    await _box.erase();
  }

  // Clear auth data
  Future<void> clearAuthData() async {
    await remove(AppConfig.keyAuthToken);
    await remove(AppConfig.keyUserId);
    await remove(AppConfig.keyUserRole);
    await remove(AppConfig.keyTenantId);
    await remove(AppConfig.keyBranchId);
  }
}
