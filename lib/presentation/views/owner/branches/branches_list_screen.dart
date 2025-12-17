import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/branch_controller.dart';

class BranchesListScreen extends StatelessWidget {
  const BranchesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bc = Get.find<BranchController>();
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Branches'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => bc.refreshBranches(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.branchCreate),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Branch'),
        backgroundColor: theme.primaryColor,
      ),
      body: Obx(() {
        if (bc.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => bc.refreshBranches(),
          child: CustomScrollView(
            slivers: [
              // Summary Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total',
                          bc.totalBranches.toString(),
                          Icons.store,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Active',
                          bc.activeBranches.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Inactive',
                          bc.inactiveBranches.toString(),
                          Icons.block,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Branches List
              if (bc.branches.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 80,
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Branches Yet',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text('Add your first branch'),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.branchCreate),
                          icon: const Icon(Icons.add_business),
                          label: const Text('Add Branch'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final branch = bc.branches[index];
                    final createdAt = DateTime.tryParse(
                      branch['created_at'] ?? '',
                    );
                    final isActive = branch['is_active'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.store,
                            size: 28,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                branch['name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (branch['code'] != null)
                              Text(
                                'Code: ${branch['code']}',
                                style: theme.textTheme.bodySmall,
                              ),
                            if (branch['address'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      branch['address'],
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (branch['phone'] != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    branch['phone'],
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Created: ${dateFormat.format(createdAt)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'toggle') {
                              _toggleStatus(context, branch, bc);
                            } else if (value == 'edit') {
                              Get.snackbar(
                                'Coming Soon',
                                'Edit branch feature',
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Row(
                                children: [
                                  Icon(
                                    isActive ? Icons.block : Icons.check_circle,
                                    size: 20,
                                    color: isActive ? Colors.red : Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isActive ? 'Deactivate' : 'Activate'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _showBranchDetails(context, branch, bc),
                      ),
                    );
                  }, childCount: bc.branches.length),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(title, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  void _toggleStatus(
    BuildContext context,
    Map<String, dynamic> branch,
    BranchController bc,
  ) {
    final isActive = branch['is_active'] == true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Deactivate Branch' : 'Activate Branch'),
        content: Text(
          isActive
              ? 'Are you sure you want to deactivate ${branch['name']}?'
              : 'Are you sure you want to activate ${branch['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await bc.toggleBranchStatus(
                branch['id'],
                !isActive,
              );
              if (success) {
                Get.snackbar(
                  'Success',
                  'Branch ${isActive ? 'deactivated' : 'activated'} successfully',
                );
              } else {
                Get.snackbar('Error', 'Failed to update branch status');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
            ),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _showBranchDetails(
    BuildContext context,
    Map<String, dynamic> branch,
    BranchController bc,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final createdAt = DateTime.tryParse(branch['created_at'] ?? '');

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
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.store, size: 32, color: Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch['name'] ?? 'Unknown',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (branch['code'] != null)
                        Text(
                          'Code: ${branch['code']}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (branch['address'] != null)
              _buildDetailRow('Address', branch['address']),
            if (branch['city'] != null || branch['state'] != null)
              _buildDetailRow(
                'Location',
                '${branch['city'] ?? ''} ${branch['state'] ?? ''}'.trim(),
              ),
            if (branch['pincode'] != null)
              _buildDetailRow('Pincode', branch['pincode']),
            if (branch['phone'] != null)
              _buildDetailRow('Phone', branch['phone']),
            if (branch['email'] != null)
              _buildDetailRow('Email', branch['email']),
            _buildDetailRow(
              'Status',
              branch['is_active'] == true ? 'Active' : 'Inactive',
            ),
            if (createdAt != null)
              _buildDetailRow('Created', dateFormat.format(createdAt)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
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
            width: 80,
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
}
