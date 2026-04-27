// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductInfo _$ProductInfoFromJson(Map<String, dynamic> json) => ProductInfo(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String?,
  brand: json['brand'] as String?,
  category: json['category'] as String?,
  ingredients: json['ingredients'] as String?,
  imageUrl: json['imageUrl'] as String?,
  quantity: json['quantity'] as String?,
  packaging: json['packaging'] as String?,
  origins: json['origins'] as String?,
  stores: json['stores'] as String?,
  countries: json['countries'] as String?,
  barcode: json['barcode'] as String?,
  nutritionInfo: json['nutritionInfo'] as String?,
  uses: json['uses'] as String?,
  dosage: json['dosage'] as String?,
  sideEffects: json['sideEffects'] as String?,
  warnings: json['warnings'] as String?,
  source: json['source'] as String?,
  expiryDate: json['expiryDate'] == null
      ? null
      : DateTime.parse(json['expiryDate'] as String),
  mfgDate: json['mfgDate'] == null
      ? null
      : DateTime.parse(json['mfgDate'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ProductInfoToJson(ProductInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'brand': instance.brand,
      'category': instance.category,
      'ingredients': instance.ingredients,
      'imageUrl': instance.imageUrl,
      'quantity': instance.quantity,
      'packaging': instance.packaging,
      'origins': instance.origins,
      'stores': instance.stores,
      'countries': instance.countries,
      'barcode': instance.barcode,
      'nutritionInfo': instance.nutritionInfo,
      'uses': instance.uses,
      'dosage': instance.dosage,
      'sideEffects': instance.sideEffects,
      'warnings': instance.warnings,
      'source': instance.source,
      'expiryDate': instance.expiryDate?.toIso8601String(),
      'mfgDate': instance.mfgDate?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
    };
