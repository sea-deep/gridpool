import 'package:flutter/material.dart';
import 'package:frontend/theme/design_tokens.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: title != null
          ? AppBar(
              title: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: child,
        ),
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
