import 'dart:convert';
import 'package:http/http.dart' as http;

/// API-Powered Product Information Service
class ProductApiService {
  // Open Food Facts API (Free)
  static Future<Map<String, dynamic>> fetchFromOpenFoodFacts(
    String barcode,
  ) async {
    try {
      final url =
          'https://world.openfoodfacts.org/api/v0/product/$barcode.json';
      print('=== OPEN FOOD FACTS API ===');
      print('URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'ExpiryTrackerApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 15));

      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];

          return {
            'success': true,
            'name': product['product_name'] ?? 'Unknown Product',
            'brand': product['brands'] ?? '',
            'category': product['categories'] ?? 'product',
            'ingredients': product['ingredients_text'] ?? '',
            'quantity':
                product['quantity'] ?? product['product_quantity'] ?? '',
            'expiryDate': _extractExpiryFromProduct(product),
            'mfgDate': _extractMfgFromProduct(product),
            'isMedicine': false,
            'confidence': 0.9,
            'source': 'Open Food Facts',
            'raw_data': product,
          };
        }
      }

      return {};
    } catch (e) {
      print('Open Food Facts API error: $e');
      return {};
    }
  }

  // FDA Drug Database API (Free)
  static Future<Map<String, dynamic>> fetchFromFDA(String searchTerm) async {
    try {
      // Try different search strategies
      List<String> searchUrls = [
        'https://api.fda.gov/drug/label.json?search=openfda.product_ndc:$searchTerm',
        'https://api.fda.gov/drug/label.json?search=openfda.brand_name:$searchTerm',
        'https://api.fda.gov/drug/label.json?search=openfda.generic_name:$searchTerm',
      ];

      for (String url in searchUrls) {
        print('=== FDA API ===');
        print('URL: $url');

        final response = await http
            .get(Uri.parse(url), headers: {'Content-Type': 'application/json'})
            .timeout(const Duration(seconds: 10));

        print('Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['meta']['results']['total'] > 0 && data['results'] != null) {
            final drug = data['results'][0];

            return {
              'success': true,
              'name':
                  drug['openfda']['brand_name']?[0] ??
                  drug['openfda']['generic_name']?[0] ??
                  drug['openfda']['substance_name']?[0] ??
                  'Unknown Medicine',
              'brand': drug['openfda']['manufacturer_name']?[0] ?? '',
              'category': 'medicine',
              'ingredients':
                  drug['active_ingredient']?.join(', ') ??
                  drug['inactive_ingredient']?.join(', ') ??
                  '',
              'dosage': drug['dosage_and_administration'] ?? '',
              'uses':
                  drug['indications_and_usage'] ??
                  drug['purpose']?.join(', ') ??
                  '',
              'warnings': drug['warnings']?.join(', ') ?? '',
              'isMedicine': true,
              'confidence': 0.9,
              'source': 'FDA Drug Database',
              'raw_data': drug,
            };
          }
        }
      }

      return {};
    } catch (e) {
      print('FDA API error: $e');
      return {};
    }
  }

  // UPCItemDB API (Free Trial)
  static Future<Map<String, dynamic>> fetchFromUPCItemDB(String barcode) async {
    try {
      final url = 'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode';
      print('=== UPCITEMDB API ===');
      print('URL: $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'User-Agent': 'ExpiryTrackerApp/1.0',
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['items'] != null && data['items'].isNotEmpty) {
          final item = data['items'][0];

          return {
            'success': true,
            'name': item['title'] ?? 'Unknown Product',
            'brand': item['brand'] ?? '',
            'category': item['category'] ?? 'product',
            'ingredients': item['description'] ?? '',
            'quantity': item['size'] ?? item['weight'] ?? '',
            'isMedicine': false,
            'confidence': 0.8,
            'source': 'UPCItemDB',
            'raw_data': item,
          };
        }
      }

      return {};
    } catch (e) {
      print('UPCItemDB API error: $e');
      return {};
    }
  }

  // Barcode Spider API (Alternative)
  static Future<Map<String, dynamic>> fetchFromBarcodeSpider(
    String barcode,
  ) async {
    try {
      final url =
          'https://api.barcodespider.com/v1/api?apikey=YOUR_API_KEY&barcode=$barcode';
      print('=== BARCODE SPIDER API ===');
      print('Note: Requires API key');

      // This is a placeholder - user needs to add their API key
      return {};
    } catch (e) {
      print('Barcode Spider API error: $e');
      return {};
    }
  }

  // Smart Product Lookup (Combines multiple sources)
  static Future<Map<String, dynamic>> smartProductLookup(String query) async {
    print('=== SMART PRODUCT LOOKUP ===');
    print('Query: $query');

    // Try barcode first
    if (RegExp(r'^\d{8,13}$').hasMatch(query)) {
      print('Detected barcode, trying barcode APIs...');

      final openFoodResult = await fetchFromOpenFoodFacts(query);
      if (openFoodResult.isNotEmpty) {
        print('Open Food Facts success!');
        return openFoodResult;
      }

      final upcResult = await fetchFromUPCItemDB(query);
      if (upcResult.isNotEmpty) {
        print('UPCItemDB success!');
        return upcResult;
      }
    }

    // Try text-based lookup for medicines
    final medicineResult = await fetchFromFDA(query);
    if (medicineResult.isNotEmpty) {
      print('FDA medicine lookup success!');
      return medicineResult;
    }

    print('No API results found');
    return {};
  }

  // Extract expiry date from product data
  static String _extractExpiryFromProduct(Map<String, dynamic> product) {
    // Look for expiry information in various fields
    List<String> expiryFields = [
      'expiry_date',
      'expiration_date',
      'best_before',
      'use_by',
    ];

    for (String field in expiryFields) {
      if (product[field] != null) {
        String date = product[field].toString();
        if (RegExp(r'\d{2}[/]\d{2,4}').hasMatch(date)) {
          return date;
        }
      }
    }

    return '';
  }

  static String _extractMfgFromProduct(Map<String, dynamic> product) {
    List<String> mfgFields = [
      'manufacturing_date',
      'mfg_date',
      'production_date',
      'packed_date',
    ];

    for (String field in mfgFields) {
      if (product[field] != null) {
        String date = product[field].toString();
        if (date.isNotEmpty) {
          return date;
        }
      }
    }

    return '';
  }

  // Enhanced OCR with API Enhancement
  static Future<Map<String, dynamic>> enhanceOCRWithAPI(
    Map<String, dynamic> ocrResult,
    String? barcode,
  ) async {
    print('=== API-ENHANCED OCR ===');

    Map<String, dynamic> enhancedResult = Map<String, dynamic>.from(ocrResult);

    // If we have a barcode, try to get API data
    if (barcode != null && barcode.isNotEmpty) {
      final apiData = await smartProductLookup(barcode);

      if (apiData.isNotEmpty) {
        print('API data found, enhancing OCR result...');

        // Merge API data with OCR data
        enhancedResult['parsed_data'] = _mergeOCRWithAPI(
          enhancedResult['parsed_data'] ?? {},
          apiData,
        );
        enhancedResult['api_enhanced'] = true;
        enhancedResult['api_source'] = apiData['source'];
        enhancedResult['confidence'] = 0.95; // High confidence with API data

        return enhancedResult;
      }
    }

    // Try to find barcode in OCR text
    String ocrText = ocrResult['text'] ?? '';
    RegExp barcodePattern = RegExp(r'\d{8,13}');
    Match? barcodeMatch = barcodePattern.firstMatch(ocrText);

    if (barcodeMatch != null) {
      String foundBarcode = barcodeMatch.group(0)!;
      print('Found barcode in OCR: $foundBarcode');

      final apiData = await smartProductLookup(foundBarcode);

      if (apiData.isNotEmpty) {
        print('API data found for OCR barcode, enhancing result...');

        enhancedResult['parsed_data'] = _mergeOCRWithAPI(
          enhancedResult['parsed_data'] ?? {},
          apiData,
        );
        enhancedResult['api_enhanced'] = true;
        enhancedResult['api_source'] = apiData['source'];
        enhancedResult['confidence'] = 0.95;
        enhancedResult['barcode'] = foundBarcode;

        return enhancedResult;
      }
    }

    // Try text-based lookup with product name
    Map<String, dynamic> parsedData = enhancedResult['parsed_data'] ?? {};
    String productName = parsedData['name'] ?? '';

    if (productName.isNotEmpty && productName != 'Unknown') {
      final apiData = await smartProductLookup(productName);

      if (apiData.isNotEmpty) {
        print('API data found for product name, enhancing result...');

        enhancedResult['parsed_data'] = _mergeOCRWithAPI(parsedData, apiData);
        enhancedResult['api_enhanced'] = true;
        enhancedResult['api_source'] = apiData['source'];
        enhancedResult['confidence'] = 0.90;

        return enhancedResult;
      }
    }

    print('No API enhancement possible');
    return enhancedResult;
  }

  // Merge OCR data with API data
  static Map<String, dynamic> _mergeOCRWithAPI(
    Map<String, dynamic> ocrData,
    Map<String, dynamic> apiData,
  ) {
    print('=== MERGING OCR WITH API DATA ===');
    print('OCR: $ocrData');
    print('API: $apiData');

    Map<String, dynamic> merged = Map<String, dynamic>.from(ocrData);

    // API data takes priority for most fields
    List<String> apiPriorityFields = [
      'name',
      'brand',
      'category',
      'ingredients',
      'dosage',
      'uses',
      'warnings',
      'isMedicine',
    ];

    for (String field in apiPriorityFields) {
      if (apiData[field] != null && apiData[field].toString().isNotEmpty) {
        merged[field] = apiData[field];
        print('Merged $field: ${apiData[field]}');
      }
    }

    // Keep OCR data for dates if API doesn't have it
    if (apiData['expiryDate'] == null && ocrData['expiryDate'] != null) {
      merged['expiryDate'] = ocrData['expiryDate'];
    }

    if (apiData['mfgDate'] == null && ocrData['mfgDate'] != null) {
      merged['mfgDate'] = ocrData['mfgDate'];
    }

    if (apiData['batchNumber'] == null && ocrData['batchNumber'] != null) {
      merged['batchNumber'] = ocrData['batchNumber'];
    }

    // Add API source information
    merged['api_source'] = apiData['source'];
    merged['api_confidence'] = apiData['confidence'];

    print('Merged result: $merged');
    return merged;
  }
}
