import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primaryColor = Color(0xFF6366F1); // Indigo
  static const secondaryColor = Color(0xFF10B981); // Emerald
  static const accentColor = Color(0xFFF43F5E); // Rose
  static const backgroundColor = Color(0xFFF8FAFC); // Slate 50

  static const darkBackgroundColor = Color(0xFF0F172A); // Slate 900
  static const darkSurfaceColor = Color(0xFF1E293B); // Slate 800

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      error: accentColor,
      surface: Colors.white,
      background: backgroundColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    textTheme: GoogleFonts.outfitTextTheme(),
    appBarTheme: _appBarTheme(Brightness.light),
    cardTheme: _cardTheme(Brightness.light),
    inputDecorationTheme: _inputTheme(Brightness.light),
    elevatedButtonTheme: _buttonTheme(),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      error: accentColor,
      surface: darkSurfaceColor,
      background: darkBackgroundColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: darkBackgroundColor,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
    appBarTheme: _appBarTheme(Brightness.dark),
    cardTheme: _cardTheme(Brightness.dark),
    inputDecorationTheme: _inputTheme(Brightness.dark),
    elevatedButtonTheme: _buttonTheme(),
  );

  static AppBarTheme _appBarTheme(Brightness brightness) => AppBarTheme(
    backgroundColor: brightness == Brightness.light
        ? Colors.white
        : darkSurfaceColor,
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 2,
    titleTextStyle: GoogleFonts.outfit(
      color: brightness == Brightness.light ? Colors.black87 : Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(
      color: brightness == Brightness.light ? Colors.black87 : Colors.white,
    ),
  );

  static CardThemeData _cardTheme(Brightness brightness) => CardThemeData(
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: brightness == Brightness.light
            ? Colors.grey.withOpacity(0.1)
            : Colors.white.withOpacity(0.05),
      ),
    ),
    color: brightness == Brightness.light ? Colors.white : darkSurfaceColor,
  );

  static InputDecorationTheme _inputTheme(
    Brightness brightness,
  ) => InputDecorationTheme(
    filled: true,
    fillColor: brightness == Brightness.light ? Colors.white : darkSurfaceColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.grey.withOpacity(
          brightness == Brightness.light ? 0.2 : 0.05,
        ),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.grey.withOpacity(
          brightness == Brightness.light ? 0.1 : 0.05,
        ),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  );

  static ElevatedButtonThemeData _buttonTheme() => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      shadowColor: primaryColor.withOpacity(0.4),
      textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );
}
