import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product_info.dart';
import '../core/services/logger_service.dart';

class ProductApiService {
  static const String _openFoodFactsUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const String _upcItemDbUrl = 'https://api.upcitemdb.com/prod/trial/lookup';
  static const int _timeoutSeconds = 15;

  /// Main product lookup method with fallback chain
  static Future<ProductInfo?> lookupProduct(String barcode) async {
    LoggerService.start('PRODUCT_API', 'Looking up product: $barcode');

    try {
      // Step 1: Try Open Food Facts API
      final openFoodFactsResult = await _lookupOpenFoodFacts(barcode);
      if (openFoodFactsResult != null) {
        LoggerService.success('PRODUCT_API', 'Found via Open Food Facts');
        return openFoodFactsResult;
      }

      // Step 2: Try UPC ItemDB API
      final upcItemDbResult = await _lookupUPCItemDb(barcode);
      if (upcItemDbResult != null) {
        LoggerService.success('PRODUCT_API', 'Found via UPC ItemDB');
        return upcItemDbResult;
      }

      LoggerService.warning('PRODUCT_API', 'Product not found in any database');
      return null;
    } catch (e) {
      LoggerService.error('PRODUCT_API', 'Lookup failed: $e');
      return null;
    }
  }

  /// Open Food Facts API lookup
  static Future<ProductInfo?> _lookupOpenFoodFacts(String barcode) async {
    try {
      final url = Uri.parse('$_openFoodFactsUrl/$barcode.json');
      final response = await http.get(url).timeout(
        Duration(seconds: _timeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          return ProductInfo(
            name: product['product_name']?.toString().trim(),
            brand: product['brands']?.toString().trim(),
            category: product['categories']?.toString().trim(),
            ingredients: product['ingredients_text']?.toString().trim(),
            imageUrl: product['image_url']?.toString().trim(),
            quantity: product['quantity']?.toString().trim(),
            packaging: product['packaging']?.toString().trim(),
            origins: product['origins']?.toString().trim(),
            stores: product['stores']?.toString().trim(),
            countries: product['countries']?.toString().trim(),
            barcode: barcode,
            nutritionInfo: product['nutriments']?.toString(),
            source: 'open_food_facts',
          );
        }
      }
    } catch (e) {
      LoggerService.error('OPEN_FOOD_FACTS', 'API error: $e');
    }
    return null;
  }

  /// UPC ItemDB API lookup
  static Future<ProductInfo?> _lookupUPCItemDb(String barcode) async {
    try {
      final url = Uri.parse('$_upcItemDbUrl?upc=$barcode');
      final response = await http.get(url).timeout(
        Duration(seconds: _timeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['total'] > 0 && data['items']?.isNotEmpty == true) {
          final item = data['items'][0];
          return ProductInfo(
            name: item['title']?.toString().trim(),
            brand: item['brand']?.toString().trim(),
            category: item['category']?.toString().trim(),
            imageUrl: item['image']?.toString().trim(),
            barcode: barcode,
            quantity: item['size']?.toString().trim(),
            source: 'upc_itemdb',
          );
        }
      }
    } catch (e) {
      LoggerService.error('UPC_ITEMDB', 'API error: $e');
    }
    return null;
  }

  /// Check if APIs are available
  static Future<bool> checkApiAvailability() async {
    try {
      final testUrl = Uri.parse('$_openFoodFactsUrl/0.json');
      final response = await http.get(testUrl).timeout(
        Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('API_CHECK', 'API availability check failed: $e');
      return false;
    }
  }

  /// Format nutrition information for display
  static String formatNutritionInfo(dynamic nutritionData) {
    if (nutritionData == null || nutritionData is! Map) {
      return 'No nutrition information available';
    }

    final nutrients = nutritionData as Map<String, dynamic>;
    final buffer = StringBuffer();

    nutrients.forEach((key, value) {
      if (value != null) {
        buffer.writeln('${key.toString().replaceAll('_', ' ').toUpperCase()}: $value');
      }
    });

    return buffer.toString().trim();
  }
}
