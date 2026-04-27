import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';

enum BiometricStatus { available, unavailable, disabled, not_enrolled, error }

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  static const String _authEnabledKey = 'biometric_auth_enabled';
  static const String _lastAuthTimeKey = 'last_biometric_auth_time';
  static const String _authTimeoutKey = 'biometric_auth_timeout';
  static const String _failedAttemptsKey = 'biometric_failed_attempts';

  final LocalAuthentication _auth = LocalAuthentication();

  bool _isInitialized = false;
  DateTime? _lastSuccessfulAuth;
  int _failedAttempts = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      LoggerService.info('BIOMETRIC', 'Initializing biometric service...');
      
      final isAvailable = await _auth.isDeviceSupported().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          LoggerService.warning('BIOMETRIC', 'Biometric check timed out - assuming not available');
          return false;
        },
      );
      
      if (!isAvailable) {
        LoggerService.warning('BIOMETRIC', 'Biometric authentication not available on this device');
      } else {
        LoggerService.success('BIOMETRIC', 'Biometric authentication is available');
        
        // Check available biometrics with timeout
        try {
          final availableBiometrics = await _auth.getAvailableBiometrics().timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              LoggerService.warning('BIOMETRIC', 'Available biometrics check timed out');
              return <BiometricType>[];
            },
          );
          LoggerService.info('BIOMETRIC', 'Available biometrics: ${availableBiometrics.map((b) => b.name)}');
        } catch (e) {
          LoggerService.warning('BIOMETRIC', 'Failed to get available biometrics: $e');
        }
      }
      
      // Load failed attempts with timeout
      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            LoggerService.warning('BIOMETRIC', 'SharedPreferences access timed out');
            throw Exception('Timeout');
          },
        );
        _failedAttempts = prefs.getInt(_failedAttemptsKey) ?? 0;
      } catch (e) {
        LoggerService.warning('BIOMETRIC', 'Failed to load failed attempts: $e');
      }
      
      _isInitialized = true;
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Failed to initialize biometric service: $e');
      _isInitialized = true; // Mark as initialized even on failure to prevent retries
    }
  }

  Future<bool> get isAuthEnabled async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Default to FALSE so users explicitly enable biometrics
      return prefs.getBool(_authEnabledKey) ?? false;
    } catch (e) {
      print('Error checking auth enabled status: $e');
      return false;
    }
  }

  Future<void> setAuthEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_authEnabledKey, enabled);
    } catch (e) {
      print('Error setting auth enabled status: $e');
    }
  }

  Future<bool> get isBiometricAvailable async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  Future<BiometricType> get availableBiometrics async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      
      if (availableBiometrics.contains(BiometricType.iris)) {
        return BiometricType.iris;
      } else if (availableBiometrics.contains(BiometricType.face)) {
        return BiometricType.face;
      } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      
      return BiometricType.weak; // Use weak as default instead of none
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Error getting available biometrics: $e');
      return BiometricType.weak;
    }
  }

  /// Get comprehensive biometric status
  Future<BiometricStatus> getBiometricStatus() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      // Check if device supports biometrics
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        return BiometricStatus.unavailable;
      }
      
      // Check if biometrics are enrolled
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        return BiometricStatus.not_enrolled;
      }
      
      // Check if user has enabled biometric auth
      final isEnabled = await isAuthEnabled;
      if (!isEnabled) {
        return BiometricStatus.disabled;
      }
      
      return BiometricStatus.available;
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Error checking biometric status: $e');
      return BiometricStatus.error;
    }
  }

  /// Get all available biometric types
  Future<List<BiometricType>> getAllAvailableBiometrics() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.toList();
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Error getting all available biometrics: $e');
      return [];
    }
  }

  /// Check if authentication is needed based on timeout
  Future<bool> isAuthenticationNeeded({Duration? timeout}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final authEnabled = await isAuthEnabled;
    if (!authEnabled) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final timeoutMinutes = prefs.getInt(_authTimeoutKey) ?? 5;
    final effectiveTimeout = timeout ?? Duration(minutes: timeoutMinutes);
    
    final lastAuthTime = prefs.getString(_lastAuthTimeKey);
    if (lastAuthTime == null) return true;
    
    final lastAuth = DateTime.parse(lastAuthTime);
    final now = DateTime.now();
    
    return now.difference(lastAuth) > effectiveTimeout;
  }

  /// Get authentication timeout in minutes
  Future<int> getAuthTimeoutMinutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_authTimeoutKey) ?? 5;
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Error getting auth timeout: $e');
      return 5;
    }
  }

  /// Set authentication timeout in minutes
  Future<void> setAuthTimeoutMinutes(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_authTimeoutKey, minutes);
      LoggerService.info('BIOMETRIC', 'Auth timeout set to $minutes minutes');
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Error setting auth timeout: $e');
    }
  }

  /// Get failed attempts count
  int get failedAttempts => _failedAttempts;

  /// Reset failed attempts
  Future<void> resetFailedAttempts() async {
    try {
      _failedAttempts = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_failedAttemptsKey, 0);
      LoggerService.success('BIOMETRIC', 'Failed attempts reset successfully');
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Error resetting failed attempts: $e');
    }
  }

  /// Check if user is locked out due to too many failed attempts
  bool get isLockedOut => _failedAttempts >= 5;

  Future<bool> authenticate({
    String reason = 'Authenticate to access your inventory',
    bool useErrorDialogs = true,
    bool biometricOnly = false,
    bool stickyAuth = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    LoggerService.info('BIOMETRIC', '=== AUTHENTICATE START ===');
    LoggerService.info('BIOMETRIC', 'Reason: $reason');
    LoggerService.info('BIOMETRIC', 'Biometric only: $biometricOnly');
    
    // Check if user is locked out
    if (isLockedOut) {
      LoggerService.warning('BIOMETRIC', 'User is locked out due to too many failed attempts');
      return false;
    }
    
    try {
      final isAvailable = await _auth.isDeviceSupported();
      LoggerService.info('BIOMETRIC', 'Device supported: $isAvailable');
      if (!isAvailable) {
        LoggerService.warning('BIOMETRIC', 'Biometric authentication not available');
        return false;
      }

      LoggerService.info('BIOMETRIC', 'Starting biometric authentication (Max 8s timeout)');
      
      final authenticated = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
        ),
      ).timeout(const Duration(seconds: 8)); // 8s timeout for the system dialog

      if (authenticated) {
        // Reset failed attempts on success
        await resetFailedAttempts();
        
        // Update last successful authentication time
        _lastSuccessfulAuth = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastAuthTimeKey, _lastSuccessfulAuth!.toIso8601String());
        
        LoggerService.success('BIOMETRIC', 'Biometric authentication successful');
      } else {
        // Increment failed attempts
        _failedAttempts++;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_failedAttemptsKey, _failedAttempts);
        
        LoggerService.warning('BIOMETRIC', 'Biometric authentication failed. Attempts: $_failedAttempts');
      }

      return authenticated;
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Authentication error: $e');
      // DO NOT increment failed attempts on system errors/timeouts
      return false;
    }
  }

  /// Quick authentication check (no UI dialogs)
  Future<bool> quickAuthenticate() async {
    return await authenticate(
      reason: 'Quick authentication',
      useErrorDialogs: false,
      biometricOnly: true,
    );
  }

  /// Authenticate with timeout
  Future<bool> authenticateWithTimeout({
    String reason = 'Authenticate to access your inventory',
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await authenticate(reason: reason).timeout(timeout);
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Authentication timeout: $e');
      return false;
    }
  }

  /// Get biometric status summary
  Future<Map<String, dynamic>> getBiometricSummary() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      final status = await getBiometricStatus();
      final availableBiometrics = await getAllAvailableBiometrics();
      final isAvailable = await isBiometricAvailable;
      final isEnabled = await isAuthEnabled;
      final isNeeded = await isAuthenticationNeeded();
      final timeoutMinutes = await getAuthTimeoutMinutes();
      
      return {
        'status': status.name,
        'isAvailable': isAvailable,
        'isEnabled': isEnabled,
        'isNeeded': isNeeded,
        'availableBiometrics': availableBiometrics.map((b) => b.name).toList(),
        'failedAttempts': _failedAttempts,
        'isLockedOut': isLockedOut,
        'timeoutMinutes': timeoutMinutes,
        'lastSuccessfulAuth': _lastSuccessfulAuth?.toIso8601String(),
      };
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Error getting biometric summary: $e');
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }

  Future<bool> canCheckBiometrics() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      print('Error checking biometrics capability: $e');
      return false;
    }
  }

  String getBiometricTypeText(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris Scanner';
      case BiometricType.weak:
        return 'Device PIN/Pattern';
      case BiometricType.strong:
        return 'Strong Biometric';
      default:
        return 'Not Available';
    }
  }

  /// Get biometric type icon
  IconData getBiometricTypeIcon(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.face:
        return Icons.face;
      case BiometricType.iris:
        return Icons.visibility;
      case BiometricType.weak:
        return Icons.pin;
      case BiometricType.strong:
        return Icons.security;
      default:
        return Icons.security;
    }
  }

  /// Get biometric status text
  String getBiometricStatusText(BiometricStatus status) {
    switch (status) {
      case BiometricStatus.available:
        return 'Available';
      case BiometricStatus.unavailable:
        return 'Not Supported';
      case BiometricStatus.disabled:
        return 'Disabled';
      case BiometricStatus.not_enrolled:
        return 'Not Enrolled';
      case BiometricStatus.error:
      default:
        return 'Error';
    }
  }

  /// Get biometric status color
  Color getBiometricStatusColor(BiometricStatus status) {
    switch (status) {
      case BiometricStatus.available:
        return Colors.green;
      case BiometricStatus.unavailable:
        return Colors.grey;
      case BiometricStatus.disabled:
        return Colors.orange;
      case BiometricStatus.not_enrolled:
        return Colors.red;
      case BiometricStatus.error:
      default:
        return Colors.red;
    }
  }

  /// Get biometric status icon
  IconData getBiometricStatusIcon(BiometricStatus status) {
    switch (status) {
      case BiometricStatus.available:
        return Icons.check_circle;
      case BiometricStatus.unavailable:
        return Icons.device_unknown;
      case BiometricStatus.disabled:
        return Icons.lock_open;
      case BiometricStatus.not_enrolled:
        return Icons.person_off;
      case BiometricStatus.error:
      default:
        return Icons.error;
    }
  }

  /// Test biometric authentication (for debugging)
  Future<Map<String, dynamic>> testBiometrics() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    final results = <String, dynamic>{};
    
    try {
      // Test device support
      results['deviceSupported'] = await _auth.isDeviceSupported();
      
      // Test biometric checking
      results['canCheckBiometrics'] = await _auth.canCheckBiometrics;
      
      // Test available biometrics
      final availableBiometrics = await _auth.getAvailableBiometrics();
      results['availableBiometrics'] = availableBiometrics.map((b) => b.name).toList();
      
      // Test authentication (without actually showing UI)
      results['authenticationTest'] = 'Authentication can be tested with authenticate() method';
      
      LoggerService.info('BIOMETRIC', 'Biometric test completed: $results');
      
      return results;
    } catch (e) {
      LoggerService.error('BIOMETRIC', 'Biometric test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Force re-initialization (for testing)
  Future<void> forceReinitialize() async {
    _isInitialized = false;
    await initialize();
  }

  Future<void> clearSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authEnabledKey);
    } catch (e) {
      print('Error clearing security settings: $e');
    }
  }
}
