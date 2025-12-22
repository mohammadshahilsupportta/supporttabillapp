# Error Handling Guide

## Overview
This document outlines the error handling patterns implemented throughout the app to prevent crashes from uncaught exceptions.

## Global Error Handling

### Main App Error Handler
Located in `lib/main.dart`:
- `FlutterError.onError` - Catches Flutter framework errors
- `PlatformDispatcher.instance.onError` - Catches async errors
- Prevents app crashes from uncaught exceptions

## Safe Controller Access

### ControllerHelper Utility
Located in `lib/core/utils/controller_helper.dart`:
- `ControllerHelper.findSafe<T>()` - Returns null if controller not found
- `ControllerHelper.findOrThrow<T>()` - Throws descriptive error
- `ControllerHelper.ensureRegistered<T>()` - Creates controller if not registered

### SafeControllerMixin
Located in `lib/core/utils/safe_controller_mixin.dart`:
- Mixin for widgets to safely access controllers
- `findControllerSafe<T>()` - Safe find method
- `findControllerOrThrow<T>()` - Find or throw

## Common Patterns

### Pattern 1: Safe Get.find() in initState
```dart
class _MyScreenState extends State<MyScreen> {
  MyController? _controller;

  @override
  void initState() {
    super.initState();
    try {
      _controller = Get.find<MyController>();
    } catch (e) {
      print('MyController not found: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return const Center(child: Text('Controller not available'));
    }
    // Use _controller safely
  }
}
```

### Pattern 2: Try-Catch Around Async Operations
```dart
Future<void> loadData() async {
  try {
    isLoading.value = true;
    final data = await _dataSource.fetchData();
    items.value = data;
  } catch (e) {
    print('Error loading data: $e');
    errorMessage.value = e.toString();
    Get.snackbar('Error', 'Failed to load data');
  } finally {
    isLoading.value = false;
  }
}
```

### Pattern 3: Null-Safe Controller Access
```dart
final controller = ControllerHelper.findSafe<MyController>();
if (controller == null) {
  return const SizedBox.shrink();
}
// Use controller safely
```

## Files Fixed

### Stock Screens
- ✅ `lib/presentation/views/branch/stock/stock_out_screen.dart`
- ⏳ `lib/presentation/views/branch/stock/stock_in_screen.dart`
- ⏳ `lib/presentation/views/branch/stock/stock_adjust_screen.dart`
- ⏳ `lib/presentation/views/branch/stock/stock_transfer_screen.dart`

### Other Screens
All screens using `Get.find()` directly in class fields should be updated to use safe access patterns.

## Best Practices

1. **Never use `Get.find()` directly in class fields**
   ```dart
   // ❌ BAD
   final controller = Get.find<MyController>();
   
   // ✅ GOOD
   MyController? _controller;
   @override
   void initState() {
     super.initState();
     try {
       _controller = Get.find<MyController>();
     } catch (e) {
       print('Controller not found: $e');
     }
   }
   ```

2. **Always wrap async operations in try-catch**
   ```dart
   // ✅ GOOD
   Future<void> doSomething() async {
     try {
       await someAsyncOperation();
     } catch (e) {
       print('Error: $e');
       // Handle error
     }
   }
   ```

3. **Check for null before using controllers**
   ```dart
   // ✅ GOOD
   if (_controller == null) {
     return const SizedBox.shrink();
   }
   // Use _controller
   ```

4. **Use ControllerHelper for safe access**
   ```dart
   // ✅ GOOD
   final controller = ControllerHelper.findSafe<MyController>();
   if (controller != null) {
     // Use controller
   }
   ```

## Testing Error Handling

To test error handling:
1. Temporarily remove controller registration from routes
2. Navigate to screens that use those controllers
3. Verify app doesn't crash and shows appropriate error messages

