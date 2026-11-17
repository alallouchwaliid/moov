import 'package:flutter/material.dart';

/// Palette de la maquette MOOV.
class MoovColors {
  static const blue = Color(0xFF1E4598);
  static const navy = Color(0xFF17263E);
  static const muted = Color(0xFF5A667C);
  static const bg = Color(0xFFF7F8FD);
  static const soft = Color(0xFFE9EFFF);
  static const line = Color(0xFFE0E8FA);
  static const green = Color(0xFF147A50);
  static const greenSoft = Color(0xFFE2F3E9);
  static const red = Color(0xFFB9251C);
  static const redSoft = Color(0xFFFBE7E5);
  static const orange = Color(0xFF9A5B00);
  static const orangeSoft = Color(0xFFFFF1DB);
}

ThemeData buildMoovTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: MoovColors.blue,
    primary: MoovColors.blue,
    onPrimary: Colors.white,
    secondary: MoovColors.blue,
    error: MoovColors.red,
    surface: Colors.white,
    onSurface: MoovColors.navy,
  );

  const pill = StadiumBorder();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: MoovColors.bg,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: MoovColors.navy, height: 1.25),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: MoovColors.navy),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: MoovColors.navy),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: MoovColors.navy),
      bodyLarge: TextStyle(fontSize: 16, color: MoovColors.navy, height: 1.45),
      bodyMedium: TextStyle(fontSize: 15, color: MoovColors.navy, height: 1.4),
      bodySmall: TextStyle(fontSize: 13, color: MoovColors.muted, height: 1.35),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: MoovColors.bg,
      foregroundColor: MoovColors.navy,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 21, fontWeight: FontWeight.w500, color: MoovColors.navy),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MoovColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 52),
        shape: pill,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: MoovColors.blue,
        minimumSize: const Size(64, 52),
        shape: pill,
        side: const BorderSide(color: Color(0xFFCCD8EE)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: MoovColors.blue,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: MoovColors.muted),
      hintStyle: const TextStyle(color: Color(0xFF8A94A8)),
      prefixIconColor: MoovColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MoovColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MoovColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MoovColors.blue, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: MoovColors.red),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: MoovColors.soft,
      surfaceTintColor: Colors.white,
      height: 68,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: const DividerThemeData(color: MoovColors.line, thickness: 1, space: 32),
  );
}
