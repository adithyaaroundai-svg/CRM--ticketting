import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../providers/productivity_providers.dart';

/// Dialog for searching and selecting an article to insert as a link
class ArticleSearchDialog extends ConsumerStatefulWidget {
  const ArticleSearchDialog({super.key});

  @override
  ConsumerState<ArticleSearchDialog> createState() =>
      _ArticleSearchDialogState();
}

class _ArticleSearchDialogState extends ConsumerState<ArticleSearchDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articlesProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Insert KB Article Link',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                autofocus: true,
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
              const SizedBox(height: 16),
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
                                  ? 'No articles in knowledge base'
                                  : 'No matching articles',
                              style: const TextStyle(color: AppColors.slate500),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final article = filtered[index];
                        return ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              LucideIcons.fileText,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            article.title,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: article.tags.isNotEmpty
                              ? Wrap(
                                  spacing: 4,
                                  children: article.tags.take(3).map((tag) {
                                    return Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.slate100,
                                        borderRadius: BorderRadius.circular(4),
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
                                )
                              : null,
                          onTap: () {
                            // Return markdown link format
                            final link = '[📘 ${article.title}]';
                            Navigator.pop(context, link);
                          },
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
        ),
      ),
    );
  }
}
