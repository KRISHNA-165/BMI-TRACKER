import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color surface = Color(0xFF1E293B);    // Slate 800
  static const Color surfaceLight = Color(0xFF334155); // Slate 700
  static const Color border = Color(0xFF334155);

  static const Color primary = Color(0xFF6366F1); // Indigo 500
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color secondary = Color(0xFF8B5CF6); // Purple 500
  static const Color accent = Color(0xFFEC4899); // Pink 500

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Category Colors
  static const Color underweight = Color(0xFF38BDF8); // Cyan
  static const Color normalWeight = Color(0xFF22C55E); // Green
  static const Color overweight = Color(0xFFF97316); // Orange
  static const Color obese = Color(0xFFEF4444); // Red

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Inter is registered in pubspec.yaml as a bundled font (assets/fonts/).
/// Using it via fontFamily: 'Inter' avoids any network dependency.
const String _interFont = 'Inter';

ThemeData getAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.obese,
    ),
    cardColor: AppColors.surface,
    textTheme: base.textTheme
        .apply(
          fontFamily: _interFont,
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          bodyMedium: const TextStyle(
              fontFamily: _interFont, color: AppColors.textPrimary),
          bodyLarge: const TextStyle(
              fontFamily: _interFont, color: AppColors.textPrimary),
          titleMedium: const TextStyle(
              fontFamily: _interFont, color: AppColors.textPrimary),
          titleLarge: const TextStyle(
              fontFamily: _interFont,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold),
          headlineSmall: const TextStyle(
              fontFamily: _interFont,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold),
          headlineMedium: const TextStyle(
              fontFamily: _interFont,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold),
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.obese),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.obese, width: 2),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: const TextStyle(
          fontFamily: _interFont,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
