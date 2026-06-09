import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expiry_tracker_app/services/multi_image_service_simple.dart';
import 'package:expiry_tracker_app/features/product/manual_product_entry_screen.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';
import 'package:expiry_tracker_app/core/services/barcode_service.dart';
import 'package:expiry_tracker_app/features/common/barcode_scanner_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Image Capture Screen with Real OCR (Google ML Kit + Tesseract)
class ImageCaptureScreenRealOCR extends StatefulWidget {
  final bool isMedicine;

  const ImageCaptureScreenRealOCR({
    super.key,
    required this.isMedicine,
  });

  @override
  State<ImageCaptureScreenRealOCR> createState() => _ImageCaptureScreenRealOCRState();
}

class _ImageCaptureScreenRealOCRState extends State<ImageCaptureScreenRealOCR> {
  List<File> _capturedImages = [];
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.isMedicine ? 'Scan Medicine' : 'Scan Product',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (_capturedImages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearImages,
              tooltip: 'Clear All Images',
            ),
        ],
      ),
      body: Column(
        children: [
          // Image Capture Section
          Container(
            width: double.infinity,
            child: _buildImageCaptureSection(),
          ),
          
          // Analysis Results Section
          Expanded(
            child: _buildAnalysisSection(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildImageCaptureSection() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 1: Capture Images',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // Captured Images Preview
          if (_capturedImages.isNotEmpty) ...[
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _capturedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _capturedImages[index],
                            fit: BoxFit.cover,
                            width: 100,
                            height: 120,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.8),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Capture Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Choose from Gallery'),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Barcode Scanning Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _scanBarcode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Barcode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Multiple Images Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _pickMultipleImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose Multiple Images'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          // Analyze Button
          if (_capturedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _analyzeImages,
                icon: _isProcessing 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isProcessing ? 'Analyzing...' : 'Analyze Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Step 2: Analysis Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isProcessing)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing images with OCR (Google ML Kit + Tesseract)...'),
                    ],
                  ),
                )
              else if (_errorMessage != null)
                _buildErrorWidget()
              else if (_analysisResult != null)
                _buildResultsWidget()
              else
                _buildEmptyState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No images captured yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture or select images to begin analysis',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade600,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Analysis Failed',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _retryAnalysis,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsWidget() {
    final result = _analysisResult!;
    final confidence = result['ocr_confidence'] ?? result['confidence'] ?? 0.0;
    final ocrMethod = result['ocr_method'] ?? 'Unknown';
    final isLowConfidence = result['is_low_confidence'] ?? false;
    final warning = result['warning'];
    final wordCount = (result['text'] ?? '').toString().split(' ').where((word) => word.isNotEmpty).length;
    
    // Get method display name
    String getMethodDisplayName(String method) {
      switch (method) {
        case 'online':
          return 'AI (Online)';
        case 'mlkit':
          return 'ML Kit (Offline)';
        case 'tesseract':
          return 'Tesseract (Offline)';
        case 'fallback':
          return 'Fallback';
        default:
          return 'Unknown';
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Indicator
          Row(
            children: [
              Icon(
                result['success'] == true ? Icons.check_circle : Icons.info,
                color: result['success'] == true ? Colors.green : Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                result['success'] == true ? 'Text Extraction Complete' : 'Processing Complete',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: result['success'] == true ? Colors.green.shade700 : Colors.blue.shade700,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // OCR Method and Confidence
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Extracted via', getMethodDisplayName(ocrMethod), 
                  ocrMethod == 'online' ? Icons.cloud : Icons.smartphone),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Confidence', '${(confidence * 100).toInt()}%', 
                  isLowConfidence ? Icons.warning : Icons.speed),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Words', wordCount.toString(), Icons.text_fields),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Images', _capturedImages.length.toString(), Icons.photo_library),
              ),
            ],
          ),
          
          // Low Confidence Warning
          if (isLowConfidence) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Low confidence result. Try better lighting.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Warning message if present
          if (warning != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Note: $warning',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // RAW EXTRACTED TEXT - ALWAYS SHOW PROMINENTLY AT TOP
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.text_snippet, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raw Extracted Text (OCR):',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(minHeight: 100),
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Builder(
                    builder: (context) {
                      final rawText = result['raw_text']?.toString() ?? result['text']?.toString() ?? '';
                      print('=== UI DISPLAY RAW TEXT ===');
                      print('Raw text length: ${rawText.length}');
                      print('Raw text content: ${rawText.substring(0, rawText.length > 200 ? 200 : rawText.length)}');
                      print('==========================');
                      
                      return SelectableText(
                        rawText.isEmpty ? 'No text extracted' : rawText,
                        style: TextStyle(
                          fontSize: 13,
                          color: rawText.isEmpty ? Colors.red : Colors.grey[800],
                          height: 1.5,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if ((result['raw_text']?.toString() ?? result['text']?.toString() ?? '').length > 100)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Full Extracted Text'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  result['raw_text']?.toString() ?? result['text']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.fullscreen, size: 16),
                      label: const Text('View Full Text'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Extracted Text Preview (always show)
          Text(
            'Extracted Text:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['text'] ?? 'No text found',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                if (result['text'] != null && result['text'].toString().isNotEmpty)
                  const SizedBox(height: 8),
                if (result['text'] != null && result['text'].toString().isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // Show full text in dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Full Extracted Text'),
                          content: SingleChildScrollView(
                            child: Text(
                              result['text'].toString(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: const Text('Show Full Text'),
                  ),
              ],
            ),
          ),
          
          // Message if any
          if (result['message'] != null && result['message'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getMessageColor(result['message']),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getMessageBorderColor(result['message'])),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMessageIcon(result['message']),
                    color: _getMessageIconColor(result['message']),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result['message'].toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getMessageTextColor(result['message']),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final colorScheme = Theme.of(context).colorScheme;
    if (_analysisResult == null || _isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
                color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_analysisResult != null)
              Column(
                children: [
                  if (_analysisResult!['allow_manual_entry'] == true)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton.icon(
                        onPressed: _proceedToManualEntry,
                        icon: const Icon(Icons.edit),
                        label: const Text('Manual Entry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _retryCapture,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retake'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _proceedToForm,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Edit & Save'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _capturedImages.add(File(image.path));
        });
        _clearResults();
      }
    } catch (e) {
      _showError('Camera error: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _capturedImages.add(File(image.path));
        });
        _clearResults();
      }
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _capturedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
        _clearResults();
      }
    } catch (e) {
      _showError('Multi-select error: $e');
    }
  }

  Future<void> _scanBarcode() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      // Show barcode scanner
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BarcodeScannerScreen(),
        ),
      );

      if (result != null && result is String) {
        // Process barcode
        await _processBarcode(result);
      }
    } catch (e) {
      LoggerService.error('BARCODE_SCAN', 'Failed to scan barcode: $e');
      setState(() {
        _errorMessage = 'Failed to scan barcode: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _processBarcode(String barcode) async {
    try {
      LoggerService.info('BARCODE_SCAN', 'Processing barcode: $barcode');
      
      // Get product information from barcode
      final productInfo = await BarcodeService.getProductInfo(barcode);
      final normalizedProductInfo = _normalizeBarcodeProductInfo(productInfo, barcode);
      
      setState(() {
        _analysisResult = {
          'success': true,
          'text': normalizedProductInfo['name'] ?? 'Unknown Product',
          'raw_text': normalizedProductInfo['name'] ?? 'Unknown Product',
          'method': 'barcode',
          'confidence': normalizedProductInfo['confidence'] ?? 0.5,
          'word_count': 1,
          'parsed_data': normalizedProductInfo,
          'enhanced': false,
          'image_count': 0,
          'ocr_method': 'barcode',
          'ocr_confidence': normalizedProductInfo['confidence'] ?? 0.5,
          'warning': normalizedProductInfo['confidence'] != null && normalizedProductInfo['confidence'] < 0.7 
              ? 'Low confidence barcode result' 
              : null,
          'is_low_confidence': (normalizedProductInfo['confidence'] ?? 0.5) < 0.7,
          'barcode': barcode,
          'image_paths': _capturedImages.map((image) => image.path).toList(),
        };
        _isProcessing = false;
      });

      LoggerService.success('BARCODE_SCAN', 'Barcode processing completed');
    } catch (e) {
      LoggerService.error('BARCODE_SCAN', 'Failed to process barcode: $e');
      setState(() {
        _errorMessage = 'Failed to process barcode: $e';
        _isProcessing = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
    _clearResults();
  }

  void _clearImages() {
    setState(() {
      _capturedImages.clear();
      _clearResults();
    });
  }

  void _clearResults() {
    setState(() {
      _analysisResult = null;
      _errorMessage = null;
    });
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  Future<void> _analyzeImages() async {
    if (_capturedImages.isEmpty) {
      setState(() {
        _errorMessage = 'No images to analyze';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      print('=== 🚀 STARTING REAL OCR ANALYSIS ===');
      print('📸 Images to analyze: ${_capturedImages.length}');
      
      // Validate all images exist before processing
      for (int i = 0; i < _capturedImages.length; i++) {
        if (!_capturedImages[i].existsSync()) {
          print('❌ Image ${i + 1} does not exist: ${_capturedImages[i].path}');
          setState(() {
            _errorMessage = 'Image ${i + 1} could not be found. Please recapture it.';
            _isProcessing = false;
          });
          return;
        }
      }
      
      final result = await MultiImageServiceSimple.processMultipleImages(_capturedImages);
      
      print('=== 📊 OCR ANALYSIS COMPLETE ===');
      print('✅ Success: ${result['success']}');
      print('📝 Has Text: ${result['raw_text'] != null && result['raw_text'].toString().isNotEmpty}');
      print('📄 Extracted Text: "${result['raw_text']}"');
      print('📏 Text Length: ${result['raw_text']?.toString().length ?? 0}');
      print('🖼️ Image Count: ${result['image_count']}');
      print('⚙️ Processing Method: ${result['processing_method']}');
      
      // Verify text extraction quality
      final extractedText = result['raw_text']?.toString() ?? '';
      if (extractedText.isNotEmpty) {
        print('🎉 TEXT EXTRACTION SUCCESSFUL!');
        print('📝 First 100 chars: "${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}"');
        print('🔢 Word count: ${extractedText.split(' ').where((word) => word.isNotEmpty).length}');
        print('📋 Line count: ${extractedText.split('\n').where((line) => line.trim().isNotEmpty).length}');
        
        // Check for common patterns
        if (extractedText.contains(RegExp(r'\d{2}/\d{2}/\d{4}'))) {
          print('📅 Date pattern found in text');
        }
        if (extractedText.contains(RegExp(r'\d{3,}'))) {
          print('🔢 Numbers found in text');
        }
        if (extractedText.contains(RegExp(r'[A-Z][a-z]+'))) {
          print('📝 Words found in text');
        }
      } else {
        print('❌ NO TEXT EXTRACTED - Check image quality and OCR settings');
      }
      
      if (result['success'] && result['raw_text'] != null && result['raw_text'].toString().isNotEmpty) {
        // Parse the extracted text using AI parser
        print('=== 🔍 PARSING EXTRACTED TEXT ===');
        final parsedData = result['parsed_data'] ?? {};
        
        print('=== ✅ PARSING COMPLETE ===');
        print('📋 Parsed Data Keys: ${parsedData.keys}');
        parsedData.forEach((key, value) {
          print('  $key: "$value"');
        });
        
        print('=== 🔍 BEFORE SETTING _analysisResult ===');
        print('result[raw_text]: ${result['raw_text']?.toString().length ?? 0} chars');
        print('result[text]: ${result['text']?.toString().length ?? 0} chars');
        print('Will store text: ${(result['raw_text']?.toString() ?? result['text']?.toString() ?? '').length} chars');
        print('Text preview: ${(result['raw_text']?.toString() ?? result['text']?.toString() ?? '').substring(0, (result['raw_text']?.toString() ?? result['text']?.toString() ?? '').length > 100 ? 100 : (result['raw_text']?.toString() ?? result['text']?.toString() ?? '').length)}');
        print('========================================');
        
        setState(() {
          _analysisResult = {
            'success': result['success'] ?? false,
            'text': result['raw_text']?.toString() ?? result['text']?.toString() ?? '',
            'raw_text': result['raw_text']?.toString() ?? result['text']?.toString() ?? '',
            'method': result['processing_method']?.toString() ?? 'unknown',
            'confidence': parsedData['confidence'] ?? 0.0,
            'word_count': result['raw_text']?.toString().split(' ').where((word) => word.isNotEmpty).length ?? 0,
            'parsed_data': parsedData ?? {},
            'enhanced': result['enhanced'] ?? false,
            'image_count': result['image_count'] ?? 0,
            'ocr_method': result['ocr_method']?.toString() ?? 'unknown',
            'ocr_confidence': result['ocr_confidence'] ?? 0.0,
            'warning': result['warning'],
            'is_low_confidence': result['is_low_confidence'] ?? false,
            'image_paths': _capturedImages.map((image) => image.path).toList(),
          };
          _isProcessing = false;
        });
        
        print('=== 🎉 ANALYSIS SUCCESSFUL ===');
        print('📝 Ready to proceed to form with parsed data');
        print('📄 Raw text in result: ${result['raw_text']?.toString().length ?? 0} chars');
        print('📄 Text in result: ${result['text']?.toString().length ?? 0} chars');
        print('📄 Stored in _analysisResult[raw_text]: ${_analysisResult!['raw_text']?.toString().length ?? 0} chars');
        print('📄 Stored in _analysisResult[text]: ${_analysisResult!['text']?.toString().length ?? 0} chars');
        print('📋 First 200 chars: ${(_analysisResult!['raw_text']?.toString() ?? '').substring(0, (_analysisResult!['raw_text']?.toString().length ?? 0) > 200 ? 200 : (_analysisResult!['raw_text']?.toString().length ?? 0))}');
        print('📊 Parsed data keys: ${parsedData.keys}');
        print('📊 Parsed name: ${parsedData['name']}');
        print('📊 Parsed expiry: ${parsedData['expiryDate']}');
        print('📊 Parsed mfg: ${parsedData['mfgDate']}');
        
      } else {
        // Handle different scenarios but never show "Analysis Failed"
        String message = 'Processing complete';
        String errorMessage = '';
        
        if (result['warning'] != null) {
          message = 'Processing completed with warnings';
          errorMessage = result['warning'].toString();
        } else if (result['is_low_confidence'] == true) {
          message = 'Processing completed with low confidence';
          errorMessage = 'Low confidence result - Check image quality';
        } else if (result['raw_text'] == null || result['raw_text'].toString().isEmpty) {
          message = 'Processing complete - No text extracted';
          errorMessage = 'No text extracted - Using fallback data';
        }
        
        // Always create a result to proceed to form
        final fallbackData = result['parsed_data'] ?? {
          'name': '',
          'expiryDate': null,
          'mfgDate': null,
          'dosage': '',
          'category': 'product',
          'isMedicine': false,
          'confidence': 0,
          'rawText': '',
        };
        
        setState(() {
          _analysisResult = {
            'success': true, // Always true to proceed
            'text': result['raw_text']?.toString() ?? '',
            'method': result['processing_method']?.toString() ?? 'fallback',
            'confidence': result['parsed_data']?['confidence'] ?? 0.0,
            'word_count': (result['raw_text']?.toString() ?? '').split(' ').where((word) => word.isNotEmpty).length,
            'parsed_data': result['parsed_data'] ?? fallbackData,
            'enhanced': result['enhanced'] ?? false,
            'image_count': result['image_count'] ?? 0,
            'warning_message': errorMessage.isNotEmpty ? errorMessage : null,
            'ocr_method': result['ocr_method']?.toString() ?? 'fallback',
            'ocr_confidence': result['ocr_confidence'] ?? 0.0,
            'warning': result['warning'],
            'is_low_confidence': result['is_low_confidence'] ?? false,
            'image_paths': _capturedImages.map((image) => image.path).toList(),
          };
          _isProcessing = false;
        });
        
        if (errorMessage.isNotEmpty) {
          print('=== ⚠️ ANALYSIS COMPLETED WITH WARNINGS: $errorMessage ===');
        } else {
          print('=== ✅ ANALYSIS COMPLETED SUCCESSFULLY ===');
        }
        print('📝 Ready to proceed to form with data');
      }
    } catch (e) {
      print('=== 💥 ANALYSIS EXCEPTION ===');
      print('❌ Error: $e');
      print('📚 Stack trace: ${StackTrace.current}');
      
      String userFriendlyMessage = 'Processing complete';
      
      // Provide more specific error messages based on common issues
      if (e.toString().contains('OutOfMemoryError')) {
        userFriendlyMessage = 'Images too large. Try with smaller or fewer images.';
      } else if (e.toString().contains('File not found')) {
        userFriendlyMessage = 'Some images could not be found. Please recapture them.';
      } else if (e.toString().contains('Network')) {
        userFriendlyMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('timeout')) {
        userFriendlyMessage = 'Processing timed out. Please try with fewer images.';
      }
      
      // Always create a fallback result to proceed to form
      final fallbackData = {
        'name': '',
        'expiryDate': null,
        'mfgDate': null,
        'dosage': '',
        'category': 'product',
        'isMedicine': false,
        'confidence': 0,
        'rawText': '',
      };
      
      setState(() {
        _analysisResult = {
          'success': true, // Always true to proceed
          'text': '',
          'method': 'error_fallback',
          'confidence': 0.0,
          'word_count': 0,
          'parsed_data': fallbackData,
          'enhanced': false,
          'image_count': 0,
          'warning_message': userFriendlyMessage,
          'ocr_method': 'fallback',
          'ocr_confidence': 0.0,
          'warning': userFriendlyMessage,
          'is_low_confidence': true,
          'image_paths': _capturedImages.map((image) => image.path).toList(),
        };
        _isProcessing = false;
      });
      
      print('=== ⚠️ ANALYSIS COMPLETED WITH ERROR HANDLING ===');
      print('📝 Ready to proceed to form with fallback data');
    }
  }

  Future<void> _retryAnalysis() async {
    await _analyzeImages();
  }

  void _retryCapture() {
    _clearImages();
  }
  
  String _getMethodDisplayName(String method) {
    switch (method) {
      case 'ocr_ai_enhanced':
        return 'OCR + AI';
      case 'ocr_local_fallback':
        return 'OCR Only';
      case 'no_text_detected':
        return 'No Text';
      case 'manual_entry_required':
        return 'Manual';
      case 'error':
        return 'Error';
      default:
        return method;
    }
  }
  
  Color _getMessageColor(String message) {
    if (message.contains('No readable text')) return Colors.red.shade50;
    if (message.contains('manual entry')) return Colors.orange.shade50;
    if (message.contains('error')) return Colors.red.shade50;
    return Colors.blue.shade50;
  }
  
  Color _getMessageBorderColor(String message) {
    if (message.contains('No readable text')) return Colors.red.shade200;
    if (message.contains('manual entry')) return Colors.orange.shade200;
    if (message.contains('error')) return Colors.red.shade200;
    return Colors.blue.shade200;
  }
  
  Color _getMessageIconColor(String message) {
    if (message.contains('No readable text')) return Colors.red.shade600;
    if (message.contains('manual entry')) return Colors.orange.shade600;
    if (message.contains('error')) return Colors.red.shade600;
    return Colors.blue.shade600;
  }
  
  Color _getMessageTextColor(String message) {
    if (message.contains('No readable text')) return Colors.red.shade700;
    if (message.contains('manual entry')) return Colors.orange.shade700;
    if (message.contains('error')) return Colors.red.shade700;
    return Colors.blue.shade700;
  }
  
  IconData _getMessageIcon(String message) {
    if (message.contains('No readable text')) return Icons.text_fields;
    if (message.contains('manual entry')) return Icons.edit;
    if (message.contains('error')) return Icons.error_outline;
    return Icons.info_outline;
  }

  void _proceedToForm() {
    if (_analysisResult != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManualProductEntryScreen(
            isMedicine: widget.isMedicine,
            analysisData: _analysisResult,
          ),
        ),
      );
    }
  }
  
  void _proceedToManualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManualProductEntryScreen(
          isMedicine: widget.isMedicine,
          analysisData: null, // Manual entry - no analysis data
        ),
      ),
    );
  }

  Map<String, dynamic> _normalizeBarcodeProductInfo(
    Map<String, dynamic> productInfo,
    String barcode,
  ) {
    final normalized = Map<String, dynamic>.from(productInfo);
    final expiry = _firstNonEmpty([
      normalized['expiryDate']?.toString(),
      normalized['expiry_date']?.toString(),
      normalized['expirationDate']?.toString(),
      normalized['expiration_date']?.toString(),
      normalized['best_before']?.toString(),
      normalized['use_by']?.toString(),
    ]);
    final mfg = _firstNonEmpty([
      normalized['mfgDate']?.toString(),
      normalized['mfg_date']?.toString(),
      normalized['manufacturingDate']?.toString(),
      normalized['manufacturing_date']?.toString(),
      normalized['production_date']?.toString(),
    ]);

    if (expiry.isNotEmpty) {
      normalized['expiryDate'] = expiry;
      normalized['expiry_date'] = expiry;
    }
    if (mfg.isNotEmpty) {
      normalized['mfgDate'] = mfg;
      normalized['mfg_date'] = mfg;
      normalized['manufacturing_date'] = mfg;
    }

    normalized['barcode'] = barcode;
    return normalized;
  }

  String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return '';
  }
}
