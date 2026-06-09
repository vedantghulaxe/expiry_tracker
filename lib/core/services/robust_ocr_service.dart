import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'connectivity_service.dart';
import 'logger_service.dart';
import 'ai_service.dart';
import 'package:expiry_tracker_app/services/tesseract_ocr_service.dart';

/// Robust OCR Service with Online/Offline Pipeline
/// Implements the exact flow specified in requirements
class RobustOCRService {
  static const int _maxImages = 5;
  static const int _minTextLength = 10;

  /// Main OCR Pipeline - Implements the exact flow specified
  static Future<OCRResult> extractTextFromImages(List<File> images) async {
    try {
      LoggerService.start(
        'ROBUST_OCR',
        'Starting OCR pipeline with ${images.length} images',
      );

      // Validate input
      if (images.isEmpty) {
        return _createFallbackResult('No images provided');
      }

      // Limit images to prevent performance issues
      final limitedImages = images.take(_maxImages).toList();
      if (limitedImages.length < images.length) {
        LoggerService.warning(
          'ROBUST_OCR',
          'Limited to ${limitedImages.length} images (max: $_maxImages)',
        );
      }

      // STEP 1: Check Internet Connectivity
      final hasInternet = await _checkInternetConnectivity();
      LoggerService.info('ROBUST_OCR', 'Internet available: $hasInternet');

      if (hasInternet) {
        // STEP 2: ONLINE OCR (PRIMARY METHOD)
        final onlineResult = await _performOnlineOCR(limitedImages);
        if (onlineResult.isValid) {
          LoggerService.success('ROBUST_OCR', 'Online OCR successful');
          return onlineResult;
        }
        LoggerService.warning(
          'ROBUST_OCR',
          'Online OCR failed, falling back to offline',
        );
      }

      // STEP 3: OFFLINE OCR (FALLBACK)
      final offlineResult = await _performOfflineOCR(limitedImages);
      if (offlineResult.isValid) {
        LoggerService.success('ROBUST_OCR', 'Offline OCR successful');
        return offlineResult;
      }

      // STEP 4: FINAL FALLBACK
      LoggerService.warning(
        'ROBUST_OCR',
        'All OCR methods failed, using fallback',
      );
      return _createFallbackResult(
        'No readable text found. Try clearer image.',
      );
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'OCR pipeline failed: $e');
      return _createFallbackResult('OCR processing failed. Please try again.');
    }
  }

  /// STEP 1: Check Internet Connectivity
  static Future<bool> _checkInternetConnectivity() async {
    try {
      final connectivity = ConnectivityService();
      await connectivity.initialize();

      // Additional check - try to reach a reliable endpoint
      if (connectivity.isConnected) {
        final response = await http
            .get(Uri.parse('https://www.google.com'))
            .timeout(Duration(seconds: 3));
        return response.statusCode == 200;
      }

      return false;
    } catch (e) {
      LoggerService.warning('ROBUST_OCR', 'Connectivity check failed: $e');
      return false;
    }
  }

  /// STEP 2: ONLINE OCR (PRIMARY METHOD)
  /// Uses ML Kit + AI for text cleaning and date extraction ONLY
  static Future<OCRResult> _performOnlineOCR(List<File> images) async {
    try {
      LoggerService.info(
        'ROBUST_OCR',
        'Starting online OCR: ML Kit + AI (text cleaning & dates only)',
      );

      // STEP 1: Extract raw text using ML Kit (reliable OCR)
      final allTexts = <String>[];
      for (final image in images) {
        final text = await _extractTextWithMLKit(image);
        if (text.isNotEmpty) {
          allTexts.add(text);
        }
      }

      final rawText = _combineAndCleanText(allTexts);
      
      if (rawText.isEmpty || rawText.length < 10) {
        return OCRResult(
          success: false,
          text: '',
          confidence: 0.0,
          method: 'mlkit',
          imageCount: images.length,
          warning: 'No text extracted from images',
        );
      }

      LoggerService.info('ROBUST_OCR', 'ML Kit extracted ${rawText.length} characters');
      print('=== RAW ML KIT TEXT ===');
      print(rawText);
      print('======================');

      // STEP 2: Use AI ONLY to clean text and extract dates
      final cleanedData = await _cleanTextAndExtractDates(rawText, images[0]);

      if (cleanedData.isEmpty || cleanedData['raw_text']?.toString().isEmpty == true) {
        // Fallback: return raw text without AI cleaning
        return OCRResult(
          success: true,
          text: rawText,
          confidence: 0.75,
          method: 'mlkit',
          imageCount: images.length,
          warning: 'AI cleaning failed, using raw OCR',
        );
      }

      // Use cleaned text and extracted dates
      final cleanedText = cleanedData['raw_text']?.toString() ?? rawText;
      final jsonString = jsonEncode(cleanedData);

      return OCRResult(
        success: true,
        text: cleanedText,
        jsonData: jsonString,
        confidence: 0.85, // Higher confidence with AI cleaning
        method: 'online',
        imageCount: images.length,
        warning: null,
      );
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'Online OCR failed: $e');
      return OCRResult(
        success: false,
        text: '',
        confidence: 0.0,
        method: 'mlkit',
        imageCount: images.length,
        warning: 'Online OCR error: ${e.toString()}',
      );
    }
  }

  /// Clean text and extract dates using AI (ONLY dates, nothing else)
  static Future<Map<String, dynamic>> _cleanTextAndExtractDates(
    String rawText,
    File image,
  ) async {
    try {
      final aiService = AIService();

      LoggerService.info(
        'ROBUST_OCR',
        'Using AI to clean text and extract dates ONLY',
      );

      // Use AI service with raw text
      final result = await aiService
          .extractStructuredData(
            imagePath: image.path,
            rawText: rawText,
          )
          .timeout(const Duration(seconds: 30));

      // Return only cleaned text and dates
      return {
        'raw_text': result['raw_text']?.toString() ?? rawText,
        'expiry': result['expiry']?.toString() ?? '',
        'mfg_date': result['mfg_date']?.toString() ?? '',
      };
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'AI cleaning failed: $e');
      return {};
    }
  }

  /// Clean and structure raw OCR text using AI
  static Future<Map<String, dynamic>> _cleanAndStructureWithAI(
    String rawText,
    File image,
  ) async {
    try {
      final aiService = AIService();

      LoggerService.info(
        'ROBUST_OCR',
        'Using AI to clean and structure OCR text',
      );

      // Use AI service with raw text as hint
      final result = await aiService
          .extractStructuredData(
            imagePath: image.path,
            rawText: rawText,
          )
          .timeout(const Duration(seconds: 30));

      // Build structured data
      final structuredData = <String, dynamic>{
        'name': result['name']?.toString() ?? '',
        'expiry_date': result['expiry']?.toString() ?? '',
        'mfg_date': result['mfg_date']?.toString() ?? '',
        'category': '',
        'ingredients': result['ingredients']?.toString() ?? '',
        'manufacturer': result['manufacturer']?.toString() ?? '',
        'brand': result['brand']?.toString() ?? '',
        'mrp': result['mrp']?.toString() ?? '',
        'batch': result['batch']?.toString() ?? '',
        'raw_text': result['raw_text']?.toString() ?? rawText, // Use AI-extracted text if available
      };

      // Extract from extraData if available
      if (result['extraData'] != null && result['extraData'].toString() != '{}') {
        try {
          final extraData = jsonDecode(result['extraData'].toString());
          if (extraData is Map) {
            structuredData['category'] = extraData['category']?.toString() ?? '';
            structuredData['dosage'] = extraData['dosage']?.toString() ?? '';
            structuredData['warnings'] = extraData['warnings']?.toString() ?? '';
            structuredData['uses'] = extraData['uses']?.toString() ?? '';
          }
        } catch (e) {
          LoggerService.warning('ROBUST_OCR', 'Failed to parse extraData: $e');
        }
      }

      // Calculate confidence based on filled fields
      final totalFields = 9;
      final filledFields = structuredData.values
          .where((v) => v != null && v.toString().isNotEmpty && v != rawText)
          .length;
      final confidenceValue = filledFields / totalFields;
      structuredData['confidence'] = confidenceValue;

      LoggerService.success(
        'ROBUST_OCR',
        'AI cleaning successful. Confidence: ${structuredData['confidence']}',
      );
      
      print('=== AI CLEANED DATA ===');
      print('Name: ${structuredData['name']}');
      print('Expiry: ${structuredData['expiry_date']}');
      print('Brand: ${structuredData['brand']}');
      print('Confidence: ${structuredData['confidence']}');
      print('======================');

      return structuredData;
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'AI cleaning failed: $e');
      return {};
    }
  }

  /// STEP 3: OFFLINE OCR (FALLBACK)
  static Future<OCRResult> _performOfflineOCR(List<File> images) async {
    try {
      LoggerService.info('ROBUST_OCR', 'Starting offline OCR processing');

      // Try Google ML Kit first
      final mlKitResult = await _performMLKitOCR(images);
      if (mlKitResult.isValid) {
        return mlKitResult;
      }

      // Try Tesseract as second fallback
      final tesseractResult = await _performTesseractOCR(images);
      if (tesseractResult.isValid) {
        return tesseractResult;
      }

      return OCRResult(
        success: false,
        text: '',
        confidence: 0.0,
        method: 'offline',
        imageCount: images.length,
        warning: 'All offline OCR methods failed',
      );
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'Offline OCR failed: $e');
      return OCRResult(
        success: false,
        text: '',
        confidence: 0.0,
        method: 'offline',
        imageCount: images.length,
        warning: 'Offline OCR error: ${e.toString()}',
      );
    }
  }

  /// Google ML Kit OCR (FIRST priority in offline)
  static Future<OCRResult> _performMLKitOCR(List<File> images) async {
    try {
      LoggerService.info('ROBUST_OCR', 'Trying Google ML Kit OCR');

      final allTexts = <String>[];

      for (final image in images) {
        final text = await _extractTextWithMLKit(image);
        if (text.isNotEmpty) {
          allTexts.add(text);
        }
      }

      final combinedText = _combineAndCleanText(allTexts);

      if (combinedText.length >= _minTextLength) {
        return OCRResult(
          success: true,
          text: combinedText,
          confidence: 0.75, // Medium confidence for ML Kit
          method: 'mlkit',
          imageCount: images.length,
          warning: null,
        );
      }

      return OCRResult(
        success: false,
        text: combinedText,
        confidence: 0.0,
        method: 'mlkit',
        imageCount: images.length,
        warning: 'ML Kit returned insufficient text',
      );
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'ML Kit OCR failed: $e');
      return OCRResult(
        success: false,
        text: '',
        confidence: 0.0,
        method: 'mlkit',
        imageCount: images.length,
        warning: 'ML Kit error: ${e.toString()}',
      );
    }
  }

  /// Extract text using Google ML Kit
  static Future<String> _extractTextWithMLKit(File image) async {
    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      await textRecognizer.close();

      // Extract all text blocks with better formatting
      final StringBuffer buffer = StringBuffer();
      
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          buffer.writeln(line.text);
        }
      }

      final extractedText = buffer.toString().trim();
      
      print('=== ML KIT EXTRACTION ===');
      print('Extracted ${extractedText.length} characters');
      print('Text: $extractedText');
      print('========================');

      return extractedText;
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'ML Kit extraction failed: $e');
      return '';
    }
  }

  /// Tesseract OCR (SECOND priority in offline)
  static Future<OCRResult> _performTesseractOCR(List<File> images) async {
    try {
      LoggerService.info('ROBUST_OCR', 'Trying Tesseract OCR');

      final allTexts = <String>[];

      for (final image in images) {
        final text = await _extractTextWithTesseract(image);
        if (text.isNotEmpty) {
          allTexts.add(text);
        }
      }

      final combinedText = _combineAndCleanText(allTexts);

      if (combinedText.length >= _minTextLength) {
        return OCRResult(
          success: true,
          text: combinedText,
          confidence: 0.65, // Lower confidence for Tesseract
          method: 'tesseract',
          imageCount: images.length,
          warning: null,
        );
      }

      return OCRResult(
        success: false,
        text: combinedText,
        confidence: 0.0,
        method: 'tesseract',
        imageCount: images.length,
        warning: 'Tesseract returned insufficient text',
      );
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'Tesseract OCR failed: $e');
      return OCRResult(
        success: false,
        text: '',
        confidence: 0.0,
        method: 'tesseract',
        imageCount: images.length,
        warning: 'Tesseract error: ${e.toString()}',
      );
    }
  }

  /// Extract text using Tesseract
  static Future<String> _extractTextWithTesseract(File image) async {
    try {
      if (kIsWeb) {
        LoggerService.warning('ROBUST_OCR', 'Tesseract not available on web');
        return '';
      }

      // Use project-local Tesseract wrapper (safe even when engine unavailable)
      final extractedText = await TesseractOCRService.extractTextFromImage(
        image,
      );

      return extractedText;
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'Tesseract extraction failed: $e');
      return '';
    }
  }

  /// Format structured data as readable text
  static String _formatStructuredDataAsText(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    if (data['name'].toString().isNotEmpty) {
      buffer.writeln('Name: ${data['name']}');
    }
    if (data['manufacturer'].toString().isNotEmpty) {
      buffer.writeln('Manufacturer: ${data['manufacturer']}');
    }
    if (data['expiry_date'].toString().isNotEmpty) {
      buffer.writeln('Expiry Date: ${data['expiry_date']}');
    }
    if (data['mfg_date'].toString().isNotEmpty) {
      buffer.writeln('Manufacturing Date: ${data['mfg_date']}');
    }
    if (data['category'].toString().isNotEmpty) {
      buffer.writeln('Category: ${data['category']}');
    }
    if (data['mrp'].toString().isNotEmpty) {
      buffer.writeln('MRP: ${data['mrp']}');
    }
    if (data['batch'].toString().isNotEmpty) {
      buffer.writeln('Batch: ${data['batch']}');
    }

    return buffer.toString().trim();
  }

  /// Combine and clean text from multiple images (for offline OCR)
  static String _combineAndCleanText(List<String> texts) {
    if (texts.isEmpty) return '';

    // Combine all texts
    final combined = texts.join('\n\n');

    // Clean up common OCR errors
    String cleaned = combined
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .replaceAll(RegExp(r'[\r\n]+'), '\n') // Normalize line breaks
        .trim();

    // Remove duplicates while preserving order
    final lines = cleaned.split('\n');
    final seenLines = <String>{};
    final uniqueLines = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && !seenLines.contains(trimmedLine)) {
        seenLines.add(trimmedLine);
        uniqueLines.add(trimmedLine);
      }
    }

    final result = uniqueLines.join('\n');
    
    print('=== TEXT CLEANING ===');
    print('Input texts: ${texts.length}');
    print('Combined length: ${combined.length}');
    print('Cleaned length: ${result.length}');
    print('Unique lines: ${uniqueLines.length}');
    print('====================');

    return result;
  }

  /// STEP 4: FINAL FALLBACK - Never return empty result
  static OCRResult _createFallbackResult(String message) {
    return OCRResult(
      success: true, // Always true to prevent UI freezing
      text: message,
      confidence: 0.0,
      method: 'fallback',
      imageCount: 0,
      warning: 'Using fallback message',
    );
  }
}

