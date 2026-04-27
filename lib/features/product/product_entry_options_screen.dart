import 'package:flutter/material.dart';
import 'product_scanner_screen.dart';
import 'manual_product_entry_screen.dart';
import '../common/image_capture_screen_simple.dart';

/// Product Entry Options Screen
/// Shows dual entry options: AI Scan and Manual Entry
class ProductEntryOptionsScreen extends StatelessWidget {
  const ProductEntryOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Product',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.withOpacity(0.1),
                    Colors.indigo.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 40,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How would you like to add a product?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose between AI-powered scanning or manual entry',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Options
            Expanded(
              child: Column(
                children: [
                  // Multi-Image Scan Option
                  _buildOptionCard(
                    context,
                    title: 'Multi-Image Scan',
                    subtitle: 'Capture multiple photos for automatic product detection',
                    icon: Icons.photo_library_outlined,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ImageCaptureScreenSimple(isMedicine: false)),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Barcode Scan Option
                  _buildOptionCard(
                    context,
                    title: 'Barcode Scan',
                    subtitle: 'Scan barcode for quick product lookup',
                    icon: Icons.qr_code_scanner,
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductScannerScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Manual Entry Option
                  _buildOptionCard(
                    context,
                    title: 'Manual Entry',
                    subtitle: 'Manually enter product details',
                    icon: Icons.edit,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManualProductEntryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
