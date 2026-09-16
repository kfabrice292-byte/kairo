import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kairo_mobile/core/theme/app_colors.dart';

class AppTheme {
  static const Color primaryColor =
      AppColors.primary; // Orange-500, used sparingly

  // Light Mode Colors
  static const Color lightBackground = Color(
    0xFFFAFAFA,
  ); // Very clean white-grey
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF111827); // Gray-900
  static const Color lightTextSecondary = AppColors.textSecondary; // Gray-500
  static const Color lightDivider = Color(0xFFE5E7EB); // Gray-200

  // Dark Mode Colors (Espresso / Warm Dark)
  static const Color darkBackground = Color(
    0xFF14110F,
  ); // Very dark brown/black
  static const Color darkSurface = Color(
    0xFF221C18,
  ); // Elevated warm dark surface
  static const Color darkTextPrimary = Color(0xFFFDFBF7); // Off-white warm
  static const Color darkTextSecondary = Color(0xFFAFA39C); // Warm grey
  static const Color darkDivider = Color(0xFF3B322D); // Warm dark grey

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: lightSurface,
      ),
      scaffoldBackgroundColor: lightBackground,
      dividerColor: lightDivider,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: lightTextPrimary,
        displayColor: lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: lightTextPrimary,
        contentTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        surface: darkSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      dividerColor: darkDivider,
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: darkTextPrimary, displayColor: darkTextPrimary),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryColor,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3B322D), // slightly lighter than dark surface
        contentTextStyle: GoogleFonts.inter(
          color: darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF4A403B), width: 1),
        ),
        elevation: 8,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
      useMaterial3: true,
    );
  }
}
