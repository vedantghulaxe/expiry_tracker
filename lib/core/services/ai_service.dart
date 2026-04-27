import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'logger_service.dart';

class AIService {
  /// Standardized extraction method for both products and medicines
  /// Uses Oxlo.ai OpenAI-compatible Vision API
  Future<Map<String, dynamic>> extractStructuredData({
    required String imagePath,
    String? rawText,
    String? barcode,
  }) async {
    LoggerService.start('AI_PROCESS', 'Initializing Oxlo.ai Vision Engine');

    final apiKey = ConfigService.oxloApiKey;

    if (apiKey.isEmpty) {
      LoggerService.error('AI_PROCESS', 'Oxlo.ai API Key is empty!');
      return _emptyResult();
    }

    try {
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final systemPrompt = '''### ROLE
You are an intelligent Pharmaceutical and Product Label Data Extraction Engine.

### TASK
Analyze the image and extract structured information.

### EXTRACTION APPROACH
Extract only what is clearly visible. If a field is not visible, return "".

### STRUCTURE
1. PRIMARY FIELDS: brand, manufacturer, mrp, batch, expiry, mfg_date, name, ingredients.
2. DYNAMIC FIELDS (extraData): All other info like quantity, category, warnings, dosage.

### OUTPUT FORMAT (STRICT JSON)
{
  "brand": "",
  "name": "",
  "manufacturer": "",
  "mrp": "",
  "batch": "",
  "expiry": "YYYY-MM-DD or MM/YYYY",
  "mfg_date": "YYYY-MM-DD or MM/YYYY",
  "ingredients": "",
  "extraData": {}
}

Return ONLY valid JSON, no explanations or markdown.''';

      final userContent = <Map<String, dynamic>>[
        {
          'type': 'text',
          'text':
              'Extract data from this product/medicine label image. OCR Hint: ${rawText ?? ''}. Barcode Hint: ${barcode ?? ''}. Return ONLY the JSON object.',
        },
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,$base64Image',
          },
        },
      ];