/// OCR Result Structure - Standardized as specified
class OCRResult {
  final bool success;
  final String text;
  final String? jsonData; // Structured JSON data for online OCR
  final double confidence;
  final String method; // 'online', 'mlkit', 'tesseract', 'fallback'
  final int imageCount;
  final String? warning;

  OCRResult({
    required this.success,
    required this.text,
    this.jsonData,
    required this.confidence,
    required this.method,
    required this.imageCount,
    this.warning,
  });

  /// Check if result is valid (has meaningful text)
  bool get isValid => success && text.length >= 10;

  /// Check if result has structured JSON data
  bool get hasStructuredData => jsonData != null && jsonData!.isNotEmpty;

  /// Get confidence percentage for UI display
  String get confidencePercentage => '${(confidence * 100).toInt()}%';

  /// Get method display name
  String get methodDisplayName {
    switch (method) {
      case 'online':
        return 'AI (Online)';
      case 'mlkit':
        return 'ML Kit (Offline)';
      case 'tesseract':
        return 'Tesseract (Offline)';
      case 'fallback':
        return 'Fallback';
      default:
        return 'Unknown';
    }
  }

  /// Get preview text (first 5 lines)
  String get previewText {
    final lines = text.split('\n');
    final previewLines = lines.take(5).toList();
    return previewLines.join('\n');
  }

  /// Check if confidence is low
  bool get isLowConfidence => confidence < 0.5;

  /// Get parsed structured data if available
  Map<String, dynamic>? get structuredData {
    if (jsonData == null || jsonData!.isEmpty) return null;
    try {
      return jsonDecode(jsonData!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'text': text,
      'jsonData': jsonData,
      'confidence': confidence,
      'method': method,
      'imageCount': imageCount,
      'warning': warning,
    };
  }

  @override
  String toString() {
    return 'OCRResult(method: $method, confidence: $confidencePercentage, length: ${text.length}, hasJson: $hasStructuredData)';
  }
}
