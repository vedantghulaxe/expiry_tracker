import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../core/services/logger_service.dart';
import '../../models/product_info.dart';

class ProductRepository {
  final AppDatabase db;

  ProductRepository(this.db);

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
          // Simple parsing for common formats
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

  Future<void> addProduct(ProductInfo productInfo) async {
    if (productInfo.name?.trim().isEmpty == true) {
      LoggerService.error('DB_SAVE', 'Cannot save product with empty name');
      throw ArgumentError('Product name cannot be empty');
    }

    try {
      LoggerService.start('DB_SAVE', 'Saving product: ${productInfo.name}');
      
      // Parse dates - handle both string and DateTime inputs
      final parsedExpiryDate = _parseDate(productInfo.expiryDate);
      final parsedMfgDate = _parseDate(productInfo.mfgDate);
      
      if (parsedExpiryDate == null) {
        LoggerService.warning('DB_SAVE', 'Product has no valid expiry date');
      }
      
      await db.into(db.products).insert(
        ProductsCompanion.insert(
          name: productInfo.name!.trim(),
          brand: productInfo.brand != null ? Value(productInfo.brand!.trim()) : const Value.absent(),
          category: productInfo.category != null ? Value(productInfo.category!.trim()) : const Value.absent(),
          quantity: productInfo.quantity != null ? Value(productInfo.quantity!.trim()) : const Value.absent(),
          ingredients: productInfo.ingredients != null ? Value(productInfo.ingredients!.trim()) : const Value.absent(),
          notes: productInfo.warnings != null ? Value(productInfo.warnings!.trim()) : const Value.absent(),
          expiryDate: parsedExpiryDate != null ? Value(parsedExpiryDate!) : const Value.absent(),
          manufacturingDate: parsedMfgDate != null ? Value(parsedMfgDate!) : const Value.absent(),
          imagePath: Value(productInfo.imageUrl?.trim()),
        ),
      );
      
      LoggerService.success('DB_SAVE', 'Successfully saved product: ${productInfo.name}');
    } catch (e) {
      LoggerService.error('DB_SAVE', 'Failed to save product ${productInfo.name}: $e');
      rethrow;
    }
  }

  Stream<List<ProductInfo>> watchAllProducts() {
    return db.select(db.products).watch().map((rows) {
      return rows.map((row) => _convertToProductInfo(row)).toList();
    });
  }

  Future<List<ProductInfo>> getAllProducts() async {
    try {
      final products = await db.select(db.products).get();
      return products.map((p) => _convertToProductInfo(p)).toList();
    } catch (e) {
      LoggerService.error('DB_LOAD', 'Failed to load products: $e');
      return [];
    }
  }

  ProductInfo _convertToProductInfo(Product product) {
    return ProductInfo(
      id: product.id,
      name: product.name,
      brand: product.brand,
      category: product.category,
      quantity: product.quantity,
      ingredients: product.ingredients,
      warnings: product.notes,
      expiryDate: product.expiryDate,
      mfgDate: product.manufacturingDate,
      imageUrl: product.imagePath,
      source: 'database',
    );
  }

  Future<void> updateProduct(int id, ProductInfo productInfo) async {
    if (productInfo.name?.trim().isEmpty == true) {
      LoggerService.error('DB_UPDATE', 'Cannot update product with empty name');
      throw ArgumentError('Product name cannot be empty');
    }

    try {
      LoggerService.start('DB_UPDATE', 'Updating product ID $id: ${productInfo.name}');
      
      // Parse dates - handle both string and DateTime inputs
      final parsedExpiryDate = _parseDate(productInfo.expiryDate);
      final parsedMfgDate = _parseDate(productInfo.mfgDate);
      
      await (db.update(db.products)..where((tbl) => tbl.id.equals(id))).write(
        ProductsCompanion(
          name: Value(productInfo.name!.trim()),
          brand: productInfo.brand != null ? Value(productInfo.brand!.trim()) : const Value.absent(),
          category: productInfo.category != null ? Value(productInfo.category!.trim()) : const Value.absent(),
          quantity: productInfo.quantity != null ? Value(productInfo.quantity!.trim()) : const Value.absent(),
          ingredients: productInfo.ingredients != null ? Value(productInfo.ingredients!.trim()) : const Value.absent(),
          notes: productInfo.warnings != null ? Value(productInfo.warnings!.trim()) : const Value.absent(),
          expiryDate: parsedExpiryDate != null ? Value(parsedExpiryDate!) : const Value.absent(),
          manufacturingDate: parsedMfgDate != null ? Value(parsedMfgDate!) : const Value.absent(),
          imagePath: Value(productInfo.imageUrl?.trim()),
        ),
      );
      
      LoggerService.success('DB_UPDATE', 'Successfully updated product ID $id: ${productInfo.name}');
    } catch (e) {
      LoggerService.error('DB_UPDATE', 'Failed to update product ID $id: $e');
      rethrow;
    }
  }

  Future<int> deleteProduct(int id) {
    return (db.delete(db.products)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<List<ProductInfo>> searchProducts(String query) async {
    try {
      final q = query.trim();
      if (q.isEmpty) return [];

      final products = await (db.select(db.products)
            ..where((tbl) =>
                tbl.name.isNotNull() &
                tbl.name.like('%$q%') |
                (tbl.brand.isNotNull() & tbl.brand.like('%$q%'))))
          .get();
      
      return products.map((product) => _convertToProductInfo(product)).toList();
    } catch (e) {
      LoggerService.error('DB_SEARCH', 'Failed to search products: $e');
      return [];
    }
  }
}
