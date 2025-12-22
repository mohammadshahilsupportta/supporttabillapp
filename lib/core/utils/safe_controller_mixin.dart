import 'package:get/get.dart';

/// Mixin to provide safe controller access methods
/// Prevents uncaught exceptions when controllers are not registered
mixin SafeControllerMixin {
  /// Safely find a controller, returns null if not registered
  T? findControllerSafe<T>() {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
      return null;
    } catch (e) {
      print('SafeControllerMixin: Error finding ${T.toString()}: $e');
      return null;
    }
  }

  /// Safely find a controller or throw descriptive error
  T findControllerOrThrow<T>({String? errorMessage}) {
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
}

