import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/widgets/app_text_field.dart';
import 'package:frontend/providers/auth_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _upiController = TextEditingController();
  bool _notificationPreference = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).user;
    _nameController = TextEditingController(text: user?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PageScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.waves_rounded, size: 72, color: scheme.primary),
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                'Welcome to GridPool',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceXs),
              Text(
                'Let\'s set up your profile to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.space2Xl),
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    AppTextField(
                      controller: _nameController,
                      hintText: 'Your Display Name',
                      prefixIcon: Icon(
                        Icons.person_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    AppTextField(
                      controller: _upiController,
                      hintText: 'UPI ID (optional, e.g. name@upi)',
                      prefixIcon: Icon(
                        Icons.wallet_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    const Divider(height: 1),
                    const SizedBox(height: DesignTokens.spaceLg),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(DesignTokens.spaceSm),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: DesignTokens.radiusMd,
                          ),
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceLg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Notifications',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurface,
                                    ),
                              ),
                              Text(
                                'Stay updated on contributions & dues',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _notificationPreference,
                          onChanged: (val) {
                            setState(() {
                              _notificationPreference = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.space2Xl),
              AppButton(
                text: 'Complete Setup',
                icon: Icon(Icons.arrow_forward_rounded, color: scheme.onPrimary),
                onPressed: () async {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a display name')),
                    );
                    return;
                  }
                  try {
                    await ref.read(authControllerProvider.notifier).completeOnboarding(
                          name: name,
                          upiId: _upiController.text.trim().isEmpty ? null : _upiController.text.trim(),
                          notificationPreference: _notificationPreference,
                        );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Setup failed: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
