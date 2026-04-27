import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:expiry_tracker_app/features/product/manual_product_entry_screen.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';
import 'package:expiry_tracker_app/core/services/barcode_service.dart';
import 'package:expiry_tracker_app/core/services/local_parser_service.dart';
import 'package:expiry_tracker_app/services/multi_image_service_simple.dart';

/// Fixed Image Capture Screen with Real OCR and Barcode Scanning
class ImageCaptureScreenFixed extends StatefulWidget {
  final bool isMedicine;

  const ImageCaptureScreenFixed({
    super.key,
    required this.isMedicine,
  });

  @override
  State<ImageCaptureScreenFixed> createState() => _ImageCaptureScreenFixedState();
}

class _ImageCaptureScreenFixedState extends State<ImageCaptureScreenFixed> {
  final ImagePicker _picker = ImagePicker();
  List<File> _capturedImages = [];
  bool _isProcessing = false;
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.isMedicine ? 'Scan Medicine' : 'Scan Product',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Step 1: Capture Images or Scan Barcode',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          
          // Capture Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _captureImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Capture Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
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
                  label: const Text('Choose from Gallery'),
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
          
          const SizedBox(height: 16),
          
          // Captured Images Preview
          if (_capturedImages.isNotEmpty) ...[
            Text(
              'Captured Images (${_capturedImages.length})',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _capturedImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _capturedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 14,
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
          
          // Analyze Button
          if (_capturedImages.isNotEmpty)
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: Text(_isProcessing ? 'Analyzing...' : 'Analyze Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Analyzing images...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_analysisResult == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No images captured yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Capture or select images to begin analysis',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: _buildResultsWidget(),
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
        case 'barcode':
          return 'Barcode Scan';
        case 'fallback':
          return 'Fallback';
        default:
          return 'Unknown';
      }
    }
    
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
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
                  result['success'] == true ? 'Extraction Complete' : 'Processing Complete',
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
                child: _buildStatCard('Method', getMethodDisplayName(ocrMethod), 
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
          
          // Parsed Data Display (NEW)
          if (result['parsed_data'] != null || result['success'] == true) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '📋 Extracted Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildParsedDataDisplay(result['parsed_data'] ?? {}),
                ],
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }

