import 'logger_service.dart';

/// Web-compatible OCR service that provides manual fallback only
class OCRService {
  bool _isInitialized = false;

  /// Initialize OCR services (web version)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    LoggerService.warning('OCR', 'Web platform detected - using manual input mode');
    _isInitialized = true;
  }

  /// Extract Text and Barcode from image (web stub)
  Future<Map<String, dynamic>> processImage(String imagePath) async {
    LoggerService.start('OCR_PIPELINE', 'Web processing - manual input mode');
    
    return {
      'barcode': null,
      'text': '',
      'method': 'web_manual',
      'message': 'Web platform - please enter data manually',
    };
  }

  void dispose() {
    LoggerService.info('OCR', 'Web OCR service disposed');
  }
}
