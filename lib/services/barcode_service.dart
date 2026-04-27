import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../core/services/logger_service.dart';

class BarcodeService {
  static MobileScannerController? _controller;
  static bool _isInitialized = false;

  /// Initialize barcode scanner
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      await _controller?.start();
      _isInitialized = true;
      LoggerService.success('BARCODE', 'Barcode scanner initialized');
    } catch (e) {
      LoggerService.error('BARCODE', 'Failed to initialize: $e');
      rethrow;
    }
  }

  /// Get current controller
  static MobileScannerController? get controller => _controller;

  /// Start scanning with callback
  static void startScanning(Function(String) onBarcodeDetected) {
    if (_controller == null) {
      LoggerService.error('BARCODE', 'Controller not initialized');
      return;
    }

    _controller!.start().then((_) {
      _controller!.barcodes.listen((capture) {
        final List<Barcode> barcodes = capture.barcodes;
        if (barcodes.isNotEmpty) {
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && code.isNotEmpty) {
              LoggerService.info('BARCODE', 'Detected: $code');
              onBarcodeDetected(code);
              break; // Process first valid barcode
            }
          }
        }
      });
    });
  }

  /// Stop scanning
  static Future<void> stopScanning() async {
    try {
      await _controller?.stop();
      LoggerService.info('BARCODE', 'Scanner stopped');
    } catch (e) {
      LoggerService.error('BARCODE', 'Failed to stop scanner: $e');
    }
  }

  /// Toggle torch/flash
  static Future<void> toggleTorch() async {
    try {
      await _controller?.toggleTorch();
    } catch (e) {
      LoggerService.error('BARCODE', 'Failed to toggle torch: $e');
    }
  }

  /// Dispose scanner
  static Future<void> dispose() async {
    try {
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      LoggerService.info('BARCODE', 'Scanner disposed');
    } catch (e) {
      LoggerService.error('BARCODE', 'Failed to dispose scanner: $e');
    }
  }

  /// Validate barcode format
  static bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return false;
    
    // Check for common barcode formats
    final patterns = [
      RegExp(r'^\d{8}$'),        // EAN-8
      RegExp(r'^\d{13}$'),       // EAN-13
      RegExp(r'^\d{12}$'),       // UPC-A
      RegExp(r'^\d{14}$'),       // ITF-14
    ];

    return patterns.any((pattern) => pattern.hasMatch(barcode));
  }
}
