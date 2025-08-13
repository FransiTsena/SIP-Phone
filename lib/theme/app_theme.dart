import 'package:flutter/material.dart';

/// Centralized application theming.
/// Use AppTheme.lightTheme / AppTheme.darkTheme in MaterialApp, or AppTheme.theme as an alias for the light theme.
class AppTheme {
  AppTheme._();

  // Core brand colors
  static const Color primary = Color(0xFF0066CC);
  static const Color secondary = Color(0xFF00BFA6);
  static const Color error = Color(0xFFB00020);

  // Backwards-compat aliases (commonly referenced in apps)
  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;

  // Legacy color aliases for compatibility with older code
  static const Color primaryLight = primary;
  static const Color primaryDark = primary;

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );

  // Alias some codebases reference.
  static ThemeData get theme => lightTheme;

  // Legacy method-style accessors for compatibility with older code
  static ThemeData light() => lightTheme;
  static ThemeData dark() => darkTheme;
}
