import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// Database Service for SQLite operations
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  /// Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database
  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'expiry_management.db');
      
      LoggerService.info('DATABASE', 'Initializing database at: $path');
      
      // Open the database
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      
      LoggerService.success('DATABASE', 'Database initialized successfully');
      return db;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to initialize database: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    try {
      LoggerService.info('DATABASE', 'Creating database tables...');
      
      // Create products table
      await db.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          brand TEXT,
          category TEXT,
          expiry_date TEXT,
          manufacturing_date TEXT,
          batch_number TEXT,
          ingredients TEXT,
          notes TEXT,
          image_path TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Create categories table
      await db.execute('''
        CREATE TABLE categories (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          description TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Create settings table
      await db.execute('''
        CREATE TABLE settings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          key TEXT UNIQUE NOT NULL,
          value TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Create logs table
      await db.execute('''
        CREATE TABLE logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          level TEXT NOT NULL,
          tag TEXT NOT NULL,
          message TEXT NOT NULL,
          timestamp TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      LoggerService.success('DATABASE', 'Database tables created successfully');
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to create tables: $e');
      rethrow;
    }
  }

  /// Upgrade database when version changes
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      LoggerService.info('DATABASE', 'Upgrading database from version $oldVersion to $newVersion');
      
      // Add upgrade logic here when needed
      
      LoggerService.success('DATABASE', 'Database upgraded successfully');
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to upgrade database: $e');
      rethrow;
    }
  }

  /// Insert a product into the database
  Future<int> insertProduct(Map<String, dynamic> product) async {
    try {
      final db = await database;
      
      product['created_at'] = DateTime.now().toIso8601String();
      product['updated_at'] = DateTime.now().toIso8601String();
      
      final id = await db.insert('products', product);
      
      LoggerService.success('DATABASE', 'Product inserted with ID: $id');
      return id;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to insert product: $e');
      rethrow;
    }
  }

  /// Get all products from database
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final db = await database;
      
      final products = await db.query(
        'products',
        orderBy: 'created_at DESC',
      );
      
      LoggerService.info('DATABASE', 'Retrieved ${products.length} products');
      return products;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to get products: $e');
      rethrow;
    }
  }

  /// Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
    try {
      final db = await database;
      
      final products = await db.query(
        'products',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'created_at DESC',
      );
      
      LoggerService.info('DATABASE', 'Retrieved ${products.length} products for category: $category');
      return products;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to get products by category: $e');
      rethrow;
    }
  }

  /// Get a product by ID
  Future<Map<String, dynamic>?> getProductById(int id) async {
    try {
      final db = await database;
      
      final products = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      
      if (products.isNotEmpty) {
        LoggerService.info('DATABASE', 'Retrieved product with ID: $id');
        return products.first;
      }
      
      return null;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to get product by ID: $e');
      rethrow;
    }
  }

  /// Update a product
  Future<void> updateProduct(int id, Map<String, dynamic> product) async {
    try {
      final db = await database;
      
      product['updated_at'] = DateTime.now().toIso8601String();
      
      await db.update(
        'products',
        product,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      LoggerService.success('DATABASE', 'Product updated with ID: $id');
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to update product: $e');
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(int id) async {
    try {
      final db = await database;
      
      await db.delete(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      LoggerService.success('DATABASE', 'Product deleted with ID: $id');
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to delete product: $e');
      rethrow;
    }
  }

  /// Search products
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final db = await database;
      
      final products = await db.query(
        'products',
        where: 'name LIKE ? OR brand LIKE ? OR notes LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: 'created_at DESC',
      );
      
      LoggerService.info('DATABASE', 'Found ${products.length} products for query: $query');
      return products;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to search products: $e');
      rethrow;
    }
  }

  /// Get expiring products (within specified days)
  Future<List<Map<String, dynamic>>> getExpiringProducts(int days) async {
    try {
      final db = await database;
      final futureDate = DateTime.now().add(Duration(days: days));
      final futureDateStr = futureDate.toIso8601String().split('T')[0];
      
      final products = await db.rawQuery('''
        SELECT * FROM products 
        WHERE expiry_date IS NOT NULL 
        AND expiry_date <= ?
        AND expiry_date >= date('now')
        ORDER BY expiry_date ASC
      ''', [futureDateStr]);
      
      LoggerService.info('DATABASE', 'Found ${products.length} expiring products within $days days');
      return products;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to get expiring products: $e');
      rethrow;
    }
  }

  /// Get expired products
  Future<List<Map<String, dynamic>>> getExpiredProducts() async {
    try {
      final db = await database;
      
      final products = await db.rawQuery('''
        SELECT * FROM products 
        WHERE expiry_date IS NOT NULL 
        AND expiry_date < date('now')
        ORDER BY expiry_date ASC
      ''');
      
      LoggerService.info('DATABASE', 'Found ${products.length} expired products');
      return products;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to get expired products: $e');
      rethrow;
    }
  }

  /// Get product statistics
  Future<Map<String, dynamic>> getProductStats() async {
    try {
      final db = await database;
      
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM products');
      final expiredResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM products 
        WHERE expiry_date IS NOT NULL AND expiry_date < date('now')
      ''');
      final expiringResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM products 
        WHERE expiry_date IS NOT NULL 
        AND expiry_date BETWEEN date('now') AND date('now', '+7 days')
      ''');
      
      final total = totalResult.first['count'] as int;
      final expired = expiredResult.first['count'] as int;
      final expiring = expiringResult.first['count'] as int;
      final valid = total - expired;
      
      final stats = {
        'total': total,
        'expired': expired,
        'expiring': expiring,
        'valid': valid,
        'expiryRate': total > 0 ? (expired / total * 100).round() : 0,
      };
      
      LoggerService.info('DATABASE', 'Product statistics: $stats');
      return stats;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to get product stats: $e');
      rethrow;
    }
  }

  /// Save a setting
  Future<void> saveSetting(String key, String value) async {
    try {
      final db = await database;
      
      await db.insert(
        'settings',
        {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      LoggerService.info('DATABASE', 'Setting saved: $key');
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to save setting: $e');
      rethrow;
    }
  }

  /// Get a setting
  Future<String?> getSetting(String key) async {
    try {
      final db = await database;
      
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      
      if (result.isNotEmpty) {
        return result.first['value'] as String?;
      }
      
      return null;
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to get setting: $e');
      rethrow;
    }
  }

  /// Log an entry
  Future<void> logEntry(String level, String tag, String message) async {
    try {
      final db = await database;
      
      await db.insert('logs', {
        'level': level,
        'tag': tag,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Don't log errors to avoid infinite loops
      print('Failed to log entry: $e');
    }
  }

  /// Clear old logs (older than specified days)
  Future<void> clearOldLogs(int days) async {
    try {
      final db = await database;
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      await db.delete(
        'logs',
        where: 'timestamp < ?',
        whereArgs: [cutoffDate.toIso8601String()],
      );
      
      LoggerService.info('DATABASE', 'Old logs cleared (older than $days days)');
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to clear old logs: $e');
    }
  }

  /// Close the database
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      LoggerService.info('DATABASE', 'Database closed');
    }
  }

  /// Reset the database (for testing purposes)
  Future<void> resetDatabase() async {
    try {
      await closeDatabase();
      
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'expiry_management.db');
      
      await deleteDatabase(path);
      
      LoggerService.warning('DATABASE', 'Database reset');
    } catch (e) {
      LoggerService.error('DATABASE', 'Failed to reset database: $e');
      rethrow;
    }
  }
}
