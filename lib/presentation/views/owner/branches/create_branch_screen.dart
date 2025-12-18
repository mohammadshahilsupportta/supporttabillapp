import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../data/datasources/auth_datasource.dart';
import '../../../../data/models/user_model.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/branch_controller.dart';

class CreateBranchScreen extends StatefulWidget {
  const CreateBranchScreen({super.key});

  @override
  State<CreateBranchScreen> createState() => _CreateBranchScreenState();
}

class _CreateBranchScreenState extends State<CreateBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final branchController = Get.find<BranchController>();
  final authController = Get.find<AuthController>();
  final AuthDataSource _authDataSource = AuthDataSource();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _createAdmin = false;
  bool _isAdminPasswordObscured = true;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _adminNameController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await branchController.createBranch(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      // If requested, create branch admin account (match website logic)
      if (_createAdmin) {
        final tenantId = authController.tenantId;
        if (tenantId == null) {
          Get.snackbar(
            'Warning',
            'Branch created, but tenant not found for admin creation.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        } else {
          // Find the created branch by code (most recent)
          Map<String, dynamic>? createdBranch;
          try {
            createdBranch = branchController.branches.firstWhere(
              (b) =>
                  (b['code'] as String?) ==
                  _codeController.text.trim().toUpperCase(),
            );
          } catch (_) {
            createdBranch = null;
          }

          final branchId = createdBranch?['id'] as String?;

          if (branchId == null) {
            Get.snackbar(
              'Warning',
              'Branch created, but could not find branch for admin account.',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          } else {
            try {
              await _authDataSource.createUser(
                email: _emailController.text.trim(),
                password: _adminPasswordController.text.trim(),
                fullName: _adminNameController.text.trim(),
                role: UserRole.branchAdmin,
                tenantId: tenantId,
                branchId: branchId,
              );

              // Navigate back immediately
              if (mounted) {
                Get.back();
              }

              // Show success message after navigation
              Get.snackbar(
                'Success',
                'Branch and branch admin "${_adminNameController.text.trim()}" created successfully',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
              return; // Exit early since we already navigated
            } catch (e) {
              // Navigate back immediately even on partial success
              if (mounted) {
                Get.back();
              }

              // Show partial success message after navigation
              Get.snackbar(
                'Partial Success',
                'Branch created, but failed to create branch admin: ${e.toString().replaceAll('Exception: ', '')}',
                snackPosition: SnackPosition.TOP,
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
              return; // Exit early since we already navigated
            }
          }
        }
      } else {
        // Navigate back immediately
        if (mounted) {
          Get.back();
        }

        // Show success message after navigation
        Get.snackbar(
          'Success',
          'Branch created successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      final message = e.toString();
      if (message.contains('BRANCH_CODE_ALREADY_EXISTS')) {
        Get.snackbar(
          'Branch Code In Use',
          'This branch code is already used. Please use a different branch code.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          message.replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Branch'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Page title & description (match website style)
            // Text(
            //   'Create New Branch',
            //   style: theme.textTheme.headlineSmall?.copyWith(
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 4),
            // Text(
            //   'Add a new branch to your shop network. Optionally manage branch administrators from the web dashboard.',
            //   style: theme.textTheme.bodyMedium?.copyWith(
            //     color: Colors.grey.shade700,
            //   ),
            // ),
            const SizedBox(height: 10),

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
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.store, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Branch Information',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Branch Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Branch Name *',
                        hintText: 'e.g., Main Branch, Downtown Branch',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.business),
                        helperText:
                            'Enter a clear, descriptive name for this branch',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter branch name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Branch Code
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        final upper = value.toUpperCase();
                        if (upper != _codeController.text) {
                          _codeController.value = _codeController.value
                              .copyWith(
                                text: upper,
                                selection: TextSelection.collapsed(
                                  offset: upper.length,
                                ),
                              );
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Branch Code *',
                        hintText: 'e.g., MAIN, BR001',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.tag),
                        helperText:
                            'Unique code for this branch (uppercase letters, numbers, hyphens, underscores only)',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter branch code';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact Info Card
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
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Contact Details',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

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
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'Enter email address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!GetUtils.isEmail(value)) {
                            return 'Please enter a valid email';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Address Card
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
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Address',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Street Address',
                        hintText: 'Enter complete address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Branch Admin section (match website BranchForm)
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
                          'Branch Administrator',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Create admin toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Create Branch Admin Account'),
                      subtitle: const Text(
                        'Each branch should have at least one administrator to manage operations',
                      ),
                      value: _createAdmin,
                      onChanged: (value) {
                        setState(() {
                          _createAdmin = value;
                        });
                      },
                    ),

                    if (_createAdmin) ...[
                      const SizedBox(height: 16),

                      // Admin Full Name
                      TextFormField(
                        controller: _adminNameController,
                        decoration: InputDecoration(
                          labelText: 'Admin Full Name *',
                          hintText: 'e.g., John Doe',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (_createAdmin) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter admin full name';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Admin Email (reuse email field validator)
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Admin Email *',
                          hintText: 'admin@example.com',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (_createAdmin) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter admin email';
                            }
                            if (!GetUtils.isEmail(value.trim())) {
                              return 'Please enter a valid email';
                            }
                          } else if (value != null && value.isNotEmpty) {
                            if (!GetUtils.isEmail(value)) {
                              return 'Please enter a valid email';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Admin Password
                      TextFormField(
                        controller: _adminPasswordController,
                        obscureText: _isAdminPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'Admin Password *',
                          hintText: 'Min. 6 characters',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isAdminPasswordObscured
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _isAdminPasswordObscured =
                                    !_isAdminPasswordObscured;
                              });
                            },
                          ),
                          helperText:
                              'Minimum 6 characters. Admin will use this to log in.',
                        ),
                        validator: (value) {
                          if (_createAdmin) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter admin password';
                            }
                            if (value.trim().length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
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
                    : const Icon(Icons.add_business),
                label: Text(
                  _isLoading ? 'Creating...' : 'Create Branch',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 70),

            // Info card about branch administrators (match website copy)
            // Card(
            //   color: Colors.blue.withValues(alpha: 0.04),
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(12),
            //     side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
            //   ),
            //   child: Padding(
            //     padding: const EdgeInsets.all(16),
            //     child: Row(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Icon(Icons.verified_user, color: Colors.blue.shade600),
            //         const SizedBox(width: 12),
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Text(
            //                 'About Branch Administrators',
            //                 style: theme.textTheme.bodyMedium?.copyWith(
            //                   fontWeight: FontWeight.w600,
            //                   color: Colors.blue.shade900,
            //                 ),
            //               ),
            //               const SizedBox(height: 4),
            //               Text(
            //                 'Each branch should have at least one administrator who can manage branch operations, staff, inventory, and billing. You can create and manage branch admins from the web dashboard.',
            //                 style: theme.textTheme.bodySmall?.copyWith(
            //                   color: Colors.blue.shade800,
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
