import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/widgets/app_bottom_sheet.dart';
import 'package:frontend/widgets/app_text_field.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/providers/pool_providers.dart';
import 'package:frontend/services/pool_repository.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/models/pool_member.dart';

class PoolMembersScreen extends ConsumerWidget {
  final Pool pool;

  const PoolMembersScreen({super.key, required this.pool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final currentUser = authState.user;
    final scheme = Theme.of(context).colorScheme;
    final membersAsync = ref.watch(poolMembersProvider(pool.id));
    final roleAsync = ref.watch(poolRoleProvider(pool.id));

    final isOwnerOrAdmin = roleAsync.maybeWhen(
      data: (role) => role == PoolRole.owner || role == PoolRole.admin,
      orElse: () => pool.createdBy == currentUser?.id,
    ) || (pool.createdBy == currentUser?.id);

    final isOwner = currentUser?.id == pool.createdBy;

    Future<void> changeMemberRole(String userId, String newRole) async {
      try {
        await ref.read(poolRepositoryProvider).updateMemberRole(
          poolId: pool.id,
          userId: userId,
          role: newRole,
        );
        ref.invalidate(poolMembersProvider(pool.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Member role updated to $newRole!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating role: $e')),
          );
        }
      }
    }

    void showAddCustomMemberSheet() {
      final nameController = TextEditingController();
      showAppBottomSheet(
        context: context,
        title: 'Add Offline Member',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add someone who doesn\'t use the app. You can manage their contributions manually.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            AppTextField(
              hintText: 'Member name',
              controller: nameController,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: 'Add Member',
                icon: Icon(Icons.person_add_rounded, color: scheme.onPrimary),
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a name')),
                    );
                    return;
                  }
                  try {
                    await ref
                        .read(poolRepositoryProvider)
                        .addCustomMember(poolId: pool.id, name: name);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$name added to the pool')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      );
    }



    return PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Pool Members',
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
              if (isOwnerOrAdmin) ...[
                const SizedBox(width: DesignTokens.spaceSm),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    shape: const CircleBorder(),
                  ),
                  icon: const Icon(Icons.person_add_rounded),
                  onPressed: showAddCustomMemberSheet,
                ),
              ],
            ],
          ),
          Expanded(
            child: membersAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
              error: (e, _) => Center(
                child: Text('Failed to load members: $e'),
              ),
              data: (members) {
                if (members.isEmpty) {
                  return const Center(
                    child: Text('No members in this pool yet.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space2Xl),
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.spaceMd),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return AppSurface(
                      elevation: 0.5,
                      showOutline: true,
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: null,
                        borderRadius: DesignTokens.radiusMd,
                        child: Padding(
                          padding: const EdgeInsets.all(DesignTokens.spaceMd),
                          child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: member.isCustom
                                    ? scheme.tertiaryContainer.withValues(alpha: 0.6)
                                    : scheme.primaryContainer.withValues(alpha: 0.6),
                                backgroundImage: member.avatarUrl.isEmpty
                                    ? null
                                    : NetworkImage(member.avatarUrl),
                                child: member.avatarUrl.isEmpty
                                    ? Text(
                                        member.name.isEmpty
                                            ? '?'
                                            : member.name[0].toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: member.isCustom
                                                  ? scheme.onTertiaryContainer
                                                  : scheme.onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      )
                                    : null,
                              ),
                              if (member.isCustom)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: scheme.tertiary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: scheme.surface,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.cloud_off_rounded,
                                      size: 10,
                                      color: scheme.onTertiary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: DesignTokens.spaceLg),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        member.id == currentUser?.id
                                            ? '${member.name} (You)'
                                            : member.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (member.isCustom) ...[
                                      const SizedBox(width: DesignTokens.spaceSm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: DesignTokens.spaceSm,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: scheme.tertiaryContainer,
                                          borderRadius: DesignTokens.radiusSm,
                                        ),
                                        child: Text(
                                          'Offline',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: scheme.onTertiaryContainer,
                                                fontSize: 10,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (member.email.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    member.email,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: scheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceMd,
                              vertical: DesignTokens.spaceXs,
                            ),
                            decoration: BoxDecoration(
                              color: member.role == PoolRole.owner
                                  ? scheme.primary.withValues(alpha: 0.1)
                                  : member.role == PoolRole.admin
                                      ? scheme.secondary.withValues(alpha: 0.1)
                                      : scheme.surfaceContainerHighest,
                              borderRadius: DesignTokens.radiusMd,
                            ),
                            child: Text(
                              member.role.name.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: member.role == PoolRole.owner
                                        ? scheme.primary
                                        : member.role == PoolRole.admin
                                            ? scheme.secondary
                                            : scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                          if (isOwner && !member.isCustom && member.id != currentUser?.id && member.role != PoolRole.owner) ...[
                            const SizedBox(width: DesignTokens.spaceXs),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded, size: 20),
                              onSelected: (value) {
                                if (value == 'make_admin') {
                                  changeMemberRole(member.id, 'admin');
                                } else if (value == 'remove_admin') {
                                  changeMemberRole(member.id, 'member');
                                }
                              },
                              itemBuilder: (context) => [
                                if (member.role == PoolRole.member)
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Text('Make Admin'),
                                  ),
                                if (member.role == PoolRole.admin)
                                  const PopupMenuItem(
                                    value: 'remove_admin',
                                    child: Text('Remove Admin'),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
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
