import 'package:flutter/material.dart';
import '../../models/product_info.dart';

/// Product Form Screen with Strict Sections
class ProductFormScreen extends StatefulWidget {
  final String entryMethod;
  final Map<String, dynamic>? extractedData;
  final ProductInfo? productInfo;
  final bool isEditing;

  const ProductFormScreen({
    super.key,
    required this.entryMethod,
    this.extractedData,
    this.productInfo,
    this.isEditing = false,
  });

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _mfgDateController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _nutritionController = TextEditingController();
  final _storageController = TextEditingController();

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
    _categoryController.dispose();
    _expiryDateController.dispose();
    _mfgDateController.dispose();
    _ingredientsController.dispose();
    _nutritionController.dispose();
    _storageController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    // Initialize with extracted data if available
    if (widget.extractedData != null) {
      _nameController.text = widget.extractedData!['name'] ?? '';
      _brandController.text = widget.extractedData!['brand'] ?? '';
      _categoryController.text = widget.extractedData!['category'] ?? '';
      _expiryDateController.text = widget.extractedData!['expiryDate'] ?? '';
      _mfgDateController.text = widget.extractedData!['mfgDate'] ?? '';
      _ingredientsController.text = widget.extractedData!['ingredients'] ?? '';
      _isAutoFilled = true;
    } else if (widget.productInfo != null) {
      final product = widget.productInfo!;
      _nameController.text = product.name ?? '';
      _brandController.text = product.brand ?? '';
      _categoryController.text = product.category ?? '';
      _expiryDateController.text = _formatDate(product.expiryDate) ?? '';
      _mfgDateController.text = _formatDate(product.mfgDate) ?? '';
      _ingredientsController.text = product.ingredients ?? '';
      _nutritionController.text = product.nutritionInfo ?? '';
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
        title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isAutoFilled)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: const Text(
                  'Auto-filled',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: Colors.green.withValues(alpha: 0.2),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
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
              _buildProductDetailsSection(),
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
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Product details auto-filled from scan. Please review and edit if needed.',
              style: TextStyle(color: Colors.green, fontSize: 14),
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
                Icon(Icons.shopping_bag, color: Colors.blue, size: 20),
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
              decoration: _buildInputDecoration(
                'Product Name*',
                'Enter product name',
              ),
              validator: (value) =>
                  value?.isEmpty == true ? 'Product name is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: _buildInputDecoration('Brand', 'Enter brand name'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              decoration: _buildInputDecoration(
                'Category',
                'e.g., Food, Cosmetics, Household',
              ),
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
                Icon(Icons.calendar_today, color: Colors.blue, size: 20),
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
              validator: (value) =>
                  value?.isEmpty == true ? 'Expiry date is required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mfgDateController,
              decoration: _buildInputDecoration(
                'Manufacturing Date',
                'DD/MM/YYYY (Optional)',
              ),
              readOnly: true,
              onTap: () => _selectDate(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailsSection() {
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
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Product Details',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ingredientsController,
              decoration: _buildInputDecoration(
                'Ingredients',
                'List main ingredients',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nutritionController,
              decoration: _buildInputDecoration(
                'Nutrition Info',
                'e.g., Calories, Proteins, Fats',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _storageController,
              decoration: _buildInputDecoration(
                'Storage Info',
                'e.g., Store in cool dry place',
              ),
              maxLines: 2,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
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
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Save Product',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Future<void> _saveProduct() async {
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

      final _ = ProductInfo(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        category: _categoryController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        nutritionInfo: _nutritionController.text.trim(),
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
            content: Text('Product saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error saving product: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
