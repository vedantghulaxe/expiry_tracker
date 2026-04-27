import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';
import 'package:expiry_tracker_app/core/services/barcode_service.dart';
import 'package:expiry_tracker_app/services/multi_image_service_simple.dart';
import 'package:expiry_tracker_app/data/database/database_service.dart';

/// Batch Processing Service for bulk operations
class BatchProcessingService {
  static final List<Map<String, dynamic>> _batchQueue = [];
  static bool _isProcessingBatch = false;
  static Map<String, dynamic> _batchProgress = {};

  /// Add multiple items to batch queue
  static void addToBatchQueue(List<Map<String, dynamic>> items) {
    _batchQueue.addAll(items);
    LoggerService.info('BATCH', 'Added ${items.length} items to batch queue');
  }

  /// Process batch queue
  static Future<Map<String, dynamic>> processBatchQueue({
    Function(Map<String, dynamic>)? onItemComplete,
    Function(String, int)? onProgress,
  }) async {
    if (_isProcessingBatch) {
      return {
        'success': false,
        'message': 'Batch processing already in progress',
      };
    }

    _isProcessingBatch = true;
    _batchProgress = {
      'total': _batchQueue.length,
      'processed': 0,
      'successful': 0,
      'failed': 0,
    };

    try {
      LoggerService.info(
        'BATCH',
        'Starting batch processing of ${_batchQueue.length} items',
      );

      for (int i = 0; i < _batchQueue.length; i++) {
        final item = _batchQueue[i];

        try {
          // Process individual item
          final result = await _processBatchItem(item);

          if (result['success']) {
            _batchProgress['successful'] =
                (_batchProgress['successful'] as int) + 1;
          } else {
            _batchProgress['failed'] = (_batchProgress['failed'] as int) + 1;
          }

          // Callback for individual item completion
          onItemComplete?.call(result);
        } catch (e) {
          _batchProgress['failed'] = (_batchProgress['failed'] as int) + 1;
          LoggerService.error('BATCH', 'Failed to process item ${i + 1}: $e');
        }

        _batchProgress['processed'] = (_batchProgress['processed'] as int) + 1;
        onProgress?.call('Processing batch...', _batchProgress['processed']);

        // Small delay to prevent overwhelming the system
        await Future.delayed(Duration(milliseconds: 100));
      }

      final summary = {
        'success': true,
        'message': 'Batch processing completed',
        'progress': _batchProgress,
      };

      LoggerService.success(
        'BATCH',
        'Batch processing completed: ${_batchProgress['successful']} successful, ${_batchProgress['failed']} failed',
      );

      // Clear queue after processing
      _batchQueue.clear();
      return summary;
    } catch (e) {
      LoggerService.error('BATCH', 'Batch processing failed: $e');
      return {'success': false, 'message': 'Batch processing failed: $e'};
    } finally {
      _isProcessingBatch = false;
    }
  }

  /// Process individual batch item
  static Future<Map<String, dynamic>> _processBatchItem(
    Map<String, dynamic> item,
  ) async {
    try {
      // Handle different item types
      if (item['type'] == 'image') {
        return await _processImageItem(item);
      } else if (item['type'] == 'barcode') {
        return await _processBarcodeItem(item);
      } else if (item['type'] == 'manual') {
        return await _processManualItem(item);
      } else {
        return {
          'success': false,
          'message': 'Unknown item type: ${item['type']}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Item processing failed: $e'};
    }
  }

  /// Process image-based item
  static Future<Map<String, dynamic>> _processImageItem(
    Map<String, dynamic> item,
  ) async {
    final File imageFile = File(item['imagePath']);

    // Process image with enhanced OCR
    final result = await MultiImageServiceSimple.processMultipleImages([
      imageFile,
    ]);

    if (result['success'] == true) {
      // Save to database
      final productId = await _saveBatchItemToDatabase(result);

      return {
        'success': true,
        'productId': productId,
        'data': result,
        'message': 'Image item processed successfully',
      };
    } else {
      return {
        'success': false,
        'message': 'Image processing failed',
        'data': result,
      };
    }
  }

  /// Process barcode-based item
  static Future<Map<String, dynamic>> _processBarcodeItem(
    Map<String, dynamic> item,
  ) async {
    final barcode = item['barcode']?.toString() ?? '';
    if (barcode.isEmpty) {
      return {'success': false, 'message': 'Missing barcode value'};
    }

    final barcodeData = await BarcodeService.getProductInfo(barcode);
    final normalizedData = <String, dynamic>{
      ...barcodeData,
      'barcode': barcode,
      'source': barcodeData['source'] ?? 'Barcode Scan',
      'expiryDate': barcodeData['expiryDate'] ?? _generateFutureDate(),
    };

    final productId = await _saveBatchItemToDatabase({
      'parsed_data': normalizedData,
    });

    return {
      'success': true,
      'productId': productId,
      'data': normalizedData,
      'message': 'Barcode item processed successfully',
    };
  }

  /// Process manual item
  static Future<Map<String, dynamic>> _processManualItem(
    Map<String, dynamic> item,
  ) async {
    final productId = await _saveBatchItemToDatabase(item);

    return {
      'success': true,
      'productId': productId,
      'data': item,
      'message': 'Manual item processed successfully',
    };
  }

  /// Save batch item to database
  static Future<int> _saveBatchItemToDatabase(
    Map<String, dynamic> itemData,
  ) async {
    final parsedData = itemData['parsed_data'] ?? itemData;

    final product = {
      'name': parsedData['name'] ?? 'Unknown Product',
      'brand': parsedData['brand'] ?? '',
      'category': parsedData['category'] ?? 'product',
      'expiry_date': parsedData['expiryDate'] ?? '',
      'manufacturing_date': parsedData['mfgDate'] ?? '',
      'batch_number': parsedData['batchNumber'] ?? '',
      'ingredients': parsedData['ingredients'] ?? '',
      'notes': 'Batch processed: ${DateTime.now().toIso8601String()}',
      'created_at': DateTime.now().toIso8601String(),
    };

    final dbService = DatabaseService();
    return await dbService.insertProduct(product);
  }

  /// Generate future date for demo purposes
  static String _generateFutureDate() {
    final future = DateTime.now().add(
      Duration(days: 30 + (DateTime.now().millisecond % 365)),
    );
    return '${future.day.toString().padLeft(2, '0')}/${future.month.toString().padLeft(2, '0')}/${future.year}';
  }

  /// Get batch progress
  static Map<String, dynamic> getBatchProgress() {
    return Map<String, dynamic>.from(_batchProgress);
  }

  /// Clear batch queue
  static void clearBatchQueue() {
    _batchQueue.clear();
    LoggerService.info('BATCH', 'Batch queue cleared');
  }

  /// Get batch queue size
  static int getBatchQueueSize() {
    return _batchQueue.length;
  }

  /// Add images from directory to batch
  static Future<Map<String, dynamic>> addImagesFromDirectory(
    String directoryPath,
  ) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return {'success': false, 'message': 'Directory does not exist'};
      }

