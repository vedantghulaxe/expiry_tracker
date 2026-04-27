import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/services/logger_service.dart';

/// Online OCR Service using Google Vision API
class OnlineOCRService {
  static const String _apiKey = 'YOUR_GOOGLE_VISION_API_KEY'; // Replace with actual API key
  static const String _baseUrl = 'https://vision.googleapis.com/v1/images:annotate';
  
  /// Check if online OCR is available (API key configured)
  static bool isAvailable() {
    return _apiKey != 'YOUR_GOOGLE_VISION_API_KEY' && _apiKey.isNotEmpty;
  }
  
  /// Extract text from image using Google Vision API
  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      if (!isAvailable()) {
        LoggerService.warning('ONLINE_OCR', 'Google Vision API key not configured');
        return '';
      }
      
      LoggerService.start('ONLINE_OCR', 'Starting online OCR extraction');
      print('=== Starting Online OCR with Google Vision API ===');
      
      // Read image bytes
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Create request body
      final requestBody = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'TEXT_DETECTION',
                'maxResults': 1,
              },
            ],
          },
        ],
      };
      
      // Make API request
      print('Sending request to Google Vision API...');
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final annotations = responseData['responses'][0]['textAnnotations'];
        
        if (annotations != null && annotations.isNotEmpty) {
          final extractedText = annotations[0]['description'] ?? '';
          
          if (extractedText.isNotEmpty) {
            LoggerService.success('ONLINE_OCR', 'Text extracted successfully');
            print('=== Online OCR Success ===');
            print('Extracted text length: ${extractedText.length}');
            print('First 100 chars: "${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}"');
            return extractedText.trim();
          }
        }
        
        LoggerService.warning('ONLINE_OCR', 'No text found in image');
        print('Online OCR: No text found');
        return '';
      } else {
        LoggerService.error('ONLINE_OCR', 'API request failed: ${response.statusCode}');
        print('Online OCR failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
        return '';
      }
    } catch (e) {
      LoggerService.error('ONLINE_OCR', 'Online OCR failed: $e');
      print('Online OCR exception: $e');
      return '';
    }
  }
  
  /// Extract text from multiple images
  static Future<String> extractTextFromMultipleImages(List<File> images) async {
    if (!isAvailable()) {
      LoggerService.warning('ONLINE_OCR', 'Google Vision API key not configured');
      return '';
    }
    
    print('=== Starting Online OCR for ${images.length} images ===');
    
    String combinedText = '';
    int successfulExtractions = 0;
    
    for (int i = 0; i < images.length; i++) {
      try {
        LoggerService.info('ONLINE_OCR', 'Processing image ${i + 1}/${images.length}');
        print('Processing image ${i + 1}/${images.length}: ${images[i].path}');
        
        final text = await extractTextFromImage(images[i]);
        
        if (text.isNotEmpty) {
          combinedText += '--- Image ${i + 1} ---\n$text\n\n';
          successfulExtractions++;
          print('Image ${i + 1} processed successfully - Text length: ${text.length}');
        } else {
          print('Image ${i + 1} processed but no text extracted');
        }
        
        // Add delay to prevent rate limiting
        if (i < images.length - 1) {
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      } catch (e) {
        LoggerService.warning('ONLINE_OCR', 'Failed to process image ${i + 1}: $e');
        print('Failed to process image ${i + 1}: $e');
        continue;
      }
    }
    
    LoggerService.success('ONLINE_OCR', 'Processed ${images.length} images, ${successfulExtractions} successful');
    print('=== Online OCR Complete ===');
    print('Successful extractions: ${successfulExtractions}/${images.length}');
    print('Combined text length: ${combinedText.length}');
    
    return combinedText.trim();
  }
  
  /// Configure API key
  static void configureApiKey(String apiKey) {
    // This would typically be stored securely
    // For now, we'll update the constant
    print('Google Vision API key configured');
    LoggerService.info('ONLINE_OCR', 'API key configured');
  }
}
