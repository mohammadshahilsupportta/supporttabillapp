import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/bill_model.dart';
import '../../../controllers/billing_controller.dart';
import '../../../controllers/branch_controller.dart';
import '../../../controllers/auth_controller.dart';

class BillDetailScreen extends StatefulWidget {
  const BillDetailScreen({super.key});

  @override
  State<BillDetailScreen> createState() => _BillDetailScreenState();
}

class _BillDetailScreenState extends State<BillDetailScreen> {
  Bill? bill;
  bool isLoading = true;
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
      setState(() => isLoading = true);
      final controller = Get.find<BillingController>();
      final billId = Get.parameters['id'];
      if (billId == null) {
        throw Exception('Bill ID not found');
      }
      final loadedBill = await controller.getBillById(billId);
      if (mounted) {
        print('Bill loaded: ${loadedBill?.invoiceNumber}');
        print('Bill items count: ${loadedBill?.items?.length ?? 0}');
        if (loadedBill?.items != null) {
          print('Items: ${loadedBill!.items!.map((i) => i.productName).toList()}');
        }
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
                decoration: const InputDecoration(
                  labelText: 'Payment Mode',
                ),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                                          style: theme.textTheme.headlineSmall?.copyWith(
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
                            isFullyPaid ? 'Paid' : '₹${dueAmount.toStringAsFixed(2)}',
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
                    _buildSummaryRow('Subtotal', '₹${bill!.subtotal.toStringAsFixed(2)}', theme),
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
                    _buildSummaryRow('GST', '₹${bill!.gstAmount.toStringAsFixed(2)}', theme),
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

  Widget _buildInfoItem(IconData icon, String label, String value, ThemeData theme) {
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
        columns: const [
          DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
            label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('Unit Price', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('GST Rate', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
          DataColumn(
            label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            numeric: true,
          ),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              DataCell(Text(item.quantity.toString())),
              DataCell(Text('₹${item.unitPrice.toStringAsFixed(2)}')),
              DataCell(Text('${item.gstRate.toStringAsFixed(1)}%')),
              DataCell(
                Text(
                  '₹${item.discount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: item.discount > 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '₹${item.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme, {Color? color}) {
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
}
