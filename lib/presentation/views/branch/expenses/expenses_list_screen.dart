import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/expense_controller.dart';

class ExpensesListScreen extends StatelessWidget {
  const ExpensesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ec = Get.find<ExpenseController>();
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ec.refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.createExpense),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: theme.primaryColor,
      ),
      body: Obx(() {
        if (ec.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => ec.refresh(),
          child: CustomScrollView(
            slivers: [
              // Summary Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Expenses',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ec.formatCurrency(ec.totalExpenses.value),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${ec.expenses.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'Records',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category Summary
              if (ec.categoryTotals.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: ec.categoryTotals.length,
                      itemBuilder: (context, index) {
                        final category = ec.categoryTotals.keys.elementAt(
                          index,
                        );
                        final amount = ec.categoryTotals[category] ?? 0;
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ec.getCategoryLabel(category),
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                ec.formatCurrency(amount),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Expenses List
              if (ec.expenses.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Expenses Yet',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text('Tap the button below to add an expense'),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.createExpense),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Expense'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final expense = ec.expenses[index];
                    final expenseDate = DateTime.tryParse(
                      expense['expense_date'] ?? '',
                    );
                    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
                    final category = expense['category'] as String? ?? 'other';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(
                              category,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(category),
                            color: _getCategoryColor(category),
                          ),
                        ),
                        title: Text(
                          expense['description'] ?? 'No description',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      category,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    ec.getCategoryLabel(category),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getCategoryColor(category),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  ec.getPaymentModeLabel(
                                    expense['payment_mode'],
                                  ),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (expense['vendor_name'] != null &&
                                expense['vendor_name'].isNotEmpty)
                              Text(
                                'Vendor: ${expense['vendor_name']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              ec.formatCurrency(amount),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              expenseDate != null
                                  ? dateFormat.format(expenseDate)
                                  : '-',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () => _showExpenseDetails(context, expense, ec),
                      ),
                    );
                  }, childCount: ec.expenses.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      }),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'rent':
        return Colors.purple;
      case 'utilities':
        return Colors.blue;
      case 'salaries':
        return Colors.green;
      case 'marketing':
        return Colors.pink;
      case 'transport':
        return Colors.orange;
      case 'maintenance':
        return Colors.teal;
      case 'office_supplies':
        return Colors.indigo;
      case 'food':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'rent':
        return Icons.home;
      case 'utilities':
        return Icons.bolt;
      case 'salaries':
        return Icons.people;
      case 'marketing':
        return Icons.campaign;
      case 'transport':
        return Icons.local_shipping;
      case 'maintenance':
        return Icons.build;
      case 'office_supplies':
        return Icons.inventory;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.receipt;
    }
  }

  void _showExpenseDetails(
    BuildContext context,
    Map<String, dynamic> expense,
    ExpenseController ec,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final expenseDate = DateTime.tryParse(expense['expense_date'] ?? '');
    final createdAt = DateTime.tryParse(expense['created_at'] ?? '');
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0;
    final category = expense['category'] as String? ?? 'other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ec.getCategoryLabel(category),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        ec.formatCurrency(amount),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Description', expense['description'] ?? '-'),
            _buildDetailRow(
              'Date',
              expenseDate != null ? dateFormat.format(expenseDate) : '-',
            ),
            _buildDetailRow(
              'Payment Mode',
              ec.getPaymentModeLabel(expense['payment_mode']),
            ),
            if (expense['vendor_name'] != null &&
                expense['vendor_name'].isNotEmpty)
              _buildDetailRow('Vendor', expense['vendor_name']),
            if (expense['receipt_number'] != null &&
                expense['receipt_number'].isNotEmpty)
              _buildDetailRow('Receipt #', expense['receipt_number']),
            if (expense['notes'] != null && expense['notes'].isNotEmpty)
              _buildDetailRow('Notes', expense['notes']),
            _buildDetailRow(
              'Created',
              createdAt != null
                  ? DateFormat('MMM dd, yyyy hh:mm a').format(createdAt)
                  : '-',
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(context, expense['id'], ec);
                    },
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String expenseId,
    ExpenseController ec,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ec.deleteExpense(expenseId);
              if (success) {
                Get.snackbar('Success', 'Expense deleted successfully');
              } else {
                Get.snackbar('Error', 'Failed to delete expense');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
