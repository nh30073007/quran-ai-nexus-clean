import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  bool _isDark = false;

  ThemeProvider(this.prefs) {
    _isDark = prefs.getBool('isDark') ?? false;
  }

  bool get isDark => _isDark;
  
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1E90FF),
        secondary: Color(0xFF87CEEB),
        surface: Colors.white,
        background: Color(0xFFF5F9FF),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1E90FF),
        foregroundColor: Colors.white,
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF87CEEB),
        secondary: Color(0xFF4682B4),
        surface: Color(0xFF1E1E1E),
        background: Color(0xFF121212),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
    );
  }

  void toggleTheme() {
    _isDark = !_isDark;
    prefs.setBool('isDark', _isDark);
    notifyListeners();
  }
}