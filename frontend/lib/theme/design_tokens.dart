import 'package:flutter/material.dart';

class DesignTokens {
  // Surfaces
  static const Color canvas = Color(0xFFFFFBFE);
  static const Color surface = Color(0xFFFFFBFE);
  static const Color surfaceContainer = Color(0xFFF3EDF7);
  static const Color surfaceContainerLow = Color(0xFFE7E0EC);
  static const Color outline = Color(0xFF79747E);

  // Foreground
  static const Color textPrimary = Color(0xFF1C1B1F);
  static const Color textMuted = Color(0xFF49454F);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);
  static const Color onSecondaryContainer = Color(0xFF1D192B);

  // Accents
  static const Color primaryAccent = Color(0xFF6750A4);
  static const Color primaryAccentLight = Color(0xFFD0BCFF);
  static const Color secondaryAccent = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color tertiaryAccent = Color(0xFF7D5260);

  // States
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Spacing
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2Xl = 48.0;
  static const double space3Xl = 64.0;

  // Radii
  static const BorderRadius radiusXs = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius radiusSm = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius radiusMd = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius radiusLg = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(28.0));
  static const BorderRadius radius2Xl = BorderRadius.all(Radius.circular(32.0));
  static const BorderRadius radiusMax = BorderRadius.all(Radius.circular(48.0));
  static const BorderRadius radiusFull = BorderRadius.all(
    Radius.circular(9999.0),
  );
  static const BorderRadius radiusInput = BorderRadius.only(
    topLeft: Radius.circular(12.0),
    topRight: Radius.circular(12.0),
    bottomLeft: Radius.circular(0.0),
    bottomRight: Radius.circular(0.0),
  );
}
