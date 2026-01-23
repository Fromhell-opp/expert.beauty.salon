import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      fontFamily: 'SF Pro',
      primaryColor: const Color(0xFF6C5CE7),
      useMaterial3: true,
    );
  }
}
