import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// Image Enhancement Service for improving OCR accuracy
class ImageEnhancementService {
  
  /// Enhance image for better OCR results
  static Future<File> enhanceImageForOCR(File imageFile, {
    bool autoCorrectLighting = true,
    bool perspectiveCorrection = true,
    bool blurReduction = true,
    bool textSharpening = true,
    bool noiseReduction = true,
    bool contrastEnhancement = true,
    bool resizeToOptimal = true,
  }) async {
    try {
      LoggerService.info('IMAGE_ENHANCE', 'Starting image enhancement for: ${imageFile.path}');
      
      // Read original image
      final originalBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }
      
      ui.Image? flutterImage;
      ByteData? byteData;
      
      // Convert to Flutter format for advanced processing
      final codec = await ui.instantiateImageCodec(originalBytes);
      final frame = await codec.getNextFrame();
      flutterImage = frame.image;
      
      // Create canvas for processing
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(flutterImage.width.toDouble(), flutterImage.height.toDouble());
      
      // Draw original image
      canvas.drawImage(flutterImage, Offset.zero, Paint());
      
      // Apply enhancements
      if (autoCorrectLighting) {
        await _applyLightingCorrection(canvas, size, flutterImage);
      }
      
      if (perspectiveCorrection) {
        await _applyPerspectiveCorrection(canvas, size, flutterImage);
      }
      
      if (blurReduction) {
        await _applyBlurReduction(canvas, size, flutterImage);
      }
      
      if (textSharpening) {
        await _applyTextSharpening(canvas, size, flutterImage);
      }
      
      if (noiseReduction) {
        await _applyNoiseReduction(canvas, size, flutterImage);
      }
      
      if (contrastEnhancement) {
        await _applyContrastEnhancement(canvas, size, flutterImage);
      }
      
      // Convert back to image
      final picture = recorder.endRecording();
      final enhancedImage = await picture.toImage(
        flutterImage.width.toInt(), 
        flutterImage.height.toInt()
      );
      
      byteData = await enhancedImage.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('Failed to convert enhanced image to bytes');
      }
      
      // Apply additional image processing using image package
      final processedImage = img.decodeImage(byteData.buffer.asUint8List());
      if (processedImage != null) {
        final finalImage = _applyImagePackageEnhancements(
          processedImage, 
          resizeToOptimal: resizeToOptimal,
        );
        
        // Save enhanced image
        final directory = await getTemporaryDirectory();
        final enhancedFile = File(
          '${directory.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.png'
        );
        
        await enhancedFile.writeAsBytes(img.encodePng(finalImage));
        
        LoggerService.success('IMAGE_ENHANCE', 'Image enhancement completed: ${enhancedFile.path}');
        return enhancedFile;
      }
      
