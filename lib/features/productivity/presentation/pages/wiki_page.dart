import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/design_system/layout/main_layout.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/components/app_card.dart';
import '../../../../core/design_system/components/app_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/productivity_providers.dart';
import '../../domain/entities/article.dart';

class WikiPage extends ConsumerStatefulWidget {
  const WikiPage({super.key});

  @override
  ConsumerState<WikiPage> createState() => _WikiPageState();
}

class _WikiPageState extends ConsumerState<WikiPage> {
  String _searchQuery = '';
  Article? _selectedArticle;
  bool _isEditing = false;
  bool _isCreating = false;

  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _startCreating() {
    setState(() {
      _isCreating = true;
      _isEditing = false;
      _selectedArticle = null;
      _titleController.clear();
      _contentController.clear();
      _tagsController.clear();
    });
  }

  void _startEditing(Article article) {
    setState(() {
      _isEditing = true;
      _isCreating = false;
      _selectedArticle = article;
      _titleController.text = article.title;
      _contentController.text = article.content;
      _tagsController.text = article.tags.join(', ');
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _isCreating = false;
      if (_selectedArticle != null) {
        _titleController.text = _selectedArticle!.title;
        _contentController.text = _selectedArticle!.content;
        _tagsController.text = _selectedArticle!.tags.join(', ');
      }
    });
  }

  Future<void> _saveArticle() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final tags = _tagsController.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and content are required')),
      );
      return;
    }

    final currentUser = ref.read(authProvider);

    if (_isCreating) {
      await ref
          .read(articleControllerProvider.notifier)
          .createArticle(
            title: title,
            content: content,
            tags: tags,
            createdBy: currentUser?.id,
          );
    } else if (_isEditing && _selectedArticle != null) {
      await ref
          .read(articleControllerProvider.notifier)
          .updateArticle(
            id: _selectedArticle!.id,
            title: title,
            content: content,
            tags: tags,
          );
    }

    setState(() {
      _isEditing = false;
      _isCreating = false;
      _selectedArticle = null;
    });

    ref.invalidate(articlesProvider);
  }

  Future<void> _deleteArticle(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: const Text('Are you sure you want to delete this article?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(articleControllerProvider.notifier).deleteArticle(id);
      setState(() {
        _selectedArticle = null;
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articlesProvider);
    final currentUser = ref.watch(authProvider);
    final canEdit =
        currentUser?.isAdmin == true || currentUser?.isSupportHead == true;

    return MainLayout(
      currentPath: '/wiki',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            final showDetail = isMobile && (_selectedArticle != null || _isCreating);

            final articleList = SizedBox(
              width: isMobile ? double.infinity : 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Knowledge Base',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                        if (canEdit)
                          IconButton(
                            icon: const Icon(LucideIcons.plus, size: 20),
                            tooltip: 'New Article',
                            onPressed: _startCreating,
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search articles...',
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: articlesAsync.when(
                      data: (articles) {
                        final filtered = articles.where((a) {
                          if (_searchQuery.isEmpty) return true;
                          return a.title.toLowerCase().contains(_searchQuery) ||
                              a.content.toLowerCase().contains(_searchQuery) ||
                              a.tags.any(
                                (t) => t.toLowerCase().contains(_searchQuery),
                              );
                        }).toList();

                        if (filtered.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.fileText,
                                    size: 48,
                                    color: AppColors.slate300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'No articles yet'
                                        : 'No matching articles',
                                    style: const TextStyle(
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final article = filtered[index];
                            final isSelected =
                                _selectedArticle?.id == article.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedArticle = article;
                                    _isEditing = false;
                                    _isCreating = false;
                                    _titleController.text = article.title;
                                    _contentController.text = article.content;
                                    _tagsController.text = article.tags.join(
                                      ', ',
                                    );
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        article.title,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.slate900,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        article.content,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.slate600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (article.tags.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 4,
                                          children: article.tags.take(3).map((
                                            tag,
                                          ) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.slate100,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.slate600,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 6),
                                      Text(
                                        'Updated ${timeago.format(article.updatedAt.toLocal())}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppColors.slate400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(
                        child: Text(
                          'Error: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );

            if (isMobile) {
              return showDetail
                  ? Column(
                      children: [
                        Expanded(child: _buildDetailPane(canEdit)),
                      ],
                    )
                  : articleList;
            }

            return Row(
              children: [
                articleList,
                const VerticalDivider(width: 1),
                Expanded(child: _buildDetailPane(canEdit)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailPane(bool canEdit) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    Widget backButton() => IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: () => setState(() {
            _selectedArticle = null;
            _isCreating = false;
            _isEditing = false;
          }),
          tooltip: 'Back',
        );

    if (_isCreating) {
      return Column(
        children: [
          if (isMobile)
            Align(alignment: Alignment.centerLeft, child: backButton()),
          Expanded(child: _buildEditor(isNew: true, canEdit: canEdit)),
        ],
      );
    }

    if (_selectedArticle == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.bookOpen, size: 64, color: AppColors.slate300),
            const SizedBox(height: 16),
            const Text(
              'Select an article to view',
              style: TextStyle(fontSize: 16, color: AppColors.slate500),
            ),
          ],
        ),
      );
    }

    if (_isEditing) {
      return Column(
        children: [
          if (isMobile)
            Align(alignment: Alignment.centerLeft, child: backButton()),
          Expanded(child: _buildEditor(isNew: false, canEdit: canEdit)),
        ],
      );
    }

    return Column(
      children: [
        if (isMobile)
          Align(alignment: Alignment.centerLeft, child: backButton()),
        Expanded(child: _buildArticleView(canEdit)),
      ],
    );
  }

  Widget _buildArticleView(bool canEdit) {
    final article = _selectedArticle!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  article.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
              ),
              if (canEdit) ...[
                IconButton(
                  icon: const Icon(LucideIcons.pencil, size: 18),
                  tooltip: 'Edit',
                  onPressed: () => _startEditing(article),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  tooltip: 'Delete',
                  color: AppColors.error,
                  onPressed: () => _deleteArticle(article.id),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (article.tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              children: article.tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: AppColors.slate100,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate700,
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Last updated ${timeago.format(article.updatedAt.toLocal())}',
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: article.content,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, height: 1.6),
                  h1: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  h2: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  h3: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  code: TextStyle(
                    backgroundColor: AppColors.slate100,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor({required bool isNew, required bool canEdit}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isNew ? 'New Article' : 'Edit Article',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                ),
              ),
              TextButton(onPressed: _cancelEdit, child: const Text('Cancel')),
              const SizedBox(width: 8),
              AppButton(
                label: isNew ? 'Create' : 'Save',
                icon: LucideIcons.save,
                onPressed: _saveArticle,
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tagsController,
            decoration: InputDecoration(
              labelText: 'Tags (comma separated)',
              hintText: 'e.g. tally, gst, troubleshooting',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(
              labelText: 'Content (Markdown supported)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            maxLines: 20,
            minLines: 10,
          ),
          const SizedBox(height: 16),
          const Text(
            'Preview:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.slate700,
            ),
          ),
          const SizedBox(height: 8),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: MarkdownBody(
                data: _contentController.text.isEmpty
                    ? '*Start typing to see preview...*'
                    : _contentController.text,
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14, height: 1.6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
