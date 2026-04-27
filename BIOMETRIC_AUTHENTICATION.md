# Biometric Authentication System

## Overview
The Expiry Tracker App includes a comprehensive biometric authentication system that provides secure access to sensitive features and data.

---

## Features Implemented

### 1. **Enhanced Biometric Service**
**File**: `lib/core/services/biometric_service.dart`

**Capabilities**:
- Support for fingerprint, face ID, and iris scanning
- Comprehensive status checking
- Authentication timeout management
- Failed attempt tracking and lockout protection
- Detailed logging and error handling

**Key Methods**:
```dart
// Initialize biometric service
await BiometricService.initialize();

// Check biometric availability
final isAvailable = await BiometricService.isBiometricAvailable();

// Authenticate user
final authenticated = await BiometricService.authenticate(
  reason: 'Authenticate to access your inventory',
  biometricOnly: false,
  stickyAuth: true,
);

// Get comprehensive status
final status = await BiometricService.getBiometricStatus();
final summary = await BiometricService.getBiometricSummary();

// Test biometrics
final testResults = await BiometricService.testBiometrics();
```

---

### 2. **Biometric Check Screen**
**File**: `lib/features/security/biometric_check_screen.dart`

**UI Features**:
- **Status Tab**: View biometric availability and settings
- **Test Tab**: Run biometric tests and authentication checks
- **Settings Tab**: Configure authentication options

**Key Components**:
- Real-time biometric status display
- Available biometrics detection
- Security settings management
- Authentication timeout configuration
- Failed attempts tracking

---

### 3. **Biometric Protection Widgets**
**File**: `lib/widgets/biometric_protected_widget.dart`

**Widgets Available**:
- `BiometricProtectedWidget`: Wrapper for sensitive screens
- `BiometricAuthDialog`: Modal authentication dialog
- `BiometricAuthButton`: Authentication trigger button

**Usage Examples**:
```dart
// Protect a screen with biometrics
BiometricProtectedWidget(
  authenticationReason: 'Authenticate to access settings',
  child: SettingsScreen(),
)

// Show authentication dialog
showDialog(
  context: context,
  builder: (context) => BiometricAuthDialog(
    reason: 'Authenticate to delete this item',
    onSuccess: () => deleteItem(),
  ),
);

// Custom authentication button
BiometricAuthButton(
  reason: 'Authenticate to export data',
  onSuccess: () => exportData(),
  child: Text('Export Secure Data'),
)
```

---

## Biometric Types Supported

### **Fingerprint**
- **Icon**: Icons.fingerprint
- **Text**: "Fingerprint"
- **Availability**: Most Android devices

### **Face ID**
- **Icon**: Icons.face
- **Text**: "Face ID"
- **Availability**: iPhones with Face ID, some Android devices

### **Iris Scanner**
- **Icon**: Icons.visibility
- **Text**: "Iris Scanner"
- **Availability**: Limited device support

---

## Biometric Status Types

### **BiometricStatus Enum**
```dart
enum BiometricStatus {
  available,      // Biometrics are available and enabled
  unavailable,    // Device doesn't support biometrics
  disabled,       // Biometrics are disabled by user
  not_enrolled,   // No biometrics enrolled on device
  error,          // Error checking biometric status
}
```

### **Status Indicators**
- **Green**: Available and working
- **Orange**: Disabled or needs attention
- **Red**: Not available or error
- **Grey**: Not supported

---

## Security Features

### **Authentication Timeout**
```dart
// Set authentication timeout (in minutes)
await BiometricService.setAuthTimeoutMinutes(5);

// Check if authentication is needed
final needsAuth = await BiometricService.isAuthenticationNeeded();

// Get current timeout setting
final timeout = await BiometricService.getAuthTimeoutMinutes();
```

### **Failed Attempts Tracking**
```dart
// Get failed attempts count
final attempts = BiometricService.failedAttempts;

// Check if user is locked out
final isLockedOut = BiometricService.isLockedOut;

// Reset failed attempts
await BiometricService.resetFailedAttempts();
```

### **Lockout Protection**
- **Threshold**: 5 failed attempts
- **Lockout Duration**: Until manually reset
- **Visual Feedback**: Lockout screen with clear messaging

---

## Implementation Guide

### **1. Basic Setup**
```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    BiometricService.initialize();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(),
    );
  }
}
```

### **2. Protect Sensitive Screens**
```dart
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BiometricProtectedWidget(
      authenticationReason: 'Authenticate to access settings',
      child: Scaffold(
        appBar: AppBar(title: Text('Settings')),
        body: SettingsContent(),
      ),
    );
  }
}
```

### **3. Custom Authentication Flow**
```dart
class SecureOperation {
  static Future<void> performSecureOperation() async {
    final biometricService = BiometricService();
    
    // Check if authentication is needed
    if (await biometricService.isAuthenticationNeeded()) {
      final authenticated = await biometricService.authenticate(
        reason: 'Authenticate to perform secure operation',
      );
      
      if (!authenticated) {
        throw Exception('Authentication failed');
      }
    }
    
    // Perform secure operation
    await secureOperation();
  }
}
```

---

## Error Handling

### **Common Errors and Solutions**

#### **Device Not Supported**
```dart
final isAvailable = await BiometricService.isBiometricAvailable();
if (!isAvailable) {
  // Show fallback authentication or disable biometric features
  showFallbackAuth();
}
```

#### **Biometrics Not Enrolled**
```dart
final status = await BiometricService.getBiometricStatus();
if (status == BiometricStatus.not_enrolled) {
  // Guide user to enroll biometrics
  showEnrollmentGuide();
}
```

