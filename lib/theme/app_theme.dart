import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const double kCardRadius = 16.0;
const double kInputRadius = 12.0;

const Color kAccentColor = Color(0xFFCE9D78);
const Color kBackgroundLight = Color(0xFFF3E6D7);
const Color kBackgroundDark = Color(0xFF162936);

const Color kStatusEmDiaTexto = Color(0xFF16A34A);
const Color kStatusEmDiaFundo = Color(0xFFF0FDF4);
const Color kStatusAlertaTexto = Color(0xFFEA580C);
const Color kStatusAlertaFundo = Color(0xFFFFF7ED);
const Color kStatusVencidoTexto = Color(0xFFDC2626);
const Color kStatusVencidoFundo = Color(0xFFFEF2F2);

const ColorScheme _colorSchemeLight = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF162936),
  onPrimary: Color(0xFFF3E6D7),
  secondary: Color(0xFFEEDDD2),
  onSecondary: Color(0xFF162936),
  error: Color(0xFFC0392B),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFCF8),
  onSurface: Color(0xFF162936),
);

const ColorScheme _colorSchemeDark = ColorScheme(
  brightness: Brightness.dark,
  primary: kAccentColor,
  onPrimary: Color(0xFF162936),
  secondary: Color(0xFF1D2F3A),
  onSecondary: Color(0xFFEEDDD2),
  error: Color(0xFFE74C3C),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFF25343E),
  onSurface: Color(0xFFF3E6D7),
);

ThemeData _buildTheme(ColorScheme colorScheme, Color background) {
  final base = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: background,
  );
  final bodyText = GoogleFonts.interTextTheme(base.textTheme);
  final displayText = GoogleFonts.barlowCondensedTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: bodyText.copyWith(
      displayLarge: displayText.displayLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
      displayMedium: displayText.displayMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      displaySmall: displayText.displaySmall?.copyWith(fontWeight: FontWeight.w900),
      headlineLarge: displayText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
      headlineMedium: displayText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
      ),
      headlineSmall: displayText.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: displayText.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: displayText.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      titleSmall: displayText.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kCardRadius)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kInputRadius),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kInputRadius)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: kAccentColor.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selecionado = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selecionado ? kAccentColor : colorScheme.onSurface.withValues(alpha: 0.5),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selecionado = states.contains(WidgetState.selected);
        return TextStyle(
          color: selecionado ? kAccentColor : colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        );
      }),
    ),
  );
}

final ThemeData appThemeLight = _buildTheme(_colorSchemeLight, kBackgroundLight);
final ThemeData appThemeDark = _buildTheme(_colorSchemeDark, kBackgroundDark);
