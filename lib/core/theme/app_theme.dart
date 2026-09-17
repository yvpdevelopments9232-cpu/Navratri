import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Festive Navratri Palette
  static const Color primaryMaroon = Color(0xFF780016);
  static const Color secondaryRed = Color(0xFFB71C1C);
  static const Color accentGold = Color(0xFFD4AF37);
  static const Color brightGold = Color(0xFFF59E0B);
  static const Color warmCream = Color(0xFFFFFDF9);
  static const Color softBackground = Color(0xFFF8F6F0);
  static const Color cardBg = Colors.white;

  // Aliases for Bachatgat style compatibility
  static const Color primary = primaryMaroon;
  static const Color secondary = secondaryRed;
  static const Color primaryLight = Color(0xFF991B1B);
  static const Color primaryDark = Color(0xFF4A000E);
  static const Color secondaryLight = Color(0xFFDC2626);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Financial & Operational Accents
  static const Color successGreen = Color(0xFF10B981);
  static const Color success = successGreen;
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color danger = expenseRed;
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color warning = warningOrange;
  static const Color warningBg = Color(0xFFFFF7ED);
  static const Color infoBlue = Color(0xFF2563EB);
  static const Color info = infoBlue;
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color purpleAccent = Color(0xFF8B5CF6);

  // Neutral Tones
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderAccent = Color(0xFFF1E6D0);
}

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.poppinsTextTheme().apply(
      fontFamilyFallback: const ['Noto Sans Devanagari', 'Yantramanav', 'sans-serif'],
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.softBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryMaroon,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryRed,
        onSecondary: Colors.white,
        tertiary: AppColors.accentGold,
        surface: AppColors.cardBg,
        onSurface: AppColors.textPrimary,
        error: AppColors.expenseRed,
        outline: AppColors.borderLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0.8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryMaroon,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryMaroon,
          side: const BorderSide(color: AppColors.primaryMaroon),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryMaroon, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.expenseRed),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
      ),
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
