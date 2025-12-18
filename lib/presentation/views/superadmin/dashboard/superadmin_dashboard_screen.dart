import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/dashboard_controller.dart';

class SuperadminDashboardScreen extends StatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  State<SuperadminDashboardScreen> createState() =>
      _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState extends State<SuperadminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const _TenantsTab(),
    const _UsersTab(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_getTitle()), elevation: 0),
      body: _screens[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickActionsSheet(context),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Home'),
            _buildNavItem(
              1,
              Icons.business_outlined,
              Icons.business,
              'Tenants',
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(2, Icons.people_outline, Icons.people, 'Users'),
            _buildNavItem(
              3,
              Icons.settings_outlined,
              Icons.settings,
              'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _selectedIndex == index;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? theme.primaryColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? theme.primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActionsSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Quick Actions', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context,
                  Icons.business,
                  'Add Tenant',
                  Colors.purple,
                  () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.tenantCreate);
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.person_add,
                  'Add User',
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    Get.snackbar('Coming Soon', 'Add user');
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.analytics,
                  'Reports',
                  Colors.blue,
                  () {
                    Navigator.pop(context);
                    Get.snackbar('Coming Soon', 'Reports');
                  },
                ),
                _buildActionButton(
                  context,
                  Icons.backup,
                  'Backup',
                  Colors.orange,
                  () {
                    Navigator.pop(context);
                    Get.snackbar('Coming Soon', 'Backup');
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Superadmin Dashboard';
      case 1:
        return 'Tenants';
      case 2:
        return 'Users';
      case 3:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }
}

// ============ DASHBOARD TAB ============
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authController = Get.find<AuthController>();
    final dc = Get.find<DashboardController>();

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Obx(
              () => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.purple.withValues(alpha: 0.1),
                        child: Text(
                          authController.currentUser.value?.fullName[0] ?? 'S',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.purple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Superadmin',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              authController.currentUser.value?.fullName ??
                                  'Admin',
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'SUPERADMIN',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('System Overview', style: theme.textTheme.titleLarge),
                Obx(
                  () => dc.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () => dc.refreshStats(),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats Grid
            Obx(
              () => GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    context,
                    'Active Tenants',
                    '${dc.tenantCount.value}',
                    Icons.business,
                    const Color(0xFF8B5CF6), // Violet
                  ),
                  _buildStatCard(
                    context,
                    'Total Users',
                    '${dc.userCount.value}',
                    Icons.people,
                    const Color(0xFF10B981), // Green
                  ),
                  _buildStatCard(
                    context,
                    'Total Branches',
                    '${dc.branchCount.value}',
                    Icons.store,
                    const Color(0xFFF59E0B), // Warning orange
                  ),
                  _buildStatCard(
                    context,
                    "Today's Sales",
                    dc.formatCurrency(dc.totalSales.value),
                    Icons.currency_rupee,
                    const Color(0xFF2563EB), // Primary blue
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Management
            Text('System Management', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  context,
                  'Manage Tenants',
                  Icons.business,
                  Colors.purple,
                  () => Get.toNamed(AppRoutes.tenantsList),
                ),
                _buildActionCard(
                  context,
                  'Manage Users',
                  Icons.people,
                  Colors.green,
                  () => Get.snackbar('Users', 'Switch to Users tab'),
                ),
                _buildActionCard(
                  context,
                  'System Logs',
                  Icons.history,
                  Colors.blue,
                  () => Get.snackbar('Logs', 'Coming soon'),
                ),
                _buildActionCard(
                  context,
                  'Backup',
                  Icons.backup,
                  Colors.orange,
                  () => Get.snackbar('Backup', 'Coming soon'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 2 : 1,
      color: isDark ? color.withValues(alpha: 0.15) : theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? color.withValues(alpha: 0.3)
              : color.withValues(alpha: 0.2),
          width: isDark ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark ? null : theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============ TENANTS TAB ============
class _TenantsTab extends StatelessWidget {
  const _TenantsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
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
            Obx(
              () => Text(
                '${dc.tenantCount.value} Tenants',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Manage your tenants'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.snackbar('Coming Soon', 'Tenant management'),
              icon: const Icon(Icons.add),
              label: const Text('Add Tenant'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ USERS TAB ============
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = Get.find<DashboardController>();

    return RefreshIndicator(
      onRefresh: () => dc.refreshStats(),
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
            Obx(
              () => Text(
                '${dc.userCount.value} Users',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),
            const Text('Manage all users in the system'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.snackbar('Coming Soon', 'User management'),
              icon: const Icon(Icons.add),
              label: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============ SETTINGS TAB ============
class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        _buildSettingsCard(
          context,
          'System Settings',
          'Configure system parameters',
          Icons.tune,
          () => Get.snackbar('Settings', 'Coming soon'),
        ),
        _buildSettingsCard(
          context,
          'Backup & Restore',
          'Manage backups',
          Icons.backup,
          () => Get.snackbar('Backup', 'Coming soon'),
        ),
        _buildSettingsCard(
          context,
          'Email Settings',
          'Configure email notifications',
          Icons.email_outlined,
          () => Get.snackbar('Email', 'Coming soon'),
        ),
        _buildSettingsCard(
          context,
          'Security',
          'Security settings',
          Icons.security,
          () => Get.snackbar('Security', 'Coming soon'),
        ),
        const SizedBox(height: 24),
        Card(
          color: Colors.red.shade50,
          child: ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () => Get.find<AuthController>().signOut(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