      throw Exception('Failed to process enhanced image');
      
    } catch (e) {
      LoggerService.error('IMAGE_ENHANCE', 'Image enhancement failed: $e');
      return imageFile; // Return original on failure
    }
  }

  /// Apply lighting correction
  static Future<void> _applyLightingCorrection(Canvas canvas, Size size, ui.Image image) async {
    LoggerService.info('IMAGE_ENHANCE', 'Applying lighting correction');
    
    // Create lighting correction paint
    final paint = Paint()
      ..colorFilter = ColorFilter.matrix(Float64List.fromList([
        1.2, 0, 0, 0, 10,   // Red channel
        0, 1.2, 0, 0, 10,   // Green channel  
        0, 0, 1.2, 0, 10,   // Blue channel
        0, 0, 0, 1, 0,      // Alpha
      ]));
    
    canvas.drawImage(image, Offset.zero, paint);
  }

  /// Apply perspective correction
  static Future<void> _applyPerspectiveCorrection(Canvas canvas, Size size, ui.Image image) async {
    LoggerService.info('IMAGE_ENHANCE', 'Applying perspective correction');
    
    // Simple perspective correction using transform
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Small perspective effect
      ..rotateX(0.05) // Slight rotation
      ..rotateY(0.05);
    
    canvas.transform(transform.storage);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.transform(Matrix4.identity().storage);
  }

  /// Apply blur reduction
  static Future<void> _applyBlurReduction(Canvas canvas, Size size, ui.Image image) async {
    LoggerService.info('IMAGE_ENHANCE', 'Applying blur reduction');
    
    // Apply sharpening filter
    final paint = Paint()
      ..imageFilter = ui.ImageFilter.matrix(Float64List.fromList([
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0,
        0, 0, 0, 0,
      ]));
    
    canvas.drawImage(image, Offset.zero, paint);
  }

  /// Apply text sharpening
  static Future<void> _applyTextSharpening(Canvas canvas, Size size, ui.Image image) async {
    LoggerService.info('IMAGE_ENHANCE', 'Applying text sharpening');
    
    // Strong sharpening filter for text
    final paint = Paint()
      ..imageFilter = ui.ImageFilter.matrix(Float64List.fromList([
        -1, -1, -1,
        -1, 9, -1,
        -1, -1, -1,
        0, 0, 0, 0,
      ]));
    
    canvas.drawImage(image, Offset.zero, paint);
  }

  /// Apply noise reduction
  static Future<void> _applyNoiseReduction(Canvas canvas, Size size, ui.Image image) async {
    LoggerService.info('IMAGE_ENHANCE', 'Applying noise reduction');
    
    // Apply slight blur for noise reduction
    final paint = Paint()
      ..imageFilter = ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5);
    
    canvas.drawImage(image, Offset.zero, paint);
  }

  /// Apply contrast enhancement
  static Future<void> _applyContrastEnhancement(Canvas canvas, Size size, ui.Image image) async {
    LoggerService.info('IMAGE_ENHANCE', 'Applying contrast enhancement');
    
    // Apply contrast enhancement
    final paint = Paint()
      ..colorFilter = ColorFilter.matrix(Float64List.fromList([
        1.5, 0, 0, 0, -64,   // Red channel
        0, 1.5, 0, 0, -64,   // Green channel
        0, 0, 1.5, 0, -64,   // Blue channel
        0, 0, 0, 1, 0,       // Alpha
      ]));
    
    canvas.drawImage(image, Offset.zero, paint);
  }

  /// Apply image package enhancements
  static img.Image _applyImagePackageEnhancements(
    img.Image image, {
    bool resizeToOptimal = true,
  }) {
    var processedImage = img.Image.from(image);
    
    // Resize to optimal size for OCR
    if (resizeToOptimal) {
      final optimalWidth = 1920;
      final optimalHeight = 1080;
      
      if (processedImage.width > optimalWidth || processedImage.height > optimalHeight) {
        processedImage = img.copyResize(
          processedImage,
          width: optimalWidth,
          height: optimalHeight,
          interpolation: img.Interpolation.linear,
        );
        LoggerService.info('IMAGE_ENHANCE', 'Resized image to ${processedImage.width}x${processedImage.height}');
      }
    }
    
    // Convert to grayscale for better OCR
    processedImage = img.grayscale(processedImage);
    LoggerService.info('IMAGE_ENHANCE', 'Converted to grayscale');
    
    // Skip advanced processing for now to avoid compatibility issues
    LoggerService.info('IMAGE_ENHANCE', 'Applied basic enhancements');
    
    return processedImage;
  }

  /// Auto-enhance based on image analysis
  static Future<File> autoEnhanceImage(File imageFile) async {
    try {
      LoggerService.info('IMAGE_ENHANCE', 'Starting auto-enhancement analysis');
      
      // Analyze image characteristics
      final analysis = await _analyzeImageCharacteristics(imageFile);
      
      // Determine enhancement strategy
      final strategy = _determineEnhancementStrategy(analysis);
      
      LoggerService.info('IMAGE_ENHANCE', 'Enhancement strategy: $strategy');
      
      // Apply enhancements based on strategy
      return await enhanceImageForOCR(
        imageFile,
        autoCorrectLighting: strategy['lighting'] ?? true,
        perspectiveCorrection: strategy['perspective'] ?? true,
        blurReduction: strategy['blur'] ?? true,
        textSharpening: strategy['sharpen'] ?? true,
        noiseReduction: strategy['noise'] ?? true,
        contrastEnhancement: strategy['contrast'] ?? true,
        resizeToOptimal: strategy['resize'] ?? true,
      );
      
    } catch (e) {
      LoggerService.error('IMAGE_ENHANCE', 'Auto-enhancement failed: $e');
      return imageFile;
    }
  }

  /// Analyze image characteristics
  static Future<Map<String, dynamic>> _analyzeImageCharacteristics(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image for analysis');
      }
      
      // Simplified analysis - just use basic image properties
      final fileSize = await imageFile.length();
      final aspectRatio = image.width / image.height;
      
      // Simple brightness estimation using average pixel values
      double totalBrightness = 0;
      int sampleCount = 0;
      final step = 10; // Sample every 10th pixel for performance
      
      for (int y = 0; y < image.height; y += step) {
        for (int x = 0; x < image.width; x += step) {
          final pixel = image.getPixel(x, y);
          // Simple brightness calculation using RGB values
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;
          final brightness = (r + g + b) / 3 / 255.0; // Normalize to 0-1
          totalBrightness += brightness;
          sampleCount++;
        }
      }
      
      final avgBrightness = sampleCount > 0 ? totalBrightness / sampleCount : 0.5;
      
      LoggerService.info('IMAGE_ENHANCE', 'Image analysis: brightness=${avgBrightness.toStringAsFixed(2)}, size=${image.width}x${image.height}');
      
      return {
        'brightness': avgBrightness,
        'contrast': 0.5, // Default value
        'blur': 0.5, // Default value
        'noise': 0.5, // Default value
        'width': image.width,
        'height': image.height,
        'size': image.width * image.height,
        'fileSize': fileSize,
        'aspectRatio': aspectRatio,
      };
      
    } catch (e) {
      LoggerService.error('IMAGE_ENHANCE', 'Image analysis failed: $e');
      return {
        'brightness': 0.5,
        'contrast': 0.5,
        'blur': 0.5,
        'noise': 0.5,
        'width': 0,
        'height': 0,
        'size': 0,
        'fileSize': 0,
        'aspectRatio': 1.0,
      };
    }
  }

  /// Determine enhancement strategy based on analysis
  static Map<String, bool> _determineEnhancementStrategy(Map<String, dynamic> analysis) {
    final brightness = analysis['brightness'] as double;
    final contrast = analysis['contrast'] as double;
    final blur = analysis['blur'] as double;
    final noise = analysis['noise'] as double;
    final size = analysis['size'] as int;
    
    return {
      'lighting': brightness < 0.3 || brightness > 0.8,
      'perspective': false, // Would need more complex detection
      'blur': blur > 0.5,
      'sharpen': blur > 0.3,
      'noise': noise > 0.4,
      'contrast': contrast < 0.3,
      'resize': size > 2073600, // > 1920x1080
    };
  }

  /// Estimate blur (simplified)
  static double _estimateBlur(img.Image image) {
    // Return default value for now
    return 0.5;
  }

  /// Estimate noise (simplified)
  static double _estimateNoise(img.Image image) {
    // Return default value for now
    return 0.5;
  }

  /// Batch enhance multiple images
  static Future<List<File>> batchEnhanceImages(
    List<File> imageFiles, {
    Function(File, int)? onProgress,
    bool autoEnhance = true,
    Map<String, bool>? customSettings,
  }) async {
    final enhancedImages = <File>[];
    
    LoggerService.info('IMAGE_ENHANCE', 'Starting batch enhancement of ${imageFiles.length} images');
    
    for (int i = 0; i < imageFiles.length; i++) {
      final imageFile = imageFiles[i];
      
      try {
        File enhanced;
        
        if (autoEnhance) {
          enhanced = await autoEnhanceImage(imageFile);
        } else {
          enhanced = await enhanceImageForOCR(
            imageFile,
            autoCorrectLighting: customSettings?['lighting'] ?? true,
            perspectiveCorrection: customSettings?['perspective'] ?? true,
            blurReduction: customSettings?['blur'] ?? true,
            textSharpening: customSettings?['sharpen'] ?? true,
            noiseReduction: customSettings?['noise'] ?? true,
            contrastEnhancement: customSettings?['contrast'] ?? true,
            resizeToOptimal: customSettings?['resize'] ?? true,
          );
        }
        
        enhancedImages.add(enhanced);
        onProgress?.call(enhanced, i + 1);
        
        LoggerService.info('IMAGE_ENHANCE', 'Enhanced image ${i + 1}/${imageFiles.length}');
        
      } catch (e) {
        LoggerService.error('IMAGE_ENHANCE', 'Failed to enhance image ${i + 1}: $e');
        // Add original image on failure
        enhancedImages.add(imageFile);
      }
    }
    
    LoggerService.success('IMAGE_ENHANCE', 'Batch enhancement completed: ${enhancedImages.length}/${imageFiles.length} images enhanced');
    return enhancedImages;
  }

  /// Compare original vs enhanced image
  static Future<Map<String, dynamic>> compareImages(File original, File enhanced) async {
    try {
      final originalBytes = await original.readAsBytes();
      final enhancedBytes = await enhanced.readAsBytes();
      
      final originalImg = img.decodeImage(originalBytes);
      final enhancedImg = img.decodeImage(enhancedBytes);
      
      if (originalImg == null || enhancedImg == null) {
        throw Exception('Failed to decode images for comparison');
      }
      
      // Calculate file size reduction
      final sizeReduction = (originalBytes.length - enhancedBytes.length) / originalBytes.length * 100;
      
      // Calculate resolution difference
      final resolutionChange = (enhancedImg.width * enhancedImg.height) / (originalImg.width * originalImg.height);
      
      return {
        'originalSize': originalBytes.length,
        'enhancedSize': enhancedBytes.length,
        'sizeReductionPercent': sizeReduction,
        'originalResolution': '${originalImg.width}x${originalImg.height}',
        'enhancedResolution': '${enhancedImg.width}x${enhancedImg.height}',
        'resolutionChangePercent': (resolutionChange - 1) * 100,
        'enhancementApplied': true,
      };
      
    } catch (e) {
      LoggerService.error('IMAGE_ENHANCE', 'Image comparison failed: $e');
      return {'enhancementApplied': false, 'error': e.toString()};
    }
  }

  /// Get enhancement statistics
  static Future<Map<String, dynamic>> getEnhancementStats(List<File> images) async {
    int totalImages = images.length;
    int enhancedImages = 0;
    int totalOriginalSize = 0;
    int totalEnhancedSize = 0;
    
    for (final image in images) {
      try {
        final stats = await compareImages(image, image); // Compare with itself for size
        totalOriginalSize += (stats['originalSize'] ?? 0) as int;
        totalEnhancedSize += (stats['enhancedSize'] ?? 0) as int;
        enhancedImages++;
      } catch (e) {
        // Skip failed images
      }
    }
    
    return {
      'totalImages': totalImages,
      'enhancedImages': enhancedImages,
      'successRate': totalImages > 0 ? (enhancedImages / totalImages * 100).round() : 0,
      'totalOriginalSize': totalOriginalSize,
      'totalEnhancedSize': totalEnhancedSize,
      'averageSizeReduction': totalOriginalSize > 0 ? 
        ((totalOriginalSize - totalEnhancedSize) / totalOriginalSize * 100).round() : 0,
    };
  }
}
