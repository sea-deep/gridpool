import 'package:flutter/material.dart';

/// Shows an error snackbar with consistent styling
void showErrorSnackBar(BuildContext context, dynamic error) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Error: $error'),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Shows a success snackbar with consistent styling
void showSuccessSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
