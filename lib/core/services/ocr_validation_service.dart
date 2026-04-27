import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tesseract_ocr/tesseract_ocr.dart';
import '../services/logger_service.dart';

/// OCR Validation Service
/// Provides comprehensive image validation before OCR processing
class OCRValidationService {
  static const double _minImageSize = 100 * 1024; // 100KB
  static const double _minConfidence = 0.6;
  static const int _minTextLength = 10;
  static const List<String> _invalidPatterns = [
    'no text found',
    'unable to process',
    'error',
    'failed',
    'null',
    'undefined',
  ];

  /// Validate image before OCR processing
  static Future<OCRValidationResult> validateImage(File imageFile) async {
    LoggerService.info('OCR_VALIDATION', '=== Starting image validation ===');
    
    try {
      // Step 1: Check if file exists
      if (!await imageFile.exists()) {
        LoggerService.error('OCR_VALIDATION', 'Image file does not exist: ${imageFile.path}');
        return OCRValidationResult(
          isValid: false,
          error: 'Image file not found',
          shouldProcess: false,
        );
      }

      // Step 2: Check file size
      final fileSize = await imageFile.length();
      if (fileSize < _minImageSize) {
        LoggerService.warning('OCR_VALIDATION', 'Image too small: ${fileSize} bytes');
        return OCRValidationResult(
          isValid: false,
          error: 'Image too small for reliable OCR',
          shouldProcess: false,
        );
      }

      // Step 3: Check image format
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes!);
      
      if (image == null) {
        LoggerService.error('OCR_VALIDATION', 'Invalid image format');
        return OCRValidationResult(
          isValid: false,
          error: 'Invalid image format',
          shouldProcess: false,
        );
      }

      // Step 4: Analyze image quality
      final qualityAnalysis = _analyzeImageQuality(image!);
      
      if (!qualityAnalysis.isAcceptable) {
        LoggerService.warning('OCR_VALIDATION', 'Image quality too low: ${qualityAnalysis.issues}');
        return OCRValidationResult(
          isValid: false,
          error: 'Image quality too low for OCR',
          shouldProcess: false,
        );
      }

      // Step 5: Check for text-like patterns
      final hasTextPattern = await _checkForTextPatterns(image!);
      
      if (hasTextPattern) {
        LoggerService.warning('OCR_VALIDATION', 'Image appears to contain text, not a product');
        return OCRValidationResult(
          isValid: false,
          error: 'Image appears to be text/screenshot, not a product',
          shouldProcess: false,
        );
      }

      LoggerService.success('OCR_VALIDATION', '=== Image validation passed ===');
      return OCRValidationResult(
        isValid: true,
        confidence: qualityAnalysis.confidence,
        shouldProcess: true,
        analysis: qualityAnalysis,
      );

    } catch (e) {
      LoggerService.error('OCR_VALIDATION', 'Image validation error: $e');
      return OCRValidationResult(
        isValid: false,
        error: 'Validation failed: $e',
        shouldProcess: false,
      );
    }
  }

  /// Analyze image quality
  static ImageQualityAnalysis _analyzeImageQuality(img.Image image) {
    final issues = <String>[];
    double confidence = 0.8; // Base confidence

    // Check brightness
    final brightness = _calculateBrightness(image);
    if (brightness < 0.2 || brightness > 0.8) {
      issues.add('Poor brightness');
      confidence -= 0.2;
    }

    // Check contrast
    final contrast = _calculateContrast(image);
    if (contrast < 0.3) {
      issues.add('Low contrast');
      confidence -= 0.1;
    }

    // Check blur detection
    final isBlurry = _detectBlur(image);
    if (isBlurry) {
      issues.add('Image appears blurry');
      confidence -= 0.3;
    }

    // Check for noise
    final hasNoise = _detectNoise(image);
    if (hasNoise) {
      issues.add('Image has noise/artifacts');
      confidence -= 0.2;
    }

    return ImageQualityAnalysis(
      isAcceptable: confidence >= _minConfidence && issues.isEmpty,
      confidence: confidence,
      issues: issues,
    );
  }

  /// Calculate image brightness
  static double _calculateBrightness(img.Image image) {
    double totalBrightness = 0;
    int pixelCount = 0;

    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    return totalBrightness / (pixelCount * 255);
  }

  /// Calculate image contrast
  static double _calculateContrast(img.Image image) {
    double totalBrightness = 0;
    int pixelCount = 0;
    List<int> brightnessValues = [];

    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        brightnessValues.add(brightness.round());
        totalBrightness += brightness;
        pixelCount++;
      }
    }

    if (brightnessValues.isEmpty) return 0.0;

    brightnessValues.sort();
    final median = brightnessValues[brightnessValues.length ~/ 2];
    
    double contrast = 0.0;
    for (final brightness in brightnessValues) {
      contrast += (brightness - median).abs();
    }

    return contrast / brightnessValues.length;
  }

  /// Simple blur detection
  static bool _detectBlur(img.Image image) {
    for (int y = 1; y < image.height - 1; y += 2) {
      for (int x = 1; x < image.width - 1; x += 2) {
        final center = image.getPixel(x, y);
        final surrounding = [
          image.getPixel(x - 1, y),
          image.getPixel(x + 1, y),
          image.getPixel(x, y - 1),
          image.getPixel(x, y + 1),
        ];

        double avgBrightness = 0;
        for (final p in surrounding) {
          avgBrightness += (p.r + p.g + p.b) / 3;
        }
        avgBrightness /= 4;

        final diff = (center.r + center.g + center.b) / 3 - avgBrightness;
        if (diff.abs() > 30) {
          return true;
        }
      }
    }
    return false;
  }

  /// Simple noise detection
  static bool _detectNoise(img.Image image) {
    int noisePixels = 0;
    int totalPixels = 0;

    for (int y = 0; y < image.height; y += 5) {
      for (int x = 0; x < image.width; x += 5) {
        final pixel = image.getPixel(x, y);
        final neighbors = [
          x > 0 ? image.getPixel(x - 1, y) : pixel,
          x < image.width - 1 ? image.getPixel(x + 1, y) : pixel,
          y > 0 ? image.getPixel(x, y - 1) : pixel,
          y < image.height - 1 ? image.getPixel(x, y + 1) : pixel,
        ];

        double avgBrightness = 0;
        for (final p in neighbors) {
          avgBrightness += (p.r + p.g + p.b) / 3;
        }
        avgBrightness /= 4;

        final diff = (pixel.r + pixel.g + pixel.b) / 3 - avgBrightness;
        if (diff.abs() > 50) {
          noisePixels++;
        }
        totalPixels++;
      }
    }

    return (noisePixels / totalPixels) > 0.1;
  }

  /// Check if image contains text patterns
  static Future<bool> _checkForTextPatterns(img.Image image) async {
    int uniformPixels = 0;
    int totalPixels = 0;

    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        totalPixels++;

        if (x > 5 && x < image.width - 5 && y > 5 && y < image.height - 5) {
          final neighbors = [
            image.getPixel(x - 2, y),
            image.getPixel(x + 2, y),
            image.getPixel(x, y - 2),
            image.getPixel(x, y + 2),
          ];

          double avgBrightness = 0;
          for (final p in neighbors) {
            avgBrightness += (p.r + p.g + p.b) / 3;
          }
          avgBrightness /= 4;

          final diff = (pixel.r + pixel.g + pixel.b) / 3 - avgBrightness;
          if (diff.abs() < 5) {
            uniformPixels++;
          }
        }
      }
    }

    return (uniformPixels / totalPixels) > 0.7;
  }

  /// Validate OCR result after processing
  static OCRValidationResult validateOCRResult(String ocrText, double confidence) {
    LoggerService.info('OCR_VALIDATION', '=== Validating OCR result ===');
    
    // Check text length
    if (ocrText.length < _minTextLength) {
      LoggerService.warning('OCR_VALIDATION', 'OCR text too short: ${ocrText.length} chars');
      return OCRValidationResult(
        isValid: false,
        error: 'OCR text too short',
        shouldProcess: false,
      );
    }

    // Check for invalid patterns
    for (final pattern in _invalidPatterns) {
      if (ocrText.toLowerCase().contains(pattern)) {
        LoggerService.warning('OCR_VALIDATION', 'OCR contains invalid pattern: $pattern');
        return OCRValidationResult(
          isValid: false,
          error: 'OCR result contains error message',
          shouldProcess: false,
        );
      }
    }

    // Check confidence
    if (confidence < _minConfidence) {
      LoggerService.warning('OCR_VALIDATION', 'OCR confidence too low: $confidence');
      return OCRValidationResult(
        isValid: false,
        error: 'OCR confidence below threshold',
        shouldProcess: false,
      );
    }

    // Check for meaningful content
    if (!_isMeaningfulText(ocrText)) {
      LoggerService.warning('OCR_VALIDATION', 'OCR text not meaningful: $ocrText');
      return OCRValidationResult(
        isValid: false,
        error: 'OCR text not meaningful',
        shouldProcess: false,
      );
    }

    LoggerService.success('OCR_VALIDATION', '=== OCR validation passed ===');
    return OCRValidationResult(
      isValid: true,
      confidence: confidence,
      shouldProcess: true,
    );
  }

  /// Check if text is meaningful and contains product-related information
  static bool _isMeaningfulText(String text) {
    // Product/medicine related keywords that indicate valid content
    final productKeywords = [
      'mrp', 'price', 'expiry', 'expire', 'batch', 'manufacture', 'date', 'valid',
      'medicine', 'tablet', 'capsule', 'syrup', 'ointment', 'cream', 'gel',
      'ingredients', 'composition', 'dosage', 'store', 'keep', 'away', 'children',
      'rs', 'rupees', 'dollar', 'USD', 'INR', 'Rs.', 'MRP', 'MAX', 'RETAIL',
      'company', 'limited', 'pvt', 'ltd', 'pharma', 'pharmaceutical',
      'mg', 'ml', 'g', 'kg', 'tablet', 'capsule', 'strip', 'bottle', 'tube',
      'prescription', 'rx', 'doctor', 'patient', 'use', 'take', 'oral', 'topical',
    ];

    // Date patterns
    final datePatterns = [
      RegExp(r'\d{2}[-/]\d{2}[-/]\d{4}'), // DD-MM-YYYY or DD/MM/YYYY
      RegExp(r'\d{4}[-/]\d{2}[-/]\d{2}'), // YYYY-MM-DD or YYYY/MM/DD
      RegExp(r'\d{2}[-/]\d{2}[-/]\d{2}'), // DD-MM-YY or DD/MM/YY
      RegExp(r'(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{1,2},?\s+\d{4}', caseSensitive: false),
    ];

    // Price patterns
    final pricePatterns = [
      RegExp(r'rs\.?\s*\d+', caseSensitive: false),
      RegExp(r'rupees?\s*\d+', caseSensitive: false),
      RegExp(r'mrp\s*[:\-]?\s*\d+', caseSensitive: false),
      RegExp(r'price\s*[:\-]?\s*\d+', caseSensitive: false),
      RegExp(r'[\$]\s*\d+'),
      RegExp(r'[\u20B9]\s*\d+'), // Rupee symbol
    ];

    final lowerText = text.toLowerCase();
    
    // Check for at least one product keyword
    final hasProductKeyword = productKeywords.any((keyword) => lowerText.contains(keyword));
    
    // Check for date patterns
    final hasDate = datePatterns.any((pattern) => pattern.hasMatch(text));
    
    // Check for price patterns
    final hasPrice = pricePatterns.any((pattern) => pattern.hasMatch(text));
    
    // Remove common words and check if meaningful content remains
    final commonWords = [
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
      'is', 'are', 'was', 'were', 'been', 'have', 'has', 'had', 'this', 'that', 'these',
      'those', 'from', 'they', 'them', 'their', 'its', 'it', 'his', 'her', 'she', 'he',
      'a', 'an', 'as', 'am', 'is', 'are', 'was', 'were', 'be', 'been', 'have', 'has', 'had', 'do', 'does', 'did',
      'will', 'would', 'should', 'could', 'may', 'might', 'can', 'shall', 'must', 'about', 'into', 'from', 'up', 'down', 'out', 'off', 'over', 'under', 'again', 'further', 'then', 'once',
    ];

    final words = text.toLowerCase().split(' ');
    final meaningfulWords = words.where((word) => 
      word.length > 2 && !commonWords.contains(word)
    ).toList();

    // Text is meaningful if it has product-related content OR date/price patterns
    final isProductRelated = hasProductKeyword || hasDate || hasPrice;
    final hasEnoughContent = meaningfulWords.length >= 3;
    
    LoggerService.info('OCR_VALIDATION', 'Product validation: keyword=$hasProductKeyword, date=$hasDate, price=$hasPrice, words=${meaningfulWords.length}');
    
    return isProductRelated && hasEnoughContent;
  }
}

/// OCR Validation Result
class OCRValidationResult {
  final bool isValid;
  final bool shouldProcess;
  final String? error;
  final double? confidence;
  final ImageQualityAnalysis? analysis;

  OCRValidationResult({
    required this.isValid,
    required this.shouldProcess,
    this.error,
    this.confidence,
    this.analysis,
  });
}

/// Image Quality Analysis
class ImageQualityAnalysis {
  final bool isAcceptable;
  final double confidence;
  final List<String> issues;

  ImageQualityAnalysis({
    required this.isAcceptable,
    required this.confidence,
    required this.issues,
  });
}
