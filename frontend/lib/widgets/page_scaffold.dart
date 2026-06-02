import 'package:flutter/material.dart';
import 'package:frontend/theme/design_tokens.dart';

import 'package:frontend/widgets/atmospheric_background.dart';

class PageScaffold extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const PageScaffold({
    super.key,
    this.title,
    required this.child,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Let AtmosphericBackground handle the background color
      appBar: title != null
          ? AppBar(
              title: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            )
          : null,
      body: AtmosphericBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
