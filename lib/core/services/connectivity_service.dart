import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity service for network status management
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _isConnected = true;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();

  /// Current connection status
  bool get isConnected => _isConnected;

  /// Stream of connection status changes
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result == ConnectivityResult.mobile || 
                     result == ConnectivityResult.wifi;

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
        final newStatus = result == ConnectivityResult.mobile || 
                         result == ConnectivityResult.wifi;
        
        if (_isConnected != newStatus) {
          _isConnected = newStatus;
          _connectionController.add(_isConnected);
        }
      });
    } catch (e) {
      _isConnected = false;
    }
  }

  /// Check current connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = result == ConnectivityResult.mobile || 
                     result == ConnectivityResult.wifi;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  /// Execute function only if connected
  static Future<T?> executeIfConnected<T>(
    Future<T> Function() function, {
    T? fallbackValue,
  }) async {
    try {
      final instance = ConnectivityService();
      if (await instance.checkConnectivity()) {
        final result = await function().timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Timeout'),
        );
        return result;
      }
    } catch (e) {
      // Silently handle errors
    }
    return fallbackValue;
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription.cancel();
    _connectionController.close();
  }
}
