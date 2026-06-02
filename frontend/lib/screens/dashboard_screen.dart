import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/async_value_widget.dart';
import 'package:frontend/widgets/empty_state_view.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/providers/dashboard_controller.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/widgets/pool_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolsAsyncValue = ref.watch(dashboardControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user?.name.split(' ').first ?? 'there';

    return PageScaffold(
      child: RefreshIndicator(
        color: scheme.primary,
        onRefresh: () => ref.read(dashboardControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: '${_getGreeting()}, $userName',
                subtitle: 'Your shared pools',
                actions: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.group_add_rounded, size: 20),
                    label: const Text('Join'),
                    onPressed: () => context.push('/join-pool'),
                  ),
                  const SizedBox(width: DesignTokens.spaceSm),
                  FilledButton.icon(
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Create'),
                    onPressed: () => context.push('/create-pool'),
                  ),
                ],
              ),
            ),



            SliverToBoxAdapter(
              child: AsyncValueWidget(
                value: poolsAsyncValue,
                data: (pools) {
                  if (pools.isEmpty) {
                    return EmptyStateView(
                      icon: Icons.waves_rounded,
                      title: 'No Pools Yet',
                      message:
                          'Create a new pool or join an existing one to start managing shared expenses.',
                      actionText: 'Join a Pool',
                      onAction: () => context.push('/join-pool'),
                    );
                  }

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: pools.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: DesignTokens.spaceLg),
                    itemBuilder: (context, index) {
                      return PoolCard(
                        pool: pools[index],
                        onTap: () {
                          context.push('/pool-details', extra: pools[index]);
                        },
                      );
                    },
                  );
                },
              ),
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


