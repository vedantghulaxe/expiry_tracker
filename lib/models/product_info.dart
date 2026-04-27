import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';


part 'product_info.g.dart';

@JsonSerializable()
class ProductInfo {
  final int? id;
  final String? name;
  final String? brand;
  final String? category;
  final String? ingredients;
  final String? imageUrl;
  final String? quantity;
  final String? packaging;
  final String? origins;
  final String? stores;
  final String? countries;
  final String? barcode;
  final String? nutritionInfo;
  final String? uses;
  final String? dosage;
  final String? sideEffects;
  final String? warnings;
  final String? source; // 'open_food_facts', 'upc_itemdb', 'open_fda', 'manual'
  final DateTime? expiryDate;
  final DateTime? mfgDate;
  final DateTime? createdAt;

  ProductInfo({
    this.id,
    this.name,
    this.brand,
    this.category,
    this.ingredients,
    this.imageUrl,
    this.quantity,
    this.packaging,
    this.origins,
    this.stores,
    this.countries,
    this.barcode,
    this.nutritionInfo,
    this.uses,
    this.dosage,
    this.sideEffects,
    this.warnings,
    this.source,
    this.expiryDate,
    this.mfgDate,
    this.createdAt,
  });

  /// Get list of image URLs (handles both single path and JSON encoded list)
  List<String> get imageUrls {
    if (imageUrl == null || imageUrl!.isEmpty) return [];
    try {
      final decoded = jsonDecode(imageUrl!);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {
      // Not a JSON list, treat as single path
    }
    return [imageUrl!];
  }

  /// Create ProductInfo with multiple images encoded as JSON string
  static String? encodeImageUrls(List<String> paths) {
    if (paths.isEmpty) return null;
    if (paths.length == 1) return paths.first;
    return jsonEncode(paths);
  }

  factory ProductInfo.fromJson(Map<String, dynamic> json) =>
      _$ProductInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ProductInfoToJson(this);

  bool get isValid => name?.isNotEmpty == true;

  /// Create ProductInfo from parsed local data
  factory ProductInfo.fromParsedData(Map<String, dynamic> parsedData) {
    return ProductInfo(
      name: parsedData['name'],
      brand: parsedData['brand'],
      category: parsedData['category'],
      dosage: parsedData['dosage'],
      ingredients: parsedData['ingredients'],
      warnings: parsedData['warnings'] is List 
          ? (parsedData['warnings'] as List).join(', ')
          : parsedData['warnings'],
      uses: parsedData['uses'] is List
          ? (parsedData['uses'] as List).join(', ')
          : parsedData['uses'],
      source: 'local_parser',
    );
  }

  /// Create empty ProductInfo
  factory ProductInfo.empty() {
    return ProductInfo(
      name: '',
      brand: '',
      category: '',
      source: 'empty',
    );
  }
  bool get isMedicine => category?.toLowerCase().contains('medicine') == true;
  bool get isProduct => !isMedicine;
}
