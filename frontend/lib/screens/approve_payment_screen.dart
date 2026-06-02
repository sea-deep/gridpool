import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/models/payment_request.dart';
import 'package:frontend/providers/pool_providers.dart';
import 'package:frontend/services/pool_repository.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';

class ApprovePaymentScreen extends ConsumerWidget {
  final Pool pool;

  const ApprovePaymentScreen({super.key, required this.pool});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentRequestsAsync = ref.watch(paymentRequestsProvider(pool.id));

    return PageScaffold(
      title: 'Approve Payments',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Pending Approvals',
            subtitle: 'Review and approve manual payment submissions from pool members.',
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
            child: paymentRequestsAsync.when(
              data: (requests) {
                final pendingRequests = requests.where((r) => r.status == PaymentRequestStatus.pending).toList();
                
                if (pendingRequests.isEmpty) {
                  return const Center(
                    child: Text(
                      'No pending payment requests.',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space3Xl),
                  itemCount: pendingRequests.length,
                  itemBuilder: (context, index) {
                    final req = pendingRequests[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                      child: AppSurface(
                        elevation: 1,
                        padding: const EdgeInsets.all(DesignTokens.spaceSm),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceSm),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(Icons.receipt_long_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
                          ),
                          title: Text(req.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            'Amount: ₹${req.amount.toStringAsFixed(0)}',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            _showReviewDialog(context, ref, pool.id, req);
                          },
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

  void _showReviewDialog(BuildContext context, WidgetRef ref, String poolId, PaymentRequest req) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: const RoundedRectangleBorder(
          borderRadius: DesignTokens.radiusXl,
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Review Payment',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              
              AppSurface(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Member:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        Text(req.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount:', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        Text(
                          '₹${req.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: DesignTokens.spaceLg),
              Text(
                'Screenshot',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              
              if (req.screenshotUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: DesignTokens.radiusMd,
                  child: Image.network(
                    req.screenshotUrl,
                    height: 400,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                )
              else
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: DesignTokens.radiusMd,
                  ),
                  child: Text(
                    'No screenshot provided.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
                
              const SizedBox(height: DesignTokens.space2Xl),
              
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Reject',
                      isPrimary: false,
                      isDestructive: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _rejectPayment(context, ref, poolId, req.id);
                      },
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spaceMd),
                  Expanded(
                    child: AppButton(
                      text: 'Approve',
                      isPrimary: true,
                      onPressed: () {
                        Navigator.pop(ctx);
                        _approvePayment(context, ref, poolId, req.id);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approvePayment(BuildContext context, WidgetRef ref, String poolId, String requestId) async {
    try {
      await ref.read(poolRepositoryProvider).approvePaymentRequest(poolId, requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment approved')));
        ref.invalidate(paymentRequestsProvider(poolId));
        ref.invalidate(poolMembersProvider(poolId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _rejectPayment(BuildContext context, WidgetRef ref, String poolId, String requestId) async {
    try {
      await ref.read(poolRepositoryProvider).rejectPaymentRequest(poolId, requestId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment rejected')));
        ref.invalidate(paymentRequestsProvider(poolId));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
