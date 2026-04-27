import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/services/logger_service.dart';
import '../core/services/config_service.dart';

/// AI Service for extracting structured data from OCR text
class AIExtractionService {
  static String get _apiKey => ConfigService.oxloApiKey;
  static bool _isInitialized = false;

  /// Initialize AI service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (_apiKey.isEmpty) {
        LoggerService.warning('AI', 'Oxlo.ai API key not configured');
        _isInitialized = false;
        return;
      }

      // Test API availability with a simple request
      final response = await http
          .post(
            Uri.parse('${ConfigService.oxloBaseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': ConfigService.oxloTextModel,
              'messages': [
                {'role': 'user', 'content': 'test'},
              ],
              'max_tokens': 5,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _isInitialized = true;
        LoggerService.success('AI', 'Oxlo.ai service initialized successfully');
      } else {
        throw Exception('API returned status ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('AI', 'Failed to initialize Oxlo.ai service: $e');
      _isInitialized = false;
    }
  }

  /// Check if AI service is available
  static bool isAvailable() {
    return _isInitialized && _apiKey.isNotEmpty;
  }

  /// Extract structured data from OCR text using Oxlo.ai
  static Future<Map<String, dynamic>> extractStructuredData(String ocrText) async {
    try {
      if (!isAvailable()) {
        LoggerService.warning('AI', 'Oxlo.ai service not available');
        return {};
      }

      if (ocrText.trim().isEmpty) {
        LoggerService.warning('AI', 'Empty OCR text provided');
        return {};
      }

      LoggerService.start('AI', 'Starting Oxlo.ai extraction');
      print('=== Starting AI Extraction ===');
      print('OCR Text Length: ${ocrText.length}');
      print('Sample Text: "${ocrText.substring(0, ocrText.length > 100 ? 100 : ocrText.length)}..."');

      final prompt = '''
Extract product/medicine information from this OCR text and return ONLY valid JSON:

OCR Text:
"""$ocrText"""

Return JSON with these exact fields:
{
  "name": "product/medicine name",
  "expiryDate": "YYYY-MM-DD format",
  "mfgDate": "YYYY-MM-DD format (if available)",
  "category": "medicine" or "product",
  "isMedicine": true/false,
  "dosage": "dosage info (for medicines)",
  "confidence": 0.0-1.0,
  "notes": "additional notes"
}

Rules:
- Return ONLY JSON, no explanations
- Use null for missing fields
- Identify if it's medicine or product
- Extract dates in YYYY-MM-DD format
- Set confidence based on text clarity
''';

      print('Sending request to Oxlo.ai...');
      final response = await http
          .post(
            Uri.parse('${ConfigService.oxloBaseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': ConfigService.oxloTextModel,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'max_tokens': 1024,
              'temperature': 0.1,
            }),
          )
          .timeout(ConfigService.apiTimeout);

      final aiText = response.statusCode == 200
          ? (jsonDecode(response.body)['choices']?[0]?['message']?['content']
                  ?.toString() ??
              '')
          : '';

      print('AI Response received');
      print('AI Text Length: ${aiText.length}');

      // Parse JSON response
      try {
        // Clean up response to extract JSON
        String jsonText = aiText.trim();
        if (jsonText.contains('```json')) {
          jsonText = jsonText.split('```json')[1].split('```')[0].trim();
        } else if (jsonText.contains('{')) {
          jsonText = jsonText.substring(jsonText.indexOf('{'));
          if (jsonText.contains('}')) {
            jsonText = jsonText.substring(0, jsonText.lastIndexOf('}') + 1);
          }
        }

        final Map<String, dynamic> result = jsonDecode(jsonText);

        // Validate and clean result
        final cleanedResult = _validateAIResult(result);

        LoggerService.success('AI', 'Oxlo.ai extraction completed successfully');
        print('=== AI Extraction Successful ===');
        print('Extracted Name: ${cleanedResult['name']}');
        print('Category: ${cleanedResult['category']}');
        print('Confidence: ${cleanedResult['confidence']}');

        return cleanedResult;
      } catch (e) {
        LoggerService.error('AI', 'Failed to parse AI response: $e');
        print('JSON Parse Error: $e');
        print('Raw AI Response: $aiText');
        return {};
      }
    } catch (e) {
      LoggerService.error('AI', 'Oxlo.ai extraction failed: $e');
      print('=== AI Extraction Failed: $e ===');
      return {};
    }
  }

  /// Validate and clean AI result
  static Map<String, dynamic> _validateAIResult(Map<String, dynamic> result) {
    return {
      'name': result['name']?.toString().trim() ?? '',
      'expiryDate': result['expiryDate']?.toString().trim() ?? '',
      'mfgDate': result['mfgDate']?.toString().trim() ?? '',
      'category': _validateCategory(result['category']),
      'isMedicine': _validateBoolean(result['isMedicine']),
      'dosage': result['dosage']?.toString().trim() ?? '',
      'confidence': _validateConfidence(result['confidence']),
      'notes': result['notes']?.toString().trim() ?? '',
    };
  }

  static String _validateCategory(dynamic category) {
    if (category == null) return 'product';
    final catStr = category.toString().toLowerCase();
    if (catStr.contains('medicine') || catStr.contains('drug') || catStr.contains('tablet')) {
      return 'medicine';
    }
    return 'product';
  }

  static bool _validateBoolean(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    final str = value.toString().toLowerCase();
    return str == 'true' || str == 'yes' || str == '1';
  }

  static double _validateConfidence(dynamic value) {
    if (value == null) return 0.5;
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is int) return value.toDouble().clamp(0.0, 1.0);
    if (value is String) {
      final num = double.tryParse(value);
      return num?.clamp(0.0, 1.0) ?? 0.5;
    }
    return 0.5;
  }

  /// Configure API key (no-op — key is loaded from ConfigService)
  static void configureApiKey(String apiKey) {
    LoggerService.info('AI', 'API key is managed via ConfigService');
    // Re-initialize to pick up any changes
    _isInitialized = false;
  }
}
