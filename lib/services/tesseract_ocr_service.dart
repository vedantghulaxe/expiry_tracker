// DISABLED: Tesseract OCR not properly configured
// This service is not currently used in the app
// The app uses Google ML Kit for OCR instead

import 'dart:io';

/// Placeholder Tesseract OCR Service (Disabled)
class TesseractOCRService {
  static bool _isInitialized = false;
  
  static Future<void> initialize() async {
    _isInitialized = false;
  }
  
  static Future<String> extractTextFromImage(File imageFile) async {
    return '';
  }
  
  static Future<String> extractTextFromMultipleImages(List<File> images) async {
    return '';
  }
  
  static Future<bool> isTesseractAvailable() async {
    return false;
  }
  
  static Future<File> preprocessImage(File imageFile) async {
    return imageFile;
  }
  
  static double getConfidenceScore(String extractedText) {
    return 0.0;
  }
}
