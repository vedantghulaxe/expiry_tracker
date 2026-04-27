import 'package:flutter/material.dart';
import 'package:expiry_tracker_app/core/services/biometric_service.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// Widget that requires biometric authentication before showing content
class BiometricProtectedWidget extends StatefulWidget {
  final Widget child;
  final String? authenticationReason;
  final Widget? fallbackWidget;
  final bool enableTimeout;
  final Duration? timeout;

  const BiometricProtectedWidget({
    Key? key,
    required this.child,
    this.authenticationReason,
    this.fallbackWidget,
    this.enableTimeout = true,
    this.timeout,
  }) : super(key: key);

  @override
  _BiometricProtectedWidgetState createState() => _BiometricProtectedWidgetState();
}

class _BiometricProtectedWidgetState extends State<BiometricProtectedWidget> {
  final BiometricService _biometricService = BiometricService();
  bool _isAuthenticated = false;
  bool _isChecking = false;
  bool _isLockedOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      await _biometricService.initialize();
      
      // Check if biometric auth is enabled
      final isEnabled = await _biometricService.isAuthEnabled;
      if (!isEnabled) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
        return;
      }

      // Check if user is locked out
      if (_biometricService.isLockedOut) {
        setState(() {
          _isLockedOut = true;
          _isChecking = false;
          _errorMessage = 'Account locked due to too many failed attempts';
        });
        return;
      }

      // Check if authentication is needed based on timeout
      final needsAuth = widget.enableTimeout 
          ? await _biometricService.isAuthenticationNeeded(timeout: widget.timeout)
          : true;

      if (needsAuth) {
        setState(() => _isChecking = true);
        await _authenticate();
      } else {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
    } catch (e) {
      LoggerService.error('BIOMETRIC_WIDGET', 'Error checking authentication status: $e');
      setState(() {
        _isChecking = false;
        _errorMessage = 'Error checking authentication status';
      });
    }
  }

  Future<void> _authenticate() async {
    try {
      final reason = widget.authenticationReason ?? 'Authenticate to access this feature';
      final authenticated = await _biometricService.authenticate(
        reason: reason,
        useErrorDialogs: false,
      );

      setState(() {
        _isAuthenticated = authenticated;
        _isChecking = false;
        if (!authenticated) {
          _errorMessage = 'Authentication failed';
        }
      });
    } catch (e) {
      LoggerService.error('BIOMETRIC_WIDGET', 'Authentication error: $e');
      setState(() {
        _isChecking = false;
        _errorMessage = 'Authentication error: $e';
      });
    }
  }

  Future<void> _retryAuthentication() async {
    setState(() {
      _errorMessage = null;
      _isChecking = true;
    });
    await _authenticate();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child;
    }

    if (_isChecking) {
      return _buildCheckingWidget();
    }

    if (_isLockedOut) {
      return _buildLockedOutWidget();
    }

    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return widget.fallbackWidget ?? _buildDefaultFallback();
  }

  Widget _buildCheckingWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Authenticating...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please use your biometric to continue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedOutWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 24),
              Text(
                'Account Locked',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Too many failed authentication attempts.\nPlease try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 24),
              Text(
                'Authentication Failed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: 16),
              Text(
                _errorMessage ?? 'An error occurred during authentication',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _retryAuthentication,
                      icon: Icon(Icons.refresh),
                      label: Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.arrow_back),
                      label: Text('Go Back'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultFallback() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.security,
                size: 64,
                color: Colors.blue,
              ),
              SizedBox(height: 24),
              Text(
                'Authentication Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This feature requires biometric authentication to access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _retryAuthentication,
                icon: Icon(Icons.fingerprint),
                label: Text('Authenticate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
              SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(Icons.arrow_back),
                label: Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple biometric authentication dialog
class BiometricAuthDialog extends StatelessWidget {
  final String reason;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;
  final VoidCallback? onFailed;

  const BiometricAuthDialog({
    Key? key,
    required this.reason,
    required this.onSuccess,
    this.onCancel,
    this.onFailed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fingerprint,
              size: 64,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'Biometric Authentication',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCancel?.call();
                    },
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      
                      final biometricService = BiometricService();
                      try {
                        final authenticated = await biometricService.authenticate(
                          reason: reason,
                          useErrorDialogs: false,
                        );
                        
                        if (authenticated) {
                          onSuccess.call();
                        } else {
                          onFailed?.call();
                        }
                      } catch (e) {
                        onFailed?.call();
                      }
                    },
                    child: Text('Authenticate'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Biometric authentication button
class BiometricAuthButton extends StatefulWidget {
  final String reason;
  final VoidCallback onSuccess;
  final VoidCallback? onFailed;
  final Widget? child;
  final ButtonStyle? style;

  const BiometricAuthButton({
    Key? key,
    required this.reason,
    required this.onSuccess,
    this.onFailed,
    this.child,
    this.style,
  }) : super(key: key);

  @override
  _BiometricAuthButtonState createState() => _BiometricAuthButtonState();
}

class _BiometricAuthButtonState extends State<BiometricAuthButton> {
  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);
    
    try {
      final biometricService = BiometricService();
      final authenticated = await biometricService.authenticate(
        reason: widget.reason,
        useErrorDialogs: false,
      );
      
      if (authenticated) {
        widget.onSuccess();
      } else {
        widget.onFailed?.call();
      }
    } catch (e) {
      widget.onFailed?.call();
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isAuthenticating ? null : _authenticate,
      style: widget.style,
      child: _isAuthenticating
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : widget.child ?? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fingerprint),
                SizedBox(width: 8),
                Text('Authenticate'),
              ],
            ),
    );
  }
}
