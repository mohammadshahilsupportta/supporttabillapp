import '../../core/services/supabase_service.dart';
import '../models/product_model.dart';

class ProductDataSource {
  final SupabaseService _supabase = SupabaseService.instance;

  // Get all products by tenant
  Future<List<Product>> getProductsByTenant(String tenantId) async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, category:categories(*), brand:brands(*)')
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          // Match web: latest products first
          .order('created_at', ascending: false);

      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: ${e.toString()}');
    }
  }

  // Get products by tenant with pagination
  Future<List<Product>> getProductsByTenantPaginated(
    String tenantId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, category:categories(*), brand:brands(*)')
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: ${e.toString()}');
    }
  }

  // Get product by ID
  Future<Product> getProductById(String productId) async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, category:categories(*), brand:brands(*)')
          .eq('id', productId)
          .single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch product: ${e.toString()}');
    }
  }

  // Create product
  Future<Product> createProduct(Product product) async {
    try {
      // For inserts, let the database generate id/created_at/updated_at
      final data = await _supabase.from('products').insert({
        'tenant_id': product.tenantId,
        'category_id': product.categoryId,
        'brand_id': product.brandId,
        'name': product.name,
        'sku': product.sku,
        'unit': product.unit,
        'selling_price': product.sellingPrice,
        'purchase_price': product.purchasePrice,
        'gst_rate': product.gstRate,
        'min_stock': product.minStock,
        'description': product.description,
        'stock_tracking_type': product.stockTrackingType.value,
        'is_active': product.isActive,
      }).select('*, category:categories(*), brand:brands(*)').single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create product: ${e.toString()}');
    }
  }

  // Update product
  Future<Product> updateProduct(
    String productId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final data = await _supabase
          .from('products')
          .update(updates)
          .eq('id', productId)
          .select('*, category:categories(*), brand:brands(*)')
          .single();

      return Product.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update product: ${e.toString()}');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _supabase
          .from('products')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: ${e.toString()}');
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String tenantId, String query) async {
    try {
      final data = await _supabase
          .from('products')
          .select('*, category:categories(*), brand:brands(*)')
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .or('name.ilike.%$query%,sku.ilike.%$query%')
          .order('name', ascending: true);

      return (data as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search products: ${e.toString()}');
    }
  }

  // Get categories
  Future<List<Category>> getCategoriesByTenant(String tenantId) async {
    try {
      final data = await _supabase
          .from('categories')
          .select()
          .eq('tenant_id', tenantId)
          // Show both Active & Inactive in app, newest first
          .order('created_at', ascending: false);

      return (data as List).map((json) => Category.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: ${e.toString()}');
    }
  }

  // Create category
  Future<Category> createCategory(Category category) async {
    try {
      // For inserts, let the database generate id/created_at/updated_at
      final data = await _supabase.from('categories').insert({
        'tenant_id': category.tenantId,
        'name': category.name,
        'code': category.code,
        'description': category.description,
        'is_active': category.isActive,
      }).select().single();

      return Category.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create category: ${e.toString()}');
    }
  }

  // Update category
  Future<Category> updateCategory(
    String categoryId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final data = await _supabase
          .from('categories')
          .update(updates)
          .eq('id', categoryId)
          .select()
          .single();

      return Category.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update category: ${e.toString()}');
    }
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('categories').delete().eq('id', categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: ${e.toString()}');
    }
  }

  // Get brands
  Future<List<Brand>> getBrandsByTenant(String tenantId) async {
    try {
      final data = await _supabase
          .from('brands')
          .select()
          .eq('tenant_id', tenantId)
          // Show both Active & Inactive in app, newest first
          .order('created_at', ascending: false);

      return (data as List).map((json) => Brand.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch brands: ${e.toString()}');
    }
  }

  // Create brand
  Future<Brand> createBrand(Brand brand) async {
    try {
      // For inserts, let the database generate id/created_at/updated_at
      final data = await _supabase.from('brands').insert({
        'tenant_id': brand.tenantId,
        'name': brand.name,
        'code': brand.code,
        'description': brand.description,
        'is_active': brand.isActive,
      }).select().single();

      return Brand.fromJson(data);
    } catch (e) {
      throw Exception('Failed to create brand: ${e.toString()}');
    }
  }

  // Update brand
  Future<Brand> updateBrand(
    String brandId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();

      final data = await _supabase
          .from('brands')
          .update(updates)
          .eq('id', brandId)
          .select()
          .single();

      return Brand.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update brand: ${e.toString()}');
    }
  }

  // Delete brand
  Future<void> deleteBrand(String brandId) async {
    try {
      await _supabase.from('brands').delete().eq('id', brandId);
    } catch (e) {
      throw Exception('Failed to delete brand: ${e.toString()}');
    }
  }
}
