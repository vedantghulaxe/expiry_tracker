import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../data/repositories/product_repository.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/ui_helpers.dart';
import '../../data/database/app_database.dart';
import '../../models/product_info.dart';
import 'package:drift/drift.dart' as drift;

/// Manual Product Entry Screen
/// Allows users to manually enter product details with multiple images
class ManualProductEntryScreen extends StatefulWidget {
  final bool isMedicine;
  final Map<String, dynamic>? analysisData;

  const ManualProductEntryScreen({
    super.key,
    this.isMedicine = false,
    this.analysisData,
  });

  @override
  State<ManualProductEntryScreen> createState() =>
      _ManualProductEntryScreenState();
}

class _ManualProductEntryScreenState extends State<ManualProductEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();
  ProductRepository? _repository;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _populateFormFromAnalysisData();
  }

  Future<void> _initializeRepository() async {
    final database = await _dbService.database;
    _repository = ProductRepository(database);
  }

  // Controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _quantityController = TextEditingController();
  final _ingredientsController = TextEditingController();
  final _notesController = TextEditingController();

  // State variables
  DateTime? _expiryDate;
  DateTime? _manufacturingDate;
  List<File> _selectedImages = [];
  bool _isLoading = false;

  /// AI-Powered Information Extraction
  Map<String, dynamic> _aiExtractInformation(
    String rawText,
    Map<String, dynamic> parsedData,
  ) {
    print('=== AI EXTRACTION START ===');

    Map<String, dynamic> aiResult = {};

    // Split text into lines for analysis
    List<String> lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    // AI Decision 1: Product Name Extraction
    aiResult['name'] = _aiExtractProductName(lines);

    // AI Decision 2: Brand/Manufacturer Extraction
    aiResult['brand'] = _aiExtractBrand(lines);

    // AI Decision 3: Date Extraction with Context
    aiResult['expiryDate'] = _aiExtractDate(lines, 'expiry');
    aiResult['mfgDate'] = _aiExtractDate(lines, 'mfg');

    // AI Decision 4: Batch Number Extraction
    aiResult['batchNumber'] = _aiExtractBatchNumber(lines);

    // AI Decision 5: Category Classification
    aiResult['category'] = _aiClassifyCategory(lines, parsedData);

    // AI Decision 6: Medicine Detection
    aiResult['isMedicine'] = _aiDetectMedicine(lines);

    // AI Decision 7: Dosage Extraction (if medicine)
    if (aiResult['isMedicine']) {
      aiResult['dosage'] = _aiExtractDosage(lines);
    }

    // AI Decision 8: Uses/Warnings Extraction
    aiResult['uses'] = _aiExtractUses(lines);
    aiResult['warnings'] = _aiExtractWarnings(lines);

    print('=== AI EXTRACTION COMPLETE ===');
    return aiResult;
  }

  /// AI Product Name Extraction
  String _aiExtractProductName(List<String> lines) {
    print('=== AI PRODUCT NAME EXTRACTION ===');

    List<String> possibleNames = [];

    for (String line in lines) {
      // Skip obvious non-product lines
      if (_isNonProductLine(line)) continue;

      // AI Pattern 1: Product names are often 2-4 words, capitalized
      if (RegExp(r'^[A-Z][a-z]+(?:\s+[A-Z][a-z]+){1,3}$').hasMatch(line)) {
        possibleNames.add(line);
        print('AI: Found capitalized product name: "$line"');
      }

      // AI Pattern 2: Product names with common product words
      if (_containsProductWord(line)) {
        possibleNames.add(line);
        print('AI: Found product with product word: "$line"');
      }

      // AI Pattern 3: Short, meaningful lines
      if (line.length > 3 &&
          line.length < 25 &&
          !line.contains(RegExp(r'\d')) &&
          !line.toLowerCase().contains('batch') &&
          !line.toLowerCase().contains('mfg') &&
          !line.toLowerCase().contains('exp')) {
        possibleNames.add(line);
        print('AI: Found short meaningful line: "$line"');
      }
    }

    // AI Decision: Choose the best candidate
    String bestName = '';
    for (String name in possibleNames) {
      if (name.length > bestName.length && name.length < 30) {
        bestName = name;
      }
    }

    print('AI: Selected product name: "$bestName"');
    return bestName;
  }

  /// AI Brand/Manufacturer Extraction
  String _aiExtractBrand(List<String> lines) {
    print('=== AI BRAND EXTRACTION ===');

    for (String line in lines) {
      // AI Pattern 1: "Manufactured by" or "Marketed by"
      if (line.toLowerCase().contains('manufactured by') ||
          line.toLowerCase().contains('marketed by')) {
        String brand = line.split(':').last.trim();
        if (brand.isNotEmpty && brand.length < 50) {
          print('AI: Found brand from "by" pattern: "$brand"');
          return brand;
        }
      }

      // AI Pattern 2: Company names with LLP/LTD/PVT
      if (RegExp(
        r'\b(LLP|LTD|PVT|LABORATORIES|LIFESCIENCE)\b',
        caseSensitive: false,
      ).hasMatch(line)) {
        // Clean up the brand name
        String brand = line
            .replaceAll(
              RegExp(
                r'\b(Inc\.?|GST|M\.R\.P\.|Rs\.?)\b.*',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
        if (brand.isNotEmpty && brand.length < 50) {
          print('AI: Found brand from company pattern: "$brand"');
          return brand;
        }
      }

      // AI Pattern 3: All caps company names
      if (RegExp(r'^[A-Z\s]{5,}$').hasMatch(line) &&
          !line.toLowerCase().contains('batch') &&
          !line.toLowerCase().contains('mfg') &&
          !line.toLowerCase().contains('exp')) {
        print('AI: Found all caps brand: "$line"');
        return line;
      }
    }

    print('AI: No brand found');
    return '';
  }

  /// AI Date Extraction with Context
  String _aiExtractDate(List<String> lines, String dateType) {
    print('=== AI DATE EXTRACTION ($dateType) ===');

    String context = dateType == 'expiry' ? 'exp' : 'mfg';

    for (String line in lines) {
      if (line.toLowerCase().contains(context) ||
          (dateType == 'expiry' && line.toLowerCase().contains('use before'))) {
        RegExp datePattern = RegExp(
          r'(\d{1,2}[/-]\d{2,4}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})',
        );
        Match? match = datePattern.firstMatch(line);

        if (match != null) {
          String date = match.group(0)!;
          print('AI: Found $dateType date: "$date"');
          return date;
        }
      }
    }

    // Fallback: Look for any date pattern
    for (String line in lines) {
      RegExp datePattern = RegExp(
        r'(\d{1,2}[/-]\d{2,4}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{4}[/-]\d{1,2}[/-]\d{1,2})',
      );
      Match? match = datePattern.firstMatch(line);

      if (match != null) {
        String date = match.group(0)!;
        print('AI: Found fallback date: "$date"');
        return date;
      }
    }

    print('AI: No $dateType date found');
    return '';
  }

  /// AI Batch Number Extraction
  String _aiExtractBatchNumber(List<String> lines) {
    print('=== AI BATCH EXTRACTION ===');

    for (String line in lines) {
      // AI Pattern 1: "Batch No." or "Batch Number"
      if (line.toLowerCase().contains('batch')) {
        RegExp batchPattern = RegExp(r'[A-Z]{2,}[/\s]*\d+');
        Match? match = batchPattern.firstMatch(line);

        if (match != null) {
          String batch = match.group(0)!;
          print('AI: Found batch number: "$batch"');
          return batch;
        }
      }

      // AI Pattern 2: License numbers (often contain batch info)
      if (line.toLowerCase().contains('lic')) {
        RegExp licPattern = RegExp(r'[A-Z][/]\d+[/]\d+');
        Match? match = licPattern.firstMatch(line);

        if (match != null) {
          String batch = match.group(0)!;
          print('AI: Found license pattern (possible batch): "$batch"');
          return batch;
        }
      }
    }

    print('AI: No batch number found');
    return '';
  }

  /// AI Category Classification
  String _aiClassifyCategory(
    List<String> lines,
    Map<String, dynamic> parsedData,
  ) {
    print('=== AI CATEGORY CLASSIFICATION ===');

    // AI Analysis: Check for medicine indicators
    int medicineScore = 0;
    int productScore = 0;

    for (String line in lines) {
      String lowerLine = line.toLowerCase();

      // Medicine indicators
      if (lowerLine.contains('tablet') ||
          lowerLine.contains('capsule') ||
          lowerLine.contains('syrup') ||
          lowerLine.contains('ointment') ||
          lowerLine.contains('medicine') ||
          lowerLine.contains('pharma')) {
        medicineScore += 3;
      }

      if (lowerLine.contains('dosage') ||
          lowerLine.contains('prescription') ||
          lowerLine.contains('medical') ||
          lowerLine.contains('clinical')) {
        medicineScore += 2;
      }

      // Product indicators
      if (lowerLine.contains('cream') ||
          lowerLine.contains('lotion') ||
          lowerLine.contains('serum') ||
          lowerLine.contains('oil') ||
          lowerLine.contains('cosmetic') ||
          lowerLine.contains('beauty')) {
        productScore += 3;
      }

      if (lowerLine.contains('ml') ||
          lowerLine.contains('grams') ||
          lowerLine.contains('pack') ||
          lowerLine.contains('net weight')) {
        productScore += 1;
      }
    }

    // AI Decision
    String category = medicineScore > productScore ? 'medicine' : 'product';
    print('AI: Medicine score: $medicineScore, Product score: $productScore');
    print('AI: Classified as: $category');

    return category;
  }

  /// AI Medicine Detection
  bool _aiDetectMedicine(List<String> lines) {
    print('=== AI MEDICINE DETECTION ===');

    for (String line in lines) {
      String lowerLine = line.toLowerCase();

      // Strong medicine indicators
      if (lowerLine.contains('tablet') ||
          lowerLine.contains('capsule') ||
          lowerLine.contains('syrup') ||
          lowerLine.contains('medicine') ||
          lowerLine.contains('pharma') ||
          lowerLine.contains('dosage')) {
        print('AI: Medicine detected: "$line"');
        return true;
      }
    }

    print('AI: Not a medicine');
    return false;
  }

  /// AI Dosage Extraction
  String _aiExtractDosage(List<String> lines) {
    print('=== AI DOSAGE EXTRACTION ===');

    for (String line in lines) {
      if (line.toLowerCase().contains('dosage') ||
          line.toLowerCase().contains('strength') ||
          line.toLowerCase().contains('mg') ||
          line.toLowerCase().contains('ml')) {
        RegExp dosagePattern = RegExp(r'\d+(?:\.\d+)?\s*(?:mg|ml|g|mcg)');
        Match? match = dosagePattern.firstMatch(line);

        if (match != null) {
          String dosage = match.group(0)!;
          print('AI: Found dosage: "$dosage"');
          return dosage;
        }
      }
    }

    print('AI: No dosage found');
    return '';
  }

  /// AI Uses Extraction
  String _aiExtractUses(List<String> lines) {
    print('=== AI USES EXTRACTION ===');

    List<String> uses = [];

    for (String line in lines) {
      if (line.toLowerCase().contains('uses') ||
          line.toLowerCase().contains('indications') ||
          line.toLowerCase().contains('benefits')) {
        String useText = line.split(':').last.trim();
        if (useText.isNotEmpty && useText.length < 100) {
          uses.add(useText);
          print('AI: Found use: "$useText"');
        }
      }
    }

    return uses.join(', ');
  }

  /// AI Warnings Extraction
  String _aiExtractWarnings(List<String> lines) {
    print('=== AI WARNINGS EXTRACTION ===');

    List<String> warnings = [];

    for (String line in lines) {
      if (line.toLowerCase().contains('warning') ||
          line.toLowerCase().contains('caution') ||
          line.toLowerCase().contains('side effect') ||
          line.toLowerCase().contains('contra')) {
        String warningText = line.split(':').last.trim();
        if (warningText.isNotEmpty && warningText.length < 100) {
          warnings.add(warningText);
          print('AI: Found warning: "$warningText"');
        }
      }
    }

    return warnings.join(', ');
  }

  /// Helper: Check if line is non-product related
  bool _isNonProductLine(String line) {
    String lowerLine = line.toLowerCase();

    return lowerLine.contains('www.') ||
        lowerLine.contains('.com') ||
        lowerLine.contains('dist.') ||
        lowerLine.contains('estate') ||
        lowerLine.contains('marketed by') ||
        lowerLine.contains('m.r.p.') ||
        lowerLine.contains('rs.') ||
        lowerLine.contains('gst') ||
        lowerLine.contains('batch') ||
        lowerLine.contains('mfg') ||
        lowerLine.contains('exp') ||
        lowerLine.contains('date') ||
        lowerLine.contains('lic') ||
        line.contains(RegExp(r'\d{2}[/]\d{2}')) ||
        line.contains(RegExp(r'^\d+')) ||
        line.contains(RegExp(r'[A-Z]/\d+'));
  }

  /// Helper: Check if line contains product words
  bool _containsProductWord(String line) {
    List<String> productWords = [
      'serum',
      'cream',
      'lotion',
      'oil',
      'gel',
      'tablet',
      'capsule',
      'medicine',
      'ointment',
      'syrup',
      'shampoo',
      'soap',
      'toothpaste',
      'perfume',
      'makeup',
      'cosmetic',
      'beauty',
      'health',
      'care',
    ];

    String lowerLine = line.toLowerCase();
    return productWords.any((word) => lowerLine.contains(word));
  }

  void _populateFormFromAnalysisData() {
    if (widget.analysisData != null) {
      print('=== AI-POWERED FORM POPULATION ===');
      print('Full analysis data: ${widget.analysisData}');

      // Handle nested and mixed result shapes safely.
      final parsedData = _normalizeParsedData(widget.analysisData!);
      print('=== NORMALIZED PARSED DATA ===');
      parsedData.forEach((key, value) {
        print('  $key: "$value"');
      });

      // Auto-fill images captured during scan flow.
      final imagePaths = _extractImagePaths(widget.analysisData!);
      if (imagePaths.isNotEmpty) {
        final existing = imagePaths
            .map((path) => File(path))
            .where((file) => file.existsSync())
            .toList();
        if (existing.isNotEmpty) {
          _selectedImages = existing.take(5).toList();
          print('Auto-filled ${_selectedImages.length} scanned images');
        }
      }

      // PRIORITY: Use AI vision extracted data directly from Oxlo.ai
      // Check all possible field name variations
      String name = parsedData['name']?.toString() ??
                    parsedData['product_name']?.toString() ??
                    '';
      String brand = parsedData['brand']?.toString() ??
                      parsedData['manufacturer']?.toString() ??
                      parsedData['company']?.toString() ??
                      '';
      String expiry = parsedData['expiry']?.toString() ??
                       parsedData['expiry_date']?.toString() ??
                       parsedData['expiryDate']?.toString() ??
                       parsedData['expiration_date']?.toString() ??
                       '';
      String mfg = parsedData['mfg']?.toString() ??
                    parsedData['mfg_date']?.toString() ??
                    parsedData['mfgDate']?.toString() ??
                    parsedData['manufacturing_date']?.toString() ??
                    '';
      String ingredients = parsedData['ingredients']?.toString() ??
                            parsedData['composition']?.toString() ??
                            '';
      String category = parsedData['category']?.toString() ??
                        parsedData['type']?.toString() ??
                        '';
      String batch = parsedData['batch']?.toString() ??
                      parsedData['batch_number']?.toString() ??
                      parsedData['batchNumber']?.toString() ??
                      '';

      print('=== AI VISION DATA (EXTRACTED) ===');
      print('Name: "$name" (Source: ${name.isEmpty ? "Empty" : "AI Vision"})');
      print('Brand: "$brand" (Source: ${brand.isEmpty ? "Empty" : "AI Vision"})');
      print('Expiry: "$expiry" (Source: ${expiry.isEmpty ? "Empty" : "AI Vision"})');
      print('Mfg: "$mfg" (Source: ${mfg.isEmpty ? "Empty" : "AI Vision"})');
      print('Category: "$category" (Source: ${category.isEmpty ? "Empty" : "AI Vision"})');
      print('Batch: "$batch" (Source: ${batch.isEmpty ? "Empty" : "AI Vision"})');
      print('Ingredients: "$ingredients" (Source: ${ingredients.isEmpty ? "Empty" : "AI Vision"})');

      // Fallback to local extraction only if AI vision data is empty
      bool usedLocalExtraction = false;
      if (name.isEmpty) {
        String rawText = widget.analysisData!['text']?.toString() ?? '';
        print('⚠️ AI vision name empty, using LOCAL REGEX EXTRACTION');
        usedLocalExtraction = true;
        Map<String, dynamic> localExtracted = _aiExtractInformation(rawText, parsedData);
        name = localExtracted['name']?.toString() ?? '';
        if (brand.isEmpty) brand = localExtracted['brand']?.toString() ?? '';
        if (expiry.isEmpty) expiry = localExtracted['expiryDate']?.toString() ?? '';
        if (mfg.isEmpty) mfg = localExtracted['mfgDate']?.toString() ?? '';
      }

      print('=== DATA SOURCE SUMMARY ===');
      print('Primary Data Source: ${usedLocalExtraction ? "LOCAL REGEX (AI Vision Failed)" : "AI VISION (Oxlo.ai)"}');

      // AGGRESSIVE: Always populate name if we have any text
      if (name.isEmpty && widget.analysisData!['text'] != null) {
        String fullText = widget.analysisData!['text'].toString();
        List<String> lines = fullText.split('\n');

        // Look for product names (skip URLs, addresses, prices)
        for (String line in lines) {
          line = line.trim();
          if (line.length > 3 &&
              line.length < 30 &&
              !line.toLowerCase().contains('batch') &&
              !line.toLowerCase().contains('mfg') &&
              !line.toLowerCase().contains('exp') &&
              !line.toLowerCase().contains('date') &&
              !line.toLowerCase().contains('www.') &&
              !line.toLowerCase().contains('.com') &&
              !line.toLowerCase().contains('dist.') &&
              !line.toLowerCase().contains('estate') &&
              !line.toLowerCase().contains('marketed by') &&
              !line.toLowerCase().contains('manufactured by') &&
              !line.toLowerCase().contains('m.r.p.') &&
              !line.toLowerCase().contains('mrp') &&
              !line.toLowerCase().contains('rs.') &&
              !line.toLowerCase().contains('gst') &&
              !line.toLowerCase().contains('tax') &&
              !line.toLowerCase().contains('inclusive') &&
              !line.toLowerCase().contains('price') &&
              !line.toLowerCase().contains('rupee') &&
              !line.contains(RegExp(r'\d{2}[/]\d{2}')) &&
              !line.contains(RegExp(r'^\d+')) &&
              !line.contains(RegExp(r'[A-Z]/\d+'))) {
            name = line;
            break;
          }
        }

        // If still no name found, try to combine short lines that look like product names
        if (name.isEmpty) {
          List<String> possibleNames = [];
          for (String line in lines) {
            line = line.trim();
            if (line.length > 2 &&
                line.length < 20 &&
                !line.contains(RegExp(r'\d')) &&
                !line.toLowerCase().contains('batch') &&
                !line.toLowerCase().contains('mfg') &&
                !line.toLowerCase().contains('exp')) {
              possibleNames.add(line);
            }
          }
          if (possibleNames.length >= 2) {
            name = possibleNames.take(2).join(' ');
          } else if (possibleNames.isNotEmpty) {
            name = possibleNames.first;
          }
        }
      }

      _nameController.text = name;
      print('FINAL - Populated name: "$name"');

      // Use AI vision brand data
      _brandController.text = brand;
      print('FINAL - Populated brand: "$brand"');

      // Use AI vision category data
      if (category.isEmpty || category == 'product') {
        if (widget.isMedicine) {
          category = 'medicine';
        } else {
          category = 'product';
        }
      }
      _categoryController.text = category;
      print('FINAL - Populated category: "$category"');

      // Use AI vision ingredients data
      if (ingredients.isNotEmpty) {
        _ingredientsController.text = ingredients;
        print('Populated ingredients: "$ingredients"');
      } else if (widget.analysisData!['text'] != null) {
        final extractedIngredients = _extractIngredientsFromText(
          widget.analysisData!['text'].toString(),
        );
        if (extractedIngredients.isNotEmpty) {
          _ingredientsController.text = extractedIngredients;
          print('Extracted ingredients from text: "$extractedIngredients"');
        }
      }

      // Populate quantity if available
      if (parsedData['quantity'] != null &&
          parsedData['quantity'].toString().isNotEmpty &&
          parsedData['quantity'] != 'Not detected') {
        _quantityController.text = parsedData['quantity'].toString();
        print('Populated quantity: "${parsedData['quantity']}"');
      } else {
        final inferredQty = _extractQuantityFromText(
          widget.analysisData!['text']?.toString() ??
              parsedData['name']?.toString() ??
              '',
        );
        if (inferredQty.isNotEmpty) {
          _quantityController.text = inferredQty;
          print('Inferred quantity: "$inferredQty"');
        }
      }

      // Build comprehensive notes
      List<String> notes = [];

      // Use AI vision batch data
      if (batch.isEmpty && widget.analysisData!['text'] != null) {
        String fullText = widget.analysisData!['text'].toString();
        List<String> lines = fullText.split('\n');
        for (String line in lines) {
          line = line.trim();
          if (line.toLowerCase().contains('batch') ||
              line.contains(RegExp(r'^[A-Z]{2,}\s+/\s+\d+')) ||
              line.contains(RegExp(r'^[A-Z]{2,}\s+\d+'))) {
            batch = line;
            print('Aggressive batch extraction: "$batch"');
            break;
          }
        }
      }

      if (batch.isNotEmpty) {
        notes.add('Batch Number: $batch');
        print('FINAL - Added batch to notes: $batch');
      }

      // Add dosage
      if (parsedData['dosage'] != null &&
          parsedData['dosage'].toString().isNotEmpty &&
          parsedData['dosage'] != 'Not applicable') {
        notes.add('Dosage: ${parsedData['dosage']}');
        print('Added dosage to notes: ${parsedData['dosage']}');
      }

      // Add uses
      if (parsedData['uses'] != null &&
          parsedData['uses'].toString().isNotEmpty &&
          parsedData['uses'] != 'Not detected') {
        notes.add('Uses: ${parsedData['uses']}');
        print('Added uses to notes: ${parsedData['uses']}');
      }

      // Add warnings
      if (parsedData['warnings'] != null &&
          parsedData['warnings'].toString().isNotEmpty &&
          parsedData['warnings'] != 'Not detected') {
        notes.add('Warnings: ${parsedData['warnings']}');
        print('Added warnings to notes: ${parsedData['warnings']}');
      }

      // Add barcode if available
      if (parsedData['barcode'] != null &&
          parsedData['barcode'].toString().isNotEmpty) {
        notes.add('Barcode: ${parsedData['barcode']}');
        print('Added barcode to notes: ${parsedData['barcode']}');
      }

      // Add source information
      if (parsedData['source'] != null &&
          parsedData['source'].toString().isNotEmpty) {
        notes.add('Source: ${parsedData['source']}');
        print('Added source to notes: ${parsedData['source']}');
      }

      // Add confidence if available
      if (parsedData['confidence'] != null) {
        final confidence = (parsedData['confidence'] as num).toDouble();
        notes.add('Confidence: ${(confidence * 100).toInt()}%');
        print('Added confidence to notes: ${(confidence * 100).toInt()}%');
      }

      if (notes.isNotEmpty) {
        _notesController.text = notes.join('\n');
        print('Populated notes with ${notes.length} items');
      }

      // Use AI vision dates directly
      String expiryDate = expiry.isNotEmpty ? expiry : '';
      String mfgDate = mfg.isNotEmpty ? mfg : '';

      if (expiryDate.isEmpty && parsedData['expiryDate'] != null &&
          parsedData['expiryDate'].toString().isNotEmpty) {
        expiryDate = parsedData['expiryDate'].toString();
        print('Found expiry from parsed_data: "$expiryDate"');
      }

      if (mfgDate.isEmpty && parsedData['mfgDate'] != null &&
          parsedData['mfgDate'].toString().isNotEmpty) {
        mfgDate = parsedData['mfgDate'].toString();
        print('Found mfg from parsed_data: "$mfgDate"');
      }

      expiryDate = _firstNonEmpty([
        expiryDate,
        parsedData['expiryDate']?.toString(),
        parsedData['expiry_date']?.toString(),
        parsedData['expiration_date']?.toString(),
        parsedData['best_before']?.toString(),
        parsedData['use_by']?.toString(),
      ]);
      mfgDate = _firstNonEmpty([
        mfgDate,
        parsedData['mfgDate']?.toString(),
        parsedData['mfg_date']?.toString(),
        parsedData['manufacturing_date']?.toString(),
        parsedData['production_date']?.toString(),
      ]);

      // AGGRESSIVE: Extract dates from raw text
      if ((expiryDate.isEmpty || mfgDate.isEmpty) &&
          widget.analysisData!['text'] != null) {
        String fullText = widget.analysisData!['text'].toString();
        List<String> lines = fullText.split('\n');

        for (String line in lines) {
          line = line.trim();

          // Look for date patterns
          if (line.contains(RegExp(r'\d{2}[/]\d{2,4}'))) {
            RegExp datePattern = RegExp(r'\d{2}[/]\d{2,4}');
            Match? match = datePattern.firstMatch(line);
            if (match != null) {
              String date = match.group(0)!;

              if (expiryDate.isEmpty &&
                  (line.toLowerCase().contains('exp') ||
                      line.toLowerCase().contains('use before') ||
                      line.toLowerCase().contains('expiry'))) {
                expiryDate = date;
                print('Aggressive expiry extraction: "$expiryDate"');
              } else if (mfgDate.isEmpty &&
                  (line.toLowerCase().contains('mfg') ||
                      line.toLowerCase().contains('manufactured') ||
                      line.toLowerCase().contains('date'))) {
                mfgDate = date;
                print('Aggressive mfg extraction: "$mfgDate"');
              } else if (expiryDate.isEmpty) {
                expiryDate = date; // Default to expiry if unsure
                print('Default expiry extraction: "$expiryDate"');
              }
            }
          }
        }
      }

      // Parse and set dates
      if (expiryDate.isNotEmpty) {
        try {
          _expiryDate = _parseDate(expiryDate);
          print('FINAL - Populated expiry date: $_expiryDate');
        } catch (e) {
          print('Failed to parse expiry date: $e');
        }
      }

      if (mfgDate.isNotEmpty) {
        try {
          _manufacturingDate = _parseDate(mfgDate);
          print('FINAL - Populated mfg date: $_manufacturingDate');
        } catch (e) {
          print('Failed to parse mfg date: $e');
        }
      }

      print('=== FORM POPULATION COMPLETE ===');
      print('Final form state:');
      print('  Name: "${_nameController.text}"');
      print('  Brand: "${_brandController.text}"');
      print('  Category: "${_categoryController.text}"');
      print('  Ingredients: "${_ingredientsController.text}"');
      print('  Notes: "${_notesController.text}"');
      print('  Expiry: $_expiryDate');
      print('  Mfg: $_manufacturingDate');
    }
  }

  Map<String, dynamic> _normalizeParsedData(Map<String, dynamic> source) {
    final normalized = <String, dynamic>{};
    normalized.addAll(source);

    if (source['parsed_data'] is Map<String, dynamic>) {
      final outer = Map<String, dynamic>.from(
        source['parsed_data'] as Map<String, dynamic>,
      );
      normalized.addAll(outer);
      if (outer['parsed_data'] is Map<String, dynamic>) {
        normalized.addAll(
          Map<String, dynamic>.from(
            outer['parsed_data'] as Map<String, dynamic>,
          ),
        );
      }
    }

    return normalized;
  }

  List<String> _extractImagePaths(Map<String, dynamic> source) {
    final raw = source['image_paths'];
    if (raw is List) {
      return raw
          .map((item) => item.toString())
          .where((path) => path.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  String _extractQuantityFromText(String text) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?\s?(?:ml|l|g|kg|mg|mcg|oz|lb|pcs|pieces|tabs|tablets|capsules))',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim() ?? '';
  }

  String _extractIngredientsFromText(String text) {
    final patterns = [
      RegExp(
        r'(?:ingredients|ingredient|composition)[:\s]+([^\n]+)',
        caseSensitive: false,
      ),
      RegExp(r'(?:contains)[:\s]+([^\n]+)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null && match.groupCount >= 1) {
        return match.group(1)!.trim();
      }
    }
    return '';
  }

  DateTime? _parseDate(String dateString) {
    try {
      final normalized = dateString
          .trim()
          .replaceAll('.', '/')
          .replaceAll('-', '/');

      if (normalized.contains('/')) {
        final parts = normalized.split('/');

        if (parts.length == 2) {
          final month = int.parse(parts[0]);
          int year = int.parse(parts[1]);

          // Expand 2-digit year: 00-49 → 2000-2049, 50-99 → 1950-1999
          if (year < 100) {
            year = year < 50 ? 2000 + year : 1900 + year;
          }

          return DateTime(year, month, 1);
        }

        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          int year = int.parse(parts[2]);

          // Expand 2-digit year
          if (year < 100) {
            year = year < 50 ? 2000 + year : 1900 + year;
          }

          return DateTime(year, month, day);
        }
      }

      // Handle YYYY-MM-DD format (ISO)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateString.trim())) {
        return DateTime.parse(dateString.trim());
      }

      return DateTime.parse(normalized);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _ingredientsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Produc...'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          TextButton(onPressed: _saveProduct, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Multiple Images Upload Section
              _buildMultiImageSection(),

              const SizedBox(height: 24),

              // Required Fields Section
              _buildSectionTitle('Required Information'),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'e.g., Parle-G Biscuits',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _brandController,
                label: 'Brand',
                hint: 'e.g., Parle',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter brand';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _categoryController,
                label: 'Category',
                hint: 'e.g., Food, Beverages, Personal Care',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter category';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _quantityController,
                label: 'Quantity / Net Weight',
                hint: 'e.g., 500g, 1L, 10 pieces',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              _buildDateSelector(
                label: 'Expiry Date',
                date: _expiryDate,
                onTap: () => _selectDate(true),
              ),

              const SizedBox(height: 16),
              _buildDateSelector(
                label: 'Manufacturing Date',
                date: _manufacturingDate,
                onTap: () => _selectDate(false),
              ),

              const SizedBox(height: 32),

              // Optional Fields Section
              _buildSectionTitle('Additional Information'),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _ingredientsController,
                label: 'Ingredients',
                hint: 'e.g., Wheat flour, sugar, edible oil',
                maxLines: 3,
                validator: null, // Optional field
              ),

              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _notesController,
                label: 'Notes',
                hint: 'Any additional information',
                maxLines: 3,
                validator: null, // Optional field
              ),

              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Product'),
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
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildMultiImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Images',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount:
                    _selectedImages.length +
                    (_selectedImages.length < 5 ? 1 : 0),
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index < _selectedImages.length) {
                    final image = _selectedImages[index];
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(image, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedImages.removeAt(index)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
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
                    );
                  }

                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _showImageSourceDialog,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 32, color: Colors.grey),
                            SizedBox(height: 4),
                            Text(
                              'Add More',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedImages.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Add Images'),
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
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date!)
                        : 'Select date',
                    style: TextStyle(
                      color: date != null
                          ? Colors.black87
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Image'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
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

      if (pickedFile != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _selectDate(bool isExpiryDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isExpiryDate
          ? (_expiryDate ?? DateTime.now().add(const Duration(days: 30)))
          : (_manufacturingDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: isExpiryDate
          ? DateTime.now().add(const Duration(days: 3650))
          : DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isExpiryDate) {
          _expiryDate = picked;
        } else {
          _manufacturingDate = picked;
        }
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product image')),
      );
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
      // Save product using existing repository
      final productInfo = ProductInfo(
        name: _nameController.text.trim(),
        brand: _brandController.text.trim().isEmpty
            ? null
            : _brandController.text.trim(),
        category: _categoryController.text.trim().isEmpty
            ? null
            : _categoryController.text.trim(),
        quantity: _quantityController.text.trim().isEmpty
            ? null
            : _quantityController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
        warnings: _notesController.text.trim(),
        expiryDate: _expiryDate!,
        mfgDate: _manufacturingDate,
        imageUrl: _selectedImages.isNotEmpty
            ? _selectedImages.first.path
            : null,
        source: 'manual_entry',
      );

      await _repository!.addProduct(productInfo);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
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
