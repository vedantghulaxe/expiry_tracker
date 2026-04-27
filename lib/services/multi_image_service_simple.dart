import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';
import 'package:expiry_tracker_app/core/services/robust_ocr_service.dart'
    as robust;
import 'package:expiry_tracker_app/core/services/local_parser_service.dart';
import 'package:expiry_tracker_app/core/services/product_api_service.dart';
import 'package:expiry_tracker_app/core/services/image_validation_service.dart';

/// Clean Multi-Image Service with Robust OCR Pipeline
class MultiImageServiceSimple {
  static final List<File> _capturedImages = [];
  static bool _isProcessing = false;

  /// Capture multiple images
  static Future<List<File>> captureMultipleImages() async {
    try {
      LoggerService.start('MULTI_IMAGE', 'Starting multi-image capture');

      final List<File> images = [];
      final ImagePicker picker = ImagePicker();

      // Allow up to 5 images
      for (int i = 0; i < 5; i++) {
        final XFile? image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );

        if (image == null) break;

        final file = File(image.path);
        images.add(file);

        // Ask user if they want to capture more
        if (i < 4) {
          // For simplicity, just continue to next image
          // In production, you might want to show a dialog
        }
      }

      _capturedImages.addAll(images);

      LoggerService.success('MULTI_IMAGE', 'Captured ${images.length} images');
      return images;
    } catch (e) {
      LoggerService.error('MULTI_IMAGE', 'Failed to capture images: $e');
      return [];
    }
  }

  /// Process images with robust OCR pipeline - FIXED VERSION
  static Future<Map<String, dynamic>> processMultipleImages(
    List<File> images,
  ) async {
    if (_isProcessing) {
      LoggerService.warning('MULTI_IMAGE', 'Processing already in progress');
      return _createProcessingInProgressResult();
    }
    _isProcessing = true;

    try {
      LoggerService.start(
        'MULTI_IMAGE',
        'Starting robust OCR pipeline with ${images.length} images',
      );

      // Validate input
      if (images.isEmpty) {
        LoggerService.warning('MULTI_IMAGE', 'No images provided');
        return _createManualEntryRequired();
      }

      // STEP 0: PRE-VALIDATION - Check if images contain product labels
      LoggerService.info(
        'MULTI_IMAGE',
        'Performing pre-validation on ${images.length} images',
      );
      final validationResults = <ImageValidationResult>[];

      for (final image in images) {
        final validation = await ImageValidationService.validateProductLabel(
          image,
        );
        validationResults.add(validation);

        if (!validation.isValid) {
          LoggerService.warning(
            'MULTI_IMAGE',
            'Image validation failed: ${validation.errorMessage}',
          );
        } else {
          LoggerService.info(
            'MULTI_IMAGE',
            'Image validation passed with confidence: ${validation.confidence?.toStringAsFixed(2)}',
          );
        }
      }

      // Check if any images passed validation
      var validImages = images.where((image) {
        final index = images.indexOf(image);
        return validationResults[index].isValid;
      }).toList();

      if (validImages.isEmpty) {
        LoggerService.warning(
          'MULTI_IMAGE',
          'No images passed validation - continuing OCR with original images',
        );
        validImages = images;
      }

      LoggerService.success(
        'MULTI_IMAGE',
        '${validImages.length} out of ${images.length} images passed validation',
      );

      // STEP 1: ROBUST OCR PIPELINE
      // Online => Gemini (when internet available)
      // Offline => Tesseract/ML Kit fallback
      final ocrResult = await robust.RobustOCRService.extractTextFromImages(
        validImages,
      );

      LoggerService.info(
        'MULTI_IMAGE',
        'OCR completed: ${ocrResult.toString()}',
      );

      // STEP 2: LOCAL PARSING (ALWAYS RUN)
      final parsedWrapper = LocalParserService.parseText(ocrResult.text);
      final parsedData = Map<String, dynamic>.from(
        parsedWrapper['parsed_data'] as Map<String, dynamic>? ?? {},
      );

      // Merge structured Gemini output when available.
      if (ocrResult.structuredData != null) {
        final structured = ocrResult.structuredData!;
        parsedData['name'] = _firstNonEmpty([
          structured['name']?.toString(),
          parsedData['name']?.toString(),
        ]);
        parsedData['expiryDate'] = _firstNonEmpty([
          structured['expiry_date']?.toString(),
          structured['expiryDate']?.toString(),
          parsedData['expiryDate']?.toString(),
        ]);
        parsedData['mfgDate'] = _firstNonEmpty([
          structured['mfg_date']?.toString(),
          structured['mfgDate']?.toString(),
          parsedData['mfgDate']?.toString(),
        ]);
        parsedData['category'] = _firstNonEmpty([
          structured['category']?.toString(),
          parsedData['category']?.toString(),
        ]);
        parsedData['ingredients'] = _firstNonEmpty([
          structured['ingredients']?.toString(),
          parsedData['ingredients']?.toString(),
        ]);
        // Also capture manufacturer as brand if brand is empty
        parsedData['brand'] = _firstNonEmpty([
          structured['manufacturer']?.toString(),
          parsedData['brand']?.toString(),
        ]);
      }

      // Ensure essential fields
      parsedData['rawText'] = ocrResult.text;
      parsedData['ocrMethod'] = ocrResult.method;
      parsedData['ocrConfidence'] = ocrResult.confidence;
      parsedData['ocrWarning'] = ocrResult.warning;

      if (parsedData['confidence'] == null) {
        parsedData['confidence'] = ocrResult.confidence;
      }

      // STEP 3: VALIDATE OCR QUALITY
      final isValidOCR = _validateOCRResult(ocrResult, parsedData);

      // STEP 4: BUILD RESULT
      var result = {
        'success': isValidOCR,
        'parsed_data': parsedData,
        'text': ocrResult.text,
        'raw_text': ocrResult.text,
        'image_count': validImages.length,
        'processing_method': 'robust_ocr',
        'ocr_method': ocrResult.method,
        'ocr_confidence': ocrResult.confidence,
        'confidence': parsedData['confidence'] ?? ocrResult.confidence,
        'enhanced': ocrResult.method == 'online',
        'ai_used': ocrResult.method == 'online',
        'warning': ocrResult.warning,
        'is_low_confidence': ocrResult.isLowConfidence,
      };

      // API-ENHANCEMENT: Try to enhance with API data
      print('=== API ENHANCEMENT START ===');
      String? barcode = _extractBarcodeFromText(ocrResult.text);

      Map<String, dynamic> apiEnhancedResult =
          await ProductApiService.enhanceOCRWithAPI(result, barcode);

      if (apiEnhancedResult['api_enhanced'] == true) {
        print('=== API ENHANCEMENT SUCCESS ===');
        print('API Source: ${apiEnhancedResult['api_source']}');
        result = apiEnhancedResult;
      } else {
        print('=== API ENHANCEMENT FAILED - USING OCR ONLY ===');
      }

      LoggerService.success('MULTI_IMAGE', 'Pipeline completed successfully');
      print('=== === ROBUST OCR + API PIPELINE COMPLETED ===');
      print('=== Method: ${ocrResult.methodDisplayName} ===');
      print('=== Confidence: ${ocrResult.confidencePercentage} ===');
      print('=== Text Length: ${ocrResult.text.length} ===');
      print('=== API Enhanced: ${result['api_enhanced'] ?? false} ===');

      return result;
    } catch (e) {
      LoggerService.error('MULTI_IMAGE', 'Pipeline failed: $e');

      // ALWAYS return a result, never fail completely
      return _createErrorResult(e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  /// Create processing in progress result
  static Map<String, dynamic> _createProcessingInProgressResult() {
    return {
      'success': false,
      'parsed_data': {'name': '', 'confidence': 0.0},
      'text': 'Processing in progress...',
      'raw_text': '',
      'image_count': 0,
      'processing_method': 'processing',
      'ocr_method': 'none',
      'ocr_confidence': 0.0,
      'enhanced': false,
      'ai_used': false,
      'confidence': 0.0,
      'warning': 'Another processing task is in progress',
      'is_low_confidence': true,
    };
  }

  /// Create manual entry required result
  static Map<String, dynamic> _createManualEntryRequired() {
    return {
      'success': false,
      'parsed_data': {'name': '', 'confidence': 0.0},
      'text': 'No images provided',
      'raw_text': '',
      'image_count': 0,
      'processing_method': 'manual_entry',
      'ocr_method': 'none',
      'ocr_confidence': 0.0,
      'enhanced': false,
      'ai_used': false,
      'confidence': 0.0,
      'warning': 'Please capture images first',
      'is_low_confidence': true,
      'allow_manual_entry': true,
    };
  }

  /// Create invalid image result
  static Map<String, dynamic> _createInvalidImageResult(String reason) {
    return {
      'success': false,
      'parsed_data': {'name': '', 'confidence': 0.0},
      'text': 'Invalid image: $reason',
      'raw_text': '',
      'image_count': 0,
      'processing_method': 'invalid_image',
      'ocr_method': 'none',
      'ocr_confidence': 0.0,
      'enhanced': false,
      'ai_used': false,
      'confidence': 0.0,
      'warning': reason,
      'is_low_confidence': true,
      'allow_manual_entry': true,
    };
  }

  /// Extract barcode from text
  static String? _extractBarcodeFromText(String text) {
    RegExp barcodePattern = RegExp(r'\d{8,13}');
    Match? match = barcodePattern.firstMatch(text);

    if (match != null) {
      String barcode = match.group(0)!;
      print('Found barcode in text: $barcode');
      return barcode;
    }

    return null;
  }

  /// Create no text result
  static Map<String, dynamic> _createNoTextResult(int imageCount) {
    return {
      'success': true,
      'parsed_data': {'name': '', 'confidence': 0.0},
      'text': 'No readable text found. Try clearer image.',
      'raw_text': '',
      'image_count': imageCount,
      'processing_method': 'fallback',
      'ocr_method': 'fallback',
      'ocr_confidence': 0.0,
      'enhanced': false,
      'ai_used': false,
      'confidence': 0.0,
      'warning': 'No text could be extracted from images',
      'is_low_confidence': true,
      'allow_manual_entry': true,
    };
  }

  /// Create error result
  static Map<String, dynamic> _createErrorResult(String error) {
    return {
      'success': false,
      'parsed_data': {},
      'raw_text': '',
      'image_count': 0,
      'processing_method': 'error',
      'enhanced': false,
      'ai_used': false,
      'message':
          'Processing error occurred. Please try again or use manual entry.',
      'error': error,
      'allow_manual_entry': true,
    };
  }

  /// Clear captured images
  static void clearCapturedImages() {
    _capturedImages.clear();
    LoggerService.info('MULTI_IMAGE', 'Cleared captured images');
  }

  /// Get captured images count
  static int get capturedImagesCount => _capturedImages.length;

  /// Get processing status
  static bool get isProcessing => _isProcessing;

  /// Validate OCR result quality
  static bool _validateOCRResult(
    robust.OCRResult ocrResult,
    Map<String, dynamic> parsedData,
  ) {
    // Check OCR confidence
    if (ocrResult.confidence < 0.3) {
      LoggerService.warning(
        'MULTI_IMAGE',
        'OCR confidence too low: ${ocrResult.confidence}',
      );
      return false;
    }

    // Check if text is meaningful
    final text = ocrResult.text.trim();
    if (text.length < 3) {
      LoggerService.warning('MULTI_IMAGE', 'OCR text too short: $text');
      return false;
    }

    // Check for common OCR errors
    final commonErrors = [
      'no text found',
      'image not clear',
      'unable to process',
      'error',
      'failed',
      'null',
      'undefined',
    ];

    if (commonErrors.any((error) => text.toLowerCase().contains(error))) {
      LoggerService.warning('MULTI_IMAGE', 'OCR contains error message: $text');
      return false;
    }

    // Check if parsed data has meaningful content
    final name = parsedData['name']?.toString().trim() ?? '';
    if (name.isEmpty || name.length < 2) {
      LoggerService.warning(
        'MULTI_IMAGE',
        'Parsed name is empty or too short: $name',
      );
      return false;
    }

    // Check for product-specific keywords (relaxed — not required)
    final productKeywords = [
      'expiry',
      'expire',
      'exp',
      'best before',
      'use by',
      'sell by',
      'product',
      'item',
      'brand',
      'ingredients',
      'net wt',
      'weight',
      'manufactured',
      'produced',
      'batch',
      'lot',
      'mfg',
      'mfd',
      'mrp',
      'price',
      'rs',
      'rupees',
    ];

    final textLower = text.toLowerCase();
    final hasProductKeywords = productKeywords.any(
      (keyword) => textLower.contains(keyword),
    );

    if (!hasProductKeywords) {
      LoggerService.warning(
        'MULTI_IMAGE',
        'Text does not contain product-related keywords (non-fatal)',
      );
      // Don't fail — some product labels may not have these keywords
    }

    // Check for dates (product labels usually have dates)
    final datePatterns = [
      RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}'), // DD/MM/YYYY, MM/DD/YYYY, etc.
      RegExp(r'\d{2,4}[/-]\d{1,2}[/-]\d{1,2}'), // YYYY/MM/DD, etc.
      RegExp(
        r'\b\d{1,2}\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{2,4}\b',
        caseSensitive: false,
      ),
    ];

    final hasDates = datePatterns.any((pattern) => pattern.hasMatch(text));
    if (!hasDates) {
      LoggerService.warning(
        'MULTI_IMAGE',
        'Text does not contain recognizable dates',
      );
      // Don't fail completely, but log warning
    }

    // Check if confidence is reasonable
    final confidence = (parsedData['confidence'] as num?)?.toDouble() ?? 0.0;
    if (confidence < 0.2) {
      LoggerService.warning(
        'MULTI_IMAGE',
        'Parsed confidence too low: $confidence',
      );
      return false;
    }

    // Check for garbage data
    if (_isGarbageData(name)) {
      LoggerService.warning('MULTI_IMAGE', 'Detected garbage data: $name');
      return false;
    }

    LoggerService.success('MULTI_IMAGE', 'OCR validation passed');
    return true;
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }

  /// Check if data is garbage
  static bool _isGarbageData(String text) {
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
      'hello',
      'world',
      'test',
      'sample',
      'example',
      'demo',
      'data',
      'text',
      'image',
      'photo',
      'picture',
      'scan',
      'ocr',
      'result',
      'output',
    ];

    final words = text.toLowerCase().split(' ');
    final meaningfulWords = words
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .toList();

    // If less than 2 meaningful words, consider it garbage
    return meaningfulWords.length < 2;
  }
}
