import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../../data/models/bill_model.dart';
import '../../../controllers/billing_controller.dart';
import '../../../controllers/branch_controller.dart';

class BillsListScreen extends StatefulWidget {
  const BillsListScreen({super.key});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  DateTime? startDate;
  DateTime? endDate;
  String searchQuery = '';
  String dateFilter = 'all'; // 'today', 'month', 'all' - Default: 'all'
  String paymentStatusFilter = 'all'; // 'all', 'paid', 'due'
  String paymentModeFilter = 'all'; // 'all', 'cash', 'card', 'upi', 'credit'

  @override
  void initState() {
    super.initState();
    // Initialize date filters with default 'all'
    _updateDateFilters();
    // Load branches if needed
    try {
      Get.put(BranchController());
    } catch (_) {
      // Already initialized
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = Get.put(BillingController());
    final branchController = Get.find<BranchController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
        actions: [
          // Period Filter Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButton<String>(
                value: dateFilter,
                underline: const SizedBox(),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: theme.primaryColor,
                  size: 20,
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'today',
                    child: Text('Today', style: TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem(
                    value: 'month',
                    child: Text('This Month', style: TextStyle(fontSize: 13)),
                  ),
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('All Time', style: TextStyle(fontSize: 13)),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      dateFilter = value;
                      _updateDateFilters();
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Compact Stats Cards - Horizontal Scrollable
          Obx(() {
            final filteredBills = _getFilteredBills(controller.bills);
            final stats = _calculateStats(filteredBills);

            return Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildCompactStatCard(
                    'Sales',
                    '₹${stats['totalSales'].toStringAsFixed(0)}',
                    '${stats['totalOrders']} orders',
                    Icons.currency_rupee,
                    Colors.green,
                    theme,
                  ),
                  const SizedBox(width: 8),
                  _buildCompactStatCard(
                    'Profit',
                    '₹${stats['totalProfit'].toStringAsFixed(0)}',
                    stats['totalSales'] > 0
                        ? '${((stats['totalProfit'] / stats['totalSales']) * 100).toStringAsFixed(1)}%'
                        : '-',
                    Icons.trending_up,
                    Colors.purple,
                    theme,
                  ),
                  const SizedBox(width: 8),
                  _buildCompactStatCard(
                    'Due',
                    '₹${stats['totalDue'].toStringAsFixed(0)}',
                    '${stats['dueOrdersCount']} orders',
                    Icons.pending,
                    Colors.red,
                    theme,
                  ),
                ],
              ),
            );
          }),

          // Search and Filters - Compact
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Search Bar - Compact
                SizedBox(
                  height: 40,
                  child: TextField(
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search invoice, customer...',
                      hintStyle: theme.textTheme.bodySmall,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // Filter Row - Compact
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactFilterDropdown(
                        paymentStatusFilter,
                        ['all', 'paid', 'due'],
                        ['All Orders', 'Paid', 'Due'],
                        (value) {
                          setState(() {
                            paymentStatusFilter = value;
                          });
                        },
                        theme,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildCompactFilterDropdown(
                        paymentModeFilter,
                        ['all', 'cash', 'card', 'upi', 'credit'],
                        ['All Modes', 'Cash', 'Card', 'UPI', 'Credit'],
                        (value) {
                          setState(() {
                            paymentModeFilter = value;
                          });
                        },
                        theme,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bills List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredBills = _getFilteredBills(controller.bills);

              if (filteredBills.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: theme.primaryColor.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders found',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        searchQuery.isNotEmpty ||
                                paymentStatusFilter != 'all' ||
                                paymentModeFilter != 'all'
                            ? 'Try adjusting your filters'
                            : 'Create your first order to get started',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => controller.loadBills(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBills.length,
                  itemBuilder: (context, index) {
                    final bill = filteredBills[index];
                    return _buildBillCard(bill, theme, branchController);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.posBilling),
        icon: const Icon(Icons.add),
        label: const Text('Create Order'),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  Widget _buildCompactStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactFilterDropdown(
    String value,
    List<String> values,
    List<String> labels,
    Function(String) onChanged,
    ThemeData theme,
  ) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
        items: List.generate(
          values.length,
          (index) => DropdownMenuItem(
            value: values[index],
            child: Text(labels[index], style: const TextStyle(fontSize: 13)),
          ),
        ),
        onChanged: (newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
      ),
    );
  }

  void _updateDateFilters() {
    final now = DateTime.now();
    switch (dateFilter) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = now;
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
      case 'all':
        startDate = null;
        endDate = null;
        break;
    }
  }

  List<Bill> _getFilteredBills(List<Bill> bills) {
    _updateDateFilters();

    return bills.where((bill) {
      // Search filter
      final matchesSearch =
          searchQuery.isEmpty ||
          bill.invoiceNumber.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          (bill.customerName?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false) ||
          (bill.customerPhone?.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ??
              false);

      // Date filter
      final matchesDate =
          (startDate == null || bill.createdAt.isAfter(startDate!)) &&
          (endDate == null ||
              bill.createdAt.isBefore(endDate!.add(const Duration(days: 1))));

      // Payment status filter
      final isFullyPaid = (bill.dueAmount ?? 0) <= 0;
      final matchesPaymentStatus =
          paymentStatusFilter == 'all' ||
          (paymentStatusFilter == 'paid' && isFullyPaid) ||
          (paymentStatusFilter == 'due' && !isFullyPaid);

      // Payment mode filter
      final matchesPaymentMode =
          paymentModeFilter == 'all' ||
          bill.paymentMode.value == paymentModeFilter;

      return matchesSearch &&
          matchesDate &&
          matchesPaymentStatus &&
          matchesPaymentMode;
    }).toList();
  }

  Map<String, dynamic> _calculateStats(List<Bill> bills) {
    double totalSales = 0;
    double totalProfit = 0;
    double totalDue = 0;
    int dueOrdersCount = 0;

    for (final bill in bills) {
      totalSales += bill.totalAmount;
      totalProfit += bill.profitAmount;
      final due = bill.dueAmount ?? 0;
      totalDue += due;
      if (due > 0) {
        dueOrdersCount++;
      }
    }

    return {
      'totalSales': totalSales,
      'totalProfit': totalProfit,
      'totalDue': totalDue,
      'dueOrdersCount': dueOrdersCount,
      'totalOrders': bills.length,
    };
  }

  Widget _buildBillCard(
    Bill bill,
    ThemeData theme,
    BranchController branchController,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isFullyPaid = (bill.dueAmount ?? 0) <= 0;

    // Get branch name
    String branchName = 'N/A';
    try {
      final branch = branchController.branches.firstWhere(
        (b) => b['id'] == bill.branchId,
        orElse: () => <String, dynamic>{},
      );
      branchName = branch['name'] ?? 'N/A';
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Get.toNamed(AppRoutes.billDetail.replaceAll(':id', bill.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.invoiceNumber,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateFormat.format(bill.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              timeFormat.format(bill.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${bill.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPaymentModeColor(
                            bill.paymentMode,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bill.paymentMode.value.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getPaymentModeColor(bill.paymentMode),
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(),

              // Details Row
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    // Customer Info
                    if (bill.customerName != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bill.customerName!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          if (bill.customerPhone != null) ...[
                            Icon(
                              Icons.phone_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              bill.customerPhone!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Branch Info
                    Row(
                      children: [
                        Icon(Icons.store, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            branchName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Financial Info Row
                    Row(
                      children: [
                        // Profit
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profit',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${bill.profitAmount.toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Due Amount
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Due Amount',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isFullyPaid
                                    ? 'Paid'
                                    : '₹${(bill.dueAmount ?? 0).toStringAsFixed(2)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: isFullyPaid
                                      ? Colors.green
                                      : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPaymentModeColor(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Colors.green;
      case PaymentMode.card:
        return Colors.blue;
      case PaymentMode.upi:
        return Colors.purple;
      case PaymentMode.credit:
        return Colors.orange;
      case PaymentMode.bankTransfer:
        return Colors.teal;
    }
  }
}
