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

class CreatePoolScreen extends ConsumerStatefulWidget {
  const CreatePoolScreen({super.key});

  @override
  ConsumerState<CreatePoolScreen> createState() => _CreatePoolScreenState();
}

class _CreatePoolScreenState extends ConsumerState<CreatePoolScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _upiController = TextEditingController();
  final _customIntervalController = TextEditingController();
  final _expectedContributionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedFrequency = 'once';

  Future<void> _handleCreate() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final expectedContribText = _expectedContributionController.text.trim();
        final expectedContrib = expectedContribText.isEmpty ? 0.0 : (double.tryParse(expectedContribText) ?? 0.0);
        
        final customIntervalText = _customIntervalController.text.trim();
        final customIntervalInt = int.tryParse(customIntervalText);

        await ref
            .read(dashboardControllerProvider.notifier)
            .createPool(
              name: _nameController.text.trim(),
              description: _descController.text.trim(),
              upiId: _upiController.text.trim(),
              frequency: _selectedFrequency,
              customInterval: _selectedFrequency == 'custom' ? customIntervalInt : null,
              expectedContribution: expectedContrib,
            );
        if (mounted) context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _upiController.dispose();
    _customIntervalController.dispose();
    _expectedContributionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PageScaffold(
      child: Column(
        children: [
          PageHeader(
            title: 'Create Pool',
            subtitle: 'Start a new shared fund',
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
                        controller: _nameController,
                        hintText: 'Pool Name',
                        prefixIcon: Icon(
                          Icons.waves_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        validator: (v) =>
                            v != null && v.trim().isEmpty ? 'Name required' : null,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      AppTextField(
                        controller: _descController,
                        hintText: 'Description (optional)',
                        prefixIcon: Icon(
                          Icons.description_outlined,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      AppTextField(
                        controller: _upiController,
                        hintText: 'Pool UPI ID',
                        prefixIcon: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        validator: (v) => v != null && v.isEmpty
                            ? 'UPI ID required'
                            : null,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedFrequency,
                        decoration: InputDecoration(
                          hintText: 'Payment Interval',
                          prefixIcon: Icon(
                            Icons.repeat_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'once',
                            child: Text('Once (Temporary Event)'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                          DropdownMenuItem(
                            value: 'quarterly',
                            child: Text('Quarterly'),
                          ),
                          DropdownMenuItem(
                            value: 'halfyearly',
                            child: Text('Half-yearly'),
                          ),
                          DropdownMenuItem(
                            value: 'yearly',
                            child: Text('Yearly'),
                          ),
                          DropdownMenuItem(
                            value: 'custom',
                            child: Text('Custom Interval'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedFrequency = val);
                          }
                        },
                      ),
                      if (_selectedFrequency == 'custom') ...[
                        const SizedBox(height: DesignTokens.spaceLg),
                        AppTextField(
                          controller: _customIntervalController,
                          hintText: 'Custom Interval (in days)',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icon(
                            Icons.edit_calendar_rounded,
                            color: scheme.onSurfaceVariant,
                          ),
                          validator: (v) {
                            if (_selectedFrequency == 'custom') {
                              if (v == null || v.trim().isEmpty) {
                                return 'Custom interval (in days) required';
                              }
                              if (int.tryParse(v.trim()) == null) {
                                return 'Please enter a valid number of days';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: DesignTokens.spaceLg),
                      AppTextField(
                        controller: _expectedContributionController,
                        hintText: 'Expected contribution per member (₹)',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icon(
                          Icons.currency_rupee_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Expected contribution required';
                          }
                          final val = double.tryParse(v.trim());
                          if (val == null || val <= 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: DesignTokens.space2Xl),
                      AppButton(
                        text: _isLoading ? 'Creating...' : 'Create new Pool',
                        onPressed: _isLoading ? null : _handleCreate,
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
