import 'package:flutter/material.dart';

class AppTheme {
  static const primaryColor = Color(0xFFC7AD79);
  static const secondaryColor = Color(0xFF8F3933);
  static const accentColor = Color(0xFFDCC99E);
  static const backgroundColor = Color(0xFF101313);
  static const darkBackground = Color(0xFF090D0E);
  static const surfaceColor = Color(0xFF1C201F);
  static const ivory = Color(0xFFF0E9DC);
  static const muted = Color(0xFFABA99F);

  static ThemeData get darkTheme {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    const edge = BorderSide(color: Color(0xFF514936));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
      side: edge,
    );
    return base.copyWith(
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: darkBackground,
        secondary: accentColor,
        surface: surfaceColor,
        onSurface: ivory,
        error: Color(0xFFC76759),
      ),
      textTheme: base.textTheme
          .apply(bodyColor: ivory, displayColor: ivory)
          .copyWith(
            headlineLarge: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 32,
              color: ivory,
            ),
            headlineMedium: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 25,
              color: ivory,
            ),
            titleLarge: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 19,
              color: ivory,
            ),
            titleMedium: const TextStyle(
              fontFamily: 'Cinzel',
              fontSize: 15,
              color: ivory,
            ),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        foregroundColor: ivory,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 16,
          letterSpacing: 1,
          color: ivory,
        ),
      ),
      cardTheme: CardThemeData(color: surfaceColor, elevation: 0, shape: shape),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: shape,
        titleTextStyle: const TextStyle(
          fontFamily: 'Cinzel',
          color: ivory,
          fontSize: 20,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF514936)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: darkBackground,
          minimumSize: const Size(48, 48),
          elevation: 0,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 13,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: darkBackground,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ivory,
          side: edge,
          shape: shape,
          minimumSize: const Size(48, 44),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accentColor),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: accentColor,
        unselectedLabelColor: muted,
        indicatorColor: primaryColor,
        dividerColor: Color(0xFF514936),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: primaryColor,
        thumbColor: accentColor,
      ),
    );
  }
}
