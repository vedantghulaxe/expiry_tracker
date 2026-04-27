import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product_info.dart';

/// Medicine Form Screen with Strict Sections
class MedicineFormScreen extends StatefulWidget {
  final String entryMethod;
  final Map<String, dynamic>? extractedData;
  final ProductInfo? productInfo;
  final bool isEditing;

  const MedicineFormScreen({
    super.key,
    required this.entryMethod,
    this.extractedData,
    this.productInfo,
    this.isEditing = false,
  });

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _mfgDateController = TextEditingController();
  final _dosageController = TextEditingController();
  final _usesController = TextEditingController();
  final _warningsController = TextEditingController();
  final _batchController = TextEditingController();

  bool _isLoading = false;
  bool _isAutoFilled = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _expiryDateController.dispose();
    _mfgDateController.dispose();
    _dosageController.dispose();
    _usesController.dispose();
    _warningsController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // Initialize with extracted data if available
    if (widget.extractedData != null) {
      _nameController.text = widget.extractedData!['name'] ?? '';
      _brandController.text = widget.extractedData!['brand'] ?? '';
      _expiryDateController.text = widget.extractedData!['expiryDate'] ?? '';
      _mfgDateController.text = widget.extractedData!['mfgDate'] ?? '';
      _dosageController.text = widget.extractedData!['dosage'] ?? '';
      _usesController.text = widget.extractedData!['uses'] ?? '';
      _warningsController.text = widget.extractedData!['warnings'] ?? '';
      _batchController.text = widget.extractedData!['batchNumber'] ?? '';
      _isAutoFilled = true;
    } else if (widget.productInfo != null) {
      final medicine = widget.productInfo!;
      _nameController.text = medicine.name ?? '';
      _brandController.text = medicine.brand ?? '';
      _expiryDateController.text = _formatDate(medicine.expiryDate) ?? '';
      _mfgDateController.text = _formatDate(medicine.mfgDate) ?? '';
      _dosageController.text = medicine.dosage ?? '';
      _usesController.text = medicine.uses ?? '';
      _warningsController.text = medicine.warnings ?? '';
    }
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Medicine' : 'Add Medicine'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAutoFilled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Auto-filled',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (_isAutoFilled) _buildAutoFilledBanner(),
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildDatesSection(),
              const SizedBox(height: 24),
              _buildMedicalInfoSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAutoFilledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Medicine details auto-filled from scan. Please review and edit if needed.',
            style: TextStyle(
              color: Colors.green,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Basic Information',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: _buildInputDecoration('Medicine Name*', 'Enter medicine name'),
              validator: (value) => value?.isEmpty == true ? 'Medicine name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: _buildInputDecoration('Brand', 'Enter brand name'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Important Dates',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expiryDateController,
              decoration: _buildInputDecoration('Expiry Date*', 'DD/MM/YYYY'),
              readOnly: true,
              onTap: () => _selectDate(true),
              validator: (value) => value?.isEmpty == true ? 'Expiry date is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mfgDateController,
              decoration: _buildInputDecoration('Manufacturing Date', 'DD/MM/YYYY (Optional)'),
              readOnly: true,
              onTap: () => _selectDate(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Medical Information',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: _buildInputDecoration('Dosage', 'e.g., 500mg, 1 tablet twice daily'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usesController,
              decoration: _buildInputDecoration('Uses', 'e.g., Fever, Pain relief, Infection'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _warningsController,
              decoration: _buildInputDecoration('Warnings', 'e.g., May cause drowsiness, Not for pregnant women'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _batchController,
              decoration: _buildInputDecoration('Batch Number', 'e.g., P12345, M2024-001'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _selectDate(bool isExpiry) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      final formatted = '${picked.day}/${picked.month}/${picked.year}';
      if (isExpiry) {
        _expiryDateController.text = formatted;
      } else {
        _mfgDateController.text = formatted;
      }
    }
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMedicine,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text(
                'Save Medicine',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final expiryParts = _expiryDateController.text.split('/');
      if (expiryParts.length != 3) {
        _showError('Invalid expiry date format');
        return;
      }

      final expiryDate = DateTime(
        int.parse(expiryParts[2]),
        int.parse(expiryParts[1]),
        int.parse(expiryParts[0]),
      );

      DateTime? mfgDate;
      if (_mfgDateController.text.isNotEmpty) {
        final mfgParts = _mfgDateController.text.split('/');
        if (mfgParts.length == 3) {
          mfgDate = DateTime(
            int.parse(mfgParts[2]),
            int.parse(mfgParts[1]),
            int.parse(mfgParts[0]),
          );
        }
      }

      final medicineInfo = ProductInfo(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        category: 'Medicine',
        dosage: _dosageController.text.trim(),
        uses: _usesController.text.trim(),
        warnings: _warningsController.text.trim(),
        expiryDate: expiryDate,
        mfgDate: mfgDate,
        source: widget.entryMethod,
      );

      // Save logic here
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error saving medicine: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
