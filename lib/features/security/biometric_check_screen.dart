import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:expiry_tracker_app/core/services/biometric_service.dart';
import 'package:expiry_tracker_app/core/services/logger_service.dart';

/// Biometric Check Screen for comprehensive biometric testing
class BiometricCheckScreen extends StatefulWidget {
  const BiometricCheckScreen({Key? key}) : super(key: key);

  @override
  _BiometricCheckScreenState createState() => _BiometricCheckScreenState();
}

class _BiometricCheckScreenState extends State<BiometricCheckScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCheckingAuth = false;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  DateTime? _lastAuthTime;
  Map<String, dynamic> _biometricSummary = {};
  Map<String, dynamic> _testResults = {};
  bool _isTesting = false;

  late BiometricService _biometricService;

  @override
  void initState() {
    super.initState();
    _biometricService = BiometricService();
    _tabController = TabController(length: 3, vsync: this);
    _initializeBiometrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeBiometrics() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _biometricService.getBiometricSummary();
      
      if (mounted) {
        setState(() {
          _biometricSummary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _biometricSummary = {
            'status': 'error',
            'error': e.toString(),
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _runBiometricTest() async {
    setState(() => _isTesting = true);
    try {
      print('=== Running biometric test ===');
      final results = await _biometricService.testBiometrics();
      print('=== Biometric test results: $results ===');
      setState(() {
        _testResults = results;
        _isTesting = false;
      });
    } catch (e) {
      print('=== Biometric test error: $e ===');
      LoggerService.error('BIOMETRIC_SCREEN', 'Failed to run biometric test: $e');
      setState(() {
        _testResults = {'success': false, 'error': e.toString()};
        _isTesting = false;
      });
    }
  }

  Future<void> _runSimpleAuthTest() async {
    setState(() => _isTesting = true);
    try {
      print('=== Running simple auth test ===');
      final result = await _biometricService.authenticate(reason: 'Test authentication');
      print('=== Simple auth result: $result ===');
      setState(() {
        _testResults = {'success': result, 'message': result ? 'Authentication successful' : 'Authentication failed'};
        _isTesting = false;
      });
    } catch (e) {
      print('=== Simple auth error: $e ===');
      setState(() {
        _testResults = {'success': false, 'error': e.toString()};
        _isTesting = false;
      });
    }
  }

  Future<void> _testAuthentication() async {
    try {
      final result = await _biometricService.authenticate(
        reason: 'Test biometric authentication',
        useErrorDialogs: false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result ? 'Authentication successful!' : 'Authentication failed'),
          backgroundColor: result ? Colors.green : Colors.red,
        ),
      );
      
      // Refresh summary
      await _initializeBiometrics();
    } catch (e) {
      LoggerService.error('BIOMETRIC_SCREEN', 'Authentication test failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication test failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biometric Check'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.info), text: 'Status'),
            Tab(icon: Icon(Icons.science), text: 'Test'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _initializeBiometrics,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(),
          _buildTestTab(),
          _buildSettingsTab(),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusCard(),
          SizedBox(height: 16),
          _buildBiometricsCard(),
          SizedBox(height: 16),
          _buildSecurityCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _biometricSummary['status'] ?? 'unknown';
    BiometricStatus statusEnum = BiometricStatus.error;
    
    try {
      statusEnum = BiometricStatus.values.firstWhere(
        (s) => s.name == status,
      );
    } catch (e) {
      statusEnum = BiometricStatus.error;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _biometricService.getBiometricStatusIcon(statusEnum),
                  color: _biometricService.getBiometricStatusColor(statusEnum),
                  size: 32,
                ),
                SizedBox(width: 12),
                Text(
                  'Biometric Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _biometricService.getBiometricStatusColor(statusEnum).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _biometricService.getBiometricStatusColor(statusEnum),
                ),
              ),
              child: Text(
                _biometricService.getBiometricStatusText(statusEnum),
                style: TextStyle(
                  color: _biometricService.getBiometricStatusColor(statusEnum),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricsCard() {
    final availableBiometrics = _biometricSummary['availableBiometrics'];
    final biometricList = availableBiometrics is List ? availableBiometrics as List : [];
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Biometrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            if (biometricList.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'No biometrics available',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...biometricList.map((biometric) {
                final biometricString = biometric.toString();
                // Handle both enum string 'BiometricType.fingerprint' and simple string 'fingerprint'
                final cleanBiometricString = biometricString.contains('.') 
                    ? biometricString.split('.').last 
                    : biometricString;
                final type = _getBiometricTypeFromString(cleanBiometricString);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _biometricService.getBiometricTypeIcon(type),
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        _biometricService.getBiometricTypeText(type),
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Spacer(),
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityCard() {
    final isEnabled = _biometricSummary['isEnabled'];
    final isNeeded = _biometricSummary['isNeeded'];
    final failedAttempts = _biometricSummary['failedAttempts'];
    final isLockedOut = _biometricSummary['isLockedOut'];
    final timeoutMinutes = _biometricSummary['timeoutMinutes'];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),
            _buildSecurityItem('Biometric Auth', isEnabled == true ? 'Enabled' : 'Disabled'),
            _buildSecurityItem('Authentication Required', isNeeded == true ? 'Yes' : 'No'),
            _buildSecurityItem('Timeout', '${timeoutMinutes ?? 5} minutes'),
            _buildSecurityItem('Failed Attempts', '${failedAttempts ?? 0}'),
            if (isLockedOut == true)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Account Locked Out',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Spacer(),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildTestTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biometric Tests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _runBiometricTest,
                    icon: _isTesting 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.science),
                    label: Text(_isTesting ? 'Testing...' : 'Run Biometric Test'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _testAuthentication,
                    icon: Icon(Icons.fingerprint),
                    label: Text('Test Authentication'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          if (_testResults.isNotEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    ..._testResults.entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                '${entry.key}:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  color: entry.value == true ? Colors.green : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authentication Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  SwitchListTile(
                    title: Text('Enable Biometric Authentication'),
                    subtitle: Text('Require biometric authentication to access the app'),
                    value: _biometricSummary['isEnabled'] ?? false,
                    onChanged: (value) async {
                      await _biometricService.setAuthEnabled(value);
                      await _initializeBiometrics();
                    },
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Authentication Timeout'),
                    subtitle: Text('Time before re-authentication is required'),
                    trailing: DropdownButton<int>(
                      value: _biometricSummary['timeoutMinutes'] ?? 5,
                      items: [1, 5, 10, 15, 30, 60].map((minutes) {
                        return DropdownMenuItem(
                          value: minutes,
                          child: Text('$minutes minutes'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          await _biometricService.setAuthTimeoutMinutes(value);
                          await _initializeBiometrics();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _biometricService.resetFailedAttempts();
                      await _initializeBiometrics();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed attempts reset')),
                      );
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Reset Failed Attempts'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _biometricService.clearSecuritySettings();
                      await _initializeBiometrics();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Security settings cleared')),
                      );
                    },
                    icon: Icon(Icons.clear),
                    label: Text('Clear Security Settings'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 48),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BiometricType _getBiometricTypeFromString(String biometricString) {
    switch (biometricString.toLowerCase()) {
      case 'fingerprint':
        return BiometricType.fingerprint;
      case 'face':
        return BiometricType.face;
      case 'iris':
        return BiometricType.iris;
      default:
        return BiometricType.weak;
    }
  }
}
