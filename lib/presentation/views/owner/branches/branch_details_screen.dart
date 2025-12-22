import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/branch_controller.dart';

class BranchDetailsScreen extends StatelessWidget {
  const BranchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    BranchController? branchController;
    try {
      branchController = Get.find<BranchController>();
    } catch (e) {
      print('BranchDetailsScreen: BranchController not found: $e');
      return Scaffold(
        appBar: AppBar(title: const Text('Branch Details'), elevation: 0),
        body: const Center(child: Text('Branch controller not available')),
      );
    }
    final Map<String, dynamic> initialBranch =
        Get.arguments as Map<String, dynamic>? ?? {};
    final String? branchId = initialBranch['id'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Branch Details'), elevation: 0),
      body: Obx(() {
        // Get updated branch data from controller, fallback to initial if not found
        Map<String, dynamic> branch = initialBranch;
        if (branchId != null && branchController != null) {
          try {
            final updatedBranch = branchController.branches.firstWhere(
              (b) => (b['id'] as String?) == branchId,
            );
            branch = updatedBranch;
          } catch (_) {
            // Branch not found in list, use initial data
            branch = initialBranch;
          }
        }

        final isActive = branch['is_active'] == true;
        final isMain = branch['is_main'] == true;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Branch Info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.store,
                              size: 32,
                              color: theme.primaryColor,
                            ),
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
                                if (branch['code'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Code: ${branch['code']}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: isDark
                                          ? theme.colorScheme.onSurfaceVariant
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Status Badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // Active/Inactive Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isActive ? Icons.check_circle : Icons.cancel,
                                  size: 16,
                                  color: isActive ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Main Branch Badge
                          if (isMain)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Main Branch',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
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
              ),
              const SizedBox(height: 16),
              // Contact Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.contact_phone,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Contact Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (branch['phone'] != null)
                        _buildInfoRow(
                          context: context,
                          theme: theme,
                          icon: Icons.phone,
                          label: 'Phone',
                          value: branch['phone'],
                          iconColor: Colors.green,
                        ),
                      if (branch['email'] != null) ...[
                        if (branch['phone'] != null) const SizedBox(height: 16),
                        _buildInfoRow(
                          context: context,
                          theme: theme,
                          icon: Icons.email,
                          label: 'Email',
                          value: branch['email'],
                          iconColor: Colors.blue,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Address Information Card
              if (branch['address'] != null ||
                  branch['city'] != null ||
                  branch['state'] != null ||
                  branch['pincode'] != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.purple,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Address Information',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (branch['address'] != null)
                          _buildInfoRow(
                            context: context,
                            theme: theme,
                            icon: Icons.home,
                            label: 'Address',
                            value: branch['address'],
                            iconColor: Colors.purple,
                          ),
                        if (branch['city'] != null ||
                            branch['state'] != null) ...[
                          if (branch['address'] != null)
                            const SizedBox(height: 16),
                          _buildInfoRow(
                            context: context,
                            theme: theme,
                            icon: Icons.location_city,
                            label: 'Location',
                            value:
                                '${branch['city'] ?? ''} ${branch['state'] ?? ''}'
                                    .trim(),
                            iconColor: Colors.purple,
                          ),
                        ],
                        if (branch['pincode'] != null) ...[
                          if (branch['address'] != null ||
                              branch['city'] != null ||
                              branch['state'] != null)
                            const SizedBox(height: 16),
                          _buildInfoRow(
                            context: context,
                            theme: theme,
                            icon: Icons.pin,
                            label: 'Pincode',
                            value: branch['pincode'],
                            iconColor: Colors.purple,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (branch['address'] != null ||
                  branch['city'] != null ||
                  branch['state'] != null ||
                  branch['pincode'] != null)
                const SizedBox(height: 16),
              // Action Buttons Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.toNamed(
                                  AppRoutes.branchEdit,
                                  arguments: branch,
                                );
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Branch'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isMain
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          title: const Text('Delete Branch'),
                                          content: Text(
                                            'Are you sure you want to delete "${branch['name']}"? This action cannot be undone and will affect all associated data.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true && branchController != null) {
                                        final success = await branchController
                                            .deleteBranch(branch['id']);
                                        if (success) {
                                          Get.back();
                                          Get.snackbar(
                                            'Success',
                                            'Branch deleted successfully',
                                            snackPosition: SnackPosition.TOP,
                                            backgroundColor: Colors.green,
                                            colorText: Colors.white,
                                          );
                                        } else {
                                          Get.snackbar(
                                            'Error',
                                            'Failed to delete branch',
                                            snackPosition: SnackPosition.TOP,
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Delete Branch'),
                            ),
                          ),
                        ],
                      ),
                      if (isMain) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Main branch cannot be deleted. Set another branch as main first.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant
                      : Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
