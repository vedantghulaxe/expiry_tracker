import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:expiry_tracker_app/features/product/manual_product_entry_screen.dart';
import 'package:expiry_tracker_app/services/multi_image_service_simple.dart';
import 'package:expiry_tracker_app/core/services/barcode_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Simple Image Capture Screen
class ImageCaptureScreenSimple extends StatefulWidget {
  final bool isMedicine;

  const ImageCaptureScreenSimple({
    super.key,
    required this.isMedicine,
  });

  @override
  State<ImageCaptureScreenSimple> createState() => _ImageCaptureScreenSimpleState();
}

class _ImageCaptureScreenSimpleState extends State<ImageCaptureScreenSimple> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _capturedImages = [];
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
      ),
      body: Column(
        children: [
          // Image Capture Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Step 1: Capture Image',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                
                // Show captured images
                if (_capturedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
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
                  
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _processImages,
                    icon: _isProcessing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isProcessing ? 'Processing...' : 'Extract Information'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Analysis Results Section
          Expanded(
            child: _buildAnalysisSection(),
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Extraction Complete!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Extracted Text
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
                  child: Text(
                    _analysisResult!['text'] ?? 'No text found',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
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
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _analysisResult = null;
                            _capturedImages.clear();
                          });
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('New Scan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (mounted) {
          setState(() {
            _capturedImages.add(File(image.path));
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to capture image: $e';
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (image != null) {
        if (mounted) {
          setState(() {
            _capturedImages.add(File(image.path));
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to pick image: $e';
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _capturedImages.removeAt(index);
    });
  }

  Future<void> _processImages() async {
    if (_capturedImages.isEmpty) return;

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
        _analysisResult = null;
      });
    }

    try {
      final result = await MultiImageServiceSimple.processMultipleImages(_capturedImages);
      
      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to process images: $e';
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _scanBarcode() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onBarcodeScanned: (barcode) async {
            Navigator.pop(context);
            await _processBarcode(barcode);
          },
        ),
      ),
    );
  }

  Future<void> _processBarcode(String barcode) async {
    if (!mounted) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      print('=== PROCESSING BARCODE: $barcode ===');
      
      // Get product info from barcode
      final productInfo = await BarcodeService.getProductInfo(barcode);
      final normalized = _normalizeBarcodeProductInfo(productInfo, barcode);
      
      // Create analysis result in the same format as image processing
      final result = {
        'success': true,
        'text': normalized['name'] ?? 'Unknown Product',
        'raw_text': 'Barcode: $barcode',
        'method': 'barcode',
        'confidence': normalized['confidence'] ?? 0.8,
        'word_count': 1,
        'parsed_data': {
          'success': true,
          'name': normalized['name'],
          'brand': normalized['brand'],
          'category': normalized['category'],
          'ingredients': normalized['ingredients'],
          'expiryDate': normalized['expiryDate'],
          'mfgDate': normalized['mfgDate'],
          'expiry_date': normalized['expiryDate'],
          'mfg_date': normalized['mfgDate'],
          'manufacturing_date': normalized['mfgDate'],
          'isMedicine': normalized['isMedicine'] ?? widget.isMedicine,
          'confidence': normalized['confidence'] ?? 0.8,
          'source': normalized['source'] ?? 'Barcode Scan',
          'raw_data': normalized,
          'barcode': barcode,
        },
        'barcode': barcode,
      };
      
      print('=== BARCODE PROCESSING COMPLETE ===');
      print('Result: $result');
      
      if (!mounted) return;
      
      setState(() {
        _analysisResult = result;
        _isProcessing = false;
      });
    } catch (e) {
      print('=== BARCODE PROCESSING ERROR: $e ===');
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to process barcode: $e';
        _isProcessing = false;
      });
    }
  }

  Map<String, dynamic> _normalizeBarcodeProductInfo(
    Map<String, dynamic> productInfo,
    String barcode,
  ) {
    final normalized = Map<String, dynamic>.from(productInfo);
    final rawData = normalized['raw_data'] is Map
        ? Map<String, dynamic>.from(normalized['raw_data'] as Map)
        : <String, dynamic>{};
    normalized['barcode'] = barcode;

    final expiry = _firstNonEmpty([
      normalized['expiryDate']?.toString(),
      normalized['expiry_date']?.toString(),
      normalized['expirationDate']?.toString(),
      normalized['expiration_date']?.toString(),
      normalized['best_before']?.toString(),
      normalized['use_by']?.toString(),
      rawData['expiryDate']?.toString(),
      rawData['expiry_date']?.toString(),
      rawData['expiration_date']?.toString(),
      rawData['best_before']?.toString(),
      rawData['use_by']?.toString(),
    ]);
    final mfg = _firstNonEmpty([
      normalized['mfgDate']?.toString(),
      normalized['mfg_date']?.toString(),
      normalized['manufacturingDate']?.toString(),
      normalized['manufacturing_date']?.toString(),
      normalized['production_date']?.toString(),
      rawData['mfgDate']?.toString(),
      rawData['mfg_date']?.toString(),
      rawData['manufacturing_date']?.toString(),
      rawData['production_date']?.toString(),
    ]);
    final ingredients = _firstNonEmpty([
      normalized['ingredients']?.toString(),
      normalized['ingredient']?.toString(),
      normalized['composition']?.toString(),
      normalized['description']?.toString(),
      rawData['ingredients']?.toString(),
      rawData['ingredient']?.toString(),
      rawData['composition']?.toString(),
      rawData['description']?.toString(),
    ]);

    if (expiry.isNotEmpty) normalized['expiryDate'] = expiry;
    if (mfg.isNotEmpty) normalized['mfgDate'] = mfg;
    if (ingredients.isNotEmpty) normalized['ingredients'] = ingredients;
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

/// Barcode Scanner Screen
class BarcodeScannerScreen extends StatefulWidget {
  final Function(String) onBarcodeScanned;

  const BarcodeScannerScreen({
    super.key,
    required this.onBarcodeScanned,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              widget.onBarcodeScanned(barcode.rawValue!);
              return;
            }
          }
        },
      ),
    );
  }
}
