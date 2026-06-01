import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/providers/pool_providers.dart';
import 'package:frontend/providers/dashboard_controller.dart';
import 'package:frontend/services/pool_repository.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';

class _CollectionRow {
  String? userId;
  TextEditingController amountController = TextEditingController();
}

class LogCollectionScreen extends ConsumerStatefulWidget {
  final Pool pool;

  const LogCollectionScreen({super.key, required this.pool});

  @override
  ConsumerState<LogCollectionScreen> createState() => _LogCollectionScreenState();
}

class _LogCollectionScreenState extends ConsumerState<LogCollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  
  String _selectedPaymentMethod = 'Cash';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  
  final List<_CollectionRow> _rows = [_CollectionRow()];
  final List<String> _paymentMethods = ['Cash', 'UPI', 'Bank Transfer', 'Other'];

  @override
  void dispose() {
    _noteController.dispose();
    for (var row in _rows) {
      row.amountController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  void _addRow() {
    setState(() {
      _rows.add(_CollectionRow());
    });
  }

  void _removeRow(int index) {
    if (_rows.length > 1) {
      setState(() {
        _rows[index].amountController.dispose();
        _rows.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate that at least one valid row exists
    final validRows = _rows.where((r) => r.userId != null && r.amountController.text.trim().isNotEmpty).toList();
    
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one member and amount.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final collections = validRows.map((r) => {
        'userId': r.userId,
        'amount': double.parse(r.amountController.text.trim()),
      }).toList();

      final data = {
        'date': _selectedDate.toIso8601String(),
        'paymentMethod': _selectedPaymentMethod,
        'note': _noteController.text.trim(),
        'collections': collections,
      };

      await ref.read(poolRepositoryProvider).logCollection(
        poolId: widget.pool.id,
        data: data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection logged successfully!')),
        );
        ref.invalidate(dashboardControllerProvider);
        ref.invalidate(ledgerProvider(widget.pool.id));
        ref.invalidate(activityFeedProvider);
        ref.invalidate(poolMembersProvider(widget.pool.id));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging collection: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(poolMembersProvider(widget.pool.id));

    return PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Log Collection',
            subtitle: 'Record offline payments received from members.',
            actions: [
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  shape: const CircleBorder(),
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Expanded(
            child: membersAsync.when(
              data: (members) {
                // Optionally filter out members with 0 due amount, but admin might want to log advance payments.
                // We'll show all members.
                if (members.isEmpty) {
                  return const Center(child: Text('No members found in this pool.'));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space3Xl),
                  child: AppSurface(
                    elevation: 0,
                    showOutline: true,
                    padding: const EdgeInsets.all(DesignTokens.spaceXl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: DesignTokens.radiusMd,
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(DateFormat.yMMMd().format(_selectedDate)),
                                  const Icon(Icons.calendar_today_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spaceLg),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPaymentMethod,
                            decoration: const InputDecoration(labelText: 'Payment Method'),
                            items: _paymentMethods.map((c) => DropdownMenuItem(
                              value: c, child: Text(c),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedPaymentMethod = val);
                            },
                          ),
                          const SizedBox(height: DesignTokens.spaceLg),
                          TextFormField(
                            controller: _noteController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (Optional)',
                              hintText: 'e.g., Handed over directly',
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spaceXl),
                          const Text(
                            'Members & Amounts',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: DesignTokens.spaceMd),
                          
                          // Dynamic Rows
                          ..._rows.asMap().entries.map((entry) {
                            final index = entry.key;
                            final row = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: row.userId,
                                      hint: const Text('Select Member'),
                                      isExpanded: true,
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      ),
                                      items: members.map((m) => DropdownMenuItem(
                                        value: m.id, 
                                        child: Text(m.name, overflow: TextOverflow.ellipsis),
                                      )).toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          row.userId = val;
                                          // Auto-fill amount with member's due amount if empty
                                          if (val != null && row.amountController.text.isEmpty) {
                                            final selectedMember = members.firstWhere((m) => m.id == val);
                                            if (selectedMember.dueAmount > 0) {
                                              row.amountController.text = selectedMember.dueAmount.toStringAsFixed(0);
                                            }
                                          }
                                        });
                                      },
                                      validator: (value) => value == null ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: DesignTokens.spaceSm),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: row.amountController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        hintText: 'Amount',
                                        prefixText: '₹',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      ),
                                      validator: (value) {
                                        if (row.userId == null) return null; // Don't validate amount if member isn't selected
                                        if (value == null || value.trim().isEmpty) return 'Required';
                                        final parsed = double.tryParse(value.trim());
                                        if (parsed == null || parsed <= 0) return 'Enter a valid positive amount';
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (_rows.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                      onPressed: () => _removeRow(index),
                                    ),
                                ],
                              ),
                            );
                          }),

                          TextButton.icon(
                            onPressed: _addRow,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Member'),
                          ),

                          const SizedBox(height: DesignTokens.space2Xl),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Save Collections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
