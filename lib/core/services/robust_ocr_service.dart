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
  static Future<OCRResult> _performOnlineOCR(List<File> images) async {
    try {
      LoggerService.info(
        'ROBUST_OCR',
        'Starting online OCR processing with Oxlo.ai APIs',
      );

      // Process images and extract structured data
      final allStructuredData = <Map<String, dynamic>>[];

      for (final image in images) {
        final structuredData = await _extractStructuredDataWithGemini(image);
        if (structuredData.isNotEmpty &&
            (structuredData['name'].toString().isNotEmpty ||
                structuredData['expiry_date'].toString().isNotEmpty)) {
          allStructuredData.add(structuredData);
        }
      }

      if (allStructuredData.isEmpty) {
        return OCRResult(
          success: false,
          text: '',
          confidence: 0.0,
          method: 'online',
          imageCount: images.length,
          warning: 'Online OCR returned no structured data',
        );
      }

      // Combine data from multiple images (use the one with highest confidence)
      final bestResult = allStructuredData.reduce(
        (a, b) => (a['confidence'] as num) > (b['confidence'] as num) ? a : b,
      );

      // Convert to JSON string for storage/transmission
      final jsonString = jsonEncode(bestResult);

      // Create a readable text representation
      final textRepresentation = _formatStructuredDataAsText(bestResult);

      final confidence = bestResult['confidence'] as num;

      // Warn if confidence is low
      String? warning;
      if (confidence < 0.5) {
        warning =
            'Low confidence extraction. Please verify the extracted information.';
      }

      return OCRResult(
        success: true,
        text: textRepresentation,
        jsonData: jsonString,
        confidence: confidence.toDouble(),
        method: 'online',
        imageCount: images.length,
        warning: warning,
      );
    } catch (e) {
      LoggerService.error('ROBUST_OCR', 'Online OCR failed: $e');
      return OCRResult(
        success: false,
        text: '',
        confidence: 0.0,
        method: 'online',
        imageCount: images.length,
        warning: 'Online OCR error: ${e.toString()}',
      );
    }
  }

  /// Extract structured data using Oxlo.ai via AIService
  /// Returns properly formatted JSON with required fields: name, expiry_date, mfg_date, category
  static Future<Map<String, dynamic>> _extractStructuredDataWithGemini(
    File image,
  ) async {
    try {
      final aiService = AIService();

      LoggerService.info(
        'ROBUST_OCR',
        'Calling Oxlo.ai for structured extraction',
      );

      // Use structured data extraction from AIService
      final result = await aiService
          .extractStructuredData(imagePath: image.path)
          .timeout(const Duration(seconds: 30));

      // Map AIService result to required structure
      final structuredData = {
        'name': result['name']?.toString() ?? '',
        'expiry_date': result['expiry']?.toString() ?? '',
        'mfg_date':
            result['mfg_date']?.toString() ?? '', // now a top-level field
        'category': '', // will be inferred below
        'ingredients': result['ingredients']?.toString() ?? '',
        'manufacturer': result['manufacturer']?.toString() ?? '',
        'mrp': result['mrp']?.toString() ?? '',
        'batch': result['batch']?.toString() ?? '',
        'raw_data': result,
      };

      // Try to extract mfg_date, category and ingredients from extraData if available
      if (result['extraData'] != null &&
          result['extraData'].toString() != '{}') {
        try {
          final extraData = jsonDecode(result['extraData'].toString());
          if (extraData is Map) {
            // Manufacturing date
            final mfgRaw =
                extraData['manufacturing_date']?.toString() ??
                extraData['mfg_date']?.toString() ??
                extraData['mfd']?.toString() ??
                extraData['manufactured_date']?.toString() ??
                '';
            if (mfgRaw.isNotEmpty) structuredData['mfg_date'] = mfgRaw;

            // Category
            final catRaw = extraData['category']?.toString() ?? '';
            if (catRaw.isNotEmpty) structuredData['category'] = catRaw;

            // Ingredients / composition
            final ingRaw =
                extraData['ingredients']?.toString() ??
                extraData['composition']?.toString() ??
                extraData['contents']?.toString() ??
                '';
            if (ingRaw.isNotEmpty) structuredData['ingredients'] = ingRaw;
          }
        } catch (e) {
          LoggerService.warning('ROBUST_OCR', 'Failed to parse extraData: $e');
        }
      }

      // Infer category from content
      if (structuredData['category'].toString().isEmpty) {
        final raw = jsonEncode(result).toLowerCase();
        if (raw.contains('tablet') ||
            raw.contains('capsule') ||
            raw.contains('medicine') ||
            raw.contains('pharma') ||
            raw.contains('dosage')) {
          structuredData['category'] = 'medicine';
        } else {
          structuredData['category'] = 'product';
        }
      }

      // Calculate confidence based on filled fields
      final totalFields = 9;
      final filledFields = structuredData.values.where((v) => v != null && v.toString().isNotEmpty).length;
      structuredData['confidence'] = filledFields / totalFields;

      LoggerService.info('ROBUST_OCR', 'AI extracted: name="${structuredData['name']}", expiry="${structuredData['expiry_date']}", brand="${structuredData['brand']}"');

      LoggerService.success(
        'ROBUST_OCR',
        'Oxlo.ai extraction successful. Confidence: ${structuredData['confidence']}',
      );
      return structuredData;
    } catch (e) {
      LoggerService.error(
        'ROBUST_OCR',
        'Oxlo.ai extraction failed or timed out: $e',
      );
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

      return recognizedText.text;
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
    final combined = texts.join('\n');

    // Remove duplicates while preserving order
    final lines = combined.split('\n');
    final seenLines = <String>{};
    final uniqueLines = <String>[];

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty && !seenLines.contains(trimmedLine)) {
        seenLines.add(trimmedLine);
        uniqueLines.add(trimmedLine);
      }
    }

    return uniqueLines.join('\n');
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
