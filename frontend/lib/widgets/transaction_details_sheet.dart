import 'package:flutter/material.dart';

import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_button.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final String title;
  final double amount;
  final String? dateStr;
  final String typeLabel;
  final String creatorName;
  final String? paymentMethod;
  final String? imageUrl;
  final bool isExpense;
  final bool isPaid;

  const TransactionDetailsSheet({
    super.key,
    required this.title,
    required this.amount,
    required this.dateStr,
    required this.typeLabel,
    required this.creatorName,
    this.paymentMethod,
    this.imageUrl,
    this.isExpense = false,
    this.isPaid = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required double amount,
    required String? dateStr,
    required String typeLabel,
    required String creatorName,
    String? paymentMethod,
    String? imageUrl,
    bool isExpense = false,
    bool isPaid = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionDetailsSheet(
        title: title,
        amount: amount,
        dateStr: dateStr,
        typeLabel: typeLabel,
        creatorName: creatorName,
        paymentMethod: paymentMethod,
        imageUrl: imageUrl,
        isExpense: isExpense,
        isPaid: isPaid,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    
    IconData iconData;
    Color iconColor;
    String prefix;

    if (isExpense) {
      iconData = Icons.money_off_rounded;
      iconColor = scheme.error;
      prefix = '-';
    } else if (isPaid) {
      iconData = Icons.check_circle_outline_rounded;
      iconColor = DesignTokens.success;
      prefix = '+';
    } else {
      iconData = Icons.receipt_long_rounded;
      iconColor = scheme.primary;
      prefix = '';
    }

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(
        top: DesignTokens.spaceMd,
        left: DesignTokens.spaceLg,
        right: DesignTokens.spaceLg,
        bottom: DesignTokens.space2Xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space2Xl),

          // Main Header (Icon + Amount)
          Center(
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 48),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          Text(
            '$prefix₹${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spaceXs),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.spaceXl),

          // Details List
          _buildDetailRow(
            context,
            icon: Icons.label_outline_rounded,
            label: 'Transaction Type',
            value: typeLabel,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
            child: Divider(height: 1),
          ),
          _buildDetailRow(
            context,
            icon: Icons.person_outline_rounded,
            label: 'Initiated By',
            value: creatorName,
          ),
          if (dateStr != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today_rounded,
              label: 'Date & Time',
              value: dateStr!,
            ),
          ],
          if (paymentMethod != null && paymentMethod!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
              child: Divider(height: 1),
            ),
            _buildDetailRow(
              context,
              icon: Icons.payments_outlined,
              label: 'Payment Method',
              value: paymentMethod!.toUpperCase(),
            ),
          ],

          if (imageUrl != null && imageUrl!.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
              child: Divider(height: 1),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              'Attached Proof',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            ClipRRect(
              borderRadius: DesignTokens.radiusMd,
              child: Image.network(
                imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: scheme.surfaceContainerHighest,
                  child: Center(
                    child: Icon(Icons.broken_image_rounded, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: DesignTokens.space2Xl),
          AppButton(
            text: 'Close',
            isPrimary: false,
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(height: DesignTokens.spaceLg),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: DesignTokens.spaceMd),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(width: DesignTokens.spaceMd),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
