import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme_service.dart';
import 'biometric_service.dart';
import 'ai_extraction_service.dart';
import 'logger_service.dart';
import 'database_service.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/medicine_repository.dart';

/// Simplified Service Manager
/// Handles all service initialization with proper error handling
class AppServiceManager {
  static final AppServiceManager _instance = AppServiceManager._internal();
  factory AppServiceManager() => _instance;
  AppServiceManager._internal();

  // Service states
  bool _isInitialized = false;

  /// Initialize all services in proper order
  Future<void> initializeServices() async {
    if (_isInitialized) {
      LoggerService.info('SERVICE_MANAGER', 'Services already initialized');
      return;
    }

    LoggerService.info('SERVICE_MANAGER', '=== Starting Service Initialization ===');

    try {
      // Initialize services in order
      await ThemeService.init();
      await DatabaseService().initialize();
      
      LoggerService.success('SERVICE_MANAGER', '=== All services initialized successfully ===');
      _isInitialized = true;
      
    } catch (e, stackTrace) {
      LoggerService.error('SERVICE_MANAGER', 'Service initialization failed: $e');
      LoggerService.error('SERVICE_MANAGER', 'Stack trace: $stackTrace');
      
      // Continue with partial initialization
      _isInitialized = true;
    }
  }

  /// Get initialization status
  bool get isInitialized => _isInitialized;
}
