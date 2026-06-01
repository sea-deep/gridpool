import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/app_text_field.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/providers/dashboard_controller.dart';

class JoinPoolScreen extends ConsumerStatefulWidget {
  const JoinPoolScreen({super.key});

  @override
  ConsumerState<JoinPoolScreen> createState() => _JoinPoolScreenState();
}

class _JoinPoolScreenState extends ConsumerState<JoinPoolScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleJoin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        await ref
            .read(dashboardControllerProvider.notifier)
            .joinPool(_codeController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Join request sent for approval.')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: DesignTokens.warning,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PageScaffold(
      child: Column(
        children: [
          PageHeader(
            title: 'Join Pool',
            subtitle: 'Enter your invite code',
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: scheme.onSurfaceVariant,
                onPressed: () => context.pop(),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: AppSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _codeController,
                        hintText: 'Invite Code (e.g. MAGIC123)',
                        prefixIcon: Icon(
                          Icons.key_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        validator: (v) =>
                            v != null && v.trim().isEmpty ? 'Code required' : null,
                      ),
                      const SizedBox(height: DesignTokens.space2Xl),
                      AppButton(
                        text: _isLoading ? 'Requesting...' : 'Request to Join',
                        onPressed: _isLoading ? null : _handleJoin,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
