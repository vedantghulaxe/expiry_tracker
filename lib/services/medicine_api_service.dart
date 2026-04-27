import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/product_info.dart';
import '../core/services/logger_service.dart';

class MedicineApiService {
  static const String _openFdaUrl = 'https://api.fda.gov/drug/label.json';
  static const int _timeoutSeconds = 15;

  /// Lookup medicine information by name
  static Future<ProductInfo?> lookupMedicine(String medicineName) async {
    LoggerService.start('MEDICINE_API', 'Looking up medicine: $medicineName');

    try {
      final url = Uri.parse('$_openFdaUrl?search=$medicineName');
      final response = await http.get(url).timeout(
        Duration(seconds: _timeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['results']?.isNotEmpty == true) {
          final result = data['results'][0];
          return _parseMedicineData(result, medicineName);
        }
      }

      LoggerService.warning('MEDICINE_API', 'Medicine not found');
      return null;
    } catch (e) {
      LoggerService.error('MEDICINE_API', 'Lookup failed: $e');
      return null;
    }
  }

  /// Parse medicine data from OpenFDA response
  static ProductInfo _parseMedicineData(Map<String, dynamic> result, String medicineName) {
    // Extract basic information
    final String? name = result['openfda']?['application_number'] != null 
        ? medicineName 
        : result['patient']?['drug_name']?.toString().trim();

    // Extract uses and purpose
    String? uses;
    if (result['patient']?['purpose'] != null) {
      final purposes = result['patient']['purpose'];
      if (purposes is List) {
        uses = purposes.map((p) => p.toString()).join(', ');
      } else {
        uses = purposes?.toString().trim();
      }
    }

    // Extract dosage information
    String? dosage;
    if (result['patient']?['dosage_and_administration'] != null) {
      final dosageInfo = result['patient']['dosage_and_administration'];
      if (dosageInfo is List) {
        dosage = dosageInfo.map((d) => d.toString()).join(', ');
      } else {
        dosage = dosageInfo?.toString().trim();
      }
    }

    // Extract warnings and precautions
    String? warnings;
    if (result['warnings'] != null) {
      final warningsList = <String>[];
      
      if (result['warnings'] is List) {
        for (final warning in result['warnings']) {
          if (warning is Map && warning['text'] != null) {
            warningsList.add(warning['text'].toString().trim());
          }
        }
      }
      
      warnings = warningsList.join('; ');
    }

    // Extract side effects
    String? sideEffects;
    if (result['patient']?['reactions'] != null) {
      final reactions = result['patient']['reactions'];
      if (reactions is List) {
        sideEffects = reactions.map((r) => r.toString()).join(', ');
      } else {
        sideEffects = reactions?.toString().trim();
      }
    }

    // Extract active ingredients
    String? ingredients;
    if (result['patient']?['active_ingredient'] != null) {
      final activeIngredients = result['patient']['active_ingredient'];
      if (activeIngredients is List) {
        ingredients = activeIngredients.map((i) => i.toString()).join(', ');
      } else {
        ingredients = activeIngredients?.toString().trim();
      }
    }

    return ProductInfo(
      name: name ?? medicineName,
      category: 'Medicine',
      uses: uses,
      dosage: dosage,
      sideEffects: sideEffects,
      warnings: warnings,
      ingredients: ingredients,
      source: 'open_fda',
    );
  }

  /// Search for medicines with partial name
  static Future<List<ProductInfo>> searchMedicines(String query) async {
    LoggerService.start('MEDICINE_API', 'Searching medicines: $query');

    try {
      final url = Uri.parse('$_openFdaUrl?search=$query&limit=10');
      final response = await http.get(url).timeout(
        Duration(seconds: _timeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['results']?.isNotEmpty == true) {
          final results = data['results'] as List;
          return results
              .map((result) => _parseMedicineData(result, query))
              .where((medicine) => medicine.isValid)
              .toList();
        }
      }

      return [];
    } catch (e) {
      LoggerService.error('MEDICINE_API', 'Search failed: $e');
      return [];
    }
  }

  /// Check if OpenFDA API is available
  static Future<bool> checkApiAvailability() async {
    try {
      final url = Uri.parse('$_openFdaUrl?search=aspirin&limit=1');
      final response = await http.get(url).timeout(
        Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      LoggerService.error('MEDICINE_API', 'API availability check failed: $e');
      return false;
    }
  }

  /// Format dosage information for display
  static String formatDosage(String? dosage) {
    if (dosage == null || dosage.isEmpty) {
      return 'Dosage information not available';
    }
    return dosage;
  }

  /// Format side effects for display
  static String formatSideEffects(String? sideEffects) {
    if (sideEffects == null || sideEffects.isEmpty) {
      return 'No side effects information available';
    }
    return sideEffects;
  }

  /// Format warnings for display
  static String formatWarnings(String? warnings) {
    if (warnings == null || warnings.isEmpty) {
      return 'No warnings available';
    }
    return warnings;
  }
}
