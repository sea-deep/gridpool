import 'package:flutter/material.dart';
import 'package:frontend/theme/design_tokens.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  String? title,
}) {
  final scheme = Theme.of(context).colorScheme;

  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: scheme.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: DesignTokens.radiusXl),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).viewInsets.bottom + DesignTokens.spaceLg,
          top: DesignTokens.spaceMd,
          left: DesignTokens.spaceLg,
          right: DesignTokens.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: DesignTokens.spaceLg),
            ],
            child,
          ],
        ),
      );
    },
  );
}
