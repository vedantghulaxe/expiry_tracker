import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product_info.dart';
import '../../data/repositories/medicine_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/database/app_database.dart';
import '../../core/services/notification_service.dart';

/// Clean Product Form Screen with Sections
class ProductFormScreenNew extends StatefulWidget {
  final ProductInfo? productInfo;
  final ProductInfo? existingItem; // New parameter for editing
  final Map<String, dynamic>? analysisData;
  final List<File>? capturedImages;
  final bool isEditing;
  final bool isMedicine;

  const ProductFormScreenNew({
    super.key,
    this.productInfo,
    this.existingItem,
    this.analysisData,
    this.capturedImages,
    this.isEditing = false,
    this.isMedicine = false,
  });

  @override
  State<ProductFormScreenNew> createState() => _ProductFormScreenNewState();
}

class _ProductFormScreenNewState extends State<ProductFormScreenNew> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _mfgDateController = TextEditingController();
  final _batchController = TextEditingController();
  final _priceController = TextEditingController();
  final _dosageController = TextEditingController();
  final _warningsController = TextEditingController();
  final _usesController = TextEditingController();
  final _sideEffectsController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _nutritionController = TextEditingController();

  bool _isMedicine = false;
  bool _isLoading = false;
  late AppDatabase _database;
  late ProductRepository _productRepository;
  late MedicineRepository _medicineRepository;
  List<File> _capturedImages = []; // Store captured images properly

  @override
  void initState() {
    super.initState();
    _isMedicine = widget.isMedicine;
    
    // Load existing images immediately if editing
    if (widget.existingItem != null && widget.existingItem!.imageUrl != null && widget.existingItem!.imageUrl!.isNotEmpty) {
      final imageUrls = widget.existingItem!.imageUrls;
      _capturedImages = imageUrls
          .map((path) => File(path))
          .where((file) => file.existsSync())
          .toList();
      print('Loaded ${_capturedImages.length} existing images in initState');
    }
    
    // Load captured images from widget if provided
    if (widget.capturedImages != null && widget.capturedImages!.isNotEmpty) {
      _capturedImages.addAll(widget.capturedImages!);
      print('Added ${widget.capturedImages!.length} captured images from widget');
    }
    
    _initializeDatabase();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize form data after database is ready
    if (widget.existingItem != null && _nameController.text.isEmpty) {
      _initializeFormWithExistingItem();
    }
  }

  void _initializeFormWithExistingItem() {
    final item = widget.existingItem!;
    setState(() {
      _nameController.text = item.name ?? '';
      _brandController.text = item.brand ?? '';
      _expiryDateController.text = item.expiryDate != null
          ? '${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}'
          : '';
      _mfgDateController.text = item.mfgDate != null
          ? '${item.mfgDate!.day}/${item.mfgDate!.month}/${item.mfgDate!.year}'
          : '';
      _dosageController.text = item.dosage ?? '';
      _warningsController.text = item.warnings ?? '';
      _usesController.text = item.uses ?? '';
      _sideEffectsController.text = item.sideEffects ?? '';
      _ingredientsController.text = item.ingredients ?? '';
      _nutritionController.text = item.nutritionInfo ?? '';
      _isMedicine = item.category?.toLowerCase().contains('medicine') ?? false;
    });
  }

  Future<void> _initializeDatabase() async {
    try {
      final database = AppDatabase();
      setState(() {
        _database = database;
        _productRepository = ProductRepository(database);
        _medicineRepository = MedicineRepository(database);
      });
      _initializeForm(); // Initialize form AFTER database is ready
    } catch (e) {
      print('Error initializing database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Database error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _expiryDateController.dispose();
    _mfgDateController.dispose();
    _batchController.dispose();
    _priceController.dispose();
    _dosageController.dispose();
    _warningsController.dispose();
    _usesController.dispose();
    _ingredientsController.dispose();
    _nutritionController.dispose();
    _database.close();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.productInfo != null) {
      final product = widget.productInfo!;
      _nameController.text = product.name ?? '';
      _brandController.text = product.brand ?? '';
      _expiryDateController.text = _formatDate(product.expiryDate) ?? '';
      _mfgDateController.text = _formatDate(product.mfgDate) ?? '';
      _dosageController.text = product.dosage ?? '';
      _warningsController.text = product.warnings ?? '';
      _usesController.text = product.uses ?? '';
      _ingredientsController.text = product.ingredients ?? '';
      _nutritionController.text = product.nutritionInfo ?? '';
      _isMedicine = product.isMedicine;
      
      // Load existing images from productInfo
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        final imageUrls = product.imageUrls;
        final existingImages = imageUrls
            .map((path) => File(path))
            .where((file) => file.existsSync())
            .toList();
        if (existingImages.isNotEmpty && _capturedImages.isEmpty) {
          _capturedImages = existingImages;
          print('Loaded ${_capturedImages.length} existing images from productInfo');
        }
      }

      // Debug logging for existing product
      print('=== EDITING EXISTING PRODUCT ===');
      print('Name: ${_nameController.text}');
      print('Brand: ${_brandController.text}');
      print('Expiry: ${_expiryDateController.text}');
      print('MFG: ${_mfgDateController.text}');
      print('Is Medicine: $_isMedicine');
      print('Images: ${_capturedImages.length}');
      print('================================');
    } else if (widget.analysisData != null) {
      final parsedData =
          widget.analysisData!['parsed_data'] as Map<String, dynamic>? ?? {};

      print('=== ANALYSIS DATA RECEIVED ===');
      print('Full analysisData: ${widget.analysisData}');
      print('Parsed data: $parsedData');
      print('Raw text: ${widget.analysisData!['raw_text']}');
      print('Text: ${widget.analysisData!['text']}');
      print('');
      print('=== ALL PARSED DATA FIELDS ===');
      parsedData.forEach((key, value) {
        print('  $key: "$value"');
      });
      print('==============================');

      // Validate parsed data before assigning
      final name = _validateAndCleanText(parsedData['name']);
      final brand = _validateAndCleanText(parsedData['brand']);
      
      // Try multiple possible field names for expiry date
      final expiryDate = _validateAndCleanText(
        parsedData['expiryDate'] ?? 
        parsedData['expiry_date'] ?? 
        parsedData['expiry'] ?? 
        parsedData['exp'] ?? 
        parsedData['best_before'] ??
        parsedData['use_by'] ?? ''
      );
      
      // Try multiple possible field names for mfg date
      final mfgDate = _validateAndCleanText(
        parsedData['mfgDate'] ?? 
        parsedData['mfg_date'] ?? 
        parsedData['mfd'] ?? 
        parsedData['manufacturing_date'] ?? 
        parsedData['manufactured'] ??
        parsedData['pkd'] ?? ''
      );
      
      // Try multiple possible field names for batch
      final batch = _validateAndCleanText(
        parsedData['batch'] ?? 
        parsedData['batch_number'] ?? 
        parsedData['lot'] ?? 
        parsedData['lot_number'] ?? ''
      );
      
      final dosage = _validateAndCleanText(parsedData['dosage']);
      final warnings = _validateAndCleanText(parsedData['warnings']);
      final uses = _validateAndCleanText(parsedData['uses']);
      final ingredients = _validateAndCleanText(parsedData['ingredients']);
      final nutritionInfo = _validateAndCleanText(parsedData['nutritionInfo'] ?? parsedData['nutrition']);
      final mrp = _validateAndCleanText(parsedData['mrp'] ?? parsedData['price']);

      // Assign validated values
      _nameController.text = name;
      _brandController.text = brand;
      _expiryDateController.text = expiryDate;
      _mfgDateController.text = mfgDate;
      _batchController.text = batch;
      _dosageController.text = dosage;
      _warningsController.text = warnings;
      _usesController.text = uses;
      _ingredientsController.text = ingredients;
      _nutritionController.text = nutritionInfo;
      _priceController.text = mrp;
      
      // Determine if medicine based on category or isMedicine flag
      final category = parsedData['category']?.toString().toLowerCase() ?? '';
      _isMedicine = parsedData['isMedicine'] == true || 
                    category.contains('medicine') || 
                    category.contains('tablet') || 
                    category.contains('capsule') ||
                    category.contains('syrup') ||
                    widget.isMedicine;

      // Debug logging for auto-fill
      print('=== AUTO-FILL DEBUG ===');
      print('Raw analysisData keys: ${widget.analysisData!.keys}');
      print('Parsed data keys: ${parsedData.keys}');
      print('Name: "$name"');
      print('Brand: "$brand"');
      print('Expiry: "$expiryDate"');
      print('MFG: "$mfgDate"');
      print('Batch: "$batch"');
      print('Dosage: "$dosage"');
      print('Ingredients: "$ingredients"');
      print('Uses: "$uses"');
      print('Warnings: "$warnings"');
      print('Nutrition: "$nutritionInfo"');
      print('MRP: "$mrp"');
      print('Category: "$category"');
      print('Is Medicine: $_isMedicine');
      print('Confidence: ${parsedData['confidence']}');
      print('======================');
    }
    
    // Load captured images from widget if provided (for new items from scan)
    if (widget.capturedImages != null && widget.capturedImages!.isNotEmpty && _capturedImages.isEmpty) {
      _capturedImages = List.from(widget.capturedImages!);
      print('Loaded ${_capturedImages.length} captured images from widget');
    }

    // Force UI update
    if (mounted) {
      setState(() {});
    }
  }

  /// Parse flexible date formats (DD/MM/YYYY, MM/YYYY, MM/YY, DD/MM/YY)
  DateTime? _parseFlexibleDate(String dateText, String fieldName) {
    // Clean and validate input
    final cleanDate = dateText.trim();
    if (cleanDate.isEmpty) return null;

    // Support multiple separators
    final normalizedDate = cleanDate.replaceAll(RegExp(r'[-]'), '/');
    final parts = normalizedDate.split('/');

    try {
      if (parts.length == 2) {
        // MM/YYYY or MM/YY format
        final month = int.parse(parts[0]);
        int year = int.parse(parts[1]);

        // Expand 2-digit year: 00-49 → 2000-2049, 50-99 → 1950-1999
        if (year < 100) {
          year = year < 50 ? 2000 + year : 1900 + year;
        }

        if (month < 1 || month > 12) {
          throw Exception('Invalid month: $month');
        }
        if (year < 1900 || year > 2100) {
          throw Exception('Invalid year: $year');
        }

        // For expiry dates, use last day of month; for MFG dates, use first day
        final day = fieldName == 'Expiry'
            ? DateTime(year, month + 1, 0).day
            : 1;
        return DateTime(year, month, day);
      } else if (parts.length == 3) {
        // DD/MM/YYYY or DD/MM/YY format
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        int year = int.parse(parts[2]);

        // Expand 2-digit year
        if (year < 100) {
          year = year < 50 ? 2000 + year : 1900 + year;
        }

        if (day < 1 || day > 31) throw Exception('Invalid day: $day');
        if (month < 1 || month > 12) throw Exception('Invalid month: $month');
        if (year < 1900 || year > 2100) throw Exception('Invalid year: $year');

        return DateTime(year, month, day);
      } else {
        throw Exception(
          'Invalid date format: "$cleanDate". Use DD/MM/YYYY or MM/YYYY',
        );
      }
    } catch (e) {
      throw Exception('Invalid $fieldName date: "$cleanDate". Error: $e');
    }
  }

  /// Validate and clean extracted text
  String _validateAndCleanText(dynamic value) {
    if (value == null) return '';
    String text = value.toString().trim();

    // Don't clean if empty
    if (text.isEmpty) return '';

    // Remove excessive whitespace but keep the text structure
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Only remove truly invalid characters (control characters, etc.)
    // Keep alphanumeric, spaces, common punctuation, and special chars used in product names
    text = text.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ''); // Remove control characters

    // Validate minimum length
    if (text.length < 2) return '';

    return text;
  }

  bool _isValidDateFormat(String date) {
    final parts = date.split('/');
    if (parts.length == 2) {
      // MM/YYYY or MM/YY format
      return parts[0].length <= 2 &&
          (parts[1].length == 4 || parts[1].length == 2);
    } else if (parts.length == 3) {
      // DD/MM/YYYY or DD/MM/YY format
      return parts[0].length <= 2 &&
          parts[1].length <= 2 &&
          (parts[2].length == 4 || parts[2].length == 2);
    }
    return false;
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Item' : 'Add New Item'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveItem,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildImageCaptureSection(),
              const SizedBox(height: 24),
              _buildDatesSection(),
              const SizedBox(height: 24),
              _buildConditionalFieldsSection(),
            ],
          ),
        ),
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
            Text(
              'Basic Information',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.label),
              ),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Category:',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isMedicine
                        ? Colors.red.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isMedicine
                          ? Colors.red.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isMedicine ? Icons.medication : Icons.inventory_2,
                        color: _isMedicine ? Colors.red : Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isMedicine ? 'Medicine' : 'Product',
                        style: TextStyle(
                          color: _isMedicine ? Colors.red : Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCaptureSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Images',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Capture Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose Image'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickMultipleImages,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose Multiple Images'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_capturedImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Selected Images (${_capturedImages.length})',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _capturedImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _capturedImages[index],
                              fit: BoxFit.cover,
                              width: 80,
                              height: 100,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _capturedImages.add(file);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image captured successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        print('Image captured: ${image.path}');
        print('Total captured images: ${_capturedImages.length}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error capturing image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _capturedImages.add(file);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        print('Image selected: ${image.path}');
        print('Total captured images: ${_capturedImages.length}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _capturedImages.addAll(images.map((xFile) => File(xFile.path)));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${images.length} images selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        print('Selected ${images.length} images:');
        for (int i = 0; i < images.length; i++) {
          print('Image ${i + 1}: ${images[i].path}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.orange,
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
            Text(
              'Important Dates',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expiryDateController,
              decoration: InputDecoration(
                labelText: 'Expiry Date *',
                hintText: 'DD/MM/YYYY or MM/YYYY',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
                helperText: 'Format: DD/MM/YYYY or MM/YYYY',
                helperStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              readOnly: true,
              onTap: () => _selectDate(true),
              validator: (value) {
                if (value?.trim().isEmpty == true) {
                  return 'Expiry date is required';
                }
                if (value != null && !_isValidDateFormat(value.trim())) {
                  return 'Invalid date format. Use DD/MM/YYYY or MM/YYYY';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mfgDateController,
              decoration: _buildInputDecoration(
                'Manufacturing Date',
                'DD/MM/YYYY',
              ),
              readOnly: true,
              onTap: () => _selectDate(false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionalFieldsSection() {
    if (_isMedicine) {
      return _buildMedicineFields();
    } else {
      return _buildProductFields();
    }
  }

  Widget _buildMedicineFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medicine Information',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dosageController,
              decoration: _buildInputDecoration(
                'Dosage',
                'e.g., 500mg, 1 tablet',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usesController,
              decoration: _buildInputDecoration(
                'Uses',
                'e.g., Fever, Pain relief',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _warningsController,
              decoration: _buildInputDecoration(
                'Warnings',
                'e.g., May cause drowsiness',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sideEffectsController,
              decoration: _buildInputDecoration(
                'Symptoms',
                'e.g., Headache, Fever, Cold',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                'e.g., Calories, Proteins',
              ),
              maxLines: 3,
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

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate data quality
    if (!_isDataValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid data! Product name must be at least 2 characters and meaningful.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Parse expiry date with multiple format support
      DateTime? expiryDate;
      if (_expiryDateController.text.isNotEmpty) {
        final expiryText = _expiryDateController.text.trim();
        expiryDate = _parseFlexibleDate(expiryText, 'Expiry');
      }

      // Parse MFG date (optional)
      DateTime? mfgDate;
      if (_mfgDateController.text.isNotEmpty) {
        final mfgText = _mfgDateController.text.trim();
        mfgDate = _parseFlexibleDate(mfgText, 'MFG');
      }

      final productInfo = ProductInfo(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        category: _isMedicine ? 'Medicine' : 'Product',
        dosage: _dosageController.text.trim(),
        uses: _usesController.text.trim(),
        warnings: _warningsController.text.trim(),
        sideEffects: _sideEffectsController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        nutritionInfo: _nutritionController.text.trim(),
        expiryDate: expiryDate,
        mfgDate: mfgDate,
        imageUrl: ProductInfo.encodeImageUrls(
          _capturedImages.map((f) => f.path).toList(),
        ),
        source: 'manual_entry',
      );

      print('=== SAVING ITEM DEBUG ===');
      print('Name: ${productInfo.name}');
      print('Brand: ${productInfo.brand}');
      print('Category: ${productInfo.category}');
      print('Expiry: ${productInfo.expiryDate}');
      print('MFG: ${productInfo.mfgDate}');
      print('Images: ${_capturedImages.length}');
      print('Is Medicine: $_isMedicine');
      print('========================');

      // Save or update to repository
      print('=== REPOSITORY SAVE START ===');
      print('Is Editing: ${widget.isEditing}');
      print('Existing Item ID: ${widget.existingItem?.id}');
      print('Is Medicine: $_isMedicine');

      if (widget.isEditing && widget.existingItem?.id != null) {
        // Update existing item
        print('Updating existing item...');
        if (_isMedicine) {
          await _medicineRepository.updateMedicine(
            widget.existingItem!.id!,
            productInfo,
          );
          print('Medicine updated successfully');
        } else {
          await _productRepository.updateProduct(
            widget.existingItem!.id!,
            productInfo,
          );
          print('Product updated successfully');
        }
      } else {
        // Add new item
        print('Adding new item...');
        if (_isMedicine) {
          await _medicineRepository.addMedicine(productInfo);
          print('Medicine added successfully');
        } else {
          await _productRepository.addProduct(productInfo);
          print('Product added successfully');
        }
      }
      print('=== REPOSITORY SAVE COMPLETE ===');

      // Schedule expiry notifications
      try {
        final notificationService = NotificationService();
        await notificationService.scheduleExpiryNotifications(productInfo);
        print('=== NOTIFICATIONS SCHEDULED ===');
        print('Scheduled notifications for: ${productInfo.name}');
      } catch (e) {
        print('=== NOTIFICATION ERROR ===');
        print('Failed to schedule notifications: $e');
      }

      if (mounted) {
        print('=== SAVE SUCCESSFUL, RETURNING TRUE ===');
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Item updated successfully!'
                  : 'Item added successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('=== SAVE ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('==================');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Validate if the data is meaningful and not garbage
  bool _isDataValid() {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();

    print('=== DATA VALIDATION ===');
    print('Name: "$name" (length: ${name.length})');
    print('Brand: "$brand" (length: ${brand.length})');

    // Check if name is meaningful
    if (name.isEmpty || name.length < 2) {
      print('❌ Validation FAILED: Name too short');
      print('======================');
      return false;
    }

    // Check for common garbage indicators
    final garbageIndicators = [
      'test',
      'demo',
      'sample',
      'example',
      'data',
      'text',
      'image',
      'photo',
      'scan',
      'ocr',
      'result',
      'output',
      'hello',
      'world',
      'null',
      'undefined',
      'error',
    ];

    if (garbageIndicators.any(
      (indicator) => name.toLowerCase().contains(indicator),
    )) {
      print('❌ Validation FAILED: Contains garbage indicator');
      print('======================');
      return false;
    }

    // Check if brand is meaningful (if provided)
    if (brand.isNotEmpty && brand.length < 2) {
      print('❌ Validation FAILED: Brand too short');
      print('======================');
      return false;
    }

    // Check for reasonable product name patterns
    if (_isLikelyGarbageText(name)) {
      print('❌ Validation FAILED: Likely garbage text');
      print('======================');
      return false;
    }

    print('✅ Validation PASSED');
    print('======================');
    return true;
  }

  /// Check if text is likely garbage
  bool _isLikelyGarbageText(String text) {
    // Remove common words and check if anything meaningful remains
    final commonWords = [
      'the',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'this',
      'that',
      'these',
      'those',
      'is',
      'are',
      'was',
      'were',
      'be',
      'been',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'could',
      'should',
    ];

    final words = text.toLowerCase().split(' ');
    final meaningfulWords = words
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .toList();

    // If less than 2 meaningful words, consider it garbage
    return meaningfulWords.length < 2;
  }
}