      final files = await directory.list().toList();
      final imageFiles = files.where((file) {
        final extension = file.path.toLowerCase().split('.').last;
        return ['jpg', 'jpeg', 'png', 'bmp', 'tiff'].contains(extension);
      }).toList();

      final batchItems = imageFiles
          .map(
            (file) => {
              'type': 'image',
              'imagePath': file.path,
              'fileName': file.uri.pathSegments.isNotEmpty
                  ? file.uri.pathSegments.last
                  : file.path,
              'addedAt': DateTime.now().toIso8601String(),
            },
          )
          .toList();

      addToBatchQueue(batchItems);

      return {
        'success': true,
        'message': 'Added ${imageFiles.length} images to batch queue',
        'count': imageFiles.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to add images from directory: $e',
      };
    }
  }

  /// Calculate batch expiry statistics
  static Map<String, dynamic> calculateBatchExpiryStats(
    List<Map<String, dynamic>> products,
  ) {
    final now = DateTime.now();
    final soon = now.add(Duration(days: 7));
    final month = now.add(Duration(days: 30));

    int expired = 0;
    int expiringSoon = 0;
    int expiringThisMonth = 0;
    int valid = 0;

    for (final product in products) {
      final expiryStr = product['expiry_date'] as String?;
      if (expiryStr == null || expiryStr.isEmpty) continue;

      try {
        final expiry = _parseDate(expiryStr);

        if (expiry.isBefore(now)) {
          expired++;
        } else if (expiry.isBefore(soon)) {
          expiringSoon++;
        } else if (expiry.isBefore(month)) {
          expiringThisMonth++;
        } else {
          valid++;
        }
      } catch (e) {
        // Skip invalid dates
      }
    }

    return {
      'total': products.length,
      'expired': expired,
      'expiringSoon': expiringSoon,
      'expiringThisMonth': expiringThisMonth,
      'valid': valid,
      'expiryRate': products.length > 0
          ? (expired / products.length * 100).round()
          : 0,
    };
  }

  /// Parse date string
  static DateTime _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    final slashParts = dateStr.split('/');
    if (slashParts.length == 3) {
      final day = int.parse(slashParts[0]);
      final month = int.parse(slashParts[1]);
      final year = int.parse(slashParts[2]);
      return DateTime(year, month, day);
    }

    final dashParts = dateStr.split('-');
    if (dashParts.length == 3) {
      final day = int.parse(dashParts[0]);
      final month = int.parse(dashParts[1]);
      final year = int.parse(dashParts[2]);
      return DateTime(year, month, day);
    }

    throw Exception('Invalid date format: $dateStr');
  }

  /// Export products to CSV
  static Future<String> exportToCSV(List<Map<String, dynamic>> products) async {
    try {
      final csvData = <List<String>>[];

      // Add header
      csvData.add([
        'ID',
        'Name',
        'Brand',
        'Category',
        'Expiry Date',
        'Manufacturing Date',
        'Batch Number',
        'Ingredients',
        'Notes',
        'Created At',
      ]);

      // Add data rows
      for (final product in products) {
        csvData.add([
          product['id']?.toString() ?? '',
          product['name']?.toString() ?? '',
          product['brand']?.toString() ?? '',
          product['category']?.toString() ?? '',
          product['expiry_date']?.toString() ?? '',
          product['manufacturing_date']?.toString() ?? '',
          product['batch_number']?.toString() ?? '',
          product['ingredients']?.toString() ?? '',
          product['notes']?.toString() ?? '',
          product['created_at']?.toString() ?? '',
        ]);
      }

      final csv = const ListToCsvConverter().convert(csvData);

      // Try Downloads directory first, fall back to app documents directory
      Directory? directory;
      try {
        directory = await getDownloadsDirectory();
      } catch (_) {
        directory = null;
      }
      directory ??= await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${directory.path}/products_export_$timestamp.csv');
      await file.writeAsString(csv);

      LoggerService.success(
        'BATCH',
        'Exported ${products.length} products to CSV: ${file.path}',
      );
      return file.path;
    } catch (e) {
      LoggerService.error('BATCH', 'CSV export failed: $e');
      throw Exception('CSV export failed: $e');
    }
  }

  /// Export products to Excel
  static Future<String> exportToExcel(
    List<Map<String, dynamic>> products,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Products'];

      // Add headers
      final headers = [
        'ID',
        'Name',
        'Brand',
        'Category',
        'Expiry Date',
        'Manufacturing Date',
        'Batch Number',
        'Ingredients',
        'Notes',
        'Created At',
      ];

      for (int i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(
          headers[i],
        );
      }

      // Add data rows
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        final rowIndex = i + 1;

        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .value = IntCellValue(
          product['id'] ?? 0,
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['name']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['brand']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['category']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['expiry_date']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['manufacturing_date']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['batch_number']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['ingredients']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['notes']?.toString() ?? '',
        );
        sheet
            .cell(
              CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex),
            )
            .value = TextCellValue(
          product['created_at']?.toString() ?? '',
        );
      }

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/products_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
      );

      final fileBytes = excel.save();
      await file.writeAsBytes(fileBytes!);

      LoggerService.success(
        'BATCH',
        'Exported ${products.length} products to Excel: ${file.path}',
      );
      return file.path;
    } catch (e) {
      LoggerService.error('BATCH', 'Excel export failed: $e');
      throw Exception('Excel export failed: $e');
    }
  }

  /// Import products from CSV
  static Future<Map<String, dynamic>> importFromCSV(String filePath) async {
    try {
      final file = File(filePath);
      final csvData = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvData);

      if (rows.isEmpty) {
        return {'success': false, 'message': 'CSV file is empty'};
      }

      // Skip header row
      final dataRows = rows.skip(1);
      int imported = 0;
      int failed = 0;

      for (final row in dataRows) {
        try {
          if (row.length >= 5) {
            final product = {
              'name': row[1]?.toString() ?? '',
              'brand': row[2]?.toString() ?? '',
              'category': row[3]?.toString() ?? 'product',
              'expiry_date': row[4]?.toString() ?? '',
              'manufacturing_date': row[5]?.toString() ?? '',
              'batch_number': row[6]?.toString() ?? '',
              'ingredients': row[7]?.toString() ?? '',
              'notes': 'Imported from CSV: ${DateTime.now().toIso8601String()}',
              'created_at': DateTime.now().toIso8601String(),
            };

            final dbService = DatabaseService();
            await dbService.insertProduct(product);
            imported++;
          }
        } catch (e) {
          failed++;
          LoggerService.error('BATCH', 'Failed to import row: $e');
        }
      }

      LoggerService.success(
        'BATCH',
        'CSV import completed: $imported imported, $failed failed',
      );

      return {
        'success': true,
        'message': 'Import completed: $imported imported, $failed failed',
        'imported': imported,
        'failed': failed,
      };
    } catch (e) {
      LoggerService.error('BATCH', 'CSV import failed: $e');
      return {'success': false, 'message': 'CSV import failed: $e'};
    }
  }

  /// Request storage permission
  static Future<bool> requestStoragePermission() async {
    try {
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      LoggerService.error('BATCH', 'Storage permission request failed: $e');
      return false;
    }
  }

  /// Share batch results
  static Future<void> shareBatchResults(Map<String, dynamic> results) async {
    try {
      final summary =
          '''
Batch Processing Results
========================
Total Items: ${results['progress']['total']}
Processed: ${results['progress']['processed']}
Successful: ${results['progress']['successful']}
Failed: ${results['progress']['failed']}
Completion Rate: ${((results['progress']['successful'] / ((results['progress']['total'] == 0) ? 1 : results['progress']['total'])) * 100).toStringAsFixed(1)}%

Generated: ${DateTime.now().toLocal().toString()}
      ''';

      await Clipboard.setData(ClipboardData(text: summary));
      LoggerService.info('BATCH', 'Batch results copied to clipboard');
    } catch (e) {
      LoggerService.error('BATCH', 'Failed to share batch results: $e');
    }
  }
}
