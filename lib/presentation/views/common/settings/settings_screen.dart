import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_routes.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    AuthController? authController;
    try {
      authController = Get.find<AuthController>();
    } catch (e) {
      print('SettingsScreen: AuthController not found: $e');
      return Scaffold(
        appBar: AppBar(title: const Text('Settings'), elevation: 0),
        body: const Center(child: Text('Auth controller not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Card
          Obx(() {
            if (authController == null) {
              return const Card(child: Center(child: Text('Auth controller not available')));
            }
            final user = authController.currentUser.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        (user?.fullName ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'User',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            user?.email ?? '',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getRoleLabel(user?.role.value),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Get.toNamed(AppRoutes.profileEdit),
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader('Account'),
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () => Get.toNamed(AppRoutes.profileEdit),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () =>
                      Get.snackbar('Coming Soon', 'Password change feature'),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.notifications,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () =>
                      Get.snackbar('Coming Soon', 'Notification settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Settings Section
          _buildSectionHeader('App Settings'),
          Card(
            child: Column(
              children: [
                _buildThemeSelector(),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => Get.snackbar('Coming Soon', 'Language settings'),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.print,
                  title: 'Print Settings',
                  subtitle: 'Configure receipt printer',
                  onTap: () => Get.snackbar('Coming Soon', 'Print settings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Business Section (for owners)
          Obx(() {
            if (authController == null) {
              return const SizedBox.shrink();
            }
            final role = authController.currentUser.value?.role.value;
            if (role == 'tenantOwner') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Business'),
                  Card(
                    child: Column(
                      children: [
                        _buildSettingsTile(
                          icon: Icons.business,
                          title: 'Business Profile',
                          subtitle: 'Update business information',
                          onTap: () =>
                              Get.snackbar('Coming Soon', 'Business profile'),
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.receipt_long,
                          title: 'Invoice Settings',
                          subtitle: 'Customize invoice format',
                          onTap: () =>
                              Get.snackbar('Coming Soon', 'Invoice settings'),
                        ),
                        const Divider(height: 1),
                        _buildSettingsTile(
                          icon: Icons.calculate,
                          title: 'Tax Settings',
                          subtitle: 'Configure GST and taxes',
                          onTap: () =>
                              Get.snackbar('Coming Soon', 'Tax settings'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Support Section
          _buildSectionHeader('Support'),
          Card(
            child: Column(
              children: [
                _buildSettingsTile(
                  icon: Icons.help,
                  title: 'Help & FAQ',
                  subtitle: 'Get help and answers',
                  onTap: () => Get.snackbar('Coming Soon', 'Help center'),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.chat,
                  title: 'Contact Support',
                  subtitle: 'Reach out to our team',
                  onTap: () => Get.snackbar('Coming Soon', 'Contact support'),
                ),
                const Divider(height: 1),
                _buildSettingsTile(
                  icon: Icons.info,
                  title: 'About',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Logout Button
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                if (authController != null) {
                  _confirmLogout(context, authController);
                }
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  String _getRoleLabel(String? role) {
    switch (role) {
      case 'tenantOwner':
        return 'Owner';
      case 'branchAdmin':
        return 'Branch Admin';
      case 'branchStaff':
        return 'Staff';
      case 'superadmin':
        return 'Super Admin';
      default:
        return 'User';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SupportaBill',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.receipt_long, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'Complete billing and inventory management solution for your business.',
        ),
      ],
    );
  }

  Widget _buildThemeSelector() {
    ThemeController? themeController;
    try {
      themeController = Get.find<ThemeController>();
    } catch (e) {
      print('SettingsScreen: ThemeController not found: $e');
      return const SizedBox.shrink();
    }

    return Obx(() {
      final currentMode = themeController!.themeMode.value;
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette, color: Colors.grey),
            title: const Text(
              'Theme',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _getThemeModeLabel(currentMode),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showThemeDialog(themeController!),
          ),
        ],
      );
    });
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeDialog(ThemeController themeController) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Obx(() {
          final currentMode = themeController.themeMode.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) {
                    themeController.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) {
                    themeController.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) {
                    themeController.setThemeMode(value);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          );
        }),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authController.signOut();
              Get.offAllNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
