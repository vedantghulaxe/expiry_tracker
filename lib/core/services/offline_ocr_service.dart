import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Offline OCR service using Google ML Kit
class OfflineOCRService {
  static final OfflineOCRService _instance = OfflineOCRService._internal();
  factory OfflineOCRService() => _instance;
  OfflineOCRService._internal();

  late TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  /// Initialize OCR service
  Future<void> initialize() async {
    try {
      _textRecognizer = TextRecognizer();
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    }
  }

  /// Process single image and extract text
  Future<Map<String, dynamic>> processImage(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      final text = recognizedText.text;
      final confidence = _calculateConfidence(recognizedText);
      
      return {
        'text': text,
        'confidence': confidence,
        'blocks': recognizedText.blocks.length,
        'imagePath': imageFile.path,
        'success': true,
      };
    } catch (e) {
      return {
        'text': '',
        'confidence': 0,
        'blocks': 0,
        'imagePath': imageFile.path,
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Process multiple images
  Future<List<Map<String, dynamic>>> processMultipleImages(List<File> imageFiles) async {
    final results = <Map<String, dynamic>>[];
    
    for (final imageFile in imageFiles) {
      final result = await processImage(imageFile);
      results.add(result);
    }
    
    return results;
  }

  /// Capture multiple images from camera
  Future<List<File>> captureMultipleImages({int maxImages = 5}) async {
    final picker = ImagePicker();
    final imageFiles = <File>[];
    
    for (int i = 0; i < maxImages; i++) {
      try {
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );
        
        if (pickedFile != null) {
          imageFiles.add(File(pickedFile.path));
        } else {
          break; // User cancelled
        }
      } catch (e) {
        continue; // Continue with next image
      }
    }
    
    return imageFiles;
  }

  /// Combine text from multiple OCR results
  static String combineText(List<Map<String, dynamic>> ocrResults) {
    final textParts = <String>[];
    final seenTexts = <String>{};
    
    // Sort by confidence (highest first)
    final sortedResults = List<Map<String, dynamic>>.from(ocrResults);
    sortedResults.sort((a, b) => (b['confidence'] as int).compareTo(a['confidence'] as int));
    
    for (final result in sortedResults) {
      final text = result['text'] as String;
      if (text.isNotEmpty && !seenTexts.contains(text.toLowerCase())) {
        textParts.add(text);
        seenTexts.add(text.toLowerCase());
      }
    }
    
    return textParts.join('\n');
  }

  /// Calculate overall confidence from text blocks
  static int _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0;
    
    int totalConfidence = 0;
    int blockCount = 0;
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          totalConfidence += ((element.confidence ?? 0.0) * 100).round();
          blockCount++;
        }
      }
    }
    
    return blockCount > 0 ? (totalConfidence / blockCount).round() : 0;
  }

  /// Dispose resources
  void dispose() {
    if (_isInitialized) {
      _textRecognizer.close();
      _isInitialized = false;
    }
  }
}
