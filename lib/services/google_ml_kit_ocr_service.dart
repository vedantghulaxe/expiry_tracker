import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Real OCR Service using Google ML Kit
class GoogleMLKitOCRService {
  static Future<Map<String, dynamic>> extractTextFromImage(File imageFile) async {
    try {
      print('=== GOOGLE ML KIT OCR START ===');
      print('Processing image: ${imageFile.path}');
      print('Image exists: ${imageFile.existsSync()}');
      print('Image size: ${imageFile.lengthSync()} bytes');
      
      // Verify image file exists and is readable
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      
      // Create input image from file
      InputImage inputImage;
      try {
        inputImage = InputImage.fromFilePath(imageFile.path);
        print('InputImage created successfully');
      } catch (e) {
        print('Error creating InputImage: $e');
        throw Exception('Failed to create InputImage from file: $e');
      }
      
      // Initialize text recognizer
      final textRecognizer = TextRecognizer();
      print('TextRecognizer initialized');
      
      // Process image
      RecognizedText recognizedText;
      try {
        recognizedText = await textRecognizer.processImage(inputImage);
        print('Image processed successfully');
      } catch (e) {
        print('Error processing image: $e');
        await textRecognizer.close();
        throw Exception('Failed to process image with ML Kit: $e');
      }
      
      // Extract text blocks
      String fullText = '';
      List<Map<String, dynamic>> textBlocks = [];
      
      print('Found ${recognizedText.blocks.length} text blocks');
      
      for (TextBlock block in recognizedText.blocks) {
        final blockText = block.text;
        fullText += blockText + '\n';
        
        print('Text block: "$blockText"');
        
        textBlocks.add({
          'text': blockText,
          'boundingBox': block.boundingBox,
          'lines': block.lines.map((line) => line.text).toList(),
        });
      }
      
      // Clean up
      await textRecognizer.close();
      
      final result = {
        'success': true,
        'text': fullText.trim(),
        'blocks': textBlocks,
        'confidence': 1.0, // Default confidence since TextBlock doesn't have confidence
        'method': 'Google ML Kit',
        'word_count': fullText.split(' ').where((word) => word.isNotEmpty).length,
        'processing_time': DateTime.now().millisecondsSinceEpoch,
      };
      
      print('=== GOOGLE ML KIT OCR RESULTS ===');
      print('Success: ${result['success']}');
      print('Text Length: ${(result['text'] as String).length}');
      print('Word Count: ${result['word_count']}');
      print('Confidence: ${result['confidence']}');
      print('Text Blocks: ${(result['blocks'] as List).length}');
      print('Extracted Text: "${result['text']}"');
      print('Method: ${result['method']}');
      print('==============================');
      
      return result;
      
    } catch (e) {
      print('Google ML Kit OCR Error: $e');
      print('Stack trace: ${StackTrace.current}');
      return {
        'success': false,
        'error': e.toString(),
        'method': 'Google ML Kit',
        'text': '',
        'blocks': [],
        'confidence': 0.0,
        'word_count': 0,
      };
    }
  }
  
