import 'package:flutter/material.dart';

final simpsonsColorScheme = ColorScheme(
  brightness: Brightness.light, // ou Brightness.dark si vous voulez une version sombre

  primary: const Color(0xFFFFD90F), // Jaune Simpson
  onPrimary: const Color(0xFF000000), // Noir pour le texte/icônes sur primaire

  secondary: const Color(0xFF0074D9), // Bleu Marge
  onSecondary: const Color(0xFFFFFFFF), // Blanc pour le texte/icônes sur secondaire

  tertiary: const Color(0xFFFF69B4), // Rose Donut
  onTertiary: const Color(0xFFFFFFFF), // Blanc pour le texte/icônes sur tertiaire

  error: const Color(0xFFFF8C00), // Orange de Bart
  onError: const Color(0xFFFFFFFF), // Gris Taupe pour le texte sur fond

  surface: const Color(0xFFFFFFFF), // Blanc Duff pour les cartes, dialogues
  onSurface: const Color(0xFF4A4A4A), // Gris Taupe pour le texte sur surface

  surfaceContainerHighest: const Color(0xFFE0E0E0), // Un gris clair pour les séparations ou fonds légers
  onSurfaceVariant: const Color(0xFF4A4A4A),

  outline: const Color(0xFFBDBDBD),
);

final simpsonsTheme = ThemeData(
  colorScheme: simpsonsColorScheme,
  appBarTheme: AppBarTheme(
    backgroundColor: simpsonsColorScheme.primary,
    foregroundColor: simpsonsColorScheme.onPrimary,
    titleTextStyle: TextStyle(
      color: simpsonsColorScheme.onPrimary,
      fontSize: 20,
      fontWeight: FontWeight.bold, // Style "cartoon"
    ),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: simpsonsColorScheme.primary,
    foregroundColor: simpsonsColorScheme.onPrimary,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: simpsonsColorScheme.secondary,
      foregroundColor: simpsonsColorScheme.onSecondary,
      textStyle: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: simpsonsColorScheme.secondary,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: simpsonsColorScheme.primary, width: 2.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: simpsonsColorScheme.outline),
    ),
    labelStyle: TextStyle(color: simpsonsColorScheme.secondary),
  ),
);