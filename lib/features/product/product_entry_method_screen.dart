import 'package:flutter/material.dart';
import 'product_form_screen_new.dart';
import '../common/barcode_scanner_screen.dart';
import '../common/image_capture_screen_real_ocr.dart';
import '../../core/services/barcode_service.dart';

/// Product Entry Method Screen
class ProductEntryMethodScreen extends StatelessWidget {
  const ProductEntryMethodScreen({super.key});

  /// Scan barcode and navigate to form with pre-filled data
  Future<void> _scanBarcodeAndNavigate(BuildContext context) async {
    // Open barcode scanner
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null || barcode.isEmpty) return;
    if (!context.mounted) return;

    // Show loading indicator while fetching product info
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Looking up product...'),
          ],
        ),
      ),
    );

    try {
      final productData = await BarcodeService.getProductInfo(barcode);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      // Check if we got meaningful data (not just the basic fallback)
      final isBasicFallback = (productData['name']?.toString() ?? '').startsWith('Product (');
      final hasExpiry = (productData['expiryDate']?.toString() ?? '').isNotEmpty;

      // Build analysisData in the format ProductFormScreenNew expects
      final parsedData = <String, dynamic>{
        'name': productData['name'] ?? '',
        'brand': productData['brand'] ?? '',
        'category': productData['category'] ?? 'product',
        'ingredients': productData['ingredients'] ?? '',
        'expiryDate': _normaliseDate(
          productData['expiryDate']?.toString() ?? '',
        ),
        'mfgDate': _normaliseDate(productData['mfgDate']?.toString() ?? ''),
        'isMedicine': productData['isMedicine'] ?? false,
        'confidence': productData['confidence'] ?? 0.5,
        'source': productData['source'] ?? 'Barcode Scan',
        'barcode': barcode,
      };

      final analysisData = <String, dynamic>{
        'success': true,
        'text': productData['name'] ?? 'Barcode: $barcode',
        'raw_text': 'Barcode: $barcode',
        'method': 'barcode',
        'parsed_data': parsedData,
        'barcode': barcode,
      };

      // If barcode not found in any API, suggest image capture for better results
      if (isBasicFallback || !hasExpiry) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBasicFallback
                  ? 'Barcode not found in databases. Try Image Capture for better results.'
                  : 'Expiry date not found. Use Image Capture to scan the label.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Capture Image',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ImageCaptureScreenRealOCR(isMedicine: false),
                  ),
                );
              },
            ),
          ),
        );
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductFormScreenNew(
            isMedicine: productData['isMedicine'] == true,
            analysisData: analysisData,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to look up barcode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Normalise various date formats to DD/MM/YYYY for the form
  String _normaliseDate(String raw) {
    if (raw.isEmpty) return '';
    // Already DD/MM/YYYY
    if (RegExp(r'^\d{1,2}/\d{1,2}/\d{4}$').hasMatch(raw)) return raw;
    // YYYY-MM-DD
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) {
      final parts = raw.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    // MM/YYYY
    if (RegExp(r'^\d{1,2}/\d{4}$').hasMatch(raw)) return raw;
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Entry Method',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How would you like to add this product?',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMethodCard(
                    context,
                    'Manual Entry',
                    'Enter product details manually',
                    Icons.edit,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProductFormScreenNew(isMedicine: false),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMethodCard(
                    context,
                    'Barcode Scan',
                    'Scan barcode to auto-fill details',
                    Icons.qr_code_scanner,
                    Colors.green,
                    () => _scanBarcodeAndNavigate(context),
                  ),
                  const SizedBox(height: 16),
                  _buildMethodCard(
                    context,
                    'Image Capture',
                    'Take photos to extract text',
                    Icons.camera_alt,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ImageCaptureScreenRealOCR(isMedicine: false),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
