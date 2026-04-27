import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// OCR Service for text extraction from images
class OCRService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from a single image
  static Future<OCRResult> extractTextFromImages(File imageFile) async {
    try {
      LoggerService.info('OCR', 'Starting text extraction from: ${imageFile.path}');
      
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final text = recognizedText.text;
      final confidence = _calculateConfidence(recognizedText);
      
      LoggerService.success('OCR', 'Text extraction completed: ${text.length} characters, confidence: ${confidence.toStringAsFixed(2)}');
      
      return OCRResult(
        text: text,
        confidence: confidence,
        method: 'mlkit',
        warning: confidence < 0.7 ? 'Low confidence OCR result' : null,
        isLowConfidence: confidence < 0.7,
      );
    } catch (e) {
      LoggerService.error('OCR', 'Text extraction failed: $e');
      return OCRResult(
        text: '',
        confidence: 0.0,
        method: 'error',
        warning: 'OCR processing failed: $e',
        isLowConfidence: true,
      );
    }
  }

  /// Calculate confidence score from recognized text
  static double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int blockCount = 0;
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          totalConfidence += (element.confidence ?? 0.0).toDouble();
          blockCount++;
        }
      }
    }
    
    return blockCount > 0 ? totalConfidence / blockCount : 0.0;
  }

  /// Dispose resources
  static void dispose() {
    _textRecognizer.close();
  }
}

/// OCR Result data class
class OCRResult {
  final String text;
  final double confidence;
  final String method;
  final String? warning;
  final bool isLowConfidence;

  OCRResult({
    required this.text,
    required this.confidence,
    required this.method,
    this.warning,
    required this.isLowConfidence,
  });

  /// Get confidence percentage
  double get confidencePercentage => confidence * 100;

  /// Get method display name
  String get methodDisplayName {
    switch (method) {
      case 'mlkit':
        return 'ML Kit OCR';
      case 'tesseract':
        return 'Tesseract OCR';
      case 'online':
        return 'Online OCR';
      case 'error':
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'OCRResult(text: "${text.substring(0, text.length > 50 ? 50 : text.length)}...", confidence: $confidence, method: $method)';
  }
}
