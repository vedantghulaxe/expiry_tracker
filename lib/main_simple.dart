import 'package:flutter/material.dart';
import 'package:expiry_tracker_app/features/dashboard/dashboard_screen.dart';

/// Simple main entry point for testing
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expiry Tracker App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
