import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/branch_controller.dart';

class EditBranchScreen extends StatefulWidget {
  const EditBranchScreen({super.key});

  @override
  State<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends State<EditBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final branchController = Get.find<BranchController>();

  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isMain = false;
  String? _branchId;

  @override
  void initState() {
    super.initState();
    // Get branch data from arguments
    final Map<String, dynamic>? branch = Get.arguments as Map<String, dynamic>?;
    if (branch != null) {
      _branchId = branch['id'] as String?;
      _nameController.text = branch['name'] ?? '';
      _codeController.text = branch['code'] ?? '';
      _addressController.text = branch['address'] ?? '';
      _phoneController.text = branch['phone'] ?? '';
      _isMain = branch['is_main'] == true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _branchId == null) return;

    setState(() => _isLoading = true);

    try {
      await branchController.updateBranch(
        branchId: _branchId!,
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        isMain: _isMain,
      );

      // Navigate back immediately
      if (mounted) {
        Get.back();
      }

      // Show success message after navigation
      Get.snackbar(
        'Success',
        'Branch updated successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
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

    if (_branchId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Branch'), elevation: 0),
        body: const Center(
          child: Text('Branch not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Branch'), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
            const SizedBox(height: 16),

            // Main Branch Option Card
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
                            Icons.star,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Branch Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Main Branch'),
                      subtitle: const Text(
                        'Mark this branch as the main branch. Only one branch can be main branch. Main branch cannot be deleted.',
                      ),
                      value: _isMain,
                      onChanged: (value) {
                        setState(() {
                          _isMain = value;
                        });
                      },
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
                    : const Icon(Icons.save),
                label: Text(
                  _isLoading ? 'Updating...' : 'Update Branch',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}

