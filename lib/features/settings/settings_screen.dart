import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/biometric_service.dart';
import '../../core/services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _authEnabled = false;
  bool _isLoading = false;
  BiometricType? _biometricType;
  Widget? child;

  @override
  void initState() {
    super.initState();
    _loadAuthSettings();
  }

  Future<void> _loadAuthSettings() async {
    setState(() => _isLoading = true);
    try {
      final enabled = await _biometricService.isAuthEnabled;
      final biometrics = await _biometricService.availableBiometrics;
      setState(() {
        _authEnabled = enabled;
        _biometricType = biometrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    }
  }

  Future<void> _toggleAuthEnabled(bool value) async {
    if (value) {
      // Check if device supports biometrics before enabling
      final isSupported = await _biometricService.isBiometricAvailable;
      if (!isSupported) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device does not support biometrics'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if biometrics are enrolled
      final canCheck = await _biometricService.canCheckBiometrics();
      if (!canCheck) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No biometrics enrolled on device. Please add fingerprint/face in device settings.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await _biometricService.setAuthEnabled(value);
      setState(() {
        _authEnabled = value;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value 
            ? 'App Lock enabled successfully' 
            : 'App Lock disabled'),
          backgroundColor: value ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Security Section
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Security',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // App Lock Toggle
                        SwitchListTile(
                          title: const Text('Enable App Lock'),
                          subtitle: Text(
                            _biometricType != BiometricType.weak 
                                ? 'Use ${_biometricService.getBiometricTypeText(_biometricType!)} to unlock'
                                : 'Device authentication not available',
                            style: TextStyle(
                              color: _biometricType != BiometricType.weak 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey,
                            ),
                          ),
                          value: _authEnabled,
                          onChanged: _toggleAuthEnabled,
                          secondary: _biometricType != BiometricType.weak 
                              ? const Icon(
                                  Icons.fingerprint,
                                  color: Color(0xFF075E54),
                                  size: 20,
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        if (_authEnabled && _biometricType != BiometricType.weak)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Authentication will be required when opening the app',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Theme Section
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeService.themeNotifier,
                  builder: (context, currentTheme, _) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  currentTheme == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Appearance',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SwitchListTile(
                              title: const Text('Dark Mode'),
                              subtitle: const Text('Switch between light and dark theme'),
                              value: currentTheme == ThemeMode.dark,
                              onChanged: (value) {
                                ThemeService.setTheme(value ? ThemeMode.dark : ThemeMode.light);
                              },
                              secondary: Icon(
                                currentTheme == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
