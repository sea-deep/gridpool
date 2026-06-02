import 'package:flutter/material.dart';
import 'dart:ui';

class AtmosphericBackground extends StatelessWidget {
  final Widget child;

  const AtmosphericBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Stack(
      children: [
        // Base background color
        Container(color: scheme.surface),
        
        // Blur shapes - Bold Factor
        Positioned.fill(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Stack(
              children: [
                Positioned(
                  top: -100,
                  right: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                    ),
                  ),
                ),
                Positioned(
                  top: 200,
                  left: -100,
                  child: Container(
                    width: 250,
                    height: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      color: scheme.tertiary.withValues(alpha: isDark ? 0.25 : 0.15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Actual content
        Positioned.fill(child: child),
      ],
    );
  }
}