  /// Calculate average confidence from text blocks
  static double _calculateAverageConfidence(List<Map<String, dynamic>> blocks) {
    if (blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    for (final block in blocks) {
      totalConfidence += block['confidence'] ?? 0.0;
    }
    
    return totalConfidence / blocks.length;
  }
  
  /// Extract structured information from multiple images
  static Future<Map<String, dynamic>> extractFromMultipleImages(List<File> images) async {
    print('=== GOOGLE ML KIT MULTI-IMAGE PROCESSING ===');
    print('Processing ${images.length} images');
    
    if (images.isEmpty) {
      return {
        'success': false,
        'error': 'No images provided',
        'method': 'Google ML Kit (Multi-Image)',
        'text': '',
        'blocks': [],
        'confidence': 0.0,
        'word_count': 0,
        'processing_time': DateTime.now().millisecondsSinceEpoch,
        'errors': ['No images to process'],
        'has_text': false,
      };
    }
    
    String combinedText = '';
    List<Map<String, dynamic>> allBlocks = [];
    double totalConfidence = 0.0;
    int successfulExtractions = 0;
    List<String> processingErrors = [];
    
    for (int i = 0; i < images.length; i++) {
      print('\n--- Processing Image ${i + 1}/${images.length} ---');
      
      try {
        // Verify each image file exists
        if (!images[i].existsSync()) {
          final error = 'Image file does not exist: ${images[i].path}';
          print('ERROR: $error');
          processingErrors.add(error);
          continue;
        }
        
        // Check file size to prevent processing very large files
        final fileSize = await images[i].length();
        if (fileSize > 10 * 1024 * 1024) { // 10MB limit
          final error = 'Image too large: ${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB (max 10MB)';
          print('ERROR: $error');
          processingErrors.add(error);
          continue;
        }
        
        final result = await extractTextFromImage(images[i]);
        
        if (result['success']) {
          final extractedText = result['text'] ?? '';
          if (extractedText.isNotEmpty) {
            combinedText += extractedText + '\n';
            allBlocks.addAll(result['blocks'] ?? []);
            totalConfidence += result['confidence'] ?? 0.0;
            successfulExtractions++;
            print('✅ Image ${i + 1} processed successfully');
            print('   Extracted text length: ${extractedText.length}');
            print('   Text blocks found: ${result['blocks']?.length ?? 0}');
          } else {
            print('⚠️ Image ${i + 1} processed but no text found');
            processingErrors.add('No text found in image ${i + 1}');
          }
        } else {
          final error = result['error'] ?? 'Unknown error';
          print('❌ Image ${i + 1} failed: $error');
          processingErrors.add('Image ${i + 1} error: $error');
        }
      } catch (e) {
        final error = 'Exception processing image ${i + 1}: $e';
        print('❌ $error');
        processingErrors.add(error);
      }
    }
    
    final averageConfidence = successfulExtractions > 0 
        ? totalConfidence / successfulExtractions 
        : 0.0;
    
    final finalResult = {
      'success': successfulExtractions > 0 && combinedText.trim().isNotEmpty,
      'text': combinedText.trim(),
      'blocks': allBlocks,
      'confidence': averageConfidence,
      'method': 'Google ML Kit (Multi-Image)',
      'images_processed': successfulExtractions,
      'total_images': images.length,
      'word_count': combinedText.split(' ').where((word) => word.isNotEmpty).length,
      'processing_time': DateTime.now().millisecondsSinceEpoch,
      'errors': processingErrors,
      'has_text': combinedText.trim().isNotEmpty,
    };
    
    print('\n=== MULTI-IMAGE OCR RESULTS ===');
    print('Overall Success: ${finalResult['success']}');
    print('Images Processed: ${finalResult['images_processed']}/${finalResult['total_images']}');
    print('Combined Text Length: ${(finalResult['text'] as String).length}');
    print('Word Count: ${finalResult['word_count']}');
    print('Average Confidence: ${finalResult['confidence']}');
    print('Total Blocks: ${(finalResult['blocks'] as List).length}');
    print('Has Text: ${finalResult['has_text']}');
    if (processingErrors.isNotEmpty) {
      print('Processing Errors: ${processingErrors.length}');
      for (final error in processingErrors) {
        print('  - $error');
      }
    }
    print('Final Extracted Text: "${finalResult['text']}"');
    print('====================================');
    
    return finalResult;
  }
  
  /// Check if Google ML Kit is available
  static bool isSupported() {
    try {
      // Google ML Kit is supported on most Android and iOS devices
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      print('Google ML Kit support check error: $e');
      return false;
    }
  }
  
  /// Get supported languages
  static List<String> getSupportedLanguages() {
    // Google ML Kit supports many languages, but we'll focus on English for now
    return [
      'en', // English
      'es', // Spanish
      'fr', // French
      'de', // German
      'it', // Italian
      'pt', // Portuguese
      'ru', // Russian
      'ja', // Japanese
      'ko', // Korean
      'zh', // Chinese
    ];
  }
}