#### **Authentication Failed**
```dart
try {
  final authenticated = await BiometricService.authenticate();
  if (!authenticated) {
    // Handle failed authentication
    showAuthFailedMessage();
  }
} catch (e) {
  // Handle authentication error
  showErrorMessage(e.toString());
}
```

#### **User Locked Out**
```dart
if (BiometricService.isLockedOut) {
  // Show lockout screen
  showLockoutScreen();
}
```

---

## Configuration Options

### **Authentication Options**
```dart
await BiometricService.authenticate(
  reason: 'Custom authentication reason',
  useErrorDialogs: true,        // Show system error dialogs
  biometricOnly: false,         // Allow device PIN as fallback
  stickyAuth: true,             // Keep authentication active
);
```

### **Timeout Settings**
```dart
// Available timeout options
[1, 5, 10, 15, 30, 60] minutes

// Custom timeout
await BiometricService.setAuthTimeoutMinutes(15);
```

### **Security Settings**
```dart
// Enable/disable biometric authentication
await BiometricService.setAuthEnabled(true);

// Clear all security settings
await BiometricService.clearSecuritySettings();
```

---

## Testing and Debugging

### **Biometric Testing**
```dart
// Run comprehensive biometric test
final results = await BiometricService.testBiometrics();
print('Test Results: $results');

// Test authentication without UI
final quickAuth = await BiometricService.quickAuthenticate();

// Test with timeout
final timeoutAuth = await BiometricService.authenticateWithTimeout(
  timeout: Duration(seconds: 10),
);
```

### **Debug Information**
```dart
// Get detailed biometric summary
final summary = await BiometricService.getBiometricSummary();
print('Biometric Summary: $summary');

// Check biometric status
final status = await BiometricService.getBiometricStatus();
print('Status: ${status.name}');

// Get available biometrics
final biometrics = await BiometricService.getAllAvailableBiometrics();
print('Available: ${biometrics.map((b) => b.name)}');
```

---

## Best Practices

### **1. Always Check Availability**
```dart
// Before using biometrics
if (await BiometricService.isBiometricAvailable()) {
  // Use biometric authentication
} else {
  // Use alternative authentication
}
```

### **2. Handle Timeouts Gracefully**
```dart
try {
  final result = await BiometricService.authenticateWithTimeout();
  // Handle success
} catch (e) {
  // Handle timeout or other errors
}
```

### **3. Provide Fallback Options**
```dart
Widget buildAuthButton() {
  return FutureBuilder<bool>(
    future: BiometricService.isBiometricAvailable(),
    builder: (context, snapshot) {
      if (snapshot.hasData && snapshot.data!) {
        return BiometricAuthButton(
          reason: 'Authenticate',
          onSuccess: () => proceed(),
        );
      } else {
        return ElevatedButton(
          onPressed: () => proceedWithPIN(),
          child: Text('Use PIN'),
        );
      }
    },
  );
}
```

### **4. Clear User Feedback**
```dart
// Show authentication status
if (isAuthenticating) {
  return CircularProgressIndicator();
} else if (isLockedOut) {
  return Text('Account locked - too many failed attempts');
} else if (authFailed) {
  return Text('Authentication failed - please try again');
}
```

---

## Security Considerations

### **Data Protection**
- Biometric data never leaves the device
- Authentication tokens are stored securely
- Failed attempts are tracked to prevent brute force

### **Privacy**
- No biometric data is stored in the app
- Uses device's secure biometric storage
- Authentication is local to the device

### **Compliance**
- Follows platform biometric guidelines
- Respects user privacy settings
- Provides clear authentication reasons

---

## Troubleshooting

### **Common Issues**

#### **Biometrics Not Working**
1. Check if device supports biometrics
2. Verify biometrics are enrolled
3. Ensure app has necessary permissions
4. Check if biometrics are enabled in settings

#### **Authentication Fails**
1. Clean fingerprint sensor/camera
2. Re-enroll biometrics
3. Check for system updates
4. Restart device

#### **App Crashes**
1. Check biometric service initialization
2. Handle exceptions properly
3. Verify biometric availability before use
4. Provide fallback authentication

### **Debug Steps**
1. Enable debug logging
2. Run biometric tests
3. Check device biometric settings
4. Verify app permissions
5. Test with different biometric types

---

## Platform-Specific Notes

### **Android**
- Requires `USE_FINGERPRINT` permission
- Supports fingerprint and face recognition
- May require device PIN as fallback

### **iOS**
- Requires `NSFaceIDUsageDescription` in Info.plist
- Supports Touch ID and Face ID
- Requires device passcode as fallback

### **Permissions**
```xml
<!-- Android -->
<uses-permission android:name="android.permission.USE_FINGERPRINT" />

<!-- iOS -->
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID to secure your data</string>
```

---

## Future Enhancements

### **Planned Features**
1. **Multi-Factor Authentication**: Combine biometrics with PIN
2. **Adaptive Authentication**: Different security levels for different features
3. **Biometric Analytics**: Track usage patterns and success rates
4. **Custom Biometric UI**: Branded authentication screens
5. **Remote Authentication**: Server-side biometric verification

### **Performance Improvements**
1. **Faster Initialization**: Optimize service startup
2. **Better Caching**: Cache authentication status
3. **Reduced Latency**: Improve authentication response time
4. **Background Processing**: Handle authentication in background

---

This comprehensive biometric authentication system provides secure, user-friendly access control while maintaining flexibility and robustness across different devices and platforms.