      final response = await http
          .post(
            Uri.parse('${ConfigService.oxloBaseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': ConfigService.oxloVisionModel,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userContent},
              ],
              'max_tokens': 1024,
              'temperature': 0.1,
            }),
          )
          .timeout(ConfigService.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText =
            data['choices']?[0]?['message']?['content']?.toString() ?? '';

        if (aiText.isNotEmpty) {
          LoggerService.success('AI_PROCESS', 'Oxlo.ai response received');
          print("[AI_DEBUG] Raw Response: $aiText");

          String cleanJson = aiText
              .replaceAll("```json", "")
              .replaceAll("```", "")
              .trim();

          // Extract JSON from response
          if (cleanJson.contains('{')) {
            cleanJson = cleanJson.substring(cleanJson.indexOf('{'));
            if (cleanJson.contains('}')) {
              cleanJson =
                  cleanJson.substring(0, cleanJson.lastIndexOf('}') + 1);
            }
          }

          final Map<String, dynamic> result = jsonDecode(cleanJson);

          return {
            "brand": result['brand'] ?? "",
            "name": result['name'] ?? "",
            "manufacturer": result['manufacturer'] ?? "",
            "mrp": result['mrp'] ?? "",
            "batch": result['batch'] ?? "",
            "expiry": result['expiry'] ?? "",
            "mfg_date": result['mfg_date'] ?? "",
            "ingredients": result['ingredients'] ?? "",
            "extraData": jsonEncode(result['extraData'] ?? {}),
          };
        }
      } else {
        LoggerService.error(
          'AI_PROCESS',
          'Oxlo.ai HTTP Error: ${response.statusCode} - ${response.body}',
        );
        print(
            "[AI_DEBUG] HTTP Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      LoggerService.error('AI_PROCESS', 'Oxlo.ai Error: $e');
      print("[AI_DEBUG] Exception Details: $e");
    }

    return _emptyResult();
  }

  /// Extract structured data from OCR text only (no image)
  Future<Map<String, dynamic>> extractFromText({
    required String ocrText,
    String? barcode,
  }) async {
    LoggerService.start('AI_PROCESS', 'Initializing Oxlo.ai Text Extraction');

    final apiKey = ConfigService.oxloApiKey;

    if (apiKey.isEmpty) {
      LoggerService.error('AI_PROCESS', 'Oxlo.ai API Key is empty!');
      return _emptyResult();
    }

    try {
      final systemPrompt = '''### ROLE
You are an intelligent Pharmaceutical and Product Label Data Extraction Engine.

### TASK
Analyze the OCR text and extract structured information.

### EXTRACTION APPROACH
Extract only what is clearly present. If a field is not present, return "".

### OUTPUT FORMAT (STRICT JSON)
{
  "brand": "",
  "name": "",
  "manufacturer": "",
  "mrp": "",
  "batch": "",
  "expiry": "YYYY-MM-DD or MM/YYYY",
  "mfg_date": "YYYY-MM-DD or MM/YYYY",
  "ingredients": "",
  "extraData": {}
}

Return ONLY valid JSON, no explanations or markdown.''';

      final response = await http
          .post(
            Uri.parse('${ConfigService.oxloBaseUrl}/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': ConfigService.oxloTextModel,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {
                  'role': 'user',
                  'content':
                      'Extract data from this OCR text. Barcode Hint: ${barcode ?? ''}.\n\nOCR Text:\n$ocrText\n\nReturn ONLY the JSON object.',
                },
              ],
              'max_tokens': 1024,
              'temperature': 0.1,
            }),
          )
          .timeout(ConfigService.apiTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText =
            data['choices']?[0]?['message']?['content']?.toString() ?? '';

        if (aiText.isNotEmpty) {
          LoggerService.success('AI_PROCESS', 'Oxlo.ai text extraction received');
          print("[AI_DEBUG] Text Response: $aiText");

          String cleanJson = aiText
              .replaceAll("```json", "")
              .replaceAll("```", "")
              .trim();

          if (cleanJson.contains('{')) {
            cleanJson = cleanJson.substring(cleanJson.indexOf('{'));
            if (cleanJson.contains('}')) {
              cleanJson =
                  cleanJson.substring(0, cleanJson.lastIndexOf('}') + 1);
            }
          }

          final Map<String, dynamic> result = jsonDecode(cleanJson);

          return {
            "brand": result['brand'] ?? "",
            "name": result['name'] ?? "",
            "manufacturer": result['manufacturer'] ?? "",
            "mrp": result['mrp'] ?? "",
            "batch": result['batch'] ?? "",
            "expiry": result['expiry'] ?? "",
            "mfg_date": result['mfg_date'] ?? "",
            "ingredients": result['ingredients'] ?? "",
            "extraData": jsonEncode(result['extraData'] ?? {}),
          };
        }
      } else {
        LoggerService.error(
          'AI_PROCESS',
          'Oxlo.ai HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      LoggerService.error('AI_PROCESS', 'Oxlo.ai Text Error: $e');
    }

    return _emptyResult();
  }

  Map<String, dynamic> _emptyResult() {
    return {
      "brand": "",
      "name": "",
      "manufacturer": "",
      "mrp": "",
      "batch": "",
      "expiry": "",
      "mfg_date": "",
      "ingredients": "",
      "extraData": "{}",
    };
  }

  /// Helper to get stats for the UI
  Map<String, dynamic> getExtractionStats(Map<String, dynamic> data) {
    int count = 0;
    if (data['brand'].toString().isNotEmpty) count++;
    if (data['name'].toString().isNotEmpty) count++;
    if (data['mrp'].toString().isNotEmpty) count++;
    if (data['batch'].toString().isNotEmpty) count++;
    if (data['expiry'].toString().isNotEmpty) count++;

    return {
      "method": "Oxlo.ai Vision",
      "fields_found": count,
      "has_extra": data['extraData'] != "{}",
    };
  }
}
