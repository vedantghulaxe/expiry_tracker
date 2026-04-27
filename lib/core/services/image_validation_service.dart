import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// Image Validation Service for Product Label Detection
/// Provides pre-OCR validation to ensure images contain product labels
class ImageValidationService {
  static const double _minTextDensity = 0.05; // Minimum text area ratio
  static const double _maxTextDensity = 0.8; // Maximum text area ratio
  static const int _minImageWidth = 200; // Minimum image width
  static const int _minImageHeight = 200; // Minimum image height
  static const double _minAspectRatio = 0.3; // Minimum width/height ratio
  static const double _maxAspectRatio = 3.0; // Maximum width/height ratio

  /// Comprehensive image validation for product labels
  static Future<ImageValidationResult> validateProductLabel(
    File imageFile,
  ) async {
    try {
      LoggerService.info(
        'IMAGE_VALIDATION',
        'Starting image validation for: ${imageFile.path}',
      );

      // Basic file validation
      if (!await imageFile.exists()) {
        return ImageValidationResult.invalid('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize < 1024) {
        // Less than 1KB
        return ImageValidationResult.invalid('Image file too small');
      }

      if (fileSize > 10 * 1024 * 1024) {
        // More than 10MB
        return ImageValidationResult.invalid('Image file too large');
      }

      // Load and decode image
      final bytes = await imageFile.readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        return ImageValidationResult.invalid('Unable to decode image');
      }

      // Basic dimension checks
      final width = decodedImage.width;
      final height = decodedImage.height;

      LoggerService.info(
        'IMAGE_VALIDATION',
        'Image dimensions: ${width}x${height}',
      );

      if (width < _minImageWidth || height < _minImageHeight) {
        return ImageValidationResult.invalid(
          'Image too small (${width}x${height})',
        );
      }

      final aspectRatio = width / height;
      if (aspectRatio < _minAspectRatio || aspectRatio > _maxAspectRatio) {
        return ImageValidationResult.invalid(
          'Invalid aspect ratio: $aspectRatio',
        );
      }

      // Check for product label characteristics
      final labelCheck = await _checkProductLabelCharacteristics(decodedImage);
      if (!labelCheck.isValid) {
        return labelCheck;
      }

      // Estimate text density (rough approximation)
      final textDensity = _estimateTextDensity(decodedImage);
      LoggerService.info(
        'IMAGE_VALIDATION',
        'Estimated text density: ${(textDensity * 100).toStringAsFixed(1)}%',
      );

      if (textDensity < _minTextDensity) {
        return ImageValidationResult.invalid(
          'Insufficient text content (${(textDensity * 100).toStringAsFixed(1)}% text density)',
        );
      }

      if (textDensity > _maxTextDensity) {
        return ImageValidationResult.invalid(
          'Too much text content (${(textDensity * 100).toStringAsFixed(1)}% text density)',
        );
      }

      LoggerService.success('IMAGE_VALIDATION', 'Image validation passed');
      return ImageValidationResult.valid(
        width: width,
        height: height,
        textDensity: textDensity,
        confidence: _calculateValidationConfidence(decodedImage, textDensity),
      );
    } catch (e) {
      LoggerService.error('IMAGE_VALIDATION', 'Image validation failed: $e');
      return ImageValidationResult.invalid('Validation error: $e');
    }
  }

  /// Check for characteristics typical of product labels
  static Future<ImageValidationResult> _checkProductLabelCharacteristics(
    img.Image image,
  ) async {
    // Check for structured layout (text blocks, logos, etc.)
    final hasStructuredContent = _hasStructuredContent(image);
    if (!hasStructuredContent) {
      return ImageValidationResult.invalid(
        'Image lacks structured content typical of product labels',
      );
    }

    // Check color distribution (product labels often have high contrast)
    final hasGoodContrast = _hasGoodContrast(image);
    if (!hasGoodContrast) {
      LoggerService.warning(
        'IMAGE_VALIDATION',
        'Low contrast detected - may be difficult to OCR',
      );
      // Don't fail validation, just warn
    }

    // Check for common non-label image types
    if (_isLikelyScreenshot(image)) {
      return ImageValidationResult.invalid(
        'Appears to be a screenshot rather than a product photo',
      );
    }

    if (_isLikelyPhoto(image)) {
      return ImageValidationResult.invalid(
        'Appears to be a general photo rather than a product label',
      );
    }

    return ImageValidationResult.valid();
  }

