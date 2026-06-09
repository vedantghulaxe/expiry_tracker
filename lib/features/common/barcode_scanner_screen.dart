import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
    formats: [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.itf,
      BarcodeFormat.codabar,
      BarcodeFormat.qrCode,
    ],
  );

  bool _isScanning = true;
  String? _lastScannedBarcode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('=== BARCODE SCANNER INITIALIZED ===');
    print('Camera facing: back');
    print('Detection speed: normal');
    print('Supported formats: EAN-13, EAN-8, UPC-A, UPC-E, Code128, Code39, Code93, ITF, Codabar, QR');
  }

  @override
  void dispose() {
    print('=== BARCODE SCANNER DISPOSED ===');
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
            icon: const Icon(Icons.flash_auto),
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
            errorBuilder: (context, error, child) {
              print('=== BARCODE SCANNER ERROR ===');
              print('Error: $error');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Camera Error',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showManualEntry,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Enter Barcode Manually'),
                    ),
                  ],
                ),
              );
            },
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

          // Manual Entry Button (always visible at bottom)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton.icon(
              onPressed: _showManualEntry,
              icon: const Icon(Icons.keyboard),
              label: const Text('Enter Barcode Manually'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Last Scanned Barcode Display
          if (_lastScannedBarcode != null)
            Positioned(
              bottom: 80,
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
    
    print('=== BARCODE SCANNER DEBUG ===');
    print('Barcodes detected: ${barcodes.length}');

    for (final barcode in barcodes) {
      print('Barcode type: ${barcode.type}');
      print('Barcode format: ${barcode.format}');
      print('Barcode raw value: ${barcode.rawValue}');
      print('Barcode display value: ${barcode.displayValue}');
      
      if (barcode.rawValue != null) {
        setState(() {
          _lastScannedBarcode = barcode.rawValue;
          _isScanning = false;
        });

        print('✅ Barcode scanned successfully: ${barcode.rawValue}');

        // Auto-proceed after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _lastScannedBarcode != null) {
            Navigator.pop(context, _lastScannedBarcode);
          }
        });

        break;
      } else {
        print('⚠️ Barcode detected but rawValue is null');
      }
    }
    
    if (barcodes.isEmpty) {
      print('⚠️ No barcodes in capture');
    }
  }

  void _showManualEntry() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Barcode'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            hintText: 'Enter barcode number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final barcode = controller.text.trim();
              if (barcode.isNotEmpty) {
                Navigator.pop(context);
                Navigator.pop(context, barcode);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
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