  Widget _buildParsedDataDisplay(Map<String, dynamic> parsedData) {
    print('=== BUILDING PARSED DATA DISPLAY ===');
    print('Parsed Data: $parsedData');
    
    // Always show at least basic info
    final fields = [
      {'label': 'Product Name', 'value': parsedData['name'] ?? 'Unknown', 'icon': Icons.inventory_2},
      {'label': 'Brand', 'value': parsedData['brand'] ?? 'Not detected', 'icon': Icons.business},
      {'label': 'Category', 'value': parsedData['category'] ?? 'product', 'icon': Icons.category},
      {'label': 'Expiry Date', 'value': parsedData['expiryDate'] ?? 'Not found', 'icon': Icons.event},
      {'label': 'Mfg Date', 'value': parsedData['mfgDate'] ?? 'Not found', 'icon': Icons.calendar_today},
      {'label': 'Batch Number', 'value': parsedData['batchNumber'] ?? 'Not found', 'icon': Icons.tag},
      {'label': 'Dosage', 'value': parsedData['dosage'] ?? 'Not applicable', 'icon': Icons.medication},
      {'label': 'Uses', 'value': parsedData['uses'] ?? 'Not detected', 'icon': Icons.healing},
      {'label': 'Warnings', 'value': parsedData['warnings'] ?? 'Not detected', 'icon': Icons.warning},
      {'label': 'Ingredients', 'value': parsedData['ingredients'] ?? 'Not detected', 'icon': Icons.list},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with confidence
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Analysis Results (${fields.length} fields)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            if (parsedData['confidence'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(parsedData['confidence']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${((parsedData['confidence'] as num) * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Display all fields (even empty ones for visibility)
        ...fields.map((field) {
          final value = field['value']?.toString() ?? 'Not detected';
          final isEmpty = value == 'Not detected' || value == 'Not found' || value == 'Not applicable';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isEmpty ? Colors.grey.shade100 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEmpty ? Colors.grey.shade300 : Colors.green.shade200,
                width: isEmpty ? 1 : 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  field['icon'] as IconData,
                  size: 18,
                  color: isEmpty ? Colors.grey.shade500 : Colors.green.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isEmpty ? Colors.grey.shade600 : Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          color: isEmpty ? Colors.grey.shade600 : Colors.grey.shade800,
                          fontWeight: isEmpty ? FontWeight.normal : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEmpty)
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green.shade600,
                  ),
              ],
            ),
          );
        }).toList(),
        
        // Action buttons
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to manual entry with this data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManualProductEntryScreen(
                        isMedicine: widget.isMedicine,
                        analysisData: _analysisResult,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Fill Form'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Raw Extracted Data'),
                      content: SingleChildScrollView(
                        child: Text(
                          parsedData.toString(),
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
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
                icon: const Icon(Icons.code, size: 16),
                label: const Text('Raw Data'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue.shade700,
                  side: BorderSide(color: Colors.blue.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getConfidenceColor(num confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_analysisResult == null || _isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _proceedToForm,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Proceed to Form'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF075E54),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _retryCapture,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF075E54)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Action Methods
  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _capturedImages.add(File(image.path));
          _errorMessage = null;
        });
        LoggerService.success('IMAGE_CAPTURE', 'Captured image from camera');
      }
    } catch (e) {
      LoggerService.error('IMAGE_CAPTURE', 'Failed to capture image: $e');
      setState(() {
        _errorMessage = 'Failed to capture image: $e';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _capturedImages.add(File(image.path));
          _errorMessage = null;
        });
        LoggerService.success('IMAGE_CAPTURE', 'Selected image from gallery');
      }
    } catch (e) {
      LoggerService.error('IMAGE_CAPTURE', 'Failed to pick image: $e');
      setState(() {
        _errorMessage = 'Failed to select image: $e';
      });
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
      
      setState(() {
        _analysisResult = {
          'success': true,
          'text': productInfo['name'] ?? 'Unknown Product',
          'raw_text': productInfo['name'] ?? 'Unknown Product',
          'method': 'barcode',
          'confidence': productInfo['confidence'] ?? 0.5,
          'word_count': 1,
          'parsed_data': productInfo,
          'enhanced': false,
          'image_count': 0,
          'ocr_method': 'barcode',
          'ocr_confidence': productInfo['confidence'] ?? 0.5,
          'warning': productInfo['confidence'] != null && productInfo['confidence'] < 0.7 
              ? 'Low confidence barcode result' 
              : null,
          'is_low_confidence': (productInfo['confidence'] ?? 0.5) < 0.7,
          'barcode': barcode,
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
      print('=== Starting OCR Analysis ===');
      print('Images to analyze: ${_capturedImages.length}');
      
      final result = await MultiImageServiceSimple.processMultipleImages(_capturedImages);
      
      print('=== OCR Analysis Complete ===');
      print('Success: ${result['success']}');
      print('Text: ${result['text']}');
      print('Method: ${result['ocr_method']}');
      
      setState(() {
        _analysisResult = result;
        _isProcessing = false;
      });
      
    } catch (e) {
      print('=== OCR Analysis Error ===');
      print('Error: $e');
      
      setState(() {
        _errorMessage = 'Analysis failed: $e';
        _isProcessing = false;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
      _analysisResult = null;
    });
  }

  void _clearImages() {
    setState(() {
      _capturedImages.clear();
      _analysisResult = null;
      _errorMessage = null;
    });
  }

  void _retryCapture() {
    _clearImages();
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
}

/// Barcode Scanner Screen
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanning = true;
  String? _lastScannedBarcode;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          
          // Scanner Overlay
          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(),
          ),
          
          // Instructions
          Positioned(
            top: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Align barcode within frame',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scanning will happen automatically',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Last Scanned Barcode Display
          if (_lastScannedBarcode != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Barcode Scanned!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _lastScannedBarcode!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _lastScannedBarcode);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green,
                      ),
                      child: const Text('Use This Barcode'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _lastScannedBarcode = barcode.rawValue;
          _isScanning = false;
        });
        
        // Auto-proceed after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _lastScannedBarcode != null) {
            Navigator.pop(context, _lastScannedBarcode);
          }
        });
        
        break;
      }
    }
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Create scan window (centered rectangle)
    final scanWindowWidth = size.width * 0.7;
    final scanWindowHeight = size.height * 0.3;
    final scanWindowLeft = (size.width - scanWindowWidth) / 2;
    final scanWindowTop = (size.height - scanWindowHeight) / 2;

    // Draw overlay (everything except the scan window)
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(Rect.fromLTWH(scanWindowLeft, scanWindowTop, scanWindowWidth, scanWindowHeight))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw scan window border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(scanWindowLeft, scanWindowTop, scanWindowWidth, scanWindowHeight),
        const Radius.circular(12),
      ),
      strokePaint,
    );

    // Draw corner indicators
    final cornerLength = 20.0;
    final cornerWidth = 4.0;
    
    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindowLeft, scanWindowTop + cornerLength)
        ..lineTo(scanWindowLeft, scanWindowTop)
        ..lineTo(scanWindowLeft + cornerLength, scanWindowTop),
      strokePaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindowLeft + scanWindowWidth - cornerLength, scanWindowTop)
        ..lineTo(scanWindowLeft + scanWindowWidth, scanWindowTop)
        ..lineTo(scanWindowLeft + scanWindowWidth, scanWindowTop + cornerLength),
      strokePaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindowLeft, scanWindowTop + scanWindowHeight - cornerLength)
        ..lineTo(scanWindowLeft, scanWindowTop + scanWindowHeight)
        ..lineTo(scanWindowLeft + cornerLength, scanWindowTop + scanWindowHeight),
      strokePaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanWindowLeft + scanWindowWidth - cornerLength, scanWindowTop + scanWindowHeight)
        ..lineTo(scanWindowLeft + scanWindowWidth, scanWindowTop + scanWindowHeight)
        ..lineTo(scanWindowLeft + scanWindowWidth, scanWindowTop + scanWindowHeight - cornerLength),
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
