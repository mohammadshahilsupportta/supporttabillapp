import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/user_controller.dart';

class UsersListScreen extends StatelessWidget {
  const UsersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uc = Get.find<UserController>();
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => uc.refreshUsers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.userCreate),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        backgroundColor: theme.primaryColor,
      ),
      body: Obx(() {
        if (uc.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => uc.refreshUsers(),
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
                          'Total Users',
                          uc.totalUsers.toString(),
                          Icons.people,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Active',
                          uc.activeUsers.toString(),
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          'Inactive',
                          uc.inactiveUsers.toString(),
                          Icons.block,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Role Summary
              if (uc.roleCounts.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: uc.roleCounts.length,
                      itemBuilder: (context, index) {
                        final role = uc.roleCounts.keys.elementAt(index);
                        final count = uc.roleCounts[role] ?? 0;
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
                                uc.getRoleLabel(role),
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '$count',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.primaryColor,
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

              // Users List
              if (uc.users.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: theme.primaryColor.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Users Yet',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        const Text('Add your first team member'),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => Get.toNamed(AppRoutes.userCreate),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add User'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final user = uc.users[index];
                    final createdAt = DateTime.tryParse(
                      user['created_at'] ?? '',
                    );
                    final isActive = user['is_active'] == true;
                    final role = user['role'] as String? ?? 'unknown';
                    final branch = user['branches'];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: _getRoleColor(
                            role,
                          ).withValues(alpha: 0.1),
                          child: Text(
                            (user['full_name'] as String? ?? '?')[0]
                                .toUpperCase(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _getRoleColor(role),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user['full_name'] ?? 'Unknown',
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
                            Text(
                              user['email'] ?? '-',
                              style: theme.textTheme.bodySmall,
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
                                    color: _getRoleColor(
                                      role,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    uc.getRoleLabel(role),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getRoleColor(role),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (branch != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    branch['name'] ?? '',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (createdAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Joined: ${dateFormat.format(createdAt)}',
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
                              _toggleStatus(context, user, uc);
                            } else if (value == 'edit') {
                              Get.snackbar('Coming Soon', 'Edit user feature');
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
                        onTap: () => _showUserDetails(context, user, uc),
                      ),
                    );
                  }, childCount: uc.users.length),
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'tenantOwner':
        return Colors.purple;
      case 'branchAdmin':
        return Colors.blue;
      case 'branchStaff':
        return Colors.green;
      case 'superadmin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _toggleStatus(
    BuildContext context,
    Map<String, dynamic> user,
    UserController uc,
  ) {
    final isActive = user['is_active'] == true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isActive ? 'Deactivate User' : 'Activate User'),
        content: Text(
          isActive
              ? 'Are you sure you want to deactivate ${user['full_name']}?'
              : 'Are you sure you want to activate ${user['full_name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await uc.toggleUserStatus(user['id'], !isActive);
              if (success) {
                Get.snackbar(
                  'Success',
                  'User ${isActive ? 'deactivated' : 'activated'} successfully',
                );
              } else {
                Get.snackbar('Error', 'Failed to update user status');
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

  void _showUserDetails(
    BuildContext context,
    Map<String, dynamic> user,
    UserController uc,
  ) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final createdAt = DateTime.tryParse(user['created_at'] ?? '');
    final branch = user['branches'];

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
                CircleAvatar(
                  radius: 32,
                  backgroundColor: _getRoleColor(
                    user['role'],
                  ).withValues(alpha: 0.1),
                  child: Text(
                    (user['full_name'] as String? ?? '?')[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _getRoleColor(user['role']),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['full_name'] ?? 'Unknown',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        uc.getRoleLabel(user['role']),
                        style: TextStyle(
                          color: _getRoleColor(user['role']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Email', user['email'] ?? '-'),
            if (user['phone'] != null) _buildDetailRow('Phone', user['phone']),
            if (branch != null)
              _buildDetailRow('Branch', branch['name'] ?? '-'),
            _buildDetailRow(
              'Status',
              user['is_active'] == true ? 'Active' : 'Inactive',
            ),
            if (createdAt != null)
              _buildDetailRow('Joined', dateFormat.format(createdAt)),
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