  /// Estimate text density in the image
  static double _estimateTextDensity(img.Image image) {
    int textPixels = 0;
    int totalPixels = image.width * image.height;

    // Simple edge detection as proxy for text
    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        final centerPixel = image.getPixel(x, y);
        final rightPixel = image.getPixel(x + 1, y);
        final bottomPixel = image.getPixel(x, y + 1);

        // Check for edges (text typically has high contrast edges)
        if (_colorDifference(centerPixel, rightPixel) > 50 ||
            _colorDifference(centerPixel, bottomPixel) > 50) {
          textPixels++;
        }
      }
    }

    return textPixels / totalPixels;
  }

  /// Calculate color difference between two pixels
  static int _colorDifference(img.Pixel pixel1, img.Pixel pixel2) {
    final r1 = pixel1.r.toInt();
    final g1 = pixel1.g.toInt();
    final b1 = pixel1.b.toInt();

    final r2 = pixel2.r.toInt();
    final g2 = pixel2.g.toInt();
    final b2 = pixel2.b.toInt();

    return ((r1 - r2).abs() + (g1 - g2).abs() + (b1 - b2).abs()) ~/ 3;
  }

  /// Check if image has structured content (text blocks, borders, etc.)
  static bool _hasStructuredContent(img.Image image) {
    // Count edge transitions — text-heavy images have many transitions
    int transitions = 0;
    for (int y = 0; y < image.height; y += 5) {
      img.Pixel? prev;
      for (int x = 0; x < image.width; x += 3) {
        final pixel = image.getPixel(x, y);
        if (prev != null && _colorDifference(prev, pixel) > 40) {
          transitions++;
        }
        prev = pixel;
      }
    }
    // A product label should have a reasonable number of transitions
    final minTransitions = (image.width * image.height) ~/ 500;
    return transitions > minTransitions;
  }

  /// Check if image has good contrast
  static bool _hasGoodContrast(img.Image image) {
    int minBrightness = 255;
    int maxBrightness = 0;

    // Sample pixels to find brightness range
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final p = image.getPixel(x, y);
        final brightness = (p.r.toDouble() * 0.299 + p.g.toDouble() * 0.587 + p.b.toDouble() * 0.114).round();
        minBrightness = brightness < minBrightness ? brightness : minBrightness;
        maxBrightness = brightness > maxBrightness ? brightness : maxBrightness;
      }
    }

    final contrastRatio = maxBrightness - minBrightness;
    return contrastRatio > 50; // Minimum contrast threshold
  }

  /// Check if image is likely a screenshot (very uniform rows of pixels)
  static bool _isLikelyScreenshot(img.Image image) {
    // Screenshots have very uniform horizontal bands — check for that
    // Don't use aspect ratio alone as product labels can have any ratio
    int uniformRows = 0;
    for (int y = 0; y < image.height; y += 20) {
      final firstPixel = image.getPixel(0, y);
      bool isUniform = true;
      for (int x = image.width ~/ 4; x < image.width * 3 ~/ 4; x += 10) {
        final pixel = image.getPixel(x, y);
        if (_colorDifference(firstPixel, pixel) > 30) {
          isUniform = false;
          break;
        }
      }
      if (isUniform) uniformRows++;
    }
    // Only flag as screenshot if >80% of sampled rows are uniform
    final totalSampled = image.height ~/ 20;
    return totalSampled > 0 && (uniformRows / totalSampled) > 0.8;
  }

  /// Check if image is likely a general photo
  static bool _isLikelyPhoto(img.Image image) {
    // General photos tend to have low text density and high color variance
    final textDensity = _estimateTextDensity(image);
    return textDensity < 0.02; // Very low text density
  }

  /// Calculate overall validation confidence
  static double _calculateValidationConfidence(
    img.Image image,
    double textDensity,
  ) {
    double confidence = 0.5; // Base confidence

    // Higher text density increases confidence
    if (textDensity > 0.1) confidence += 0.2;
    if (textDensity > 0.2) confidence += 0.2;

    // Good contrast increases confidence
    if (_hasGoodContrast(image)) confidence += 0.1;

    // Structured content increases confidence
    if (_hasStructuredContent(image)) confidence += 0.2;

    return confidence.clamp(0.0, 1.0);
  }
}

/// Result of image validation
class ImageValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int? width;
  final int? height;
  final double? textDensity;
  final double? confidence;

  ImageValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.width,
    this.height,
    this.textDensity,
    this.confidence,
  });

  factory ImageValidationResult.valid({
    int? width,
    int? height,
    double? textDensity,
    double? confidence,
  }) {
    return ImageValidationResult._(
      isValid: true,
      width: width,
      height: height,
      textDensity: textDensity,
      confidence: confidence,
    );
  }

  factory ImageValidationResult.invalid(String message) {
    return ImageValidationResult._(isValid: false, errorMessage: message);
  }

  @override
  String toString() {
    if (isValid) {
      return 'ImageValidationResult(valid, confidence: ${confidence?.toStringAsFixed(2)}, size: ${width}x${height})';
    } else {
      return 'ImageValidationResult(invalid: $errorMessage)';
    }
  }
}

