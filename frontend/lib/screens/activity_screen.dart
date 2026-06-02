import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:intl/intl.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/empty_state_view.dart';
import 'package:frontend/providers/pool_providers.dart';
import 'package:frontend/widgets/transaction_details_sheet.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final activityAsync = ref.watch(activityFeedProvider);

    return PageScaffold(
      child: RefreshIndicator(
        color: scheme.primary,
        onRefresh: () async {
          ref.invalidate(activityFeedProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: PageHeader(
                title: 'Activity',
                subtitle: 'Recent transactions across your pools',
              ),
            ),
            activityAsync.when(
              loading: () => SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Failed to load activity: $e')),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyStateView(
                      icon: Icons.receipt_long_rounded,
                      title: 'No Activity Yet',
                      message:
                          'When group members add expenses or make payments, they will appear here.',
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = entries[index];
                      return _ActivityEntryCard(entry: entry);
                    },
                    childCount: entries.length,
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: DesignTokens.space3Xl),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityEntryCard extends StatelessWidget {
  final Map<String, dynamic> entry;

  const _ActivityEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = entry['type'] as String? ?? '';
    final description = entry['description'] as String? ?? 'No description';
    final amount = (entry['amount'] as num?)?.toDouble() ?? 0.0;
    final poolName = entry['poolName'] as String? ?? 'Unknown Pool';
    final createdByName = entry['createdByName'] as String? ?? entry['createdBy'] ?? '';
    final timestamp = entry['timestamp'] as String?;
    final imageUrl = entry['imageUrl'] as String?;

    final isExpense = type == 'expense_added';
    final isContributionCreated = type == 'contribution_created';
    final isPaid = type == 'contribution_paid';

    IconData iconData;
    Color iconColor;
    String prefix;

    if (isExpense) {
      iconData = Icons.money_off_rounded;
      iconColor = scheme.error;
      prefix = '-';
    } else if (isContributionCreated) {
      iconData = Icons.add_circle_outline_rounded;
      iconColor = scheme.tertiary;
      prefix = '';
    } else if (isPaid) {
      iconData = Icons.check_circle_outline_rounded;
      iconColor = DesignTokens.success;
      prefix = '+';
    } else {
      iconData = Icons.receipt_long_rounded;
      iconColor = scheme.primary;
      prefix = '';
    }

    String timeAgo = '';
    if (timestamp != null) {
      final dt = DateTime.tryParse(timestamp);
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 1) {
          timeAgo = 'Just now';
        } else if (diff.inHours < 1) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inDays < 1) {
          timeAgo = '${diff.inHours}h ago';
        } else if (diff.inDays < 7) {
          timeAgo = '${diff.inDays}d ago';
        } else {
          timeAgo = '${dt.day}/${dt.month}/${dt.year}';
        }
      }
    }
    
    String fullDateStr = '';
    if (timestamp != null) {
      final dt = DateTime.tryParse(timestamp);
      if (dt != null) {
        fullDateStr = DateFormat.yMMMd().add_jm().format(dt.toLocal());
      }
    }

    String typeLabel = 'Transaction';
    if (isExpense) typeLabel = 'Expense';
    if (isPaid) typeLabel = 'Payment';
    if (isContributionCreated) typeLabel = 'Contribution Request';

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
      child: AppSurface(
        elevation: 0.5,
        showOutline: true,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 12),
        onTap: () {
          TransactionDetailsSheet.show(
            context: context,
            title: description,
            amount: amount,
            dateStr: fullDateStr.isNotEmpty ? fullDateStr : null,
            typeLabel: typeLabel,
            creatorName: createdByName,
            imageUrl: imageUrl,
            isExpense: isExpense,
            isPaid: isPaid,
          );
        },
        child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 22),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$createdByName • $poolName',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (timeAgo.isNotEmpty) ...[
                            Text(
                              ' • $timeAgo',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceSm),
                Text(
                  '$prefix₹${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isExpense
                            ? scheme.error
                            : isPaid
                                ? DesignTokens.success
                                : scheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
      ),
    );
  }
}

