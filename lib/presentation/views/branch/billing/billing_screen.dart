import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Bill'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Implement barcode scanner
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.point_of_sale,
                size: 80,
                color: theme.primaryColor.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text('POS Billing Screen', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text(
                'This screen will contain:\n'
                '• Product search and selection\n'
                '• Cart management\n'
                '• GST calculation\n'
                '• Payment processing\n'
                '• Invoice generation\n'
                '• Print functionality',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Get.snackbar(
                    'Coming Soon',
                    'POS billing functionality will be implemented',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                child: const Text('Start Billing Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
