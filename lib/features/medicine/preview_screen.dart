import 'package:flutter/material.dart';
import 'dart:io';
import '../../core/services/api_service.dart';
import '../../core/services/logger_service.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../models/product_info.dart';

/// Preview Screen for Medicine Data Before Saving
/// Allows user to review and edit extracted data before final save
class MedicinePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> extractedData;
  final File? imageFile;
  final String? imagePath;
  final MedicineRepository repository;

  const MedicinePreviewScreen({
    super.key,
    required this.extractedData,
    this.imageFile,
    this.imagePath,
    required this.repository,
  });

  @override
  State<MedicinePreviewScreen> createState() => _MedicinePreviewScreenState();
}

class _MedicinePreviewScreenState extends State<MedicinePreviewScreen> {
  late TextEditingController nameController;
  late TextEditingController manufacturerController;
  late TextEditingController mrpController;
  late TextEditingController batchController;
  late TextEditingController dosageController;
  late TextEditingController doctorController;
  late TextEditingController symptomsController;
  DateTime? selectedExpiryDate;
  bool isSaving = false;
  bool backendSyncEnabled = true;

  // Add repository getter
  MedicineRepository get repository => widget.repository;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _checkBackendHealth();
  }

  void _initializeControllers() {
    // Safe field extraction with multiple fallbacks
    String extractName() {
      final candidates = [
        widget.extractedData['name'],
        widget.extractedData['brand'],
        widget.extractedData['product_name'],
        'Unknown Medicine'
      ];
      for (final candidate in candidates) {
        if (candidate != null && candidate.toString().isNotEmpty) {
          return candidate.toString();
        }
      }
      return '';
    }

    nameController = TextEditingController(text: extractName());
    manufacturerController = TextEditingController(
      text: widget.extractedData['manufacturer']?.toString() ?? 
             widget.extractedData['brand']?.toString() ?? ''
    );
    mrpController = TextEditingController(
      text: widget.extractedData['mrp']?.toString() ?? ''
    );
    batchController = TextEditingController(
      text: widget.extractedData['batch']?.toString() ?? 
             widget.extractedData['batch_number']?.toString() ?? ''
    );
    dosageController = TextEditingController(
      text: widget.extractedData['dosage']?.toString() ?? ''
    );
    doctorController = TextEditingController(
      text: widget.extractedData['doctor_name']?.toString() ?? ''
    );
    symptomsController = TextEditingController(
      text: widget.extractedData['symptoms']?.toString() ?? ''
    );

    // Safe expiry date parsing
    final expiryCandidate = widget.extractedData['expiry_date'] ??
                           widget.extractedData['expiry'] ??
                           widget.extractedData['exp'];
    
    if (expiryCandidate != null) {
      final expiryStr = expiryCandidate.toString();
      // Try multiple date formats
      final formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy', 'dd-MM-yyyy'];
      
      for (final format in formats) {
        try {
          selectedExpiryDate = DateTime.parse(expiryStr);
          if (selectedExpiryDate != null) break;
        } catch (e) {
          // Try parsing with different approach
          continue;
        }
      }
      
      // Fallback: try basic parsing
      if (selectedExpiryDate == null) {
        selectedExpiryDate = DateTime.tryParse(expiryStr);
      }
    }

    LoggerService.info('PREVIEW_INIT', 'Controllers initialized with data: ${nameController.text}');
  }

  Future<void> _checkBackendHealth() async {
    final isHealthy = await ApiService.checkHealth();
    setState(() {
      backendSyncEnabled = isHealthy;
    });
  }

  Future<void> _saveMedicine() async {
    if (nameController.text.trim().isEmpty) {
      _showError('Please enter a medicine name');
      return;
    }

    setState(() => isSaving = true);

    try {
      LoggerService.start('PREVIEW_SAVE', 'Saving medicine: ${nameController.text}');

      // Step 1: Save to local database (always works)
      await repository.addMedicine(
        ProductInfo(
          name: nameController.text.trim(),
          uses: symptomsController.text.trim(),
          dosage: dosageController.text.trim(),
          brand: manufacturerController.text.trim(),
          imageUrl: widget.imagePath,
          expiryDate: selectedExpiryDate,
          category: 'Medicine',
        ),
      );

      LoggerService.success('PREVIEW_SAVE', 'Saved to local database');

      // Step 2: Sync to backend (if available)
      if (backendSyncEnabled) {
        try {
          await ApiService.syncItem(
            name: nameController.text.trim(),
            category: 'medicine',
            brand: manufacturerController.text.trim(),
            dosage: dosageController.text.trim(),
            doctorName: doctorController.text.trim(),
            symptoms: symptomsController.text.trim(),
            prescriptionImage: widget.imagePath,
            mrp: mrpController.text.trim(),
            batch: batchController.text.trim(),
            manufacturer: manufacturerController.text.trim(),
            extraData: widget.extractedData.toString(),
          );
          LoggerService.success('PREVIEW_SYNC', 'Synced to backend successfully');
        } catch (e) {
          LoggerService.warning('PREVIEW_SYNC', 'Backend sync failed, but local save succeeded: $e');
        }
      }

      if (mounted) {
        _showSuccess('Medicine saved successfully!');
        Navigator.of(context).pop(true); // Return success to previous screen
      }
    } catch (e) {
      LoggerService.error('PREVIEW_SAVE', 'Save failed: $e');
      if (mounted) {
        _showError('Failed to save medicine: $e');
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null && picked != selectedExpiryDate) {
      setState(() {
        selectedExpiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Medicine Details'),
        actions: [
          if (!backendSyncEnabled)
            const Tooltip(
              message: 'Backend offline - local save only',
              child: Icon(Icons.cloud_off, color: Colors.orange),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Preview
            if (widget.imageFile != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.imageFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported, size: 50),
                      );
                    },
                  ),
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Extraction Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Extraction Method',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          widget.extractedData['method']?.contains('gemini') == true
                              ? Icons.auto_awesome
                              : Icons.text_fields,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.extractedData['method'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Editable Fields
            _buildSectionTitle('Medicine Information'),
            _buildTextField('Name', nameController, Icons.medication, required: true),
            _buildTextField('Symptoms', symptomsController, Icons.sick, required: true),
            _buildTextField('Manufacturer', manufacturerController, Icons.business),
            _buildTextField('Dosage', dosageController, Icons.medication),
            _buildTextField('Doctor Name', doctorController, Icons.person),
            _buildTextField('MRP', mrpController, Icons.currency_rupee),
            _buildTextField('Batch Number', batchController, Icons.qr_code),
            
            const SizedBox(height: 16),
            
            // Expiry Date Picker
            _buildSectionTitle('Expiry Date'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  selectedExpiryDate != null
                      ? '${selectedExpiryDate!.day}/${selectedExpiryDate!.month}/${selectedExpiryDate!.year}'
                      : 'Select expiry date',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectExpiryDate,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveMedicine,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Saving...'),
                        ],
                      )
                    : const Text('Save Medicine', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    manufacturerController.dispose();
    mrpController.dispose();
    batchController.dispose();
    dosageController.dispose();
    doctorController.dispose();
    symptomsController.dispose();
    super.dispose();
  }
}
