import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/models/pool_member.dart';
import 'package:frontend/models/join_request.dart';
import 'package:frontend/models/payment_request.dart';

import 'package:frontend/providers/pool_providers.dart';
import 'package:frontend/providers/dashboard_controller.dart';
import 'package:frontend/services/pool_repository.dart';

class PoolDetailsScreen extends ConsumerWidget {
  final Pool initialPool;

  const PoolDetailsScreen({super.key, required this.initialPool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolsAsync = ref.watch(dashboardControllerProvider);
    final pool = poolsAsync.maybeWhen(
      data: (pools) => pools.firstWhere((p) => p.id == initialPool.id, orElse: () => initialPool),
      orElse: () => initialPool,
    );

    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    final scheme = Theme.of(context).colorScheme;
    final membersAsync = ref.watch(poolMembersProvider(pool.id));
    final roleAsync = ref.watch(poolRoleProvider(pool.id));

    final joinRequestsAsync = ref.watch(joinRequestsProvider(pool.id));
    final paymentRequestsAsync = ref.watch(paymentRequestsProvider(pool.id));
    
    final pendingPaymentCount = paymentRequestsAsync.maybeWhen(
      data: (requests) => requests.where((r) => r.status == PaymentRequestStatus.pending).length,
      orElse: () => 0,
    );


    final pendingCount = joinRequestsAsync.maybeWhen(
      data: (requests) => requests.where((r) => r.status == JoinRequestStatus.pending).length,
      orElse: () => 0,
    );

    final members = membersAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <PoolMember>[],
    );

    final isOwner = pool.createdBy == currentUser?.id;
    final isAdmin = isOwner || roleAsync.maybeWhen(
      data: (role) => role == PoolRole.owner || role == PoolRole.admin,
      orElse: () => false,
    );

    final totalPending = members.fold(0.0, (sum, m) => sum + m.dueAmount);

    return PageScaffold(
      child: RefreshIndicator(
        color: scheme.primary,
        onRefresh: () async {
          ref.invalidate(dashboardControllerProvider);
          ref.invalidate(poolMembersProvider(pool.id));
          ref.invalidate(poolRoleProvider(pool.id));
          await Future.delayed(const Duration(milliseconds: 800));
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: pool.name,
                subtitle: 'Balance: ₹${pool.currentBalance.toStringAsFixed(0)}',
                actions: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: scheme.surfaceContainerHighest,
                      foregroundColor: scheme.onSurfaceVariant,
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: DesignTokens.spaceSm),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text('Invite Code'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: pool.inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Invite code copied to clipboard!',
                          ),
                          backgroundColor: DesignTokens.success,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 1. Overview Block
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceLg),
                child: AppSurface(
                  elevation: 0.5,
                  showOutline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Totals',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      Row(
                        children: [
                          Expanded(
                            child: _TotalStat(
                              label: 'Collected',
                              value: pool.totalCollected,
                              color: DesignTokens.success,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceLg),
                          Expanded(
                            child: _TotalStat(
                              label: 'Spent',
                              value: pool.totalSpent,
                              color: DesignTokens.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      Row(
                        children: [
                          Expanded(
                            child: _TotalStat(
                              label: 'Balance',
                              value: pool.currentBalance,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceLg),
                          Expanded(
                            child: _TotalStat(
                              label: 'Pending',
                              value: totalPending,
                              color: scheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Due Status Block
            if (currentUser != null)
              Builder(builder: (context) {
                final currentMember = members.where((m) => m.id == currentUser.id).firstOrNull;
                final userDue = currentMember?.dueAmount ?? 0.0;
                
                final hasDues = userDue > 0;
                
                final hasPendingRequest = paymentRequestsAsync.maybeWhen(
                  data: (requests) => requests.any((r) => r.userId == currentUser.id && r.status == PaymentRequestStatus.pending),
                  orElse: () => false,
                );

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.spaceLg),
                    child: AppSurface(
                      elevation: 1,
                      showOutline: true,
                      color: hasPendingRequest
                          ? scheme.tertiaryContainer 
                          : (hasDues ? scheme.secondaryContainer : scheme.surfaceContainerHigh),
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                hasPendingRequest ? Icons.hourglass_top_rounded
                                  : (hasDues ? Icons.payment_outlined : Icons.check_circle_outline), 
                                color: hasPendingRequest ? scheme.onTertiaryContainer
                                  : (hasDues ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
                              ),
                              const SizedBox(width: DesignTokens.spaceSm),
                              Expanded(
                                child: Text(
                                  hasPendingRequest ? 'Payment Pending' : 'Payment Status',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: hasPendingRequest ? scheme.onTertiaryContainer
                                      : (hasDues ? scheme.onSecondaryContainer : scheme.onSurface),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: DesignTokens.spaceSm),
                          Text(
                            hasPendingRequest
                                ? 'Your payment of ₹${userDue.toStringAsFixed(0)} is pending admin approval. You will be notified once it is reviewed.'
                                : (hasDues 
                                    ? 'Your current due is ₹${userDue.toStringAsFixed(0)}. Please clear this when you can to help maintain the pool balance.'
                                    : 'You have no pending dues. You\'re all caught up!'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: hasPendingRequest ? scheme.onTertiaryContainer
                                : (hasDues ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
                            ),
                          ),
                          if (hasDues && !hasPendingRequest && isAdmin) ...[
                            const SizedBox(height: DesignTokens.spaceLg),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: scheme.secondary,
                                  foregroundColor: scheme.onSecondary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: DesignTokens.radiusMd,
                                  ),
                                ),
                                icon: const Icon(Icons.payment_rounded),
                                label: const Text(
                                  'Log My Payment',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Log Payment'),
                                      content: Text('Are you sure you want to log your payment of ₹${userDue.toStringAsFixed(0)}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          child: const Text('Confirm'),
                                        ),
                                      ],
                                    ),
                                  );
                                  
                                  if (confirm == true && context.mounted) {
                                    try {
                                      await ref.read(poolRepositoryProvider).payDue(
                                        poolId: pool.id,
                                        amount: userDue,
                                      );
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Payment logged successfully!')),
                                        );
                                        ref.invalidate(dashboardControllerProvider);
                                        ref.invalidate(poolMembersProvider(pool.id));
                                        ref.invalidate(ledgerProvider(pool.id));
                                        ref.invalidate(activityFeedProvider);
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error logging payment: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                          if (hasDues && !hasPendingRequest && !isAdmin) ...[
                            const SizedBox(height: DesignTokens.spaceLg),
                            if (pool.upiId == null || pool.upiId!.isEmpty)
                              Text(
                                'Pool owner has not set a UPI ID yet. Payment is not available.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSecondaryContainer,
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: scheme.secondary,
                                    foregroundColor: scheme.onSecondary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: DesignTokens.radiusMd,
                                    ),
                                  ),
                                  icon: const Icon(Icons.payment_rounded),
                                  label: const Text(
                                    'Pay Now',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    context.push('/payment-submission', extra: {
                                      'pool': pool,
                                      'amountDue': userDue,
                                    });
                                  },
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

            // 3. Action Menu Block
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space2Xl),
                child: AppSurface(
                  elevation: 0.5,
                  showOutline: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        mainAxisSpacing: DesignTokens.spaceMd,
                        crossAxisSpacing: DesignTokens.spaceMd,
                        childAspectRatio: 0.75,
                        children: [
                          _ActionCard(
                            title: 'View Members',
                            icon: Icons.people_alt_rounded,
                            onTap: () => context.push('/pool-members', extra: pool),
                          ),
                          _ActionCard(
                            title: 'Money In',
                            icon: Icons.arrow_downward_rounded,
                            onTap: () => context.push('/money-in', extra: pool),
                          ),
                          _ActionCard(
                            title: 'Money Out',
                            icon: Icons.arrow_upward_rounded,
                            onTap: () => context.push('/money-out', extra: pool),
                          ),
                          if (isAdmin) ...[

                            _ActionCard(
                              title: 'Approve Join',
                              icon: Icons.person_add_alt_1_rounded,
                              badgeCount: pendingCount,
                              onTap: () => context.push('/approve-join', extra: pool),
                            ),
                            _ActionCard(
                              title: 'Approve Payment',
                              icon: Icons.receipt_long_rounded,
                              badgeCount: pendingPaymentCount,
                              onTap: () => context.push('/approve-payment', extra: pool),
                            ),

                            _ActionCard(
                              title: 'Log Collection',
                              icon: Icons.payments_rounded,
                              onTap: () => context.push('/log-collection', extra: pool),
                            ),
                            _ActionCard(
                              title: 'Log Expense',
                              icon: Icons.money_off_rounded,
                              onTap: () => context.push('/log-expense', extra: pool),
                            ),
                            _ActionCard(
                              title: 'Edit Pool Info',
                              icon: Icons.edit_rounded,
                              onTap: () => context.push('/edit-pool', extra: pool),
                            ),
                            _ActionCard(
                              title: 'Delete Pool',
                              icon: Icons.delete_outline_rounded,
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Pool'),
                                    content: const Text('Are you sure you want to permanently delete this pool? This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.error,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirm == true && context.mounted) {
                                  try {
                                    await ref.read(poolRepositoryProvider).deletePool(pool.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Pool deleted successfully')),
                                      );
                                      ref.invalidate(dashboardControllerProvider);
                                      context.go('/dashboard');
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error deleting pool: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      onTap: onTap,
      elevation: 0,
      hoverElevation: 2,
      showOutline: true,
      color: Colors.transparent,
      borderRadius: DesignTokens.radiusMd, // Reduced from default radiusLg (24) to radiusMd (16)
      padding: const EdgeInsets.all(DesignTokens.spaceXs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: DesignTokens.spaceSm),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.spaceSm),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12), // 16 (radiusMd) - 4 (spaceXs) = 12
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer, size: 24),
              ),
              if (badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: scheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : badgeCount.toString(),
                      style: TextStyle(
                        color: scheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _TotalStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: DesignTokens.spaceXs),
        Text(
          '₹${value.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }
}
