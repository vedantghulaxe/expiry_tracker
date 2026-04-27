import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);

  static ValueNotifier<ThemeMode> get themeNotifier => _themeNotifier;

  static ThemeMode get currentTheme => _themeNotifier.value;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);
    
    if (savedTheme != null) {
      _themeNotifier.value = _getThemeMode(savedTheme);
    }
  }

  static Future<void> toggleTheme() async {
    final newTheme = _themeNotifier.value == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    _themeNotifier.value = newTheme;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _getThemeString(newTheme));
  }

  static Future<void> setTheme(ThemeMode theme) async {
    _themeNotifier.value = theme;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _getThemeString(theme));
  }

  static ThemeMode _getThemeMode(String themeString) {
    switch (themeString) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static String _getThemeString(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
      default:
        return 'light';
    }
  }

  // Light theme colors
  static const Color lightPrimary = Color(0xFF075E54);
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Color(0xFFF5F5F5);
  static const Color lightOnSurface = Colors.black87;

  // Dark theme colors
  static const Color darkPrimary = Color(0xFF128C7E);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Colors.white;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        background: lightBackground,
        surface: lightSurface,
        onSurface: lightOnSurface,
        secondary: Colors.green,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: lightOnSurface,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        background: darkBackground,
        surface: darkSurface,
        onSurface: darkOnSurface,
        secondary: Colors.green,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: darkOnSurface,
      ),
    );
  }
}
