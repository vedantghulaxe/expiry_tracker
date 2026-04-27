class ConfigService {
  // Oxlo.ai API (OpenAI-compatible endpoint)
  static const String _oxloApiKey = String.fromEnvironment(
    'OXLO_API_KEY',
    defaultValue: 'sk_WEjud3_3D4_KrpFaqIKab8m2aHlWxnH3YGL-u-B8xz0',
  );

  static String get oxloApiKey => _oxloApiKey;

  static const String oxloBaseUrl = 'https://api.oxlo.ai/v1';
  static const String oxloVisionModel = 'ministral-14b';
  static const String oxloTextModel = 'mistral-7b';

  // Legacy getter for backward compatibility
  static String get geminiApiKey => _oxloApiKey;

  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
}