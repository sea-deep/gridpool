import 'package:flutter/material.dart';
import 'dart:ui';

class OrganicBackground extends StatelessWidget {
  final Widget child;

  const OrganicBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    return Stack(
      children: [
        // Base surface
        Container(color: scheme.surface),
        
        // Organic blur shape 1 (Primary)
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer.withValues(alpha: 0.4),
            ),
          ),
        ),
        
        // Organic blur shape 2 (Secondary)
        Positioned(
          top: 200,
          left: -100,
          child: Container(
            width: 250,
            height: 400,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(150),
              color: scheme.secondaryContainer.withValues(alpha: 0.3),
            ),
          ),
        ),
        
        // Organic blur shape 3 (Tertiary)
        Positioned(
          bottom: -50,
          right: 50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.tertiary.withValues(alpha: 0.15),
            ),
          ),
        ),

        // Blur layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        
        // Content
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
