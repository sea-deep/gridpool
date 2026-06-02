import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/models/auth_models.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.loading;

    // Auth error listener
    ref.listen(authControllerProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    return PageScaffold(
      child: Stack(
        children: [
          // Main content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  Center(
                    child: ClipRRect(
                      borderRadius: DesignTokens.radiusXl,
                      child: Image.asset(
                        'assets/icons/logo.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  Text(
                    'GridPool',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text(
                    'Transparent, shared money management.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DesignTokens.space3Xl),

                  // Feature highlights
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _FeatureChip(
                        icon: Icons.visibility_rounded,
                        label: 'Transparent',
                        scheme: scheme,
                      ),
                      _FeatureChip(
                        icon: Icons.group_rounded,
                        label: 'Shared',
                        scheme: scheme,
                      ),
                      _FeatureChip(
                        icon: Icons.bolt_rounded,
                        label: 'Simple',
                        scheme: scheme,
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space3Xl),

                  // Login card
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: DesignTokens.radiusXl,
                      border: Border.all(
                        color: scheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Get started',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(
                          'Sign in to create or join a pool',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        AppButton(
                          text: isLoading ? 'Signing in...' : 'Continue with Google',
                          isLoading: isLoading,
                          icon: isLoading
                              ? null
                              : Icon(
                                  Icons.login_rounded,
                                  color: scheme.onPrimary,
                                  size: 20,
                                ),
                          onPressed: isLoading ? null : () {
                            ref
                                .read(authControllerProvider.notifier)
                                .signInWithGoogle();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme scheme;

  const _FeatureChip({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.primary, size: 22),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
