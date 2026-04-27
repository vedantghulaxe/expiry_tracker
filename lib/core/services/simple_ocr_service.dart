import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'logger_service.dart';

class OCRService {
  bool _isInitialized = false;
  late TextRecognizer _textRecognizer;
  late BarcodeScanner _barcodeScanner;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _barcodeScanner = BarcodeScanner();
    _isInitialized = true;
  }

  Future<Map<String, dynamic>> processImage(String imagePath) async {
    if (kIsWeb) return {'barcode': null, 'text': ''};
    
    final File file = File(imagePath);
    if (!await file.exists()) return {'barcode': null, 'text': ''};

    final inputImage = InputImage.fromFilePath(imagePath);
    
    try {
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
      String? barcode = barcodes.isNotEmpty ? barcodes.first.rawValue : null;

      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      return {
        'barcode': barcode,
        'text': recognizedText.text,
      };
    } catch (e) {
      LoggerService.error('OCR', 'ML Kit error: $e');
      return {'barcode': null, 'text': ''};
    }
  }

  void dispose() {
    if (_isInitialized && !kIsWeb) {
      _textRecognizer.close();
      _barcodeScanner.close();
    }
  }
}
