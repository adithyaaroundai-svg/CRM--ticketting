import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/utils/json_converters.dart';
import '../../../../core/design_system/components/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/customer_notes_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class CustomerNotesSection extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerNotesSection({super.key, required this.customerId});

  @override
  ConsumerState<CustomerNotesSection> createState() =>
      _CustomerNotesSectionState();
}

class _CustomerNotesSectionState extends ConsumerState<CustomerNotesSection> {
  final _noteController = TextEditingController();
  bool _pinNext = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitNote() async {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    setState(() => _isSubmitting = true);

    try {
      final client = Supabase.instance.client;
      await client.from('customer_notes').insert({
        'customer_id': widget.customerId,
        'agent_id': currentUser.id,
        'note': text,
        'is_pinned': _pinNext,
      });

      // Force refresh of notes stream so pinned notes reflect instantly
      ref.invalidate(customerNotesProvider(widget.customerId));

      if (!mounted) return;
      _noteController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note added successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add note: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _togglePinned(String noteId, bool isPinned) async {
    try {
      final client = Supabase.instance.client;
      await client
          .from('customer_notes')
          .update({
            'is_pinned': !isPinned,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', noteId);

      // Ensure any pinned-state changes propagate immediately
      ref.invalidate(customerNotesProvider(widget.customerId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update pin: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(customerNotesProvider(widget.customerId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pinned Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 16),

        // Add Note Form
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add an internal note about this customer...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _pinNext,
                    onChanged: (value) {
                      setState(() {
                        _pinNext = value ?? false;
                      });
                    },
                  ),
                  const Text(
                    'Pin this note',
                    style: TextStyle(fontSize: 12, color: AppColors.slate700),
                  ),
                  const Spacer(),
                  AppButton(
                    label: 'Add Note',
                    icon: LucideIcons.plus,
                    isLoading: _isSubmitting,
                    onPressed: _isSubmitting ? null : _submitNote,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Notes List
        notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.stickyNote,
                      size: 48,
                      color: AppColors.slate300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No notes yet',
                      style: TextStyle(color: AppColors.slate500, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                final isPinned = note['is_pinned'] as bool? ?? false;
                final agentId = note['agent_id'] as String;
                final createdAt = parseUtcDate(note['created_at'] as String);

                final agentAsync = ref.watch(
                  ticketAssignedAgentProvider(agentId),
                );

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.user,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                agentAsync.when(
                                  data: (agentData) => Text(
                                    agentData?['username'] ?? 'Unknown User',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  loading: () => const Text('Loading...'),
                                  error: (_, __) => const Text('Unknown User'),
                                ),
                                Text(
                                  createdAt.toLocal().toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                              size: 16,
                              color: isPinned
                                  ? AppColors.warning
                                  : AppColors.slate400,
                            ),
                            tooltip: isPinned ? 'Unpin' : 'Pin',
                            onPressed: () =>
                                _togglePinned(note['id'] as String, isPinned),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        note['note'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.slate700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Error loading notes: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
