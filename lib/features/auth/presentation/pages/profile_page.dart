import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design_system/design_system.dart';
import '../providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../backup/backup_service.dart';

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
        backgroundColor: AppColors.slate50,
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
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.slate200,
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? const Icon(
                                  LucideIcons.user,
                                  size: 40,
                                  color: AppColors.slate500,
                                )
                              : null,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                    Text(
                      user?.role ?? 'Role',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate500,
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
                    const Divider(height: 32),
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
                  ],
                ),
              ),
              if (isSupport) ...[
                const SizedBox(height: 24),
                const Text(
                  'My Support Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: ticketsAsync.when(
                    data: (tickets) {
                      final currentUser = user;
                      if (currentUser == null) {
                        return const Text(
                          'No agent information available.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate600,
                          ),
                        );
                      }

                      final myTickets = tickets
                          .where((t) => t.assignedTo == currentUser.id)
                          .toList();

                      if (myTickets.isEmpty) {
                        return const Text(
                          'No tickets assigned to you yet. Your support stats will appear here once you start working on tickets.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate600,
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
                          const Text(
                            'Based on the last 30 days of ticket activity.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate600,
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
              if (user?.isAdmin == true) ...[
                const SizedBox(height: 24),
                const Text(
                  'Data & Backup',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 16),
                _BackupCard(),
              ],
              const SizedBox(height: 24),
              const Text(
                'Security',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate900,
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppColors.slate500)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.slate900,
          ),
        ),
      ],
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

      // Resize image to 512x512 while maintaining aspect ratio
      img.Image resizedImage = img.copyResize(
        originalImage,
        width: 512,
        height: 512,
        interpolation: img.Interpolation.linear,
      );

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
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      constraints: const BoxConstraints(minWidth: 140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.slate600),
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
                const Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
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
                      child: const Text('Cancel'),
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
        Text(widget.label, style: const TextStyle(fontSize: 14, color: AppColors.slate500)),
        const SizedBox(width: 16),
        Expanded(
          child: _editing
              ? Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: const TextStyle(fontSize: 14, color: AppColors.slate900),
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
                        icon: const Icon(LucideIcons.check, size: 18, color: AppColors.success),
                        onPressed: _save,
                        tooltip: 'Save',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18, color: AppColors.slate400),
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate900,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.pencil, size: 14, color: AppColors.slate400),
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

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentTeamsUserId ?? '');
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
      if (success) _editing = false;
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
        const Text(
          'Teams User ID',
          style: TextStyle(fontSize: 14, color: AppColors.slate500),
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
                        style: const TextStyle(fontSize: 14, color: AppColors.slate900),
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
                        icon: const Icon(LucideIcons.check, size: 18, color: AppColors.success),
                        onPressed: _save,
                        tooltip: 'Save',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 18, color: AppColors.slate400),
                        onPressed: () {
                          _ctrl.text = widget.currentTeamsUserId ?? '';
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
                        widget.currentTeamsUserId?.isNotEmpty == true
                            ? widget.currentTeamsUserId!
                            : 'Not set',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.currentTeamsUserId?.isNotEmpty == true
                              ? AppColors.slate900
                              : AppColors.slate400,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.pencil, size: 14, color: AppColors.slate400),
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
            const Text(
              'Display Color',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate500,
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
                      ? Border.all(color: AppColors.slate900, width: 3)
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
                    ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
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
                    const Text(
                      'Local Backup',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Exports tickets, customers & chat to a .zip file on your device.',
                      style: TextStyle(fontSize: 12, color: AppColors.slate500),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Last backup row
          Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: AppColors.slate400),
              const SizedBox(width: 6),
              const Text(
                'Last backup: ',
                style: TextStyle(fontSize: 13, color: AppColors.slate500),
              ),
              lastBackupAsync.when(
                data: (dt) => Text(
                  _formatBackupTime(dt),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate700,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                ),
                error: (_, __) => const Text('Unknown',
                    style: TextStyle(fontSize: 13, color: AppColors.slate500)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // What's included note
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.slate200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Includes:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
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
                  : const Icon(LucideIcons.download, size: 16),
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
          Icon(icon, size: 12, color: AppColors.slate400),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.slate600),
          ),
        ],
      ),
    );
  }
}
