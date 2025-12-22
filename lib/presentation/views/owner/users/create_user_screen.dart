import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/branch_controller.dart';
import '../../../controllers/user_controller.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  UserController? _userController;
  BranchController? _branchController;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _role = 'branchStaff';
  String? _branchId;
  bool _isLoading = false;

  final List<Map<String, String>> _roles = [
    {'value': 'branchStaff', 'label': 'Staff'},
    {'value': 'branchAdmin', 'label': 'Branch Admin'},
    {'value': 'tenantOwner', 'label': 'Owner'},
  ];

  @override
  void initState() {
    super.initState();
    try {
      _userController = Get.find<UserController>();
    } catch (e) {
      print('CreateUserScreen: UserController not found: $e');
    }
    // Try to get BranchController if available
    try {
      _branchController = Get.find<BranchController>();
    } catch (e) {
      try {
        Get.put(BranchController());
        _branchController = Get.find<BranchController>();
      } catch (e2) {
        print('CreateUserScreen: BranchController not found: $e2');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Branch is required for staff and admin roles
    if ((_role == 'branchStaff' || _role == 'branchAdmin') &&
        _branchId == null) {
      Get.snackbar(
        'Error',
        'Please select a branch for this user',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_userController == null) {
      Get.snackbar('Error', 'User controller not available');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _userController!.createUser(
        email: _emailController.text.trim(),
        fullName: _nameController.text.trim(),
        role: _role,
        branchId: _branchId,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      if (success) {
        Get.back();
        Get.snackbar(
          'Success',
          'User created successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to create user',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add User'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Card
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
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person_add,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'User Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter full name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address *',
                        hintText: 'Enter email address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                        helperText: 'This will be used for login',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email address';
                        }
                        if (!GetUtils.isEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'Enter phone number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Role & Branch Card
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
                            Icons.admin_panel_settings,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Role & Access',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Role Selection
                    DropdownButtonFormField<String>(
                      value: _role,
                      decoration: InputDecoration(
                        labelText: 'User Role *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.badge),
                      ),
                      items: _roles.map((role) {
                        return DropdownMenuItem<String>(
                          value: role['value'],
                          child: Text(role['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _role = value;
                            // Clear branch selection for owner role
                            if (value == 'tenantOwner') {
                              _branchId = null;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Branch Selection (only for staff/admin)
                    if (_role != 'tenantOwner')
                      Obx(() {
                        return DropdownButtonFormField<String>(
                          value: _branchId,
                          decoration: InputDecoration(
                            labelText: 'Assign to Branch *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.store),
                          ),
                          items: (_branchController?.branches ?? [])
                              .where((b) => b['is_active'] == true)
                              .map<DropdownMenuItem<String>>((branch) {
                                return DropdownMenuItem<String>(
                                  value: branch['id'],
                                  child: Text(branch['name'] ?? 'Unknown'),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            setState(() => _branchId = value);
                          },
                          validator: (value) {
                            if (_role != 'tenantOwner' &&
                                (value == null || value.isEmpty)) {
                              return 'Please select a branch';
                            }
                            return null;
                          },
                        );
                      }),

                    const SizedBox(height: 16),

                    // Role Description
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getRoleDescription(_role),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade700,
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
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.person_add),
                label: Text(
                  _isLoading ? 'Creating...' : 'Create User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getRoleDescription(String role) {
    switch (role) {
      case 'tenantOwner':
        return 'Owner has full access to all branches, products, users, and reports.';
      case 'branchAdmin':
        return 'Branch Admin can manage their assigned branch, including billing, stock, and expenses.';
      case 'branchStaff':
        return 'Staff can perform billing and basic stock operations at their assigned branch.';
      default:
        return '';
    }
  }
}
