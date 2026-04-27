import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:expiry_tracker_app/core/services/product_api_service.dart';
import 'package:expiry_tracker_app/core/services/ai_service.dart';
import 'package:expiry_tracker_app/core/services/config_service.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// Enhanced Barcode Service for scanning and extracting product information
class BarcodeService {
  static const String _openFoodFactsUrl = 'https://world.openfoodfacts.org/api/v0/product/';
  static const String _upcDatabaseUrl = 'https://api.upcdatabase.org/product/';

  /// Scan barcode from image using ML Kit
  static Future<String?> scanBarcodeFromImage(String imagePath) async {
    // This would integrate with ML Kit barcode scanning
    // For now, return null - the mobile_scanner package handles this
    return null;
  }

  /// Extract product information from barcode using enhanced API service
  /// Falls back to Oxlo.ai when product APIs don't find the barcode
  static Future<Map<String, dynamic>> getProductInfo(String barcode) async {
    try {
      print('=== ENHANCED BARCODE SERVICE: Fetching info for $barcode ===');
      
      // Use the new API-powered service
      final result = await ProductApiService.smartProductLookup(barcode);
      
      if (result.isNotEmpty) {
        print('=== BARCODE SERVICE: API success ===');
        return result;
      }
      
      // Fallback: Use Oxlo.ai to look up barcode info
      print('=== BARCODE SERVICE: No API data, trying Oxlo.ai fallback ===');
      final aiResult = await _lookupBarcodeWithAI(barcode);
      if (aiResult.isNotEmpty) {
        return aiResult;
      }
      
      // Return basic info if all methods fail
      print('=== BARCODE SERVICE: No data found, using basic info ===');
      return _createBasicBarcodeInfo(barcode);
      
    } catch (e) {
      print('=== BARCODE SERVICE: Error - $e ===');
      return _createBasicBarcodeInfo(barcode);
    }
  }

