import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/custom_channel_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

class CreateChannelDialog extends ConsumerStatefulWidget {
  const CreateChannelDialog({super.key});

  @override
  ConsumerState<CreateChannelDialog> createState() => _CreateChannelDialogState();
}

class _CreateChannelDialogState extends ConsumerState<CreateChannelDialog> {
  final _nameController = TextEditingController();
  bool _isPrivate = false;
  bool _isLoading = false;
  final Set<String> _selectedAgentIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createChannel() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    final currentUser = ref.read(authProvider);
    if (currentUser == null) return;

    // Make sure current user is added to channels by default
    final memberIds = _selectedAgentIds.toList();
    if (!memberIds.contains(currentUser.id)) {
      memberIds.add(currentUser.id);
    }

    final newChannel = await ref.read(customChannelsProvider.notifier).createChannel(
      name: name,
      isPrivate: _isPrivate,
      createdBy: currentUser.id,
      memberIds: memberIds,
    );

    setState(() => _isLoading = false);

    if (newChannel != null && mounted) {
      Navigator.of(context).pop();
      context.go('/c/${newChannel.id}');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create channel.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(agentsListProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Create Channel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Channel Name',
                  hintText: 'e.g. project-updates',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(LucideIcons.hash, size: 18),
                ),
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Make Private'),
                subtitle: const Text('Only invited members can view or join this channel.'),
                value: _isPrivate,
                onChanged: (val) {
                  setState(() => _isPrivate = val);
                },
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),
              const SizedBox(height: 16),

              if (_isPrivate) ...[
                const Text('Invite Members', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Expanded(
                  child: agentsAsync.when(
                    data: (agents) {
                      if (agents.isEmpty) return const Text('No agents found.');
                      return ListView.builder(
                        itemCount: agents.length,
                        itemBuilder: (context, index) {
                          final a = agents[index];
                          final id = a['id'] as String;
                          final name = a['full_name'] ?? a['username'] ?? 'Unknown';
                          final isSelected = _selectedAgentIds.contains(id);
                          
                          // Don't show current user in invite list
                          if (id == ref.read(authProvider)?.id) return const SizedBox.shrink();

                          return CheckboxListTile(
                            title: Text(name),
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedAgentIds.add(id);
                                } else {
                                  _selectedAgentIds.remove(id);
                                }
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Text('Error loading agents'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading ? null : _createChannel,
                  child: _isLoading 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
