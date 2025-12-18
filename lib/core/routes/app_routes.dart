import 'package:get/get.dart';

import '../../presentation/controllers/auth_controller.dart';
import '../../presentation/controllers/billing_controller.dart';
import '../../presentation/controllers/branch_controller.dart';
import '../../presentation/controllers/customer_controller.dart';
import '../../presentation/controllers/dashboard_controller.dart';
import '../../presentation/controllers/expense_controller.dart';
import '../../presentation/controllers/product_controller.dart';
import '../../presentation/controllers/purchase_controller.dart';
import '../../presentation/controllers/stock_controller.dart';
import '../../presentation/controllers/tenant_controller.dart';
import '../../presentation/controllers/user_controller.dart';
import '../../presentation/views/auth/login_screen.dart';
import '../../presentation/views/auth/splash_screen.dart';
import '../../presentation/views/branch/billing/bill_detail_screen.dart';
import '../../presentation/views/branch/billing/billing_screen.dart';
import '../../presentation/views/branch/billing/bills_list_screen.dart';
import '../../presentation/views/branch/billing/pos_billing_screen.dart';
import '../../presentation/views/branch/dashboard/branch_dashboard_screen.dart';
import '../../presentation/views/branch/expenses/create_expense_screen.dart';
import '../../presentation/views/branch/expenses/expenses_list_screen.dart';
import '../../presentation/views/branch/products/create_product_screen.dart';
import '../../presentation/views/branch/products/edit_product_screen.dart';
import '../../presentation/views/branch/products/products_list_screen.dart';
import '../../presentation/views/branch/purchases/create_purchase_screen.dart';
import '../../presentation/views/branch/purchases/purchases_list_screen.dart';
import '../../presentation/views/branch/reports/sales_report_screen.dart';
import '../../presentation/views/branch/reports/stock_report_screen.dart';
import '../../presentation/views/branch/stock/current_stock_screen.dart';
import '../../presentation/views/branch/stock/stock_adjust_screen.dart';
import '../../presentation/views/branch/stock/stock_in_screen.dart';
import '../../presentation/views/branch/stock/stock_ledger_screen.dart';
import '../../presentation/views/branch/stock/stock_out_screen.dart';
import '../../presentation/views/branch/stock/stock_transfer_screen.dart';
import '../../presentation/views/common/settings/profile_edit_screen.dart';
import '../../presentation/views/common/settings/settings_screen.dart';
import '../../presentation/views/owner/branches/branch_details_screen.dart';
import '../../presentation/views/owner/branches/create_branch_screen.dart';
import '../../presentation/views/owner/catalogue/brands_list_screen.dart';
import '../../presentation/views/owner/catalogue/categories_list_screen.dart';
import '../../presentation/views/owner/customers/create_customer_screen.dart';
import '../../presentation/views/owner/customers/customers_list_screen.dart';
import '../../presentation/views/owner/dashboard/owner_dashboard_screen.dart';
import '../../presentation/views/owner/users/create_user_screen.dart';
import '../../presentation/views/owner/users/users_list_screen.dart';
import '../../presentation/views/superadmin/dashboard/superadmin_dashboard_screen.dart';
import '../../presentation/views/superadmin/tenants/create_tenant_screen.dart';
import '../../presentation/views/superadmin/tenants/tenants_list_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/';
  static const String login = '/login';

  // Branch routes
  static const String branchDashboard = '/branch/dashboard';
  static const String billing = '/branch/billing';
  static const String posBilling = '/branch/pos-billing';
  static const String billsList = '/branch/bills';
  static const String billDetail = '/branch/bills/:id';
  static const String stockList = '/branch/stock';
  static const String stockIn = '/branch/stock/in';
  static const String stockOut = '/branch/stock/out';
  static const String stockAdjust = '/branch/stock/adjust';
  static const String stockTransfer = '/branch/stock/transfer';
  static const String stockLedger = '/branch/stock-ledger';
  static const String productsList = '/branch/products';
  static const String createProduct = '/branch/products/create';
  static const String editProduct = '/branch/products/edit/:id';
  static const String expensesList = '/branch/expenses';
  static const String createExpense = '/branch/expenses/create';
  static const String purchasesList = '/branch/purchases';
  static const String purchaseCreate = '/branch/purchases/create';
  static const String salesReport = '/branch/reports/sales';
  static const String stockReport = '/branch/reports/stock';

  // Superadmin routes
  static const String superadminDashboard = '/superadmin/dashboard';
  static const String tenantsList = '/superadmin/tenants';
  static const String tenantCreate = '/superadmin/tenants/create';

  // Owner routes
  static const String ownerDashboard = '/owner/dashboard';
  static const String branchCreate = '/owner/branches/create';
  static const String branchDetails = '/owner/branches/details';
  static const String productManagement = '/owner/products';
  static const String usersList = '/owner/users';
  static const String userCreate = '/owner/users/create';
  static const String categoriesList = '/owner/catalogue/categories';
  static const String brandsList = '/owner/catalogue/brands';
  static const String customersList = '/owner/customers';
  static const String customerCreate = '/owner/customers/create';

  // Common routes
  static const String settings = '/settings';
  static const String profileEdit = '/profile/edit';

  // GetX Pages
  static final List<GetPage> routes = [
    // Auth Routes
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(
      name: login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),

    // Superadmin Routes
    GetPage(
      name: superadminDashboard,
      page: () => const SuperadminDashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
        Get.lazyPut<DashboardController>(() => DashboardController());
      }),
    ),
    GetPage(
      name: tenantsList,
      page: () => const TenantsListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<TenantController>(() => TenantController());
      }),
    ),
    GetPage(
      name: tenantCreate,
      page: () => const CreateTenantScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<TenantController>(() => TenantController());
      }),
    ),

    // Owner Routes
    GetPage(
      name: ownerDashboard,
      page: () => const OwnerDashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
        Get.lazyPut<DashboardController>(() => DashboardController());
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    // Register more specific routes first
    GetPage(
      name: branchDetails,
      page: () => const BranchDetailsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BranchController>(() => BranchController());
      }),
    ),
    GetPage(
      name: branchCreate,
      page: () => const CreateBranchScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BranchController>(() => BranchController());
      }),
    ),
    GetPage(
      name: usersList,
      page: () => const UsersListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<UserController>(() => UserController());
      }),
    ),
    GetPage(
      name: userCreate,
      page: () => const CreateUserScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<UserController>(() => UserController());
        Get.lazyPut<BranchController>(() => BranchController());
      }),
    ),
    GetPage(
      name: categoriesList,
      page: () => const CategoriesListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: brandsList,
      page: () => const BrandsListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: customersList,
      page: () => const CustomersListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CustomerController>(() => CustomerController());
      }),
    ),
    GetPage(
      name: customerCreate,
      page: () => const CreateCustomerScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<CustomerController>(() => CustomerController());
      }),
    ),

    // Branch Routes
    GetPage(
      name: branchDashboard,
      page: () => const BranchDashboardScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
        Get.lazyPut<DashboardController>(() => DashboardController());
        Get.lazyPut<BillingController>(() => BillingController());
      }),
    ),

    // Billing Routes
    GetPage(
      name: billing,
      page: () => const BillingScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(
      name: posBilling,
      page: () => const POSBillingScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BillingController>(() => BillingController());
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: billsList,
      page: () => const BillsListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BillingController>(() => BillingController());
      }),
    ),
    GetPage(
      name: billDetail,
      page: () => const BillDetailScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<BillingController>(() => BillingController());
      }),
    ),

    // Product Routes
    GetPage(
      name: productsList,
      page: () => const ProductsListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: createProduct,
      page: () => const CreateProductScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: editProduct,
      page: () => const EditProductScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),

    // Stock Routes
    GetPage(
      name: stockList,
      page: () => const CurrentStockScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StockController>(() => StockController());
      }),
    ),
    GetPage(
      name: stockIn,
      page: () => const StockInScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StockController>(() => StockController());
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: stockOut,
      page: () => const StockOutScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StockController>(() => StockController());
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: stockAdjust,
      page: () => const StockAdjustScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StockController>(() => StockController());
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),
    GetPage(
      name: stockTransfer,
      page: () => const StockTransferScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StockController>(() => StockController());
        Get.lazyPut<ProductController>(() => ProductController());
        Get.lazyPut<BranchController>(() => BranchController());
      }),
    ),
    GetPage(
      name: stockLedger,
      page: () => const StockLedgerScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StockController>(() => StockController());
      }),
    ),

    // Expense Routes
    GetPage(
      name: expensesList,
      page: () => const ExpensesListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ExpenseController>(() => ExpenseController());
      }),
    ),
    GetPage(
      name: createExpense,
      page: () => const CreateExpenseScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ExpenseController>(() => ExpenseController());
      }),
    ),

    // Purchase Routes
    GetPage(
      name: purchasesList,
      page: () => const PurchasesListScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PurchaseController>(() => PurchaseController());
      }),
    ),
    GetPage(
      name: purchaseCreate,
      page: () => const CreatePurchaseScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<PurchaseController>(() => PurchaseController());
        Get.lazyPut<ProductController>(() => ProductController());
      }),
    ),

    // Report Routes
    GetPage(
      name: salesReport,
      page: () => const SalesReportScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<DashboardController>(() => DashboardController());
      }),
    ),
    GetPage(
      name: stockReport,
      page: () => const StockReportScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<StockController>(() => StockController());
      }),
    ),

    // Common Routes
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
    GetPage(
      name: profileEdit,
      page: () => const ProfileEditScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
      }),
    ),
  ];
}
