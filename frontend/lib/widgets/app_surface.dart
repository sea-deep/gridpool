import 'package:flutter/material.dart';
import 'package:frontend/theme/design_tokens.dart';

class AppSurface extends StatefulWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final bool showOutline;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double elevation;
  final double? hoverElevation;
  final double? pressedElevation;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const AppSurface({
    super.key,
    required this.child,
    this.borderRadius = DesignTokens.radiusLg,
    this.showOutline = false,
    this.padding,
    this.color,
    this.elevation = 1,
    this.hoverElevation,
    this.pressedElevation,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  State<AppSurface> createState() => _AppSurfaceState();
}

class _AppSurfaceState extends State<AppSurface> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _handleHover(bool value) {
    if (!mounted || widget.onTap == null) return;
    setState(() => _isHovered = value);
  }

  void _handleHighlight(bool value) {
    if (!mounted || widget.onTap == null) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final surfaceColor = widget.color ?? scheme.surfaceContainerHighest;
    final outline = widget.showOutline
        ? BorderSide(color: scheme.outline.withValues(alpha: 0.3))
        : BorderSide.none;

    final baseElevation = widget.elevation;
    final hoverElevation = widget.hoverElevation ?? baseElevation + 1;
    final pressedElevation = widget.pressedElevation ?? 0;

    final effectiveElevation = _isPressed
        ? pressedElevation
        : _isHovered
        ? hoverElevation
        : baseElevation;

    final content = Padding(
      padding: widget.padding ?? const EdgeInsets.all(DesignTokens.spaceLg),
      child: widget.child,
    );

    return AnimatedPhysicalModel(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      color: surfaceColor,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      elevation: effectiveElevation,
      shape: BoxShape.rectangle,
      borderRadius: widget.borderRadius,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: outline == BorderSide.none
              ? null
              : Border.fromBorderSide(outline),
        ),
        child: widget.onTap == null
            ? content
            : Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: widget.onTap,
                  onHover: _handleHover,
                  onHighlightChanged: _handleHighlight,
                  borderRadius: widget.borderRadius,
                  overlayColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) {
                      return scheme.primary.withValues(alpha: 0.12);
                    }
                    if (states.contains(WidgetState.hovered)) {
                      return scheme.primary.withValues(alpha: 0.08);
                    }
                    return null;
                  }),
                  child: content,
                ),
              ),
      ),
    );
  }
}
