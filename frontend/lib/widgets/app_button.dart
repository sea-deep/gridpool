import 'package:flutter/material.dart';
import 'package:frontend/theme/design_tokens.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isLoading;
  final Widget? icon;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelMedium;
    final padding = const EdgeInsets.symmetric(
      vertical: DesignTokens.spaceMd,
      horizontal: DesignTokens.spaceLg,
    );

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isPrimary ? scheme.onPrimary : scheme.primary,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: DesignTokens.spaceSm),
        ],
        Text(text),
      ],
    );

    if (isDestructive) {
      return FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          padding: padding,
          textStyle: textStyle,
          backgroundColor: scheme.error,
          foregroundColor: scheme.onError,
          shape: const StadiumBorder(),
        ),
        child: child,
      );
    }

    final style = FilledButton.styleFrom(
      padding: padding,
      textStyle: textStyle,
      shape: const StadiumBorder(),
    );

    if (isPrimary) {
      return FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: style,
        child: child,
      );
    }

    return FilledButton.tonal(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: child,
    );
  }
}
