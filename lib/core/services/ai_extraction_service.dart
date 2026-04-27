import 'logger_service.dart';

/// AI Extraction Service
class AIExtractionService {
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    LoggerService.info('AI_EXTRACTION', 'AI service initialized');
  }

  static bool get isInitialized => _isInitialized;
}
