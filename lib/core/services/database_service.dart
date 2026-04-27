import '../../data/database/app_database.dart';

import 'package:drift/drift.dart' as drift;

import '../services/logger_service.dart';



/// Enhanced Database Service with proper initialization and error handling

class DatabaseService {

  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() => _instance;

  DatabaseService._internal();



  AppDatabase? _database;

  bool _isInitialized = false;



  /// Initialize database service

  Future<void> initialize() async {

    if (_isInitialized) {

      LoggerService.info('DATABASE_SERVICE', 'Database service already initialized');

      return;

    }



    try {

      LoggerService.info('DATABASE_SERVICE', 'Initializing database service...');

      _database = AppDatabase();

      

      // Test database connection

      if (_database != null) {

        await _database!.customSelect('SELECT 1').get();

      }

      

      _isInitialized = true;

      LoggerService.success('DATABASE_SERVICE', 'Database service initialized successfully');

    } catch (e, stackTrace) {

      LoggerService.error('DATABASE_SERVICE', 'Database initialization failed: $e');

      LoggerService.error('DATABASE_SERVICE', 'Stack trace: $stackTrace');

      _isInitialized = false;

      rethrow;

    }

  }



  /// Get database instance (async - waits for init)
  Future<AppDatabase> get database async {
    if (!_isInitialized) {
      LoggerService.warning('DATABASE_SERVICE', 'Database service not initialized');
      throw Exception('Database service must be initialized before accessing database');
    }
    return _database!;
  }

  /// Get database instance synchronously (only call AFTER initialization)
  AppDatabase get db => _database ?? AppDatabase();



  /// Insert product with validation and logging

  Future<void> insertProduct(Map<String, dynamic> product) async {

    if (!_isInitialized) {

      LoggerService.error('DATABASE_SERVICE', 'Database service not initialized');

      throw Exception('Database service must be initialized before inserting products');

    }



    try {

      final db = await database;

      

      // Validate product data

      if (!_isValidProductData(product)) {

        LoggerService.warning('DATABASE_SERVICE', 'Invalid product data: $product');

        throw ArgumentError('Product data validation failed');

      }



      await db.into(db.products).insert(ProductsCompanion.insert(

        name: product['name'] ?? '',

        brand: product['brand'] ?? '',

        category: product['category'] ?? '',

        imagePath: drift.Value(product['imageUrl'] ?? ''),

        expiryDate: product['expiryDate'] != null 

            ? drift.Value(DateTime.parse(product['expiryDate'])) 

            : const drift.Value.absent(),

        manufacturingDate: product['manufacturingDate'] != null 

            ? drift.Value(DateTime.parse(product['manufacturingDate'])) 

            : const drift.Value.absent(),

        ingredients: drift.Value(product['ingredients'] ?? ''),

        notes: drift.Value(product['notes'] ?? ''),

        createdAt: drift.Value(DateTime.now()),

      ));

    } catch (e, stackTrace) {

      LoggerService.error('DATABASE_SERVICE', 'Failed to insert product: $e');

      LoggerService.error('DATABASE_SERVICE', 'Stack trace: $stackTrace');

      throw Exception('Failed to insert product: $e');

    }

  }



  Future<List<Map<String, dynamic>>> getAllProducts() async {

    final db = await database;

    try {

      final products = await (db.select(db.products)..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])).get();

      

      LoggerService.info('DATABASE_SERVICE', 'Retrieved ${products.length} products from database');

      

      return products.map((p) => {

        'id': p.id,

        'name': p.name,

        'brand': p.brand,

        'category': p.category,

        'imageUrl': p.imagePath,

        'expiryDate': p.expiryDate?.toIso8601String(),

        'manufacturingDate': p.manufacturingDate?.toIso8601String(),

        'ingredients': p.ingredients,

        'notes': p.notes,

        'createdAt': p.createdAt.toIso8601String(),

      }).toList();

    } catch (e, stackTrace) {

      LoggerService.error('DATABASE_SERVICE', 'Failed to get products: $e');

      LoggerService.error('DATABASE_SERVICE', 'Stack trace: $stackTrace');

      return [];

    }

  }

  /// Validate product data before insertion
  bool _isValidProductData(Map<String, dynamic> product) {
    // Check required fields
    if (product['name'] == null || product['name'].toString().trim().isEmpty) {
      return false;
    }

    // Check for harmful patterns
    final name = product['name'].toString().toLowerCase();
    final harmfulPatterns = [
      'drop table', 'delete from', 'insert into', 'update set', 
      'script', 'javascript', '<script', 'onclick', 'onerror',
      'eval(', 'alert(', 'document.cookie'
    ];
    
    for (final pattern in harmfulPatterns) {
      if (name.contains(pattern)) {
        return false;
      }
    }

    // Check name length
    if (name.length > 200) {
      return false;
    }

    return true;
  }

}
