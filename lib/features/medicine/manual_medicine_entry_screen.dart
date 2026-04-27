import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/ui_helpers.dart';
import '../../models/product_info.dart';

/// Manual Medicine Entry Screen
/// Allows users to manually enter medicine details
class ManualMedicineEntryScreen extends StatefulWidget {
  const ManualMedicineEntryScreen({super.key});

  @override
  State<ManualMedicineEntryScreen> createState() => _ManualMedicineEntryScreenState();
}

class _ManualMedicineEntryScreenState extends State<ManualMedicineEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final MedicineRepository _repository = MedicineRepository(DatabaseService().db);
  
  // Controllers
  final _nameController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _dosageController = TextEditingController();
  final _doctorController = TextEditingController();
  final _brandController = TextEditingController();
  final _mrpController = TextEditingController();
  final _batchController = TextEditingController();
  
  // State variables
  DateTime? _expiryDate;
  File? _selectedImage;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _symptomsController.dispose();
    _dosageController.dispose();
    _doctorController.dispose();
    _brandController.dispose();
    _mrpController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manual Medicine Entry',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveMedicine,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Section
              _buildImageSection(),
              
              const SizedBox(height: 24),
              
              // Required Fields Section
              _buildSectionTitle('Required Information'),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nameController,
                label: 'Medicine Name',
                hint: 'e.g., Paracetamol 500mg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter medicine name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _symptomsController,
                label: 'Symptoms',
                hint: 'e.g., fever, cold, headache',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter symptoms';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _dosageController,
                label: 'Dosage',
                hint: 'e.g., 500mg, 10ml',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter dosage';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              _buildDateSelector(),
              
              const SizedBox(height: 32),
              
              // Optional Fields Section
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _doctorController,
                label: 'Doctor Name',
                hint: 'e.g., Dr. Smith',
                validator: null, // Optional field
              ),
              
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _brandController,
                label: 'Brand',
                hint: 'e.g., Dolo, Crocin',
                validator: null, // Optional field
              ),
              
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _mrpController,
                label: 'MRP',
                hint: 'e.g., 25.00',
                keyboardType: TextInputType.number,
                validator: null, // Optional field
              ),
              
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _batchController,
                label: 'Batch Number',
                hint: 'e.g., ABC123',
                validator: null, // Optional field
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMedicine,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Medicine'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Image',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed: () => setState(() => _selectedImage = null),
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add medicine image',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () => _pickImage(ImageSource.camera),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Camera'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _pickImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Gallery'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expiry Date',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _expiryDate != null
                        ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                        : 'Select expiry date',
                    style: TextStyle(
                      color: _expiryDate != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select expiry date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save medicine using existing repository
      await _repository.addMedicine(
        ProductInfo(
          name: _nameController.text.trim(),
          dosage: _dosageController.text.trim(),
          brand: _brandController.text.trim(),
          uses: _symptomsController.text.trim(),
          imageUrl: _selectedImage?.path,
          expiryDate: _expiryDate,
          category: 'Medicine',
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medicine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
