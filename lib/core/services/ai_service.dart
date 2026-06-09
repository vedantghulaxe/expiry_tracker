import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'logger_service.dart';

class AIService {
  /// Standardized extraction method for both products and medicines
  /// Uses Groq API with Llama 3.2 Vision for ultra-fast, accurate extraction
  Future<Map<String, dynamic>> extractStructuredData({
    required String imagePath,
    String? rawText,
    String? barcode,
  }) async {
    LoggerService.start('AI_PROCESS', 'Initializing Groq AI Vision Engine (Llama 3.2)');

    final apiKey = ConfigService.oxloApiKey;

    if (apiKey.isEmpty) {
      LoggerService.error('AI_PROCESS', 'Groq API Key is empty!');
      return _emptyResult();
    }

    // Retry logic for connection issues
    int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        LoggerService.info(
          'AI_PROCESS',
          'Attempt $attempt of $maxRetries (Groq Llama 3.2)',
        );

        final imageBytes = await File(imagePath).readAsBytes();
        final base64Image = base64Encode(imageBytes);

        final systemPrompt = '''You are a TEXT CLEANING and DATE EXTRACTION specialist.

YOUR ONLY JOB:
1. Clean the OCR text (fix spacing, remove noise)
2. Extract ONLY the expiry date and manufacturing date

CRITICAL RULES:
- DO NOT generate product names
- DO NOT generate brand names
- DO NOT generate batch numbers
- DO NOT generate MRP/price
- DO NOT generate ingredients
- DO NOT add any information not in the OCR text
- ONLY clean the text and find dates

DATE EXTRACTION RULES:
- Look for patterns like: DD/MM/YYYY, MM/YYYY, DD-MM-YYYY
- Keywords for expiry: EXP, EXPIRY, BEST BEFORE, USE BY, USE BEFORE
- Keywords for manufacturing: MFG, MFD, PKD, MANUFACTURED, PRODUCTION DATE
- Convert dates to YYYY-MM-DD format if possible
- If month/year only, use YYYY-MM format
- If you cannot find a date, return empty string ""

EXAMPLE INPUT:
"""
PARACETAMOL 500MG
MFG: 05/2023
EXP: 04/2025
BATCH: ABC123
MRP: Rs. 50
"""

EXAMPLE OUTPUT:
{
  "raw_text": "PARACETAMOL 500MG\nMFG: 05/2023\nEXP: 04/2025\nBATCH: ABC123\nMRP: Rs. 50",
  "mfg_date": "2023-05",
  "expiry": "2025-04",
  "name": "",
  "brand": "",
  "batch": "",
  "mrp": "",
  "ingredients": "",
  "extraData": {}
}

RETURN ONLY JSON. NO OTHER TEXT.''';

        final userContent = <Map<String, dynamic>>[
          {
            'type': 'text',
            'text':
                'OCR TEXT TO CLEAN:\n"""${rawText ?? ""}"""\n\nYOUR TASK:\n1. Clean this OCR text (fix spacing, remove noise)\n2. Extract ONLY expiry date and manufacturing date\n3. DO NOT generate any other fields\n4. Return cleaned text in "raw_text" field\n5. Return dates in "expiry" and "mfg_date" fields\n\nReturn ONLY the JSON object.',
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
                'User-Agent': 'ExpiryTrackerApp/1.0',
              },
              body: jsonEncode({
                'model': ConfigService.oxloVisionModel,
                'messages': [
                  {'role': 'system', 'content': systemPrompt},
                  {'role': 'user', 'content': userContent},
                ],
                'max_tokens': 1024,
                'temperature': 0.0, // Zero temperature for no creativity/hallucination
              }),
            )
            .timeout(ConfigService.apiTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiText =
              data['choices']?[0]?['message']?['content']?.toString() ?? '';

          if (aiText.isNotEmpty) {
            LoggerService.success('AI_PROCESS', 'Groq AI (Llama 3.2) response received');
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

            // ONLY return cleaned text and dates - nothing else
            return {
              "raw_text": result['raw_text'] ?? rawText ?? "",
              "expiry": result['expiry'] ?? "",
              "mfg_date": result['mfg_date'] ?? "",
              // All other fields empty - let local parser handle them
              "brand": "",
              "name": "",
              "manufacturer": "",
              "mrp": "",
              "batch": "",
              "ingredients": "",
              "quantity": "",
              "category": "",
              "dosage": "",
              "warnings": "",
              "extraData": "{}",
            };
          }
        } else {
          LoggerService.error(
            'AI_PROCESS',
            'Groq API HTTP Error: ${response.statusCode} - ${response.body}',
          );
          print(
              "[AI_DEBUG] HTTP Error: ${response.statusCode} - ${response.body}");
        }
      } on SocketException catch (e) {
        LoggerService.error(
          'AI_PROCESS',
          'Connection error (attempt $attempt): $e',
        );
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      } on HttpException catch (e) {
        LoggerService.error(
          'AI_PROCESS',
          'HTTP error (attempt $attempt): $e',
        );
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      } catch (e) {
        LoggerService.error('AI_PROCESS', 'Groq API Error: $e');
        print("[AI_DEBUG] Exception Details: $e");
        if (attempt < maxRetries && e.toString().contains('connection')) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        break;
      }
    }

    return _emptyResult();
  }

  /// Extract structured data from OCR text only (no image)
  /// Uses Groq Llama 3.3 70B for text extraction
  Future<Map<String, dynamic>> extractFromText({
    required String ocrText,
    String? barcode,
  }) async {
    LoggerService.start('AI_PROCESS', 'Initializing Groq AI Text Extraction (Llama 3.3 70B)');

    final apiKey = ConfigService.oxloApiKey;

    if (apiKey.isEmpty) {
      LoggerService.error('AI_PROCESS', 'Groq API Key is empty!');
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
          LoggerService.success('AI_PROCESS', 'Groq AI text extraction received');
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
          'Groq API HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      LoggerService.error('AI_PROCESS', 'Groq API Text Error: $e');
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
      "method": "Groq AI (Llama 3.2 Vision)",
      "fields_found": count,
      "has_extra": data['extraData'] != "{}",
    };
  }
}
