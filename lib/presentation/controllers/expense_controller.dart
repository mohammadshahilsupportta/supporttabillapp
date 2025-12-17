import 'package:get/get.dart';

import '../../data/datasources/expense_datasource.dart';
import 'auth_controller.dart';

class ExpenseController extends GetxController {
  final ExpenseDataSource _dataSource = ExpenseDataSource();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Map<String, dynamic>> expenses = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxMap<String, double> categoryTotals = <String, double>{}.obs;

  // Category labels
  static const Map<String, String> categoryLabels = {
    'rent': 'Rent',
    'utilities': 'Utilities',
    'salaries': 'Salaries',
    'marketing': 'Marketing',
    'transport': 'Transport',
    'maintenance': 'Maintenance',
    'office_supplies': 'Office Supplies',
    'food': 'Food',
    'other': 'Other',
  };

  // Payment mode labels
  static const Map<String, String> paymentModeLabels = {
    'cash': 'Cash',
    'card': 'Card',
    'upi': 'UPI',
    'bank_transfer': 'Bank Transfer',
  };

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      isLoading.value = true;

      final branchId = _authController.currentUser.value?.branchId;
      final tenantId = _authController.currentUser.value?.tenantId;
      final role = _authController.currentUser.value?.role.value;

      if (role == 'tenantOwner' && tenantId != null) {
        // Tenant owner sees all expenses from all branches
        expenses.value = await _dataSource.getExpensesByTenant(tenantId);
      } else if (branchId != null) {
        // Branch user sees only their branch expenses
        expenses.value = await _dataSource.getExpenses(branchId);
      } else {
        expenses.value = [];
      }

      // Calculate totals
      _calculateTotals();
    } catch (e) {
      print('[ExpenseController] Error loading expenses: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateTotals() {
    double total = 0;
    Map<String, double> catTotals = {};

    for (var expense in expenses) {
      final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
      final category = expense['category'] as String? ?? 'other';

      total += amount;
      catTotals[category] = (catTotals[category] ?? 0) + amount;
    }

    totalExpenses.value = total;
    categoryTotals.value = catTotals;
  }

  Future<bool> createExpense({
    required String category,
    required String description,
    required double amount,
    required String paymentMode,
    required String expenseDate,
    String? receiptNumber,
    String? vendorName,
    String? notes,
  }) async {
    try {
      isLoading.value = true;

      final branchId = _authController.currentUser.value?.branchId;
      final userId = _authController.currentUser.value?.id;

      if (branchId == null) {
        throw Exception('Branch not found');
      }

      await _dataSource.createExpense(
        branchId: branchId,
        category: category,
        description: description,
        amount: amount,
        paymentMode: paymentMode,
        expenseDate: expenseDate,
        receiptNumber: receiptNumber,
        vendorName: vendorName,
        notes: notes,
        createdBy: userId,
      );

      // Reload expenses
      await loadExpenses();

      return true;
    } catch (e) {
      print('[ExpenseController] Error creating expense: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      isLoading.value = true;

      final success = await _dataSource.deleteExpense(expenseId);

      if (success) {
        await loadExpenses();
      }

      return success;
    } catch (e) {
      print('[ExpenseController] Error deleting expense: $e');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadExpenses();
  }

  String getCategoryLabel(String? category) {
    return categoryLabels[category ?? 'other'] ?? 'Other';
  }

  String getPaymentModeLabel(String? mode) {
    return paymentModeLabels[mode ?? 'cash'] ?? 'Cash';
  }

  String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }
}
