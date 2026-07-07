import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../providers/productivity_providers.dart';

class CannedResponseDialog extends ConsumerStatefulWidget {
  const CannedResponseDialog({super.key});

  @override
  ConsumerState<CannedResponseDialog> createState() =>
      _CannedResponseDialogState();
}

class _CannedResponseDialogState extends ConsumerState<CannedResponseDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsesAsync = ref.watch(cannedResponsesProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isCreating ? 'New Canned Response' : 'Quick Responses',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isCreating)
              _CreateResponseForm(
                onCancel: () => setState(() => _isCreating = false),
                onSuccess: () => setState(() => _isCreating = false),
              )
            else ...[
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search responses...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: responsesAsync.when(
                  data: (responses) {
                    final filtered = responses.where((r) {
                      return r.title.toLowerCase().contains(_searchQuery) ||
                          r.content.toLowerCase().contains(_searchQuery) ||
                          (r.category?.toLowerCase().contains(_searchQuery) ??
                              false);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No responses found'),
                            const SizedBox(height: 8),
                            if (_searchQuery.isNotEmpty)
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Create this response'),
                                onPressed: () =>
                                    setState(() => _isCreating = true),
                              ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final response = filtered[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            response.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            response.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.slate500),
                          ),
                          trailing: response.category != null
                              ? Chip(
                                  label: Text(
                                    response.category!,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                          onTap: () =>
                              Navigator.of(context).pop(response.content),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Response'),
                  onPressed: () => setState(() => _isCreating = true),
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _CreateResponseForm extends ConsumerStatefulWidget {
  final VoidCallback onCancel;
  final VoidCallback onSuccess;

  const _CreateResponseForm({required this.onCancel, required this.onSuccess});

  @override
  ConsumerState<_CreateResponseForm> createState() =>
      _CreateResponseFormState();
}

class _CreateResponseFormState extends ConsumerState<_CreateResponseForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(cannedResponseControllerProvider.notifier)
          .addResponse(
            _titleController.text.trim(),
            _contentController.text.trim(),
            _categoryController.text.trim(),
          );
      widget.onSuccess();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            validator: (val) => val?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category (optional)',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contentController,
            decoration: const InputDecoration(
              labelText: 'Content',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            validator: (val) => val?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 24),
          OverflowBar(
            alignment: MainAxisAlignment.end,
            spacing: 8,
            overflowSpacing: 8,
            children: [
              TextButton(
                onPressed: widget.onCancel,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isSubmitting ? 'Saving...' : 'Save Response'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
