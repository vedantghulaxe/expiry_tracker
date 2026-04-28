import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/auth/lock_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'core/services/logger_service.dart';
import 'core/services/simple_service_manager.dart';
import 'core/services/theme_service.dart';
import 'core/services/biometric_service.dart';
import 'core/services/notification_service.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  try {
    await NotificationService().initialize();
    LoggerService.success('MAIN', 'Notification service initialized');
  } catch (e) {
    LoggerService.error('MAIN', 'Failed to initialize notifications: $e');
  }

  // We do NOT await initialization here to prevent the black screen freeze.
  // Initialization happens inside the app structure.
  LoggerService.info('MAIN', '=== Launching App ===');
  runApp(const ExpiryTrackerApp());
}

class ExpiryTrackerApp extends StatelessWidget {
  const ExpiryTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Expiry Tracker',
          debugShowCheckedModeBanner: false,
          theme: ThemeService.lightTheme,
          darkTheme: ThemeService.darkTheme,
          themeMode: themeMode,
          home: const AuthWrapper(),
          builder: (context, widget) {
            ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      const Text('Something went wrong!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(errorDetails.exceptionAsString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        ),
                        child: const Text('Reload App'),
                      ),
                    ],
                  ),
                ),
              );
            };
            return widget!;
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _isCheckingAuth = true;
  bool _isAuthenticated = false;
  DateTime? _lastAuthTime;
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize biometric service before checking authentication
    _initializeBiometricService();
  }

  Future<void> _initializeBiometricService() async {
    try {
      // 1. Initialize all core services (inc. Biometrics) first
      // This is non-blocking to the initial UI frame
      await SimpleServiceManager().initializeServices();
      
      await _biometricService.initialize().timeout(const Duration(seconds: 5));
      // Wait for first frame before triggering biometric prompt
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthentication());
    } catch (e) {
      LoggerService.error('AUTH', 'Initialization or Biometric service failure: $e');
      // Allow access if initialization fails (to prevent lockout)
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = true;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Re-authenticate when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _checkIfReauthNeeded();
    }
  }

  Future<void> _checkIfReauthNeeded() async {
    if (_lastAuthTime == null) return;

    final now = DateTime.now();
    final timeSinceLastAuth = now.difference(_lastAuthTime!);

    // Re-authenticate if more than 5 minutes have passed
    if (timeSinceLastAuth.inMinutes > 5) {
      final authEnabled = await _biometricService.isAuthEnabled;
      if (authEnabled) {
        setState(() => _isAuthenticated = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuthentication());
      }
    }
  }

  Future<void> _checkAuthentication() async {
    LoggerService.info('AUTH', '=== CHECKING AUTHENTICATION ===');
    try {
      // Check if biometric auth is enabled in settings
      final authEnabled = await _biometricService.isAuthEnabled;
      LoggerService.info('AUTH', 'Auth enabled in settings: $authEnabled');
      if (!authEnabled) {
        LoggerService.info('AUTH', 'Biometric authentication disabled in settings - allowing access');
        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = true;
        });
        return;
      }

      // Check device biometric support
      final isDeviceSupported = await _biometricService.isBiometricAvailable;
      LoggerService.info('AUTH', 'Device supports biometrics: $isDeviceSupported');
      if (!isDeviceSupported) {
        LoggerService.warning('AUTH', 'Device does not support biometrics - allowing access');
        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = true; // Allow access without biometrics
        });
        return;
      }

      // Check if biometrics are enrolled
      final canCheckBiometrics = await _biometricService.canCheckBiometrics();
      LoggerService.info('AUTH', 'Biometrics enrolled: $canCheckBiometrics');
      if (!canCheckBiometrics) {
        LoggerService.warning('AUTH', 'No biometrics enrolled on device - allowing access');
        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = true; // Allow access without biometrics
        });
        return;
      }

      // Check if authentication is needed based on timeout
      final needsAuth = await _biometricService.isAuthenticationNeeded();
      LoggerService.info('AUTH', 'Authentication needed: $needsAuth');
      if (!needsAuth) {
        LoggerService.info('AUTH', 'Authentication not needed (within timeout) - allowing access');
        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = true;
        });
        return;
      }

      // Perform biometric authentication with password fallback
      LoggerService.info('AUTH', 'Performing biometric authentication with password fallback');
      
      // UNBLOCK: If user is locked out, reset attempts once to allow access after our fix
      if (_biometricService.isLockedOut) {
        LoggerService.warning('AUTH', 'User is locked out from previous failures. Resetting for recovery...');
        await _biometricService.resetFailedAttempts();
      }

      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to access Expiry Tracker',
        useErrorDialogs: true,
        biometricOnly: false, // Enable password fallback
      );
      LoggerService.info('AUTH', 'Authentication result: $authenticated');

      if (authenticated) {
        _lastAuthTime = DateTime.now();
        LoggerService.success('AUTH', 'Biometric authentication successful');
        if (mounted) {
          setState(() {
            _isCheckingAuth = false;
            _isAuthenticated = true;
          });
        }
      } else {
        LoggerService.warning('AUTH', 'Biometric authentication failed');
        if (mounted) {
          setState(() => _isCheckingAuth = false);
          _showAuthError();
        }
      }
    } catch (e) {
      LoggerService.error('AUTH', 'Authentication check failed: $e');
      // On error, allow access to prevent app lockout
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
          _isAuthenticated = true;
        });
      }
    }
    LoggerService.info('AUTH', '=== AUTHENTICATION CHECK COMPLETE ===');
  }

  void _showAuthError() {
    setState(() {
      _isCheckingAuth = false;
      _isAuthenticated = false;
    });

    // Show error dialog after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Authentication Required'),
          content: const Text(
            'Biometric authentication is required to use this app.\n\n'
            'If biometrics are not available, use your device PIN/password.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isCheckingAuth = true);
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _checkAuthentication(),
                );
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_isAuthenticated) {
      return LockScreen(
        onAuthenticated: () {
          _lastAuthTime = DateTime.now();
          setState(() {
            _isAuthenticated = true;
          });
        },
      );
    }

    return const DashboardScreen();
  }
}


