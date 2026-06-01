import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/models/join_request.dart';
import 'package:frontend/providers/pool_providers.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/services/pool_repository.dart';

class ApproveJoinScreen extends ConsumerWidget {
  final Pool pool;

  const ApproveJoinScreen({super.key, required this.pool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final joinRequestsAsync = ref.watch(joinRequestsProvider(pool.id));

    return PageScaffold(
      child: Column(
        children: [
          PageHeader(
            title: 'Approve Join',
            subtitle: pool.name,
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
            ],
          ),
          Expanded(
            child: joinRequestsAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
              error: (e, _) => Center(
                child: Text(
                  'Failed to load join requests: $e',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              data: (requests) {
                // Filter only pending requests
                final pendingRequests = requests.where((r) => r.status == JoinRequestStatus.pending).toList();

                if (pendingRequests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 64, color: scheme.primary.withValues(alpha: 0.5)),
                        const SizedBox(height: DesignTokens.spaceMd),
                        Text(
                          'No pending requests',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space2Xl),
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = pendingRequests[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                      child: AppSurface(
                        elevation: 0.5,
                        showOutline: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceMd,
                          vertical: DesignTokens.spaceSm,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: scheme.secondaryContainer,
                              backgroundImage: request.userAvatarUrl.isNotEmpty
                                  ? NetworkImage(request.userAvatarUrl)
                                  : null,
                              child: request.userAvatarUrl.isEmpty
                                  ? Text(
                                      request.userName.isNotEmpty
                                          ? request.userName[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: scheme.onSecondaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: DesignTokens.spaceMd),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.userName,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    request.userEmail,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: DesignTokens.success.withValues(alpha: 0.1),
                                foregroundColor: DesignTokens.success,
                              ),
                              icon: const Icon(Icons.check_rounded),
                              onPressed: () async {
                                try {
                                  await ref.read(poolRepositoryProvider).approveJoinRequest(
                                    poolId: pool.id,
                                    request: request,
                                    approverId: ref.read(authControllerProvider).user?.id ?? '',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Request approved!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                            const SizedBox(width: DesignTokens.spaceSm),
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: scheme.error.withValues(alpha: 0.1),
                                foregroundColor: scheme.error,
                              ),
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () async {
                                try {
                                  await ref.read(poolRepositoryProvider).rejectJoinRequest(
                                    poolId: pool.id,
                                    request: request,
                                    approverId: ref.read(authControllerProvider).user?.id ?? '',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Request rejected')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
