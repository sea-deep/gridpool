import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/theme/design_tokens.dart';

class AppTheme {
  static ColorScheme get fallbackLightScheme => const ColorScheme(
    brightness: Brightness.light,
    primary: DesignTokens.primaryAccent,
    onPrimary: Colors.white,
    primaryContainer: DesignTokens.primaryAccentLight,
    onPrimaryContainer: DesignTokens.onSurface,
    secondary: DesignTokens.secondaryAccent,
    onSecondary: Colors.white,
    secondaryContainer: DesignTokens.secondaryContainer,
    onSecondaryContainer: DesignTokens.onSecondaryContainer,
    tertiary: DesignTokens.tertiaryAccent,
    onTertiary: Colors.white,
    surface: DesignTokens.surface,
    onSurface: DesignTokens.onSurface,
    surfaceContainerHighest: DesignTokens.surfaceContainerLow,
    onSurfaceVariant: DesignTokens.onSurfaceVariant,
    outline: DesignTokens.outline,
    error: DesignTokens.warning,
    onError: Colors.white,
  );

  static ColorScheme get fallbackDarkScheme => ColorScheme.fromSeed(
    seedColor: DesignTokens.primaryAccent,
    brightness: Brightness.dark,
  );

  static ThemeData get lightTheme => themeFromScheme(fallbackLightScheme);

  static ThemeData get darkTheme => themeFromScheme(fallbackDarkScheme);

  static ThemeData themeFromScheme(ColorScheme scheme) {
    final textTheme = _textTheme(
      primaryColor: scheme.onSurface,
      mutedColor: scheme.onSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        indicatorColor: scheme.secondaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onSurfaceVariant;
          return IconThemeData(color: color);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final color = states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant;
          return textTheme.labelSmall?.copyWith(color: color);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        hintStyle: GoogleFonts.roboto(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: DesignTokens.radiusInput,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: DesignTokens.radiusInput,
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: DesignTokens.radiusInput,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: DesignTokens.radiusInput,
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spaceLg,
          vertical: DesignTokens.spaceMd,
        ),
      ),
    );
  }

  static TextTheme _textTheme({
    required Color primaryColor,
    required Color mutedColor,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.roboto(
        fontSize: 56,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      displayMedium: GoogleFonts.roboto(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: primaryColor,
      ),
      displaySmall: GoogleFonts.roboto(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: primaryColor,
      ),
      headlineLarge: GoogleFonts.roboto(
        fontSize: 48,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: primaryColor,
      ),
      headlineMedium: GoogleFonts.roboto(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: primaryColor,
      ),
      headlineSmall: GoogleFonts.roboto(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: primaryColor,
      ),
      titleLarge: GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 1.3,
        color: primaryColor,
      ),
      bodyLarge: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryColor,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: mutedColor,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: mutedColor,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: primaryColor,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.2,
        color: mutedColor,
      ),
    );
  }
}
