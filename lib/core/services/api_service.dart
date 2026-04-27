import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'logger_service.dart';

/// API Service for FastAPI Backend Integration
/// Works alongside existing local database without breaking functionality
class ApiService {
  // Use different URLs for different platforms
  static String get _baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator to host
    } else {
      return 'http://localhost:8000'; // Default for web/desktop
    }
  }
  static const Duration _timeout = Duration(seconds: 15); // Increased timeout

  /// Process data through backend (validation + fallback extraction)
  static Future<Map<String, dynamic>> processData({
    required String rawText,
    String? barcode,
    String? category,
    Map<String, dynamic>? geminiData,
  }) async {
    try {
      LoggerService.start('API_PROCESS', 'Sending data to backend for processing');
      LoggerService.info('API_PROCESS', 'Using backend URL: $_baseUrl');
      LoggerService.info('API_PROCESS', 'Request data: category=$category, barcode=$barcode, hasGeminiData=${geminiData != null}');
      
      final requestBody = {
        'raw_text': rawText,
        'barcode': barcode,
        'category': category,
        'gemini_data': geminiData, // Send Gemini data if available
      };
      
      LoggerService.debug('API_PROCESS', 'Request body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/process'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(_timeout);

      LoggerService.info('API_PROCESS', 'Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        LoggerService.debug('API_PROCESS', 'Response body: ${jsonEncode(responseData)}');
        
        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          LoggerService.success('API_PROCESS', 'Backend processing successful: ${data['name'] ?? 'Unknown'}');
          return data;
        } else {
          LoggerService.warning('API_PROCESS', 'Backend processing failed: ${responseData['message']}');
          return {};
        }
      } else {
        LoggerService.error('API_PROCESS', 'HTTP Error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      LoggerService.error('API_PROCESS', 'API call failed: $e');
      LoggerService.info('API_PROCESS', 'Falling back to Gemini data due to backend failure');
      return {}; // Return empty data to trigger fallback
    }
  }

  /// Sync item to backend database
  static Future<bool> syncItem({
    required String name,
    required String category,
    String? brand,
    String? dosage,
    String? doctorName,
    String? symptoms,
    String? prescriptionImage,
    String? barcode,
    String? mrp,
    String? batch,
    String? manufacturer,
    String? extraData,
  }) async {
    try {
      LoggerService.start('API_SYNC', 'Syncing item to backend: $name');
      
      final requestBody = {
        'name': name,
        'category': category,
        'brand': brand,
        'dosage': dosage,
        'doctor_name': doctorName,
        'symptoms': symptoms,
        'prescription_image': prescriptionImage,
        'barcode': barcode,
        'mrp': mrp,
        'batch': batch,
        'manufacturer': manufacturer,
        'extra_data': extraData,
      };
      
      LoggerService.debug('API_SYNC', 'Sync request: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(_timeout);

      LoggerService.info('API_SYNC', 'Sync response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.debug('API_SYNC', 'Sync response body: ${jsonEncode(data)}');
        
        if (data['success'] == true) {
          LoggerService.success('API_SYNC', 'Item synced successfully: ${data['item_id']}');
          return true;
        } else {
          LoggerService.warning('API_SYNC', 'Sync failed: ${data['message']}');
          return false;
        }
      } else {
        LoggerService.error('API_SYNC', 'Sync HTTP error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      LoggerService.error('API_SYNC', 'Sync error: $e');
      return false;
    }
  }

  /// Get all items from backend
  static Future<List<Map<String, dynamic>>> getItems({String? category}) async {
    try {
      LoggerService.start('API_GET', 'Fetching items from backend');
      
      String url = '$_baseUrl/items';
      if (category != null) {
        url += '?category=$category';
      }
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        LoggerService.success('API_GET', 'Retrieved ${data.length} items from backend');
        return data.cast<Map<String, dynamic>>();
      } else {
        LoggerService.error('API_GET', 'HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      LoggerService.error('API_GET', 'Get items error: $e');
      return [];
    }
  }

  /// Delete item from backend
  static Future<bool> deleteItem(int itemId) async {
    try {
      LoggerService.start('API_DELETE', 'Deleting item from backend: $itemId');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/items/$itemId'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          LoggerService.success('API_DELETE', 'Item deleted successfully');
          return true;
        }
      }
      
      LoggerService.error('API_DELETE', 'Delete failed: ${response.statusCode}');
      return false;
    } catch (e) {
      LoggerService.error('API_DELETE', 'Delete error: $e');
      return false;
    }
  }

  /// Check backend health
  static Future<bool> checkHealth() async {
    try {
      LoggerService.start('API_HEALTH', 'Checking backend health');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'healthy') {
          LoggerService.success('API_HEALTH', 'Backend is healthy');
          return true;
        }
      }
      
      LoggerService.warning('API_HEALTH', 'Backend not healthy');
      return false;
    } catch (e) {
      LoggerService.error('API_HEALTH', 'Health check failed: $e');
      return false;
    }
  }
}
