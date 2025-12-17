import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/tenant_controller.dart';

class TenantsListScreen extends StatelessWidget {
  const TenantsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tc = Get.find<TenantController>();
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tenants'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tc.refreshTenants(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.tenantCreate),
        icon: const Icon(Icons.add_business),
        label: const Text('Add Tenant'),
        backgroundColor: theme.primaryColor,
      ),
      body: Obx(() {
        if (tc.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => tc.refreshTenants(),
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
                          tc.totalTenants.toString(),
                          Icons.business,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Active',
                          tc.activeTenants.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Inactive',
                          tc.inactiveTenants.toString(),
                          Icons.block,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Tenants List
              if (tc.tenants.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business_outlined,
                          size: 80,
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Tenants Yet',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text('Add your first tenant'),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.tenantCreate),
                          icon: const Icon(Icons.add_business),
                          label: const Text('Add Tenant'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final tenant = tc.tenants[index];
                    final createdAt = DateTime.tryParse(
                      tenant['created_at'] ?? '',
                    );
                    final isActive = tenant['is_active'] == true;
                    final plan =
                        tenant['subscription_plan'] as String? ?? 'basic';

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
                            color: _getPlanColor(plan).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.business,
                            size: 28,
                            color: _getPlanColor(plan),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tenant['business_name'] ??
                                    tenant['name'] ??
                                    'Unknown',
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
                            if (tenant['email'] != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.email,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      tenant['email'],
                                      style: theme.textTheme.bodySmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getPlanColor(
                                      plan,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    plan.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getPlanColor(plan),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (createdAt != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    dateFormat.format(createdAt),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'toggle') {
                              _toggleStatus(context, tenant, tc);
                            } else if (value == 'view') {
                              _showTenantDetails(context, tenant, tc);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 20),
                                  SizedBox(width: 8),
                                  Text('View Details'),
                                ],
                              ),
                            ),
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
                          ],
                        ),
                        onTap: () => _showTenantDetails(context, tenant, tc),
                      ),
                    );
                  }, childCount: tc.tenants.length),
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

  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'premium':
        return Colors.purple;
      case 'pro':
        return Colors.blue;
      case 'enterprise':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  void _toggleStatus(
    BuildContext context,
    Map<String, dynamic> tenant,
    TenantController tc,
  ) {
    final isActive = tenant['is_active'] == true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Deactivate Tenant' : 'Activate Tenant'),
        content: Text(
          isActive
              ? 'Are you sure you want to deactivate ${tenant['business_name']}?'
              : 'Are you sure you want to activate ${tenant['business_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await tc.toggleTenantStatus(
                tenant['id'],
                !isActive,
              );
              if (success) {
                Get.snackbar(
                  'Success',
                  'Tenant ${isActive ? 'deactivated' : 'activated'} successfully',
                );
              } else {
                Get.snackbar('Error', 'Failed to update tenant status');
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

  void _showTenantDetails(
    BuildContext context,
    Map<String, dynamic> tenant,
    TenantController tc,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final createdAt = DateTime.tryParse(tenant['created_at'] ?? '');

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
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    size: 32,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tenant['business_name'] ?? tenant['name'] ?? 'Unknown',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tenant['subscription_plan']?.toString().toUpperCase() ??
                            'BASIC',
                        style: TextStyle(
                          color: _getPlanColor(
                            tenant['subscription_plan'] ?? 'basic',
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (tenant['email'] != null)
              _buildDetailRow('Email', tenant['email']),
            if (tenant['phone'] != null)
              _buildDetailRow('Phone', tenant['phone']),
            if (tenant['address'] != null)
              _buildDetailRow('Address', tenant['address']),
            if (tenant['gst_number'] != null)
              _buildDetailRow('GST Number', tenant['gst_number']),
            _buildDetailRow(
              'Status',
              tenant['is_active'] == true ? 'Active' : 'Inactive',
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
}
