import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../data/datasources/billing_datasource.dart';
import '../../../../data/models/bill_model.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/billing_controller.dart';
import '../../../controllers/branch_controller.dart';

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  Bill? bill;
  bool isLoading = true;
  bool isLoadingItems = false;
  bool isProcessingPayment = false;
  bool isUpdatingItem = false;
  String? editingItemId;
  final Map<String, Map<String, String>> editValues = {};
  final TextEditingController paymentAmountController = TextEditingController();
  PaymentMode selectedPaymentMode = PaymentMode.cash;

  @override
  void initState() {
    super.initState();
    _loadBill();
  }

  @override
  void dispose() {
    paymentAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadBill() async {
    try {
      final billId = Get.parameters['id'];
      if (billId == null) {
        throw Exception('Bill ID not found');
      }

      // Check if bill was passed as argument (fast path)
      final passedBill = Get.arguments as Bill?;
      if (passedBill != null) {
        // Use passed bill immediately - screen loads instantly!
        if (mounted) {
          setState(() {
            bill = passedBill;
            isLoading = false;
          });
        }

        // Load items in background if not already present
        if (passedBill.items == null || passedBill.items!.isEmpty) {
          setState(() => isLoadingItems = true);
          _loadBillItems(billId);
        }
        return;
      }

      // Fallback: fetch full bill (slower path - for deep links)
      setState(() => isLoading = true);
      final controller = Get.find<BillingController>();
      final loadedBill = await controller.getBillById(billId);
      if (mounted) {
        setState(() {
          bill = loadedBill;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        Get.snackbar('Error', 'Failed to load bill: ${e.toString()}');
      }
    }
  }

  Future<void> _loadBillItems(String billId) async {
    try {
      final controller = Get.find<BillingController>();
      // Use faster items-only fetch
      final items = await controller.getBillItemsOnly(billId);
      if (mounted && bill != null) {
        setState(() {
          // Use copyWith from BillExtension
          bill = bill!.copyWith(items: items);
          isLoadingItems = false;
        });
      }
    } catch (e) {
      // Items loading failed silently - bill info is still visible
      print('Failed to load bill items: $e');
      if (mounted) {
        setState(() => isLoadingItems = false);
      }
    }
  }

  Future<void> _collectPayment() async {
    if (bill == null) return;

    final amount = double.tryParse(paymentAmountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar('Error', 'Please enter a valid amount');
      return;
    }

    final currentPaid = bill!.paidAmount ?? 0;
    final totalAmount = bill!.totalAmount;
    final dueAmount = totalAmount - currentPaid;

    if (amount > dueAmount) {
      Get.snackbar(
        'Error',
        'Payment amount exceeds due. Maximum: ₹${dueAmount.toStringAsFixed(2)}',
      );
      return;
    }

    setState(() => isProcessingPayment = true);
    try {
      // Note: Payment collection API needs to be implemented in BillingDataSource
      // For now, show a message
      Get.snackbar('Info', 'Payment collection feature will be implemented');
      // TODO: Implement payment collection
      // final controller = Get.find<BillingController>();
      // await controller.addPayment(billId: bill!.id, amount: amount, paymentMode: selectedPaymentMode);

      paymentAmountController.clear();
      if (mounted) {
        Navigator.pop(context); // Close dialog
        await _loadBill(); // Reload bill
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to record payment: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isProcessingPayment = false);
      }
    }
  }

  void _showPaymentDialog() {
    final dueAmount = (bill!.totalAmount - (bill!.paidAmount ?? 0));
    paymentAmountController.text = dueAmount.toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Collect Payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: paymentAmountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Max: ₹${dueAmount.toStringAsFixed(2)}',
                  prefixText: '₹',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMode>(
                value: selectedPaymentMode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: PaymentMode.values.map((mode) {
                  return DropdownMenuItem(
                    value: mode,
                    child: Text(mode.value.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedPaymentMode = value);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isProcessingPayment ? null : _collectPayment,
            child: isProcessingPayment
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branchController = Get.find<BranchController>();
    final authController = Get.find<AuthController>();

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (bill == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Order not found', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
    final paidAmount = bill!.paidAmount ?? 0;
    final totalAmount = bill!.totalAmount;
    final dueAmount = totalAmount - paidAmount;
    final isFullyPaid = dueAmount <= 0;

    // Get branch name
    String branchName = 'N/A';
    try {
      final branch = branchController.branches.firstWhere(
        (b) => b['id'] == bill!.branchId,
        orElse: () => <String, dynamic>{},
      );
      branchName = branch['name'] ?? 'N/A';
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: () {
                Get.snackbar('Info', 'PDF download feature coming soon');
              },
              icon: const Icon(Icons.download, size: 18, color: Colors.white),
              label: const Text(
                'Download PDF',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.receipt,
                                    color: theme.primaryColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      bill!.invoiceNumber,
                                      style: theme.textTheme.headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                dateFormat.format(bill!.createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isFullyPaid)
                          OutlinedButton.icon(
                            onPressed: _showPaymentDialog,
                            icon: const Icon(Icons.payment, size: 18),
                            label: const Text('Collect Payment'),
                          ),
                      ],
                    ),
                    const Divider(height: 32),
                    // Branch and Customer Info
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoItem(
                                Icons.store,
                                'Branch',
                                branchName,
                                theme,
                              ),
                              if (authController.currentUser.value != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoItem(
                                  Icons.person,
                                  'Created By',
                                  authController.currentUser.value!.fullName,
                                  theme,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (bill!.customerName != null)
                                _buildInfoItem(
                                  Icons.person_outline,
                                  'Customer',
                                  bill!.customerName!,
                                  theme,
                                ),
                              if (bill!.customerPhone != null) ...[
                                const SizedBox(height: 12),
                                _buildInfoItem(
                                  Icons.phone,
                                  'Phone',
                                  bill!.customerPhone!,
                                  theme,
                                ),
                              ],
                              const SizedBox(height: 12),
                              _buildInfoItem(
                                Icons.payment,
                                'Payment Mode',
                                bill!.paymentMode.value.toUpperCase(),
                                theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Payment Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPaymentStatusItem(
                            'Total Amount',
                            '₹${totalAmount.toStringAsFixed(2)}',
                            Colors.black87,
                            theme,
                          ),
                          _buildPaymentStatusItem(
                            'Paid Amount',
                            '₹${paidAmount.toStringAsFixed(2)}',
                            Colors.green,
                            theme,
                          ),
                          _buildPaymentStatusItem(
                            'Due Amount',
                            isFullyPaid
                                ? 'Paid'
                                : '₹${dueAmount.toStringAsFixed(2)}',
                            isFullyPaid ? Colors.green : Colors.red,
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (bill!.items != null && bill!.items!.isNotEmpty)
                      _buildItemsTable(bill!.items!, theme)
                    else if (isLoadingItems)
                      _buildItemsShimmer(theme)
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No items in this order',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Order Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Subtotal',
                      '₹${bill!.subtotal.toStringAsFixed(2)}',
                      theme,
                    ),
                    if (bill!.discount > 0) ...[
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Discount',
                        '-₹${bill!.discount.toStringAsFixed(2)}',
                        theme,
                        color: Colors.red,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'GST',
                      '₹${bill!.gstAmount.toStringAsFixed(2)}',
                      theme,
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (bill!.profitAmount > 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profit',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                          Text(
                            '₹${bill!.profitAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStatusItem(
    String label,
    String value,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(List<BillItem> items, ThemeData theme) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;

        return Container(
          margin: EdgeInsets.only(bottom: index < items.length - 1 ? 12 : 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.grey[800]
                : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.grey[700]!
                  : Colors.grey[200]!,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name and Total
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '₹${item.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Quantity x Price
              Text(
                '${item.quantity} × ₹${item.unitPrice.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),

              // Details Row (GST, Discount)
              Row(
                children: [
                  _buildItemDetailChip(
                    'GST: ${item.gstRate.toStringAsFixed(1)}%',
                    theme,
                  ),
                  const SizedBox(width: 8),
                  if (item.discount > 0)
                    _buildItemDetailChip(
                      'Disc: ₹${item.discount.toStringAsFixed(2)}',
                      theme,
                      isDiscount: true,
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemDetailChip(
    String text,
    ThemeData theme, {
    bool isDiscount = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDiscount
            ? Colors.red.withValues(alpha: 0.1)
            : theme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDiscount ? Colors.red : theme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Column(
      children: List.generate(3, (index) {
        return Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            margin: EdgeInsets.only(bottom: index < 2 ? 12 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name and Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 18,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 18,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Quantity row
                Container(
                  height: 14,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                // Chips row
                Row(
                  children: [
                    Container(
                      height: 24,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 24,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
