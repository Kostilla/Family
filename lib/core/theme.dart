import 'package:flutter/material.dart';

class AppGradients {
  static const light = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF0FDFA)],
  );

  static const dark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF07111F), Color(0xFF0F172A), Color(0xFF09201D)],
  );
}

ThemeData _baseTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF14B8A6),
    brightness: brightness,
  );

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: isDark ? const Color(0xFF07111F) : const Color(0xFFF8FAFC),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
        letterSpacing: -.4,
      ),
    ),
    textTheme: TextTheme(
      displaySmall: TextStyle(fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: -.9),
      headlineLarge: TextStyle(fontWeight: FontWeight.w900, color: scheme.onSurface, letterSpacing: -.8),
      headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface, letterSpacing: -.7),
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface, letterSpacing: -.5),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, color: scheme.onSurface),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
      titleSmall: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
      bodyLarge: TextStyle(color: scheme.onSurface),
      bodyMedium: TextStyle(color: scheme.onSurfaceVariant),
      bodySmall: TextStyle(color: scheme.onSurfaceVariant),
      labelLarge: const TextStyle(fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF111C2E) : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      side: BorderSide(color: scheme.outlineVariant.withOpacity(.45)),
      backgroundColor: isDark ? const Color(0xFF111C2E) : Colors.white,
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      margin: const EdgeInsets.symmetric(vertical: 7, horizontal: 0),
      elevation: 0,
      shadowColor: Colors.black.withOpacity(isDark ? .18 : .06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      color: isDark ? const Color(0xFF0F1A2B) : Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      height: 70,
      backgroundColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant,
          )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant.withOpacity(.45), thickness: .8),
  );
}

final appTheme = _baseTheme(Brightness.light);
final appDarkTheme = _baseTheme(Brightness.dark);