  /// Use Oxlo.ai to identify product from barcode number with retry logic
  static Future<Map<String, dynamic>> _lookupBarcodeWithAI(String barcode) async {
    final apiKey = ConfigService.oxloApiKey;
    if (apiKey.isEmpty) return {};

    int maxRetries = 3;
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        LoggerService.info('BARCODE', 'Oxlo.ai lookup attempt $attempt of $maxRetries');

        final prompt = '''Identify the product associated with this barcode number: $barcode

Return ONLY valid JSON with these fields:
{
  "name": "product name",
  "brand": "brand/manufacturer",
  "category": "medicine/food/product/cosmetic",
  "ingredients": "key ingredients if known",
  "isMedicine": true/false,
  "confidence": 0.0-1.0,
  "notes": "any additional info"
}

If you cannot identify the product, return {"name": "", "confidence": 0.0}.
Return ONLY JSON, no explanations.''';

        final response = await http
            .post(
              Uri.parse('${ConfigService.oxloBaseUrl}/chat/completions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $apiKey',
                'User-Agent': 'ExpiryTrackerApp/1.0',
              },
              body: jsonEncode({
                'model': ConfigService.oxloTextModel,
                'messages': [
                  {'role': 'user', 'content': prompt},
                ],
                'max_tokens': 512,
                'temperature': 0.1,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final aiText =
              data['choices']?[0]?['message']?['content']?.toString() ?? '';

          if (aiText.isNotEmpty) {
            String cleanJson = aiText
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();

            if (cleanJson.contains('{')) {
              cleanJson = cleanJson.substring(cleanJson.indexOf('{'));
              if (cleanJson.contains('}')) {
                cleanJson = cleanJson.substring(0, cleanJson.lastIndexOf('}') + 1);
              }
            }

            final Map<String, dynamic> result = jsonDecode(cleanJson);
            final name = result['name']?.toString() ?? '';
            final confidence = _parseConfidence(result['confidence']);

            if (name.isNotEmpty && confidence > 0.3) {
              LoggerService.success('BARCODE', 'Oxlo.ai identified barcode product: $name');
              return {
                'success': true,
                'name': name,
                'brand': result['brand']?.toString() ?? '',
                'category': result['category']?.toString() ?? 'product',
                'ingredients': result['ingredients']?.toString() ?? '',
                'isMedicine': result['isMedicine'] == true,
                'confidence': confidence,
                'source': 'Oxlo.ai (AI Lookup)',
                'barcode': barcode,
              };
            }
          }
        }
      } on SocketException catch (e) {
        LoggerService.warning('BARCODE', 'Connection error (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      } on HttpException catch (e) {
        LoggerService.warning('BARCODE', 'HTTP error (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
      } catch (e) {
        LoggerService.warning('BARCODE', 'Oxlo.ai barcode lookup failed: $e');
        if (attempt < maxRetries && e.toString().contains('connection')) {
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        break;
      }
    }
    
    return {};
  }

  static double _parseConfidence(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is int) return value.toDouble().clamp(0.0, 1.0);
    final num = double.tryParse(value.toString());
    return num?.clamp(0.0, 1.0) ?? 0.0;
  }

  /// Fetch from Open Food Facts API
  static Future<Map<String, dynamic>> _fetchFromOpenFoodFacts(String barcode) async {
    try {
      final url = '$_openFoodFactsUrl$barcode.json';
      print('=== OPEN FOOD FACTS API CALL ===');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'ExpiryTrackerApp/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Data Status: ${data['status']}');
        print('Has Product: ${data['product'] != null}');
        
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          print('Product Name: ${product['product_name']}');
          print('Brand: ${product['brands']}');
          
          return {
            'success': true,
            'name': product['product_name'] ?? 'Unknown Product',
            'brand': product['brands'] ?? '',
            'category': _detectCategory(product),
            'ingredients': product['ingredients_text'] ?? '',
            'expiryDate': _extractExpiryDate(product),
            'mfgDate': _extractMfgDate(product),
            'isMedicine': _isMedicine(product),
            'confidence': 0.9,
            'source': 'Open Food Facts',
            'raw_data': product,
          };
        } else {
          print('Product not found in Open Food Facts');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
      
      return {};
    } catch (e) {
      print('Open Food Facts API error: $e');
      return {};
    }
  }

  /// Fetch from UPC Database API
  static Future<Map<String, dynamic>> _fetchFromUPCDatabase(String barcode) async {
    try {
      final url = '$_upcDatabaseUrl$barcode';
      print('=== UPC DATABASE API CALL ===');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));
      
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Description: ${data['description']}');
        print('Brand: ${data['brand']}');
        
        return {
          'success': true,
          'name': data['description'] ?? 'Unknown Product',
          'brand': data['brand'] ?? '',
          'category': 'product',
          'isMedicine': false,
          'confidence': 0.7,
          'source': 'UPC Database',
          'raw_data': data,
        };
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
      
      return {};
    } catch (e) {
      print('UPC Database API error: $e');
      return {};
    }
  }

  /// Fetch from FDA Drug Database API (for medicines)
  static Future<Map<String, dynamic>> _fetchFromFDADatabase(String barcode) async {
    try {
      // Try different NDC formats for medicine barcodes
      List<String> searchTerms = [
        'openfda.product_ndc:$barcode',
        'openfda.product_ndc:${barcode.substring(0, barcode.length - 1)}', // Remove check digit
        'openfda.product_type.human_drug:$barcode',
        'openfda.substance_name:$barcode',
      ];
      
      for (String searchTerm in searchTerms) {
        final url = 'https://api.fda.gov/drug/label.json?search=$searchTerm&limit=1';
        print('=== FDA DRUG DATABASE API CALL ===');
        print('URL: $url');
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));
        
        print('Status Code: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Total results: ${data['meta']['results']['total']}');
          
          if (data['meta']['results']['total'] > 0 && data['results'] != null && data['results'].isNotEmpty) {
            final drug = data['results'][0];
            final name = drug['openfda']['brand_name']?[0] ?? 
                       drug['openfda']['generic_name']?[0] ?? 
                       drug['openfda']['substance_name']?[0] ?? 'Unknown Medicine';
            final manufacturer = drug['openfda']['manufacturer_name']?[0] ?? '';
            final purpose = drug['purpose']?.join(', ') ?? drug['indications_and_usage'] ?? '';
            final warnings = drug['warnings']?.join(', ') ?? drug['precautions'] ?? '';
            final dosage = drug['dosage_and_administration'] ?? '';
            
            print('FDA Database success - Name: $name, Manufacturer: $manufacturer');
            
            return {
              'success': true,
              'name': name,
              'brand': manufacturer,
              'category': 'medicine',
              'ingredients': purpose,
              'warnings': warnings,
              'dosage': dosage,
              'isMedicine': true,
              'confidence': 0.9,
              'source': 'FDA Drug Database',
              'raw_data': drug,
            };
          }
        }
      }
      
      print('Medicine not found in FDA Database');
      return {};
    } catch (e) {
      print('FDA Database API error: $e');
      return {};
    }
  }

  /// Fetch from Nutritionix API (for food products)
  static Future<Map<String, dynamic>> _fetchFromNutritionix(String barcode) async {
    try {
      final url = 'https://trackapi.nutritionix.com/v2/search/item?upc=$barcode';
      print('=== NUTRITIONIX API CALL ===');
      print('URL: $url');
      
      // Nutritionix requires app credentials - using demo for now
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-app-id': 'demo-app-id', // Replace with actual credentials
          'x-app-key': 'demo-app-key', // Replace with actual credentials
        },
      ).timeout(const Duration(seconds: 15));
      
      print('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['foods'] != null && data['foods'].isNotEmpty) {
          final food = data['foods'][0];
          final name = food['food_name'] ?? 'Unknown Product';
          final brand = food['brand_name'] ?? '';
          final ingredients = food['ingredients'] ?? '';
          
          print('Nutritionix success - Name: $name, Brand: $brand');
          
          return {
            'success': true,
            'name': name,
            'brand': brand,
            'category': 'food',
            'ingredients': ingredients,
            'isMedicine': false,
            'confidence': 0.8,
            'source': 'Nutritionix',
            'raw_data': food,
          };
        } else {
          print('Product not found in Nutritionix');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
      
      return {};
    } catch (e) {
      print('Nutritionix API error: $e');
      return {};
    }
  }

  /// Fetch from UPCItemDB API (free, no auth required)
  static Future<Map<String, dynamic>> _fetchFromUPCItemDB(String barcode) async {
    try {
      final url = 'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode';
      print('=== UPCITEMDB API CALL ===');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));
      
      print('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Total items: ${data['total']}');
        
        if (data['total'] > 0 && data['items'] != null && data['items'].isNotEmpty) {
          final item = data['items'][0];
          final name = item['title'] ?? 'Unknown Product';
          final brand = item['brand'] ?? '';
          final description = item['description'] ?? '';
          
          print('UPCItemDB success - Name: $name, Brand: $brand');
          
          return {
            'success': true,
            'name': name,
            'brand': brand,
            'category': 'product',
            'ingredients': description,
            'isMedicine': false,
            'confidence': 0.8,
            'source': 'UPCItemDB',
            'raw_data': item,
          };
        } else {
          print('Product not found in UPCItemDB');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Response: ${response.body}');
      }
      
      return {};
    } catch (e) {
      print('UPCItemDB API error: $e');
      return {};
    }
  }

  /// Simple Open Food Facts lookup without authentication
  static Future<Map<String, dynamic>> _fetchSimpleOpenFoodFacts(String barcode) async {
    try {
      final url = 'https://world.openfoodfacts.org/api/v0/product/$barcode.json';
      print('=== SIMPLE OPEN FOOD FACTS API CALL ===');
      print('URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));
      
      print('Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Status: ${data['status']}');
        print('Product found: ${data['product'] != null}');
        
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final name = product['product_name'] ?? 'Unknown Product';
          final brand = product['brands'] ?? '';
          
          print('Simple lookup success - Name: $name, Brand: $brand');
          
          return {
            'success': true,
            'name': name,
            'brand': brand,
            'category': _detectCategory(product),
            'ingredients': product['ingredients_text'] ?? '',
            'isMedicine': _isMedicine(product),
            'confidence': 0.8,
            'source': 'Open Food Facts (Simple)',
            'raw_data': product,
          };
        }
      }
      
      return {};
    } catch (e) {
      print('Simple Open Food Facts error: $e');
      return {};
    }
  }

  /// Create basic barcode info when APIs fail
  static Map<String, dynamic> _createBasicBarcodeInfo(String barcode) {
    print('=== CREATING BASIC BARCODE INFO ===');
    print('Barcode: $barcode');
    
    return {
      'success': true,
      'name': 'Product ($barcode)',
      'brand': 'Unknown Brand',
      'category': 'product',
      'isMedicine': false,
      'confidence': 0.4,
      'source': 'Barcode Scan',
      'barcode': barcode,
      'notes': 'Barcode scanned but no product database found. Manual entry required.',
    };
  }

  /// Detect product category from product data
  static String _detectCategory(Map<String, dynamic> product) {
    final categories = product['categories']?.toString().toLowerCase() ?? '';
    final name = product['product_name']?.toString().toLowerCase() ?? '';
    
    if (categories.contains('medicine') || categories.contains('drug') || 
        categories.contains('pharmaceutical') || name.contains('medicine') ||
        name.contains('tablet') || name.contains('capsule')) {
      return 'medicine';
    }
    
    if (categories.contains('food') || categories.contains('beverage')) {
      return 'food';
    }
    
    return 'product';
  }

  /// Extract expiry date from product data
  static String? _extractExpiryDate(Map<String, dynamic> product) {
    // Check various expiry date fields
    final expiryFields = [
      'expiration_date',
      'expiry_date', 
      'best_before',
      'use_by',
    ];
    
    for (final field in expiryFields) {
      if (product[field] != null && product[field].toString().isNotEmpty) {
        return product[field].toString();
      }
    }
    
    return null;
  }

  /// Extract manufacturing date from product data
  static String? _extractMfgDate(Map<String, dynamic> product) {
    // Check various manufacturing date fields
    final mfgFields = [
      'manufacturing_date',
      'mfg_date',
      'production_date',
    ];
    
    for (final field in mfgFields) {
      if (product[field] != null && product[field].toString().isNotEmpty) {
        return product[field].toString();
      }
    }
    
    return null;
  }

  /// Check if product is medicine
  static bool _isMedicine(Map<String, dynamic> product) {
    final categories = product['categories']?.toString().toLowerCase() ?? '';
    final name = product['product_name']?.toString().toLowerCase() ?? '';
    
    return categories.contains('medicine') || categories.contains('drug') || 
           categories.contains('pharmaceutical') || name.contains('medicine') ||
           name.contains('tablet') || name.contains('capsule');
  }
}
