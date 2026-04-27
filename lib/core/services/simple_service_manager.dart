import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_service.dart';
import 'biometric_service.dart';
import 'ai_extraction_service.dart';
import 'logger_service.dart';
import 'database_service.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/medicine_repository.dart';

/// Simple Service Manager
/// Handles all service initialization with proper error handling
class SimpleServiceManager {
  static final SimpleServiceManager _instance =
      SimpleServiceManager._internal();
  factory SimpleServiceManager() => _instance;
  SimpleServiceManager._internal();

  // Service instances
  bool _isInitialized = false;

  /// Initialize all services in proper order
  Future<void> initializeServices() async {
    if (_isInitialized) {
      LoggerService.info('SERVICE_MANAGER', 'Services already initialized');
      return;
    }

    LoggerService.info(
      'SERVICE_MANAGER',
      '=== Starting Service Initialization ===',
    );

    // Theme — required
    try {
      await ThemeService.init();
    } catch (e) {
      LoggerService.warning('SERVICE_MANAGER', 'ThemeService init failed: $e');
    }

    // Database — required, but don't block other services
    try {
      await DatabaseService().initialize();
      LoggerService.success('SERVICE_MANAGER', 'Database initialized');
    } catch (e) {
      LoggerService.error('SERVICE_MANAGER', 'Database init failed: $e');
    }

    // AI service — optional
    try {
      await AIExtractionService.initialize();
      LoggerService.success('SERVICE_MANAGER', 'AI service initialized');
    } catch (e) {
      LoggerService.warning('SERVICE_MANAGER', 'AI service init failed (non-fatal): $e');
    }

    // Biometric — required for auth, but don't crash if unavailable
    try {
      await BiometricService().initialize();
      LoggerService.success('SERVICE_MANAGER', 'Biometric service initialized');
    } catch (e) {
      LoggerService.warning('SERVICE_MANAGER', 'Biometric init failed (non-fatal): $e');
    }

    _isInitialized = true;
    LoggerService.success(
      'SERVICE_MANAGER',
      '=== All services initialized ===',
    );
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;
}
