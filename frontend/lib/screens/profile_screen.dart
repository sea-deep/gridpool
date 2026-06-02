import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/theme/design_tokens.dart';
import 'package:frontend/widgets/page_header.dart';
import 'package:frontend/widgets/page_scaffold.dart';
import 'package:frontend/widgets/app_surface.dart';
import 'package:frontend/widgets/app_button.dart';
import 'package:frontend/widgets/app_text_field.dart';
import 'package:frontend/providers/auth_controller.dart';
import 'package:frontend/models/auth_models.dart';
import 'package:frontend/services/image_upload_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _notificationPreference = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _lastUserId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFields(User user) {
    _nameController.text = user.name;
    _notificationPreference = user.notificationPreference;
    _lastUserId = user.id;
  }

  Future<void> _handleAvatarUpload() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final url = await ImageUploadService.pickAndUpload(
        source: source,
        folder: 'gridpool/avatars',
      );
      if (url != null && mounted) {
        await ref.read(authControllerProvider.notifier).updateProfile(
              name: _nameController.text.trim(),
              notificationPreference: _notificationPreference,
              avatarUrl: url,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated!'),
              backgroundColor: DesignTokens.success,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload photo')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            name: name,
            notificationPreference: _notificationPreference,
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: DesignTokens.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: DesignTokens.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;
    final scheme = Theme.of(context).colorScheme;

    if (user != null && user.id != _lastUserId) {
      _initFields(user);
    }

    return PageScaffold(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const PageHeader(
              title: 'Profile Settings',
              subtitle: 'Customize your identity and preferences',
            ),
            if (user != null) ...[
              // Premium Profile Card
              AppSurface(
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _isUploadingAvatar ? null : _handleAvatarUpload,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundColor: scheme.primaryContainer,
                              backgroundImage: NetworkImage(user.avatarUrl),
                            ),
                            if (_isUploadingAvatar)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black38,
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: scheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: scheme.surface, width: 2),
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: scheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLg),
              
              // Edit Details Form
              AppSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Account Settings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    AppTextField(
                      controller: _nameController,
                      hintText: 'Display Name',
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spaceLg),
                    const Divider(height: 1),
                    const SizedBox(height: DesignTokens.spaceLg),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(DesignTokens.spaceSm),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: DesignTokens.radiusMd,
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            color: scheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.spaceLg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dues & Reminders',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: scheme.onSurface,
                                    ),
                              ),
                              Text(
                                'Get notified when new ledger events occur',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Switch.adaptive(
                          value: _notificationPreference,
                          onChanged: (val) {
                            setState(() {
                              _notificationPreference = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space2Xl),
                    AppButton(
                      text: _isSaving ? 'Saving...' : 'Save Settings',
                      isLoading: _isSaving,
                      icon: _isSaving ? null : Icon(Icons.check_rounded, color: scheme.onPrimary),
                      onPressed: _isSaving ? null : _handleSave,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.space2Xl),
              
              // Logout Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Log Out',
                    isPrimary: false,
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceLg),

              // App version info
              Text(
                'GridPool v1.0.0',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DesignTokens.space3Xl),
            ],
          ],
        ),
      ),
    );
  }
}
