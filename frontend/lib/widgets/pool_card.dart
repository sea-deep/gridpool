import 'package:flutter/material.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/models/pool_model.dart';

class PoolCard extends StatelessWidget {
  final Pool pool;
  final VoidCallback? onTap;

  const PoolCard({super.key, required this.pool, this.onTap});

  String get _frequencyLabel {
    switch (pool.frequency) {
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'quarterly':
        return 'Quarterly';
      case 'yearly':
        return 'Yearly';
      case 'custom':
        return pool.customInterval != null ? '${pool.customInterval} days' : 'Custom';
      case 'once':
      default:
        return 'One-time';
    }
  }

  IconData get _frequencyIcon {
    switch (pool.frequency) {
      case 'weekly':
        return Icons.calendar_view_week_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      case 'quarterly':
      case 'yearly':
        return Icons.date_range_rounded;
      case 'custom':
        return Icons.tune_rounded;
      case 'once':
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasPending = pool.pendingAmount > 0;

    return AppSurface(
      onTap: onTap,
      elevation: 0.5,
      hoverElevation: 2,
      showOutline: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Gradient accent strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.tertiary,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Pool icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: DesignTokens.radiusMd,
                      ),
                      child: Icon(
                        Icons.waves_rounded,
                        color: scheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pool.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pool.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceLg),

                // Stats row
                Row(
                  children: [
                    // Balance
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balance',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${pool.currentBalance.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pending (if any)
                    if (hasPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceSm,
                          vertical: DesignTokens.spaceXs,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.warning.withValues(alpha: 0.1),
                          borderRadius: DesignTokens.radiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: DesignTokens.warning,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${pool.pendingAmount.toStringAsFixed(0)} pending',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: DesignTokens.warning,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceMd),

                // Footer chips
                Row(
                  children: [
                    // Members chip
                    _Chip(
                      icon: Icons.people_outline_rounded,
                      label: '${pool.memberCount}',
                      color: scheme.onSecondaryContainer,
                      bgColor: scheme.secondaryContainer,
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    // Frequency chip
                    _Chip(
                      icon: _frequencyIcon,
                      label: _frequencyLabel,
                      color: scheme.onSurfaceVariant,
                      bgColor: scheme.surfaceContainerHighest,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: scheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  const _Chip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: DesignTokens.radiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
