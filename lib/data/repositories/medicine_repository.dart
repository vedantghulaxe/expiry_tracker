import 'package:drift/drift.dart';
import 'dart:convert';
import '../database/app_database.dart';
import '../../core/services/logger_service.dart';
import '../../models/product_info.dart';

class MedicineRepository {
  final AppDatabase db;

  MedicineRepository(this.db);

  /// Parse date from string or return existing DateTime
  DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) {
      // Try common date formats
      final formats = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'MM/yyyy',
        'yyyy/MM',
        'MM-dd-yyyy',
      ];
      
      for (final format in formats) {
        try {
          if (format == 'MM/yyyy' || format == 'yyyy/MM') {
            final parts = date.split(date.contains('/') ? '/' : '-');
            if (parts.length == 2) {
              final month = int.tryParse(parts[0]) ?? int.tryParse(parts[1]);
              final year = int.tryParse(parts[1]) ?? int.tryParse(parts[0]);
              if (month != null && year != null) {
                return DateTime(year, month);
              }
            }
          } else {
            final parsed = DateTime.tryParse(date);
            if (parsed != null) return parsed;
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  Future<void> addMedicine(ProductInfo medicineInfo) async {
    if (medicineInfo.name?.trim().isEmpty == true) {
      LoggerService.error('DB_SAVE', 'Cannot save medicine with empty name');
      throw ArgumentError('Medicine name cannot be empty');
    }

    try {
      LoggerService.start('DB_SAVE', 'Saving medicine: ${medicineInfo.name}');
      
      // Parse dates - handle both string and DateTime inputs
      final parsedExpiryDate = _parseDate(medicineInfo.expiryDate);
      final parsedMfgDate = _parseDate(medicineInfo.mfgDate);
      
      if (parsedExpiryDate == null) {
        LoggerService.warning('DB_SAVE', 'Medicine has no valid expiry date');
      }
      
      final insertedId = await db.into(db.medicines).insert(
        MedicinesCompanion.insert(
          name: medicineInfo.name!.trim(),
          symptoms: Value(medicineInfo.sideEffects?.trim()),
          dosage: Value(medicineInfo.dosage?.trim()),
          doctorName: Value(null),
          prescriptionImage: Value(medicineInfo.imageUrl?.trim()),
          expiryDate: parsedExpiryDate != null ? Value(parsedExpiryDate!) : const Value.absent(),
          brand: Value(medicineInfo.brand),
          mrp: Value(null),
          batch: Value(null),
          manufacturer: Value(medicineInfo.brand),
          extraData: Value(_createExtraData(medicineInfo)),
        ),
      );
      
      LoggerService.success('DB_SAVE', 'Successfully saved medicine: ${medicineInfo.name}');
    } catch (e, stackTrace) {
      LoggerService.error('DB_SAVE', 'Failed to save medicine ${medicineInfo.name}: $e');
      rethrow;
    }
  }

  String _createExtraData(ProductInfo medicineInfo) {
    final extraData = <String, dynamic>{};
    
    if (medicineInfo.warnings?.isNotEmpty == true) {
      extraData['warnings'] = medicineInfo.warnings;
    }
    if (medicineInfo.sideEffects?.isNotEmpty == true) {
      extraData['sideEffects'] = medicineInfo.sideEffects;
    }
    if (medicineInfo.uses?.isNotEmpty == true) {
      extraData['uses'] = medicineInfo.uses;
    }
    if (medicineInfo.mfgDate != null) {
      extraData['mfgDate'] = medicineInfo.mfgDate!.toIso8601String();
    }
    if (medicineInfo.expiryDate != null) {
      extraData['expiryDate'] = medicineInfo.expiryDate!.toIso8601String();
    }
    
    // Use proper JSON encoding
    if (extraData.isEmpty) return '';
    
    try {
      return const JsonEncoder().convert(extraData);
    } catch (e) {
      LoggerService.warning('DB_SAVE', 'Failed to encode extra data as JSON: $e');
      return extraData.toString();
    }
  }

  Stream<List<ProductInfo>> watchAllMedicines() {
    return db.select(db.medicines).watch().map((rows) {
      return rows.map((row) => _convertToProductInfo(row)).toList();
    });
  }

  Future<List<ProductInfo>> getAllMedicines() async {
    try {
      final medicines = await db.select(db.medicines).get();
      return medicines.map((medicine) => _convertToProductInfo(medicine)).toList();
    } catch (e) {
      LoggerService.error('DB_LOAD', 'Failed to load medicines: $e');
      return [];
    }
  }

  ProductInfo _convertToProductInfo(Medicine medicine) {
    // Parse extra data if available
    Map<String, dynamic>? extraData;
    if (medicine.extraData != null) {
      try {
        extraData = _parseExtraData(medicine.extraData!);
      } catch (e) {
        LoggerService.warning('DB_PARSE', 'Failed to parse extra data: $e');
      }
    }

    return ProductInfo(
      id: medicine.id,
      name: medicine.name,
      brand: medicine.brand,
      category: 'Medicine',
      dosage: medicine.dosage,
      uses: extraData?['symptoms'],
      warnings: extraData?['warnings'],
      sideEffects: extraData?['sideEffects'],
      mfgDate: extraData?['mfgDate'] != null 
          ? DateTime.tryParse(extraData!['mfgDate'])
          : null,
      expiryDate: medicine.expiryDate ?? (extraData?['expiryDate'] != null
          ? DateTime.tryParse(extraData!['expiryDate'])
          : null),
      imageUrl: medicine.prescriptionImage,
      source: 'database',
    );
  }

  Map<String, dynamic> _parseExtraData(String extraDataString) {
    if (extraDataString.isEmpty) return {};
    
    try {
      // Try JSON parsing first
      final decoded = jsonDecode(extraDataString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      // Fall back to simple parsing for legacy data
      LoggerService.warning('DB_PARSE', 'JSON parse failed, using simple parsing: $e');
    }
    
    // Simple parsing for legacy format
    final data = <String, dynamic>{};
    final pairs = extraDataString.replaceAll(RegExp(r'[{}]'), '').split(',');
    
    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        final key = parts[0].trim().replaceAll(RegExp(r'''['\"]'''), '');
        final value = parts[1].trim().replaceAll(RegExp(r'''['\"]'''), '');
        data[key] = value;
      }
    }
    
    return data;
  }

  Future<List<ProductInfo>> searchMedicines(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];

      final medicines = await (db.select(db.medicines)
            ..where(
              (tbl) =>
                  tbl.name.isNotNull() &
                  tbl.name.like('%$q%') |
                  (tbl.brand.isNotNull() & tbl.brand.like('%$q%'))))
          .get();
      
      final convertedMedicines = medicines.map((medicine) => _convertToProductInfo(medicine)).toList();
      return convertedMedicines;
    } catch (e) {
      LoggerService.error('DB_SEARCH', 'Failed to search medicines: $e');
      return [];
    }
  }

  Future<void> updateMedicine(int id, ProductInfo medicineInfo) async {
    if (medicineInfo.name?.trim().isEmpty == true) {
      LoggerService.error('DB_UPDATE', 'Cannot update medicine with empty name');
      throw ArgumentError('Medicine name cannot be empty');
    }

    try {
      LoggerService.start('DB_UPDATE', 'Updating medicine ID $id: ${medicineInfo.name}');
      
      // Parse dates - handle both string and DateTime inputs
      final parsedExpiryDate = _parseDate(medicineInfo.expiryDate);
      final parsedMfgDate = _parseDate(medicineInfo.mfgDate);
      
      await (db.update(db.medicines)..where((tbl) => tbl.id.equals(id))).write(
        MedicinesCompanion(
          name: Value(medicineInfo.name!.trim()),
          symptoms: Value(medicineInfo.sideEffects?.trim()),
          dosage: Value(medicineInfo.dosage?.trim()),
          prescriptionImage: Value(medicineInfo.imageUrl?.trim()),
          expiryDate: parsedExpiryDate != null ? Value(parsedExpiryDate!) : const Value.absent(),
          brand: Value(medicineInfo.brand),
          manufacturer: Value(medicineInfo.brand),
          extraData: Value(_createExtraData(medicineInfo)),
          updatedAt: Value(DateTime.now()),
        ),
      );
      
      LoggerService.success('DB_UPDATE', 'Successfully updated medicine ID $id: ${medicineInfo.name}');
    } catch (e) {
      LoggerService.error('DB_UPDATE', 'Failed to update medicine ID $id: $e');
      rethrow;
    }
  }

  Future<int> deleteMedicine(int id) {
    return (db.delete(db.medicines)..where((tbl) => tbl.id.equals(id))).go();
  }
}
