import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import "package:frontend/widgets/transaction_details_sheet.dart";
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/providers/pool_providers.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/models/ledger_entry.dart';

class MoneyInScreen extends ConsumerWidget {
  final Pool pool;

  const MoneyInScreen({super.key, required this.pool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(ledgerProvider(pool.id));

    return PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Collection History',
            subtitle: 'A complete ledger of all payments and contributions collected in this pool.',
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
            child: ledgerAsync.when(
              data: (entries) {
                // Filter only positive credits to the pool (payments, collections)
                final credits = entries.where((e) {
                  return e.type == LedgerEntryType.payment ||
                         e.type == LedgerEntryType.contributionPaid ||
                         e.type == LedgerEntryType.paymentMarkedOffline ||
                         e.type == LedgerEntryType.duePaid ||
                         (e.type == LedgerEntryType.manualAdjustment && e.amount > 0);
                }).toList();
                
                if (credits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        Text(
                          'No collections yet.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space3Xl),
                  itemCount: credits.length,
                  itemBuilder: (context, index) {
                    final entry = credits[index];
                    final dateStr = entry.timestamp != null 
                        ? DateFormat.yMMMd().add_jm().format(entry.timestamp!.toLocal())
                        : 'Unknown date';
                        
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                      child: AppSurface(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 12),
                        onTap: () {
                          TransactionDetailsSheet.show(
                            context: context,
                            title: entry.description ?? 'Payment',
                            amount: entry.amount,
                            dateStr: dateStr,
                            typeLabel: 'Money In',
                            creatorName: entry.createdBy,
                            paymentMethod: entry.paymentMethod?.name,
                            imageUrl: entry.imageUrl,
                            isPaid: true,
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(DesignTokens.spaceSm),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spaceLg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.description ?? 'Payment',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+ ₹${entry.amount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: DesignTokens.success,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
