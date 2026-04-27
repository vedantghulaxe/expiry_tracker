import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expiry_tracker_app/core/services/batch_processing_service.dart';
import 'package:expiry_tracker_app/core/services/image_enhancement_service.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';
import 'package:expiry_tracker_app/data/database/database_service.dart';

/// Batch Processing Screen for bulk operations
class BatchProcessingScreen extends StatefulWidget {
  const BatchProcessingScreen({Key? key}) : super(key: key);

  @override
  _BatchProcessingScreenState createState() => _BatchProcessingScreenState();
}

class _BatchProcessingScreenState extends State<BatchProcessingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _batchQueue = [];
  bool _isProcessing = false;
  Map<String, dynamic> _progress = {};
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = false;

  // Image enhancement settings
  bool _autoEnhance = true;
  bool _lightingCorrection = true;
  bool _perspectiveCorrection = true;
  bool _blurReduction = true;
  bool _textSharpening = true;
  bool _noiseReduction = true;
  bool _contrastEnhancement = true;
  bool _resizeToOptimal = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Processing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.upload_file), text: 'Import'),
            Tab(icon: Icon(Icons.image), text: 'Enhance'),
            Tab(icon: Icon(Icons.analytics), text: 'Process'),
            Tab(icon: Icon(Icons.download), text: 'Export'),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadProducts),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImportTab(),
          _buildEnhanceTab(),
          _buildProcessTab(),
          _buildExportTab(),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return Padding(
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
                    'Import from Gallery',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Select multiple images from gallery for batch processing',
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _importFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Select Images'),
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
                    'Import from Directory',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text('Select a directory containing images'),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _importFromDirectory,
                    icon: Icon(Icons.folder),
                    label: Text('Select Directory'),
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
                    'Import from CSV',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text('Import products from CSV file'),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _importFromCSV,
                    icon: Icon(Icons.file_upload),
                    label: Text('Select CSV File'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          if (_batchQueue.isNotEmpty)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Batch Queue',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Spacer(),
                        Text(
                          '${_batchQueue.length} items',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Items ready for batch processing'),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _batchQueue.length / 100,
                      backgroundColor: Colors.blue.shade200,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhanceTab() {
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
                    'Image Enhancement Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Auto-Enhance'),
                    subtitle: Text(
                      'Automatically determine best enhancement strategy',
                    ),
                    value: _autoEnhance,
                    onChanged: (value) {
                      setState(() {
                        _autoEnhance = value;
                        if (value) {
                          _lightingCorrection = true;
                          _perspectiveCorrection = true;
                          _blurReduction = true;
                          _textSharpening = true;
                          _noiseReduction = true;
                          _contrastEnhancement = true;
                          _resizeToOptimal = true;
                        }
                      });
                    },
                  ),
                  Divider(),
                  if (!_autoEnhance) ...[
                    SwitchListTile(
                      title: Text('Lighting Correction'),
                      subtitle: Text('Auto-correct brightness and exposure'),
                      value: _lightingCorrection,
                      onChanged: (value) =>
                          setState(() => _lightingCorrection = value),
                    ),
                    SwitchListTile(
                      title: Text('Perspective Correction'),
                      subtitle: Text('Correct perspective distortion'),
                      value: _perspectiveCorrection,
                      onChanged: (value) =>
                          setState(() => _perspectiveCorrection = value),
                    ),
                    SwitchListTile(
                      title: Text('Blur Reduction'),
                      subtitle: Text('Reduce image blur for better OCR'),
                      value: _blurReduction,
                      onChanged: (value) =>
                          setState(() => _blurReduction = value),
                    ),
                    SwitchListTile(
                      title: Text('Text Sharpening'),
                      subtitle: Text('Enhance text clarity'),
                      value: _textSharpening,
                      onChanged: (value) =>
                          setState(() => _textSharpening = value),
                    ),
                    SwitchListTile(
                      title: Text('Noise Reduction'),
                      subtitle: Text('Reduce image noise'),
                      value: _noiseReduction,
                      onChanged: (value) =>
                          setState(() => _noiseReduction = value),
                    ),
                    SwitchListTile(
                      title: Text('Contrast Enhancement'),
                      subtitle: Text(
                        'Improve contrast for better text recognition',
                      ),
                      value: _contrastEnhancement,
                      onChanged: (value) =>
                          setState(() => _contrastEnhancement = value),
                    ),
                    SwitchListTile(
                      title: Text('Resize to Optimal'),
                      subtitle: Text('Resize to optimal dimensions for OCR'),
                      value: _resizeToOptimal,
                      onChanged: (value) =>
                          setState(() => _resizeToOptimal = value),
                    ),
                  ],
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
                    'Enhance Images',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text('Enhance images in batch queue for better OCR results'),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _batchQueue.isEmpty ? null : _enhanceBatchImages,
                    icon: Icon(Icons.auto_fix_high),
                    label: Text('Enhance Batch Images'),
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
                    'Enhance Single Image',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text('Select and enhance a single image'),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _enhanceSingleImage,
                    icon: Icon(Icons.image),
                    label: Text('Select & Enhance Image'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Batch Processing',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  if (_isProcessing) ...[
                    Text(
                      'Processing batch...',
                      style: TextStyle(color: Colors.orange),
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(),
                    SizedBox(height: 8),
                    Text(
                      'Progress: ${_progress['processed'] ?? 0}/${_progress['total'] ?? 0}',
                    ),
                    Text('Successful: ${_progress['successful'] ?? 0}'),
                    Text('Failed: ${_progress['failed'] ?? 0}'),
                  ] else ...[
                    Text('Ready to process ${_batchQueue.length} items'),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _batchQueue.isEmpty
                                ? null
                                : _startBatchProcessing,
                            icon: Icon(Icons.play_arrow),
                            label: Text('Start Processing'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _batchQueue.isEmpty
                                ? null
                                : _clearBatchQueue,
                            icon: Icon(Icons.clear),
                            label: Text('Clear Queue'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                    'Batch Statistics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  if (_products.isNotEmpty) ...[
                    _buildBatchStats(),
                  ] else ...[
                    Text('No products to analyze'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Products',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text('Export your products to various formats'),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_products.isEmpty || _isLoading)
                              ? null
                              : _exportToCSV,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.table_chart),
                          label: Text('Export to CSV'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (_products.isEmpty || _isLoading)
                              ? null
                              : _exportToExcel,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.grid_on),
                          label: Text('Export to Excel'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 48),
                          ),
                        ),
                      ),
                    ],
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
                        final stats =
                            BatchProcessingService.calculateBatchExpiryStats(
                              _products,
                            );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expired: ${stats['expired']}'),
                            Text('Expiring Soon: ${stats['expiringSoon']}'),
                            Text('Valid: ${stats['valid']}'),
                            SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _shareBatchResults,
                              icon: Icon(Icons.share),
                              label: Text('Share Summary'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 48),
                              ),
                            ),
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

  Widget _buildBatchStats() {
    final stats = BatchProcessingService.calculateBatchExpiryStats(_products);

    return Column(
      children: [
        _buildStatItem('Total Products', '${stats['total']}', Icons.inventory),
        _buildStatItem(
          'Expired',
          '${stats['expired']}',
          Icons.warning,
          Colors.red,
        ),
        _buildStatItem(
          'Expiring Soon',
          '${stats['expiringSoon']}',
          Icons.schedule,
          Colors.orange,
        ),
        _buildStatItem(
          'Valid',
          '${stats['valid']}',
          Icons.check_circle,
          Colors.green,
        ),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 200,
          child: _buildExpiryChart(stats),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon, [
    Color color = Colors.blue,
  ]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Spacer(),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryChart(Map<String, dynamic> stats) {
    final total = stats['total'] as int;
    if (total == 0) return Container();

    final expired = (stats['expired'] as int) / total;
    final expiringSoon = (stats['expiringSoon'] as int) / total;
    final valid = (stats['valid'] as int) / total;
    final expiredFlex = ((expired * 100).round()).clamp(1, 98).toInt();
    final expiringSoonFlex = ((expiringSoon * 100).round())
        .clamp(1, 98)
        .toInt();
    final validFlex = ((valid * 100).round()).clamp(1, 98).toInt();

    return Column(
      children: [
        Text(
          'Expiry Distribution',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: expiredFlex,
                child: Container(
                  color: Colors.red,
                  child: Center(
                    child: Text(
                      '${(expired * 100).round()}%',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: expiringSoonFlex,
                child: Container(
                  color: Colors.orange,
                  child: Center(
                    child: Text(
                      '${(expiringSoon * 100).round()}%',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: validFlex,
                child: Container(
                  color: Colors.green,
                  child: Center(
                    child: Text(
                      '${(valid * 100).round()}%',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Container(width: 12, height: 12, color: Colors.red),
            SizedBox(width: 4),
            Text('Expired'),
            Spacer(),
            Container(width: 12, height: 12, color: Colors.orange),
            SizedBox(width: 4),
            Text('Expiring Soon'),
            Spacer(),
            Container(width: 12, height: 12, color: Colors.green),
            SizedBox(width: 4),
            Text('Valid'),
          ],
        ),
      ],
    );
  }

  Future<void> _importFromGallery() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMultiImage();

      if (result.isNotEmpty) {
        final batchItems = result
            .map(
              (image) => {
                'type': 'image',
                'imagePath': image.path,
                'fileName': image.name,
                'addedAt': DateTime.now().toIso8601String(),
              },
            )
            .toList();

        BatchProcessingService.addToBatchQueue(batchItems);
        setState(() => _batchQueue.addAll(batchItems));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${batchItems.length} images to batch queue'),
          ),
        );
      }
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to import from gallery: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import images: $e')));
    }
  }

  Future<void> _importFromDirectory() async {
    try {
      // TODO: Implement directory picker when file_picker is fixed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Directory picker temporarily unavailable')),
      );
    } catch (e) {
      LoggerService.error(
        'BATCH_SCREEN',
        'Failed to import from directory: $e',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import directory: $e')));
    }
  }

  Future<void> _importFromCSV() async {
    try {
      // TODO: Implement CSV picker when file_picker is fixed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV import temporarily unavailable')),
      );
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to import CSV: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to import CSV: $e')));
    }
  }

  Future<void> _enhanceBatchImages() async {
    try {
      final imageFiles = _batchQueue
          .where((item) => item['type'] == 'image')
          .map((item) => File(item['imagePath']))
          .toList();

      if (imageFiles.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No images in batch queue')));
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Enhancing Images'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Enhancing ${imageFiles.length} images...'),
            ],
          ),
        ),
      );

      final enhancedImages = await ImageEnhancementService.batchEnhanceImages(
        imageFiles,
        onProgress: (enhanced, count) {
          // Update progress if needed
        },
        autoEnhance: _autoEnhance,
        customSettings: _autoEnhance
            ? null
            : {
                'lighting': _lightingCorrection,
                'perspective': _perspectiveCorrection,
                'blur': _blurReduction,
                'sharpen': _textSharpening,
                'noise': _noiseReduction,
                'contrast': _contrastEnhancement,
                'resize': _resizeToOptimal,
              },
      );

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enhanced ${enhancedImages.length} images')),
      );
    } catch (e) {
      Navigator.of(context).pop();
      LoggerService.error('BATCH_SCREEN', 'Failed to enhance batch images: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to enhance images: $e')));
    }
  }

  Future<void> _enhanceSingleImage() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickMultiImage();

      if (result.isNotEmpty) {
        final originalFile = File(result.first.path);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text('Enhancing Image'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Enhancing image...'),
              ],
            ),
          ),
        );

        final enhancedFile = await ImageEnhancementService.enhanceImageForOCR(
          originalFile,
          autoCorrectLighting: _lightingCorrection,
          perspectiveCorrection: _perspectiveCorrection,
          blurReduction: _blurReduction,
          textSharpening: _textSharpening,
          noiseReduction: _noiseReduction,
          contrastEnhancement: _contrastEnhancement,
          resizeToOptimal: _resizeToOptimal,
        );

        Navigator.of(context).pop();

        // Show comparison
        final comparison = await ImageEnhancementService.compareImages(
          originalFile,
          enhancedFile,
        );

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Enhancement Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Original Size: ${comparison['originalSize']} bytes'),
                Text('Enhanced Size: ${comparison['enhancedSize']} bytes'),
                Text(
                  'Size Reduction: ${comparison['sizeReductionPercent']?.toStringAsFixed(1)}%',
                ),
                SizedBox(height: 16),
                Text('Enhanced image saved to: ${enhancedFile.path}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to enhance single image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to enhance image: $e')));
    }
  }

  Future<void> _startBatchProcessing() async {
    try {
      setState(() => _isProcessing = true);

      final result = await BatchProcessingService.processBatchQueue(
        onProgress: (message, processed) {
          if (mounted) {
            setState(() {
              _progress = BatchProcessingService.getBatchProgress();
            });
          }
        },
        onItemComplete: (itemResult) {
          // Handle individual item completion
        },
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result['success'] == true) {
        // Reload products from DB
        await _loadProducts();
        if (!mounted) return;

        // Auto-export CSV
        String? csvPath;
        if (_products.isNotEmpty) {
          try {
            await BatchProcessingService.requestStoragePermission();
            csvPath = await BatchProcessingService.exportToCSV(_products);
            LoggerService.success('BATCH_SCREEN', 'Auto CSV export: $csvPath');
          } catch (e) {
            LoggerService.error('BATCH_SCREEN', 'Auto CSV export failed: $e');
          }
        }

        final progress = result['progress'] as Map<String, dynamic>? ?? {};
        final successCount = progress['successful'] ?? 0;
        final failedCount = progress['failed'] ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              csvPath != null
                  ? 'Done: $successCount processed, $failedCount failed.\nCSV saved: $csvPath'
                  : 'Done: $successCount processed, $failedCount failed.',
            ),
            duration: const Duration(seconds: 6),
          ),
        );

        // Switch to Export tab
        if (csvPath != null) {
          _tabController.animateTo(3);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Batch processing failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      LoggerService.error('BATCH_SCREEN', 'Batch processing failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Batch processing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearBatchQueue() async {
    BatchProcessingService.clearBatchQueue();
    setState(() => _batchQueue = []);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Batch queue cleared')));
  }

  Future<void> _exportToCSV() async {
    try {
      // Request storage permission on Android
      await BatchProcessingService.requestStoragePermission();

      setState(() => _isLoading = true);
      final filePath = await BatchProcessingService.exportToCSV(_products);
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV exported: $filePath'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      LoggerService.error('BATCH_SCREEN', 'CSV export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportToExcel() async {
    try {
      // Request storage permission on Android
      await BatchProcessingService.requestStoragePermission();

      setState(() => _isLoading = true);
      final filePath = await BatchProcessingService.exportToExcel(_products);
      setState(() => _isLoading = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel exported: $filePath'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      LoggerService.error('BATCH_SCREEN', 'Excel export failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Excel export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareBatchResults() async {
    try {
      final progress = BatchProcessingService.getBatchProgress();
      final hasProgress = progress.containsKey('total');
      final payload = hasProgress
          ? {'progress': progress}
          : {
              'progress': {
                'total': _products.length,
                'processed': _products.length,
                'successful': _products.length,
                'failed': 0,
              },
            };
      await BatchProcessingService.shareBatchResults(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch summary copied to clipboard')),
      );
    } catch (e) {
      LoggerService.error('BATCH_SCREEN', 'Failed to share batch results: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share results: $e')));
    }
  }
}
