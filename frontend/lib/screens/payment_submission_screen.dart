import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:frontend/models/pool_model.dart';
import 'package:frontend/services/upi_service.dart';
import 'package:frontend/services/image_upload_service.dart';
import 'package:frontend/services/pool_repository.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';

class PaymentSubmissionScreen extends ConsumerStatefulWidget {
  final Pool pool;
  final double amountDue;

  const PaymentSubmissionScreen({
    super.key,
    required this.pool,
    required this.amountDue,
  });

  @override
  ConsumerState<PaymentSubmissionScreen> createState() => _PaymentSubmissionScreenState();
}

class _PaymentSubmissionScreenState extends ConsumerState<PaymentSubmissionScreen> {
  File? _screenshotFile;
  bool _isUploading = false;

  Future<void> _pickScreenshot() async {
    final file = await ImageUploadService.pickImageWithSource();
    if (file != null) {
      setState(() {
        _screenshotFile = file;
      });
    }
  }

  Future<void> _submitPayment() async {
    if (_screenshotFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a screenshot of your payment.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final String? screenshotUrl = await ImageUploadService.uploadImage(
        _screenshotFile!,
        folder: 'gridpool_payments',
      );

      if (screenshotUrl == null) {
        throw Exception('Failed to upload screenshot. Please try again.');
      }

      await ref.read(poolRepositoryProvider).submitPaymentRequest(
            poolId: widget.pool.id,
            amount: widget.amountDue,
            screenshotUrl: screenshotUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted! Waiting for admin approval.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upiUrl = UpiService.getUpiUrl(
      upiId: widget.pool.upiId ?? '',
      payeeName: widget.pool.name,
      amount: widget.amountDue,
      transactionNote: 'GridPool: Due Payment',
    );

    return PageScaffold(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Pay Your Due',
              subtitle: 'Scan the QR code below using any UPI app to settle your balance.',
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
            
            // Amount Due Card
            AppSurface(
              elevation: 0,
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                children: [
                  Text(
                    'Amount Due',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  Text(
                    '₹${widget.amountDue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),

            // QR Code Box
            AppSurface(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Text(
                        'Scan to Pay',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: DesignTokens.radiusLg,
                    ),
                    child: QrImageView(
                      data: upiUrl,
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceXl),
                  Text(
                    'Or copy UPI ID directly',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.pool.upiId ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UPI ID copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      label: Text(
                        widget.pool.upiId ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),

            // Screenshot Upload
            AppSurface(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Text(
                        'Upload Payment Screenshot',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  if (_screenshotFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: DesignTokens.radiusMd,
                          child: Image.file(
                            _screenshotFile!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            style: IconButton.styleFrom(backgroundColor: Colors.black54),
                            onPressed: () => setState(() => _screenshotFile = null),
                          ),
                        ),
                      ],
                    )
                  else
                    InkWell(
                      onTap: _pickScreenshot,
                      borderRadius: DesignTokens.radiusMd,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: DesignTokens.radiusMd,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(DesignTokens.spaceMd),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                size: 32,
                                color: Theme.of(context).colorScheme.onSecondaryContainer,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spaceMd),
                            Text(
                              'Tap to upload screenshot',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: DesignTokens.spaceXs),
                            Text(
                              'Supported formats: JPG, PNG',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space2Xl),
            
            // Submit Button
            AppButton(
              onPressed: _submitPayment,
              isLoading: _isUploading,
              text: 'Submit Payment',
              icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
            ),
            const SizedBox(height: DesignTokens.space3Xl),
          ],
        ),
      ),
    );
  }
}
