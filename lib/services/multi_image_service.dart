import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/logger_service.dart';
import '../core/services/offline_ocr_service.dart';
import '../core/services/local_parser_service.dart';
import '../core/services/connectivity_service.dart';
import '../models/product_info.dart';
import 'product_api_service.dart';
import 'medicine_api_service.dart';

class MultiImageService {
  static final List<File> _capturedImages = [];
  static bool _isProcessing = false;

  /// Capture multiple images of product/medicine
  static Future<List<File>> captureMultipleImages() async {
    try {
      LoggerService.start('MULTI_IMAGE', 'Starting multi-image capture');
      
      final images = await OfflineOCRService().captureMultipleImages(maxImages: 5);
      
      _capturedImages.clear();
      _capturedImages.addAll(images);
      
      LoggerService.success('MULTI_IMAGE', 'Captured ${images.length} images');
      return images;
    } catch (e) {
      LoggerService.error('MULTI_IMAGE', 'Failed to capture images: $e');
      return [];
    }
  }

  /// Process multiple images with offline-first approach
  static Future<Map<String, dynamic>> processMultipleImages(
    List<File> images
  ) async {
    if (_isProcessing) return _createEmptyResult();
    _isProcessing = true;

    try {
      LoggerService.start('MULTI_IMAGE', 'Processing ${images.length} images');
      
      // Step 1: OCR - Extract text from all images
      final ocrResults = await OfflineOCRService().processMultipleImages(images);
      final combinedText = OfflineOCRService.combineText(ocrResults);
      
      if (combinedText.isEmpty) {
        LoggerService.warning('MULTI_IMAGE', 'No text extracted from images');
        return _createEmptyResult();
      }
      
      // Step 2: Local Parsing - Primary processing (MANDATORY)
      final parsedResult = LocalParserService.parseText(combinedText);
      
      if (!LocalParserService.isValidResult(parsedResult)) {
        LoggerService.warning('MULTI_IMAGE', 'Local parsing confidence too low');
        return _createEmptyResult();
      }
      
      LoggerService.success('MULTI_IMAGE', 'Local parsing completed successfully');
      
      // Step 3: Optional Enhancement - Only if internet available
      Map<String, dynamic> enhancedResult = Map.from(parsedResult);
      
      await ConnectivityService.executeIfConnected(() async {
        try {
          LoggerService.info('MULTI_IMAGE', 'Attempting API enhancement');
          
          // Try barcode-based lookup first
          final barcode = _extractBarcodeFromText(combinedText);
          if (barcode != null) {
            final apiData = await _lookupWithAPI(barcode, parsedResult['category']);
            if (apiData != null) {
              enhancedResult = _mergeData(parsedResult, apiData);
              LoggerService.success('MULTI_IMAGE', 'API enhancement successful');
            }
          }
        } catch (e) {
          LoggerService.warning('MULTI_IMAGE', 'API enhancement failed: $e');
          // Continue with local result
        }
      });
      
      final result = {
        'parsed_data': enhancedResult,
        'raw_text': combinedText,
        'ocr_results': ocrResults,
        'image_count': images.length,
        'processing_method': 'offline_first',
        'enhanced': enhancedResult != parsedResult,
        'success': true,
      };
      
      LoggerService.success('MULTI_IMAGE', 'Processing completed successfully');
      return result;
    } catch (e) {
      LoggerService.error('MULTI_IMAGE', 'Processing failed: $e');
      return _createEmptyResult();
    } finally {
      _isProcessing = false;
    }
  }

  /// Extract text from multiple images (legacy method)
  static Future<Map<String, dynamic>> extractTextFromMultipleImages(
    List<File> images
  ) async {
    return await processMultipleImages(images);
  }

  /// Extract barcode from text using regex patterns
  static String? _extractBarcodeFromText(String text) {
    final patterns = [
      RegExp(r'\b(\d{13})\b'), // EAN-13
      RegExp(r'\b(\d{12})\b'), // UPC-A
      RegExp(r'\b(\d{8})\b'),  // EAN-8
      RegExp(r'\b(\d{14})\b'), // ITF-14
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }

  /// Lookup data using APIs based on category
  static Future<Map<String, dynamic>?> _lookupWithAPI(
    String barcode, 
    String category
  ) async {
    try {
      if (category == 'medicine') {
        final medicineInfo = await MedicineApiService.lookupMedicine(barcode);
        return medicineInfo?.toJson();
      } else {
        final productInfo = await ProductApiService.lookupProduct(barcode);
        return productInfo?.toJson();
      }
    } catch (e) {
      LoggerService.error('MULTI_IMAGE', 'API lookup failed: $e');
      return null;
    }
  }

  /// Merge local parsed data with API data
  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> apiData
  ) {
    final merged = Map<String, dynamic>.from(localData);
    
    // Prefer API data for missing or low-confidence fields
    if (apiData['name']?.isNotEmpty == true && 
        (localData['name']?.isEmpty == true || localData['confidence'] < 70)) {
      merged['name'] = apiData['name'];
    }
    
    if (apiData['brand']?.isNotEmpty == true && localData['brand']?.isEmpty == true) {
      merged['brand'] = apiData['brand'];
    }
    
    if (apiData['category']?.isNotEmpty == true && localData['category'] == 'product') {
      merged['category'] = apiData['category'];
    }
    
    // Add API source information
    merged['api_source'] = apiData['source'];
    merged['enhanced'] = true;
    merged['confidence'] = math.max(localData['confidence'] ?? 0, 85);
    
    return merged;
  }

  /// Create empty result
  static Map<String, dynamic> _createEmptyResult() {
    return {
      'parsed_data': {
        'name': '',
        'expiryDate': null,
        'mfgDate': null,
        'dosage': '',
        'category': 'product',
        'isMedicine': false,
        'confidence': 0,
        'rawText': '',
      },
      'raw_text': '',
      'ocr_results': [],
      'image_count': 0,
      'processing_method': 'offline_first',
      'enhanced': false,
      'success': false,
    };
  }

  /// Get captured images
  static List<File> get capturedImages => List.from(_capturedImages);
  
  /// Clear captured images
  static void clearCapturedImages() {
    _capturedImages.clear();
  }

  /// Check if processing
  static bool get isProcessing => _isProcessing;
}
