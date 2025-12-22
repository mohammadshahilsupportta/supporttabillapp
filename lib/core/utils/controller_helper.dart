import 'package:get/get.dart';

/// Helper utility for safely accessing GetX controllers
/// Prevents uncaught exceptions when controllers are not registered
class ControllerHelper {
  /// Safely find a controller, returns null if not registered
  static T? findSafe<T>() {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      return null;
    } catch (e) {
      print('ControllerHelper: Error finding ${T.toString()}: $e');
      return null;
    }
  }

  /// Safely find a controller, throws descriptive error if not found
  static T findOrThrow<T>({String? errorMessage}) {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      throw Exception(
        errorMessage ?? 'Controller ${T.toString()} is not registered',
      );
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception(
        errorMessage ?? 'Error finding controller ${T.toString()}: $e',
      );
    }
  }

  /// Ensure controller is registered, create if not
  static T ensureRegistered<T>(T Function() factory) {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      return Get.put<T>(factory());
    } catch (e) {
      print('ControllerHelper: Error ensuring ${T.toString()}: $e');
      return Get.put<T>(factory());
    }
  }
}

