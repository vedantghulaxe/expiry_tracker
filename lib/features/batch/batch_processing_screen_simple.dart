import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expiry_tracker_app/core/services/batch_processing_service.dart';
import 'package:expiry_tracker_app/core/services/image_enhancement_service.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';
import 'package:expiry_tracker_app/data/database/database_service.dart';

/// Simple Batch Processing Screen
class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({Key? key}) : super(key: key);

  @override
  _BatchProcessingScreenState createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final dbService = DatabaseService();
      final products = await dbService.getAllProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to load products: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importImages() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMultiImage();
      
      if (result != null && result.isNotEmpty) {
        final batchItems = result.map((image) => {
          'type': 'image',
          'imagePath': image.path,
          'fileName': image.name,
          'addedAt': DateTime.now().toIso8601String(),
        }).toList();
        
        BatchProcessingService.addToBatchQueue(batchItems);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${batchItems.length} images to batch queue')),
        );
      }
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to import images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import images: $e')),
      );
    }
  }

  Future<void> _processBatch() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await BatchProcessingService.processBatchQueue();
      
      if (result['success']) {
        await _loadProducts();
        String? csvPath;
        if (_products.isNotEmpty) {
          try {
            csvPath = await BatchProcessingService.exportToCSV(_products);
          } catch (e) {
            LoggerService.error('BATCH_SCREEN', 'Auto CSV export failed: $e');
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              csvPath != null
                  ? 'Batch processing completed. CSV exported: $csvPath'
                  : 'Batch processing completed',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch processing failed')),
        );
      }
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to process batch: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process batch: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToCSV() async {
    try {
      if (_products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No products to export')),
        );
        return;
      }
      
      final filePath = await BatchProcessingService.exportToCSV(_products);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to CSV: $filePath')),
      );
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to export CSV: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Processing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.upload_file), text: 'Import'),
            Tab(icon: Icon(Icons.download), text: 'Export'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Import Images',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _importImages,
                    icon: Icon(Icons.photo_library),
                    label: Text('Select Multiple Images'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _processBatch,
                    icon: _isLoading ? CircularProgressIndicator() : Icon(Icons.play_arrow),
                    label: Text(_isLoading ? 'Processing...' : 'Process Batch Queue'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Queue Status',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Text('Queue Size: ${BatchProcessingService.getBatchQueueSize()}'),
                  Text('Total Products: ${_products.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _exportToCSV,
                    icon: Icon(Icons.file_download),
                    label: Text('Export to CSV'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Text('Total Products: ${_products.length}'),
                  if (_products.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final stats = BatchProcessingService.calculateBatchExpiryStats(_products);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expired: ${stats['expired']}'),
                            Text('Expiring Soon: ${stats['expiringSoon']}'),
                            Text('Valid: ${stats['valid']}'),
                          ],
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
