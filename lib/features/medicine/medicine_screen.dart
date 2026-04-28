import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/services/simple_ocr_service.dart';
import '../../core/services/ai_service.dart';
import '../../core/services/database_service.dart';
import '../../core/services/logger_service.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../models/product_info.dart';
import 'preview_screen.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  State<MedicineScreen> createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> manufacturerControllers = [];
  final List<TextEditingController> mrpControllers = [];
  final List<TextEditingController> batchControllers = [];
  final List<TextEditingController> dosageControllers = [];
  final List<TextEditingController> doctorControllers = [];
  final List<DateTime?> expiryDates = [];
  final List<File?> imageFiles = [];
  final List<String?> extraDataList = [];

  final ocrService = OCRService();
  final aiService = AIService();

  bool isLoading = false;
  late MedicineRepository repository;

  @override
  void initState() {
    super.initState();
    repository = MedicineRepository(DatabaseService().db);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await ocrService.initialize();
  }

  Future<String> saveImagePermanently(String tempPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = p.basename(tempPath);
    final newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_$name';
    await File(tempPath).copy(newPath);
    return newPath;
  }

  Future<void> pickMultipleImages() async {
    final picker = ImagePicker();
    final List<XFile> pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isEmpty) return;

    setState(() => isLoading = true);

    try {
      for (var pickedFile in pickedFiles) {
        await _processSingleImage(pickedFile);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _processTestImage(String medicineName) async {
    try {
      LoggerService.start('TEST_PROCESS', 'Processing test medicine: $medicineName');
      
      // Step 1: Create mock test data
      final ocrResult = {
        'text': '$medicineName\nExp: 12/2025\nBatch: TEST123\nMfg: Jan 2024',
        'barcode': '1234567890123'
      };
      final geminiData = {
        'name': medicineName,
        'brand': 'Test Brand',
        'dosage': '500mg',
        'expiry_date': '2025-12-01',
        'batch': 'TEST123',
        'manufacturer': 'Test Manufacturer',
        'method': 'test_data',
      };
      
      LoggerService.info('TEST_OCR', 'Using mock OCR data');
      LoggerService.success('TEST_GEMINI', 'Using mock Gemini data');

      // Step 2: Use Gemini data directly (backend removed)
      final finalData = geminiData;
      
      // Step 3: Navigate to Preview Screen
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MedicinePreviewScreen(
              extractedData: finalData,
              repository: repository,
            ),
          ),
        );

        if (result == true) {
          LoggerService.success('TEST_SAVE', 'Test medicine saved successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Test medicine saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.error('TEST_PROCESS', 'Failed to process test medicine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Test processing failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processSingleImage(XFile pickedFile) async {
    try {
      LoggerService.start('IMAGE_PROCESS', 'Processing image: ${p.basename(pickedFile.path)}');
      
      final savedPath = await saveImagePermanently(pickedFile.path);
      final ocrResult = await ocrService.processImage(savedPath);

      LoggerService.info('OCR_RESULT', 'Text extracted: ${ocrResult['text'].length} chars, Barcode: ${ocrResult['barcode'] ?? 'None'}');

      // Step 1: Gemini Processing (existing)
      final geminiData = await aiService.extractStructuredData(
        imagePath: savedPath,
        rawText: ocrResult['text'] ?? '',
        barcode: ocrResult['barcode'] ?? '',
      );

      LoggerService.success('GEMINI_PROCESS', 'Gemini extraction completed: ${geminiData['name'] ?? 'Unknown'}');

      // Step 2: Use Gemini data directly (backend removed)
      final finalData = geminiData;
      
      // Step 3: Navigate to Preview Screen
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MedicinePreviewScreen(
              extractedData: finalData,
              imageFile: File(savedPath),
              imagePath: savedPath,
              repository: repository,
            ),
          ),
        );

        // Step 5: Handle preview result (if user saved)
        if (result == true) {
          LoggerService.success('PREVIEW_SAVE', 'Medicine saved successfully from preview');
          // Optional: Show success message or refresh UI
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Medicine saved successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.error('UI_PROCESS', 'Failed to process image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Processing failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Intelligent Label Scanner")),
      body: Column(
        children: [
          if (isLoading) const LinearProgressIndicator(),
          
          // Test Mode Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.science, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Test Mode (No Camera Needed)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Test with simulated medicine data:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Paracetamol 500mg', 'Ibuprofen 400mg', 'Amoxicillin 500mg', 'Cough Syrup', 'Vitamin D3'].map((name) {
                    return ElevatedButton(
                      onPressed: () => _processTestImage(name),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(name),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          Expanded(
            child: nameControllers.isEmpty
                ? const Center(child: Text("Scan medicine labels to begin"))
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: nameControllers.length,
                    itemBuilder: (context, index) => _buildMedicineCard(index),
                  ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(imageFiles[index]!, width: 100, height: 100, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    children: [
                      _buildField(nameControllers[index], "Brand Name", Icons.label),
                      _buildField(manufacturerControllers[index], "Manufacturer", Icons.business),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildField(mrpControllers[index], "MRP", Icons.currency_rupee)),
                const SizedBox(width: 10),
                Expanded(child: _buildField(batchControllers[index], "Batch", Icons.numbers)),
              ],
            ),
            _buildDatePicker(index),
            _buildExtraDataUI(index),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _saveEntry(index),
              child: const Text("Save to Database"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
    );
  }

  Widget _buildExtraDataUI(int index) {
    if (extraDataList[index] == null) return const SizedBox();
    try {
      Map<String, dynamic> extra = jsonDecode(extraDataList[index]!);
      if (extra.isEmpty) return const SizedBox();

      return ExpansionTile(
        title: const Text("Additional Extracted Data", style: TextStyle(fontSize: 14)),
        children: extra.entries.map((e) => ListTile(
          title: Text(e.key.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 12)),
          trailing: Text(e.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        )).toList(),
      );
    } catch (_) {
      return const SizedBox();
    }
  }

  Widget _buildDatePicker(int index) {
    return ListTile(
      leading: const Icon(Icons.event),
      title: Text(expiryDates[index] == null ? "Select Expiry" : "Expiry: ${expiryDates[index]!.toLocal()}".split(' ')[0]),
      onTap: () async {
        final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2040));
        if (date != null) setState(() => expiryDates[index] = date);
      },
    );
  }

  Future<void> _saveEntry(int index) async {
    await repository.addMedicine(
      ProductInfo(
        name: nameControllers[index].text,
        brand: manufacturerControllers[index].text,
        imageUrl: imageFiles[index]?.path,
        category: 'Medicine',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved Successfully!")));
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : pickMultipleImages,
        icon: const Icon(Icons.add_a_photo),
        label: const Text("Scan Multiple Labels"),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
      ),
    );
  }
}
