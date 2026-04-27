import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/services/simple_ocr_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/barcode_api_service.dart';
import '../../core/services/database_service.dart';
import '../../data/repositories/product_repository.dart';
import '../../models/product_info.dart';

class ProductScannerScreen extends StatefulWidget {
  const ProductScannerScreen({super.key});

  @override
  State<ProductScannerScreen> createState() => _ProductScannerScreenState();
}

class _ProductScannerScreenState extends State<ProductScannerScreen> {
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  
  final ocrService = OCRService();
  final aiService = AIService();
  final barcodeApi = BarcodeApiService();

  DateTime? expiryDate;
  File? imageFile;
  bool isLoading = false;
  late ProductRepository repository;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
  }

  Future<void> _initializeRepository() async {
    repository = ProductRepository(DatabaseService().db);
  }

  Future<void> processImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    final newImage = File(picked.path);
    
    setState(() {
      imageFile = newImage;
      isLoading = true;
    });

    try {
      // 1. Permanent Image Storage
      final directory = await getApplicationDocumentsDirectory();
      final name = p.basename(picked.path);
      final savedPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_$name';
      await File(picked.path).copy(savedPath);

      // 2. OCR & Barcode Detection
      final result = await ocrService.processImage(savedPath);
      String? detectedBarcode = result['barcode'];
      String rawText = result['text'];

      // 3. Barcode API Lookup
      String? productNameFromBarcode;
      if (detectedBarcode != null) {
        productNameFromBarcode = await barcodeApi.getProductName(detectedBarcode);
      }

      // 4. AI Smart Extraction
      final structuredData = await aiService.extractStructuredData(
        imagePath: savedPath,
        rawText: "Barcode Result: $productNameFromBarcode. OCR Text: $rawText",
        barcode: detectedBarcode,
      );

      // 5. Auto-Fill UI
      setState(() {
        nameController.text = productNameFromBarcode ?? structuredData['brand'] ?? "";
        if (structuredData['expiry'] != null && structuredData['expiry'].toString().isNotEmpty) {
          try {
            expiryDate = DateTime.parse(structuredData['expiry']);
          } catch (_) {}
        }
      });

      // 6. Auto-Save to Database
      Map<String, dynamic> extra = {};
      if (structuredData['extraData'] != null) {
        try {
          extra = jsonDecode(structuredData['extraData']);
        } catch (_) {}
      }

      await repository.addProduct(
        ProductInfo(
          name: nameController.text.isNotEmpty ? nameController.text : "Auto-Extracted Product",
          imageUrl: savedPath,
          expiryDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
          brand: structuredData['brand'],
          category: structuredData['category'] ?? '',
          quantity: extra['quantity']?.toString(),
          ingredients: extra['ingredients']?.toString(),
          warnings: extra['warnings']?.toString(),
          mfgDate: structuredData['mfgDate'] != null
              ? DateTime.tryParse(structuredData['mfgDate'].toString())
              : null,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Product Processed & Saved!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Product Intelligence", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildImagePreview(),
                const SizedBox(height: 25),
                _buildInputField(nameController, "Product Name", Icons.shopping_cart),
                const SizedBox(height: 10),
                _buildDatePicker(),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: _buildActionButton("Camera", Icons.camera_alt, () => processImage(ImageSource.camera), Colors.blue)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildActionButton("Gallery", Icons.photo_library, () => processImage(ImageSource.gallery), Colors.orange)),
                  ],
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text("AI is extracting product details...", style: TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: imageFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(imageFile!, fit: BoxFit.cover),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.camera_alt_outlined, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text("No image selected", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => processImage(ImageSource.gallery),
                  child: const Text("Select Image"),
                ),
              ],
            ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.indigo),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => expiryDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(15),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Colors.indigo),
            const SizedBox(width: 15),
            Text(expiryDate == null 
                ? "Select Expiry Date" 
                : "Expiry: ${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}"),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, Color color) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    super.dispose();
  }
}
