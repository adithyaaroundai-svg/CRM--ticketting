import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../backup/backup_service.dart';
import '../../../tickets/presentation/providers/table_font_size_provider.dart';
import '../../../../core/design_system/theme/theme_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final isSupport = user?.isSupport == true;

    return MainLayout(
      currentPath: '/profile',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(title: 'My Profile'),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: user?.avatarUrl != null
                              ? () => _showAvatarPreview(context, user!.avatarUrl!)
                              : null,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: user?.avatarUrl != null
                                ? Image.network(
                                    user!.avatarUrl!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: context.adaptiveSlate200,
                                        child: Icon(
                                          LucideIcons.user,
                                          size: 40,
                                          color: context.adaptiveSlate500,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: context.adaptiveSlate200,
                                    child: Icon(
                                      LucideIcons.user,
                                      size: 40,
                                      color: context.adaptiveSlate500,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: () => _pickAndUploadImage(context, ref),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  LucideIcons.camera,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.fullName ?? 'User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.adaptiveSlate900,
                      ),
                    ),
                    Text(
                      user?.role ?? 'Role',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.adaptiveSlate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _FieldEditor(
                      label: 'Username',
                      currentValue: user?.username ?? '',
                      hint: 'Enter username',
                      onSave: (v) => ref.read(authProvider.notifier).updateUsername(v),
                      successMsg: 'Username updated',
                      errorMsg: 'Failed to update username',
                    ),
                    Divider(height: 32),
                    _FieldEditor(
                      label: 'Full name',
                      currentValue: user?.fullName ?? '',
                      hint: 'Enter full name',
                      onSave: (v) => ref.read(authProvider.notifier).updateFullName(v),
                      successMsg: 'Full name updated',
                      errorMsg: 'Failed to update full name',
                    ),
                    const Divider(height: 32),
                    _TeamsUserIdEditor(currentTeamsUserId: user?.teamsUserId),
                    const Divider(height: 32),
                    _ColorSelector(currentHex: user?.displayColor),
                    const Divider(height: 32),
                    const _ThemeSelector(),
                  ],
                ),
              ),
              if (isSupport) ...[
                const SizedBox(height: 24),
                Text(
                  'My Support Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.adaptiveSlate900,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: ticketsAsync.when(
                    data: (tickets) {
                      final currentUser = user;
                      if (currentUser == null) {
                        return Text(
                          'No agent information available.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.adaptiveSlate600,
                          ),
                        );
                      }

                      final myTickets = tickets
                          .where((t) => t.assignedTo == currentUser.id)
                          .toList();

                      if (myTickets.isEmpty) {
                        return Text(
                          'No tickets assigned to you yet. Your support stats will appear here once you start working on tickets.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.adaptiveSlate600,
                          ),
                        );
                      }

                      final now = DateTime.now();
                      final lookbackStart = now.subtract(
                        const Duration(days: 30),
                      );
                      final resolvedStatuses = <String>[
                        'Resolved',
                        'Closed',
                        'BillProcessed',
                      ];

                      final myResolvedLast30d = myTickets.where((t) {
                        if (!resolvedStatuses.contains(t.status)) return false;
                        final updatedAt = t.updatedAt;
                        if (updatedAt == null) return false;
                        return updatedAt.isAfter(lookbackStart);
                      }).toList();

                      final myActive = myTickets
                          .where((t) => !resolvedStatuses.contains(t.status))
                          .length;

                      Duration totalResolution = Duration.zero;
                      for (final t in myResolvedLast30d) {
                        final updatedAt = t.updatedAt;
                        final createdAt = t.createdAt;
                        if (updatedAt != null && createdAt != null) {
                          totalResolution += updatedAt.difference(createdAt);
                        }
                      }

                      double? avgResolutionHours;
                      if (myResolvedLast30d.isNotEmpty) {
                        avgResolutionHours =
                            totalResolution.inMinutes /
                            myResolvedLast30d.length /
                            60.0;
                      }

                      String avgResolutionLabel;
                      if (avgResolutionHours == null) {
                        avgResolutionLabel = '—';
                      } else if (avgResolutionHours >= 48) {
                        final days = avgResolutionHours / 24.0;
                        avgResolutionLabel = '${days.toStringAsFixed(1)} d';
                      } else {
                        avgResolutionLabel =
                            '${avgResolutionHours.toStringAsFixed(1)} h';
                      }

                      bool isResolvedStatus(String status) =>
                          resolvedStatuses.contains(status);

                      final mySlaWarnings = myTickets.where((t) {
                        if (isResolvedStatus(t.status)) return false;
                        final slaDue = t.slaDue;
                        if (slaDue == null) return false;
                        final remainingMinutes = slaDue
                            .difference(now)
                            .inMinutes;
                        return remainingMinutes <= 60;
                      }).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Based on the last 30 days of ticket activity.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.adaptiveSlate600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _SupportProfileStat(
                                label: 'Assigned to me (all time)',
                                value: myTickets.length.toString(),
                              ),
                              _SupportProfileStat(
                                label: 'Active now',
                                value: myActive.toString(),
                              ),
                              _SupportProfileStat(
                                label: 'Resolved (last 30d)',
                                value: myResolvedLast30d.length.toString(),
                              ),
                              _SupportProfileStat(
                                label: 'Avg resolution time',
                                value: avgResolutionLabel,
                              ),
                              _SupportProfileStat(
                                label: 'Response time warnings',
                                value: mySlaWarnings.toString(),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (err, _) => Text(
                      'Error loading support metrics: $err',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
              if (user?.isAdmin == true) ...[
                const SizedBox(height: 24),
                Text(
                  'Data & Backup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.adaptiveSlate900,
                  ),
                ),
                const SizedBox(height: 16),
                _BackupCard(),
              ],
              const SizedBox(height: 24),
              Text(
                'Display Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.adaptiveSlate900,
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ticket Table Font Size',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.adaptiveSlate800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('A', style: TextStyle(fontSize: 12, color: context.adaptiveSlate500)),
                        Expanded(
                          child: Slider(
                            value: ref.watch(tableFontSizeProvider),
                            min: 0.8,
                            max: 1.5,
                            divisions: 7,
                            label: '${(ref.watch(tableFontSizeProvider) * 100).toInt()}%',
                            activeColor: context.isDarkMode ? Colors.white : AppColors.primary,
                            inactiveColor: context.isDarkMode ? Colors.white.withValues(alpha: 0.2) : context.adaptiveSlate200,
                            onChanged: (val) {
                               ref.read(tableFontSizeProvider.notifier).setScale(val);
                            },
                          ),
                        ),
                        Text('A', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.adaptiveSlate500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.adaptiveSlate900,
                ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.secondary(
                        label: 'Change Password',
                        icon: LucideIcons.lock,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => const _ChangePasswordDialog(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        label: 'Logout',
                        icon: LucideIcons.logOut,
                        variant: AppButtonVariant.destructive,
                        onPressed: () =>
                            ref.read(authProvider.notifier).logout(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAvatarPreview(BuildContext context, String avatarUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Center(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 300,
                        height: 300,
                        color: context.adaptiveSlate200,
                        child: Icon(
                          LucideIcons.imageOff,
                          size: 48,
                          color: context.adaptiveSlate500,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Processing and uploading image...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Read the original image bytes
      final fileBytes = await image.readAsBytes();
      
      // Decode the image
      img.Image? originalImage = img.decodeImage(fileBytes);
      if (originalImage == null) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to process image'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Resize image to max 512px while preserving aspect ratio
      final maxDimension = 512;
      final aspectRatio = originalImage.width / originalImage.height;
      img.Image resizedImage;
      
      if (originalImage.width > originalImage.height) {
        // Landscape: resize width to 512, calculate height
        final newWidth = maxDimension;
        final newHeight = (maxDimension / aspectRatio).round();
        resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      } else {
        // Portrait: resize height to 512, calculate width
        final newHeight = maxDimension;
        final newWidth = (maxDimension * aspectRatio).round();
        resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with 85% quality
      final resizedBytes = img.encodeJpg(resizedImage, quality: 85);

      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final storage = Supabase.instance.client.storage;
      
      // Upload the resized image
      try {
        await storage.from('avatars').uploadBinary(
          fileName,
          resizedBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
      } catch (uploadError) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text('Upload failed: $uploadError'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final publicUrl = storage.from('avatars').getPublicUrl(fileName);

      final success = await ref.read(authProvider.notifier).updateAvatarUrl(publicUrl);

      if (!context.mounted) return;

      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile picture'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _SupportProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _SupportProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.adaptiveSlate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.adaptiveBorder),
      ),
      constraints: const BoxConstraints(minWidth: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.adaptiveSlate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.adaptiveSlate600),
          ),
        ],
      ),
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider);
    if (user == null) {
      Navigator.of(context).pop();
      return;
    }

    final currentPassword = _currentController.text.trim();
    final newPassword = _newController.text.trim();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;
      final response = await client.rpc(
        'change_agent_password',
        params: {
          'p_agent_id': user.id,
          'p_current_password': currentPassword,
          'p_new_password': newPassword,
        },
      );

      if (!mounted) return;

      final success = response is Map && (response['success'] == true);
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        final message = (response is Map && response['message'] is String)
            ? response['message'] as String
            : 'Failed to change password. Please check your current password.';
        messenger.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error changing password: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.adaptiveSlate900,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _currentController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password should be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    AppButton(
                      label: _isSubmitting ? 'Saving...' : 'Update Password',
                      icon: LucideIcons.check,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldEditor extends StatefulWidget {
  final String label;
  final String currentValue;
  final String hint;
  final Future<bool> Function(String) onSave;
  final String successMsg;
  final String errorMsg;

  const _FieldEditor({
    required this.label,
    required this.currentValue,
    required this.hint,
    required this.onSave,
    required this.successMsg,
    required this.errorMsg,
  });

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  late final TextEditingController _ctrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    if (value.isEmpty) return;
    setState(() => _saving = true);
    final success = await widget.onSave(value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) _editing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? widget.successMsg : widget.errorMsg),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.label, style: TextStyle(fontSize: 14, color: context.adaptiveSlate500)),
        const SizedBox(width: 16),
        Expanded(
          child: _editing
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: TextStyle(fontSize: 14, color: context.adaptiveSlate900),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: const OutlineInputBorder(),
                          hintText: widget.hint,
                        ),
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_saving)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else ...[
                      IconButton(
                        icon: Icon(LucideIcons.check, size: 18, color: AppColors.success),
                        onPressed: _save,
                        tooltip: 'Save',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: context.adaptiveSlate400),
                        onPressed: () {
                          _ctrl.text = widget.currentValue;
                          setState(() => _editing = false);
                        },
                        tooltip: 'Cancel',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        widget.currentValue.isNotEmpty ? widget.currentValue : '-',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.adaptiveSlate900,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(LucideIcons.pencil, size: 14, color: context.adaptiveSlate400),
                      onPressed: () => setState(() => _editing = true),
                      tooltip: 'Edit ${widget.label}',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _TeamsUserIdEditor extends ConsumerStatefulWidget {
  final String? currentTeamsUserId;
  const _TeamsUserIdEditor({this.currentTeamsUserId});

  @override
  ConsumerState<_TeamsUserIdEditor> createState() => _TeamsUserIdEditorState();
}

class _TeamsUserIdEditorState extends ConsumerState<_TeamsUserIdEditor> {
  late final TextEditingController _ctrl;
  bool _editing = false;
  bool _saving = false;
  late String _displayValue;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.currentTeamsUserId ?? '';
    _ctrl = TextEditingController(text: _displayValue);
  }

  @override
  void didUpdateWidget(_TeamsUserIdEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTeamsUserId != widget.currentTeamsUserId) {
      _displayValue = widget.currentTeamsUserId ?? '';
      if (!_editing) {
        _ctrl.text = _displayValue;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Teams User ID'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final success = await ref.read(authProvider.notifier).updateTeamsUserId(value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) {
        _editing = false;
        _displayValue = value;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Teams User ID updated' : 'Failed to update Teams User ID'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Teams User ID',
          style: TextStyle(fontSize: 14, color: context.adaptiveSlate500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _editing
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: TextStyle(fontSize: 14, color: context.adaptiveSlate900),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                          hintText: 'e.g. user@org.onmicrosoft.com',
                        ),
                        onSubmitted: (_) => _save(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_saving)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    else ...[
                      IconButton(
                        icon: Icon(LucideIcons.check, size: 18, color: AppColors.success),
                        onPressed: _save,
                        tooltip: 'Save',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(LucideIcons.x, size: 18, color: context.adaptiveSlate400),
                        onPressed: () {
                          _ctrl.text = _displayValue;
                          setState(() => _editing = false);
                        },
                        tooltip: 'Cancel',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _displayValue.isNotEmpty ? _displayValue : 'Not set',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _displayValue.isNotEmpty
                              ? context.adaptiveSlate900
                              : context.adaptiveSlate400,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(LucideIcons.pencil, size: 14, color: context.adaptiveSlate400),
                      onPressed: () => setState(() => _editing = true),
                      tooltip: 'Edit Teams User ID',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ColorSelector extends ConsumerStatefulWidget {
  final String? currentHex;
  const _ColorSelector({this.currentHex});

  @override
  ConsumerState<_ColorSelector> createState() => _ColorSelectorState();
}

class _ColorSelectorState extends ConsumerState<_ColorSelector> {
  static const _colors = [
    '#3B82F6', // Blue
    '#10B981', // Green
    '#F59E0B', // Emerald
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#F97316', // Orange
    '#6366F1', // Violet
  ];

  bool _isSaving = false;

  void _onColorSelected(String hex) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    
    final success = await ref.read(authProvider.notifier).updateDisplayColor(hex);
    
    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Display color updated'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update display color'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Display Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.adaptiveSlate500,
              ),
            ),
            if (_isSaving)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((hex) {
            final isSelected = widget.currentHex?.toLowerCase() == hex.toLowerCase();
            final color = _hexToColor(hex);

            return InkWell(
              onTap: () => _onColorSelected(hex),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: context.adaptiveSlate900, width: 3)
                      : null,
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: isSelected
                    ? Icon(LucideIcons.check, color: Colors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Backup Card ────────────────────────────────────────────────────────────────

class _BackupCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  bool _isRunning = false;
  String? _lastResultMessage;
  bool _lastWasSuccess = false;

  String _formatBackupTime(DateTime? dt) {
    if (dt == null) return 'Never';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago  (${DateFormat('hh:mm a').format(dt)})';
    return DateFormat('MMM d, yyyy  hh:mm a').format(dt);
  }

  Future<void> _runBackup() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() {
      _isRunning = true;
      _lastResultMessage = null;
    });

    final result = await createLocalBackup(
      agentId: user.id,
      agentName: user.fullName,
      agentRole: user.role,
    );

    // Refresh the last-backup-time provider
    ref.invalidate(lastBackupTimeProvider);

    if (!mounted) return;

    setState(() {
      _isRunning = false;
      _lastWasSuccess = result.success;
      if (result.success) {
        _lastResultMessage = 'Saved to:\n${result.filePath}';
      } else {
        _lastResultMessage = 'Error: ${result.error}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastBackupAsync = ref.watch(lastBackupTimeProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.hardDrive,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local Backup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.adaptiveSlate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Exports tickets, customers & chat to a .zip file on your device.',
                      style: TextStyle(fontSize: 12, color: context.adaptiveSlate500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(height: 1),
          const SizedBox(height: 14),

          // Last backup row
          Row(
            children: [
              Icon(LucideIcons.clock, size: 14, color: context.adaptiveSlate400),
              const SizedBox(width: 6),
              Text(
                'Last backup: ',
                style: TextStyle(fontSize: 13, color: context.adaptiveSlate500),
              ),
              lastBackupAsync.when(
                data: (dt) => Text(
                  _formatBackupTime(dt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.adaptiveSlate700,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                error: (_, __) => Text('Unknown',
                    style: TextStyle(fontSize: 13, color: context.adaptiveSlate500)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // What's included note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.adaptiveSlate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.adaptiveSlate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Includes:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.adaptiveSlate600,
                  ),
                ),
                const SizedBox(height: 4),
                _includeRow(LucideIcons.ticket, 'All tickets & comments'),
                _includeRow(LucideIcons.users, 'All customers'),
                _includeRow(LucideIcons.messageSquare, 'Chat messages (global + DMs)'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Result message
          if (_lastResultMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _lastWasSuccess
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _lastWasSuccess
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _lastWasSuccess ? LucideIcons.checkCircle : LucideIcons.alertCircle,
                    size: 16,
                    color: _lastWasSuccess ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastResultMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _lastWasSuccess ? AppColors.success : AppColors.error,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isRunning ? null : _runBackup,
              icon: _isRunning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(LucideIcons.download, size: 16),
              label: Text(_isRunning ? 'Creating backup...' : 'Create Local Backup'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _includeRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: context.adaptiveSlate400),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: context.adaptiveSlate600),
          ),
        ],
      ),
    );
  }
}

class _ThemeSelector extends ConsumerWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.palette,
              size: 20,
              color: context.adaptiveSlate500,
            ),
            const SizedBox(width: 8),
            Text(
              'App Theme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.adaptiveSlate900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildThemeOption(
              context: context,
              title: 'White (Light)',
              type: AppThemeType.white,
              currentTheme: currentTheme,
              onSelect: () => ref.read(themeProvider.notifier).setTheme(AppThemeType.white),
            ),
            _buildThemeOption(
              context: context,
              title: 'Blue Gradient (Dark)',
              type: AppThemeType.blueGradient,
              currentTheme: currentTheme,
              onSelect: () => ref.read(themeProvider.notifier).setTheme(AppThemeType.blueGradient),
            ),
            _buildThemeOption(
              context: context,
              title: 'Pink (Dark)',
              type: AppThemeType.pink,
              currentTheme: currentTheme,
              onSelect: () => ref.read(themeProvider.notifier).setTheme(AppThemeType.pink),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required AppThemeType type,
    required AppThemeType currentTheme,
    required VoidCallback onSelect,
  }) {
    final isSelected = type == currentTheme;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : context.adaptiveSlate200,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? LucideIcons.checkCircle2 : LucideIcons.circle,
              size: 20,
              color: isSelected ? Colors.white : context.adaptiveSlate400,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : context.adaptiveSlate700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
