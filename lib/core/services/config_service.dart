class ConfigService {
  // ========================================
  // 🚀 GROQ API CONFIGURATION (RECOMMENDED)
  // ========================================
  // Groq provides ultra-fast inference with better accuracy
  // Free tier: 30 requests/minute, 14,400 requests/day

  static const String _groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static String get oxloApiKey => _groqApiKey;

  // Groq API Configuration
  static const String oxloBaseUrl = 'https://api.groq.com/openai/v1';
  static const String oxloVisionModel =
      'llama-3.2-11b-vision-preview'; // Fast & accurate
  static const String oxloTextModel =
      'llama-3.3-70b-versatile'; // Best for text extraction

  // Alternative models (if you need more power):
  // Vision: 'llama-3.2-90b-vision-preview' (slower but more accurate)
  // Text: 'mixtral-8x7b-32768' (faster but less accurate)

  // ========================================
  // 📊 OLD OXLO.AI CONFIGURATION (BACKUP)
  // ========================================
  // Uncomment below to switch back to Oxlo.ai
  /*
  static const String _oxloApiKey = String.fromEnvironment(
    'OXLO_API_KEY',
    defaultValue: 'sk_WEjud3_3D4_KrpFaqIKab8m2aHlWxnH3YGL-u-B8xz0',
  );
  static String get oxloApiKey => _oxloApiKey;
  static const String oxloBaseUrl = 'https://api.oxlo.ai/v1';
  static const String oxloVisionModel = 'ministral-14b';
  static const String oxloTextModel = 'mistral-7b';
  */

  // Legacy getter for backward compatibility
  static String get geminiApiKey => _groqApiKey;

  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxImageSizeBytes = 10 * 1024 * 1024; // 10MB
}
