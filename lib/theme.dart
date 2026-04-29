import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Map<String, Color> categoryColors = {
    'shuffle':    Color(0xFF7C6FFF),
    'sports':     Color(0xFF2ECC71),
    'celebrity':  Color(0xFFFF8C42),
    'culture':    Color(0xFFE91E8C),
    'tech':       Color(0xFF29B6F6),
    'gaming':     Color(0xFF9B59B6),
    'food':       Color(0xFFFF6B35),
    'geography':  Color(0xFF00BCD4),
    'history':    Color(0xFFFFB300),
    'politics':   Color(0xFFEF5350),
    'science':    Color(0xFF26A69A),
    'automotive': Color(0xFF78909C),
  };

  static Color categoryColor(String id) =>
      categoryColors[id] ?? const Color(0xFF7C6FFF);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1A1E33),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7C6FFF),
      secondary: Color(0xFFFF6B6B),
      surface: Color(0xFF242840),
    ),
    useMaterial3: true,
  );
}

class AppColors {
  static const background    = Color(0xFF1A1E33);
  static const surface       = Color(0xFF242840);
  static const surfaceLight  = Color(0xFF2E3354);
  static const surfaceLighter= Color(0xFF363D66);
  static const correct       = Color(0xFF2ECC71);
  static const wrong         = Color(0xFFFF4757);
  static const textPrimary   = Color(0xFFF2F3FF);
  static const textSecondary = Color(0xFF9BA3C7);
  static const gold          = Color(0xFFFFD700);
  static const cardBorder    = Color(0xFF3A4070);
}
