import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'logger_service.dart';

class AIService {
  /// Standardized extraction method for both products and medicines
  /// Uses Oxlo.ai OpenAI-compatible Vision API with retry logic
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

    // Retry logic for connection issues
    int maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        LoggerService.info(
          'AI_PROCESS',
          'Attempt $attempt of $maxRetries',
        );

        final imageBytes = await File(imagePath).readAsBytes();
        final base64Image = base64Encode(imageBytes);

        final systemPrompt = '''### ROLE
You are an expert AI for extracting product information from Indian product and medicine labels with 99% accuracy. Your job is to INTELLIGENTLY map text from the image to the correct form fields.

### TASK
Analyze the image and extract structured information. Use your AI intelligence to identify which text belongs to which field and populate the form correctly.

### INTELLIGENT FIELD MAPPING RULES

#### 1. PRODUCT NAME (name field)
- **What to look for**: The LARGEST, most prominent text on the label
- **Usually**: First line, bold text, brand name + product type
- **Examples**: 
  - "Crocin 500mg" ✅
  - "Parle-G Gold Biscuits" ✅
  - "Himalaya Face Wash" ✅
  - "Dolo 650 Tablet" ✅
- **NOT**: Manufacturer name, batch number, dates, prices
- **Field**: `name`

#### 2. BRAND/MANUFACTURER (brand field)
- **What to look for**: Company name, often with "Pvt Ltd", "LLP", "Laboratories"
- **Keywords**: "Manufactured by", "Marketed by", "Made by", "Mfg by"
- **Examples**:
  - "GSK Pharmaceuticals Ltd" ✅
  - "Parle Products Pvt Ltd" ✅
  - "Himalaya Drug Company" ✅
- **Extract**: Just the company name without "Manufactured by" prefix
- **Field**: `brand`

#### 3. EXPIRY DATE (expiry field)
- **What to look for**: Date near "EXP", "EXPIRY", "BEST BEFORE", "USE BY", "USE BEFORE"
- **Common formats on Indian labels**:
  - **DDMMMYY**: "04APR26", "03AUG26", "15DEC25" (MOST COMMON)
  - **DD/MM/YYYY**: "04/04/2026", "15/12/2025"
  - **MM/YYYY**: "04/2026", "12/2025"
  - **DD-MM-YYYY**: "04-04-2026"
- **CRITICAL**: Extract EXACTLY as written, don't convert format
- **Examples**:
  - See "EXP: 04APR26" → Extract "04APR26" ✅
  - See "Best Before: 04/2026" → Extract "04/2026" ✅
  - See "Use By: 15/12/2025" → Extract "15/12/2025" ✅
- **Field**: `expiry`

#### 4. MANUFACTURING DATE (mfg_date field)
- **What to look for**: Date near "MFG", "MFD", "PKD", "MANUFACTURED ON", "PACKED ON"
- **Same formats as expiry date**
- **Examples**:
  - See "MFG: 04JAN26" → Extract "04JAN26" ✅
  - See "PKD: 01/2026" → Extract "01/2026" ✅
- **Field**: `mfg_date`

#### 5. BATCH NUMBER (batch field)
- **What to look for**: Alphanumeric code near "BATCH", "B.No", "LOT", "L.No"
- **Examples**:
  - "Batch No: B123" → Extract "B123" ✅
  - "LOT: GC/1301" → Extract "GC/1301" ✅
  - "B.No: 004J25" → Extract "004J25" ✅
- **Field**: `batch`

#### 6. INGREDIENTS/COMPOSITION (ingredients field)
- **What to look for**: Text after "INGREDIENTS", "COMPOSITION", "CONTAINS", "ACTIVE INGREDIENTS"
- **For medicines**: Active pharmaceutical ingredients with strength
- **For products**: List of ingredients
- **Examples**:
  - "Paracetamol 500mg" ✅
  - "Wheat Flour, Sugar, Salt" ✅
- **Field**: `ingredients`

#### 7. DOSAGE (dosage field - MEDICINES ONLY)
- **What to look for**: Strength/dosage information
- **Examples**:
  - "500mg" ✅
  - "650mg per tablet" ✅
  - "10ml twice daily" ✅
- **Field**: `dosage` (in extraData)

#### 8. WARNINGS (warnings field - MEDICINES ONLY)
- **What to look for**: Text after "WARNING", "CAUTION", "SIDE EFFECTS", "PRECAUTIONS"
- **Examples**:
  - "Do not exceed recommended dose" ✅
  - "May cause drowsiness" ✅
- **Field**: `warnings` (in extraData)

#### 9. USES (uses field - MEDICINES ONLY)
- **What to look for**: Text after "USES", "INDICATIONS", "FOR", "TREATS"
- **Examples**:
  - "For fever and pain relief" ✅
  - "Treats cold and flu symptoms" ✅
- **Field**: `uses` (in extraData)

#### 10. CATEGORY DETECTION (category field)
- **Medicine indicators**: tablet, capsule, syrup, injection, medicine, drug, pharmaceutical, dosage, prescription
- **Product indicators**: food, beverage, cosmetic, personal care, household
- **Auto-detect**: Based on visible text and context
- **Field**: `category` (in extraData)

### SMART CONTEXT AWARENESS
Use your AI intelligence to understand relationships:
- Text NEAR "EXP" → Expiry date
- Text NEAR "MFG" → Manufacturing date  
- LARGEST text → Product name
- Text with "Ltd"/"Pvt" → Brand/Manufacturer
- Numbers with "Rs"/"₹" → Price (MRP)
- Text after "Batch" → Batch number
- Text after "Ingredients" → Ingredients list

### DATE FORMAT INTELLIGENCE
**CRITICAL FOR INDIAN PRODUCTS**:
- "04APR26" means April 4, 2026 (DD-MMM-YY format)
- "03AUG26" means August 3, 2026
- "15DEC25" means December 15, 2025
- **DO NOT CONVERT** - Extract exactly as written!

### OUTPUT FORMAT (STRICT JSON)
Return ONLY this JSON structure, nothing else:

{
  "name": "product name (largest/prominent text)",
  "brand": "brand/manufacturer name (company with Ltd/Pvt)",
  "manufacturer": "full manufacturer name",
  "mrp": "price with currency (if visible)",
  "batch": "batch/lot number",
  "expiry": "expiry date EXACTLY as written",
  "mfg_date": "manufacturing date EXACTLY as written",
  "ingredients": "ingredients or composition",
  "quantity": "net weight/quantity with unit",
  "extraData": {
    "category": "medicine or product",
    "dosage": "dosage (medicines only)",
    "warnings": "warnings (medicines only)",
    "uses": "uses/indications (medicines only)"
  }
}

### FIELD MAPPING EXAMPLES

**Example 1: Medicine Label**
Image shows:
```
CROCIN 500
GSK Pharmaceuticals Ltd
Paracetamol 500mg
EXP: 04APR26
MFG: 04JAN26
Batch: B123
For fever and pain relief
```

Correct mapping:
```json
{
  "name": "CROCIN 500",
  "brand": "GSK Pharmaceuticals Ltd",
  "expiry": "04APR26",
  "mfg_date": "04JAN26",
  "batch": "B123",
  "ingredients": "Paracetamol 500mg",
  "extraData": {
    "category": "medicine",
    "dosage": "500mg",
    "uses": "For fever and pain relief"
  }
}
```

**Example 2: Product Label**
Image shows:
```
Parle-G Gold
Parle Products Pvt Ltd
Best Before: 12/2026
Ingredients: Wheat Flour, Sugar
Net Wt: 200g
```

Correct mapping:
```json
{
  "name": "Parle-G Gold",
  "brand": "Parle Products Pvt Ltd",
  "expiry": "12/2026",
  "ingredients": "Wheat Flour, Sugar",
  "quantity": "200g",
  "extraData": {
    "category": "product"
  }
}
```

### IMPORTANT RULES
1. ✅ Extract dates in ORIGINAL format (don't convert "04APR26")
2. ✅ Use AI intelligence to map text to correct fields
3. ✅ Return empty string "" only if field is truly not visible
4. ✅ Understand context (text near keywords belongs to that field)
5. ✅ Return ONLY valid JSON, no explanations, no markdown
6. ✅ Be smart about which text goes in which field

Your goal: Make the form auto-fill PERFECTLY so users don't need to edit anything!''';

        final userContent = <Map<String, dynamic>>[
          {
            'type': 'text',
            'text':
                'Analyze this product/medicine label image and extract ALL visible information. Use your intelligence to identify which text belongs to which field (name, brand, dates, etc). OCR Hint: ${rawText ?? 'No hint'}. Barcode: ${barcode ?? 'None'}. Return ONLY the JSON object.',
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

            // Extract extraData fields if present
            final extraData = result['extraData'] as Map<String, dynamic>? ?? {};
            
            return {
              "brand": result['brand'] ?? "",
              "name": result['name'] ?? "",
              "manufacturer": result['manufacturer'] ?? "",
              "mrp": result['mrp'] ?? "",
              "batch": result['batch'] ?? "",
              "expiry": result['expiry'] ?? "",
              "mfg_date": result['mfg_date'] ?? "",
              "ingredients": result['ingredients'] ?? "",
              "quantity": result['quantity'] ?? "",
              "category": extraData['category'] ?? "",
              "dosage": extraData['dosage'] ?? "",
              "warnings": extraData['warnings'] ?? "",
              "extraData": jsonEncode(extraData),
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
        LoggerService.error('AI_PROCESS', 'Oxlo.ai Error: $e');
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
