import 'package:get/get.dart';

import '../../data/datasources/product_datasource.dart';
import '../../data/models/product_model.dart';
import 'auth_controller.dart';

class ProductController extends GetxController {
  final ProductDataSource _dataSource = ProductDataSource();

  // Observables
  final products = <Product>[].obs;
  final categories = <Category>[].obs;
  final brands = <Brand>[].obs;
  final filteredProducts = <Product>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    loadCategories();
    loadBrands();
  }

  // Load all products
  Future<void> loadProducts() async {
    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;
      final branchId = authController.branchId;
      final user = authController.currentUser.value;

      // Debug logging
      print('=== ProductController.loadProducts ===');
      print('User: ${user?.fullName}');
      print('User Role: ${user?.role.value}');
      print('Tenant ID: $tenantId');
      print('Branch ID: $branchId');

      if (tenantId == null) {
        // No tenant ID means we can't load products
        print('ERROR: No tenant ID found, cannot load products');
        products.value = [];
        filteredProducts.value = [];
        return;
      }

      print('Fetching products for tenant: $tenantId');
      products.value = await _dataSource.getProductsByTenant(tenantId);
      print('Products fetched: ${products.length}');
      filteredProducts.value = products;
    } catch (e) {
      print('ERROR loading products: $e');
      Get.snackbar(
        'Error',
        'Failed to load products: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;

      if (tenantId == null) return;

      categories.value = await _dataSource.getCategoriesByTenant(tenantId);
    } catch (e) {
      print('Failed to load categories: $e');
    }
  }

  // Load brands
  Future<void> loadBrands() async {
    try {
      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;

      if (tenantId == null) return;

      brands.value = await _dataSource.getBrandsByTenant(tenantId);
    } catch (e) {
      print('Failed to load brands: $e');
    }
  }

  // Search products
  Future<void> searchProducts(String query) async {
    searchQuery.value = query;

    if (query.isEmpty) {
      filteredProducts.value = products;
      return;
    }

    try {
      isLoading.value = true;

      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;

      if (tenantId == null) return;

      filteredProducts.value = await _dataSource.searchProducts(
        tenantId,
        query,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Search failed: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      return await _dataSource.getProductById(productId);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load product: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  // Create product
  Future<bool> createProduct(Product product) async {
    try {
      isLoading.value = true;

      await _dataSource.createProduct(product);

      Get.snackbar(
        'Success',
        'Product created successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload products
      await loadProducts();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create product: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Create product from form data (convenience method)
  Future<bool> createProductFromData({
    required String name,
    String? sku,
    required String unit,
    required double sellingPrice,
    double? purchasePrice,
    required double gstRate,
    required int minStock,
    String? description,
    String? categoryId,
    String? brandId,
    StockTrackingType stockTrackingType = StockTrackingType.quantity,
    bool isActive = true,
  }) async {
    try {
      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;

      if (tenantId == null) {
        throw Exception('Tenant ID not found');
      }

      // Capitalize product name similar to catalogue
      final normalizedName = _capitalizeWords(name);

      // Prevent duplicate SKU within tenant (case-insensitive)
      final normalizedSku = sku?.trim().toLowerCase();
      if (normalizedSku != null && normalizedSku.isNotEmpty) {
        final existsSku = products.any(
          (p) => (p.sku ?? '').trim().toLowerCase() == normalizedSku,
        );
        if (existsSku) {
          Get.snackbar(
            'Error',
            'SKU already exists for this tenant',
            snackPosition: SnackPosition.TOP,
          );
          return false;
        }
      }

      final product = Product(
        id: '', // Will be generated by Supabase
        tenantId: tenantId,
        categoryId: categoryId,
        brandId: brandId,
        name: normalizedName,
        sku: sku,
        unit: unit,
        sellingPrice: sellingPrice,
        purchasePrice: purchasePrice,
        gstRate: gstRate,
        minStock: minStock,
        description: description,
        stockTrackingType: stockTrackingType,
        isActive: isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createProduct(product);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create product: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      isLoading.value = true;

      await _dataSource.updateProduct(productId, updates);

      Get.snackbar(
        'Success',
        'Product updated successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload products
      await loadProducts();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      isLoading.value = true;

      await _dataSource.deleteProduct(productId);

      Get.snackbar(
        'Success',
        'Product deleted successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload products
      await loadProducts();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete product: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Toggle product active status
  Future<bool> toggleProductActive(
    String productId,
    bool newStatus, {
    int? currentStock,
  }) async {
    try {
      // Prevent activating product with zero stock (matching website logic)
      if (newStatus && (currentStock ?? 0) == 0) {
        Get.snackbar(
          'Error',
          'Cannot activate product with zero stock. Please add stock first.',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      await _dataSource.toggleProductActive(productId, newStatus);

      Get.snackbar(
        'Success',
        'Product status updated successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload products
      await loadProducts();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update product status: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Create category
  Future<bool> createCategory(
    String name, {
    String? code,
    String? description,
  }) async {
    try {
      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;

      if (tenantId == null) {
        throw Exception('Tenant ID not found');
      }

      // Prevent duplicate category names (case-insensitive, trimmed)
      final normalized = name.trim().toLowerCase();
      final existsByName = categories.any(
        (c) => c.name.trim().toLowerCase() == normalized,
      );
      if (existsByName) {
        Get.snackbar(
          'Error',
          'Category already exists',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final category = Category(
        id: '', // Will be generated by Supabase
        tenantId: tenantId,
        name: name,
        code: code,
        description: description,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataSource.createCategory(category);

      Get.snackbar(
        'Success',
        'Category created successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload categories
      await loadCategories();

      return true;
    } catch (e) {
      final raw = e.toString();
      String message = raw;
      if (raw.contains('categories_tenant_id_code_key') ||
          raw.contains('duplicate key value')) {
        message = 'Category code already exists for this tenant';
      }
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Create brand
  Future<bool> createBrand(
    String name, {
    String? code,
    String? description,
  }) async {
    try {
      final authController = Get.find<AuthController>();
      final tenantId = authController.tenantId;

      if (tenantId == null) {
        throw Exception('Tenant ID not found');
      }

      // Prevent duplicate brand names (case-insensitive, trimmed)
      final normalized = name.trim().toLowerCase();
      final existsByName = brands.any(
        (b) => b.name.trim().toLowerCase() == normalized,
      );
      if (existsByName) {
        Get.snackbar(
          'Error',
          'Brand already exists',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }

      final brand = Brand(
        id: '', // Will be generated by Supabase
        tenantId: tenantId,
        name: name,
        code: code,
        description: description,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dataSource.createBrand(brand);

      Get.snackbar(
        'Success',
        'Brand created successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload brands
      await loadBrands();

      return true;
    } catch (e) {
      final raw = e.toString();
      String message = raw;
      if (raw.contains('brands_tenant_id_code_key') ||
          raw.contains('duplicate key value')) {
        message = 'Brand code already exists for this tenant';
      }
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _dataSource.updateCategory(categoryId, updates);

      Get.snackbar(
        'Success',
        'Category updated successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload categories
      await loadCategories();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update category: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String categoryId) async {
    try {
      await _dataSource.deleteCategory(categoryId);

      Get.snackbar(
        'Success',
        'Category deleted successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload categories
      await loadCategories();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete category: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Update brand
  Future<bool> updateBrand(
    String brandId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _dataSource.updateBrand(brandId, updates);

      Get.snackbar(
        'Success',
        'Brand updated successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload brands
      await loadBrands();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update brand: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Delete brand
  Future<bool> deleteBrand(String brandId) async {
    try {
      await _dataSource.deleteBrand(brandId);

      Get.snackbar(
        'Success',
        'Brand deleted successfully',
        snackPosition: SnackPosition.TOP,
      );

      // Reload brands
      await loadBrands();

      return true;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete brand: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Filter products by category
  void filterByCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products
          .where((p) => p.categoryId == categoryId)
          .toList();
    }
  }

  // Filter products by brand
  void filterByBrand(String? brandId) {
    if (brandId == null || brandId.isEmpty) {
      filteredProducts.value = products;
    } else {
      filteredProducts.value = products
          .where((p) => p.brandId == brandId)
          .toList();
    }
  }

  // Clear filters
  void clearFilters() {
    filteredProducts.value = products;
    searchQuery.value = '';
  }

  /// Capitalize the first letter of each word in the given string.
  String _capitalizeWords(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final words = trimmed.split(RegExp(r'\s+'));
    return words
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}