import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/canned_response.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/deal.dart';

part 'productivity_providers.g.dart';

@riverpod
Future<List<CannedResponse>> cannedResponses(Ref ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('canned_responses')
      .select()
      .order('title', ascending: true);

  return (response as List)
      .map((json) => CannedResponse.fromJson(json))
      .toList();
}

@riverpod
class CannedResponseController extends _$CannedResponseController {
  @override
  FutureOr<void> build() {}

  Future<void> addResponse(
    String title,
    String content,
    String category,
  ) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('canned_responses').insert({
        'title': title,
        'content': content,
        'category': category,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });
      if (!ref.mounted) return;
      ref.invalidate(cannedResponsesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }
}

@riverpod
Stream<List<AppNotification>> notifications(Ref ref) {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    return Stream.value([]);
  }

  return client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map(
        (data) => data.map((json) => AppNotification.fromJson(json)).toList(),
      );
}

@riverpod
class NotificationController extends _$NotificationController {
  @override
  FutureOr<void> build() {}

  Future<void> markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      // Handle error silently or log
    }
  }

  Future<void> markAllAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      ref.invalidate(notificationsProvider);
    } catch (e) {
      // Handle error silently or log
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Knowledge Base (Wiki) Providers
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Future<List<Article>> articles(Ref ref) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('articles')
      .select()
      .order('updated_at', ascending: false);

  return (response as List).map((json) => Article.fromJson(json)).toList();
}

@riverpod
Future<Article?> article(Ref ref, String articleId) async {
  final client = Supabase.instance.client;
  final response = await client
      .from('articles')
      .select()
      .eq('id', articleId)
      .maybeSingle();

  if (response == null) return null;
  return Article.fromJson(response);
}

@riverpod
class ArticleController extends _$ArticleController {
  @override
  FutureOr<void> build() {}

  Future<void> createArticle({
    required String title,
    required String content,
    List<String> tags = const [],
    String? createdBy,
  }) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('articles').insert({
        'title': title,
        'content': content,
        'tags': tags,
        'created_by': createdBy,
      });
      if (!ref.mounted) return;
      ref.invalidate(articlesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> updateArticle({
    required String id,
    required String title,
    required String content,
    List<String> tags = const [],
  }) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      await Supabase.instance.client
          .from('articles')
          .update({
            'title': title,
            'content': content,
            'tags': tags,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      if (!ref.mounted) return;
      ref.invalidate(articlesProvider);
      ref.invalidate(articleProvider(id));
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteArticle(String id) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('articles').delete().eq('id', id);
      if (!ref.mounted) return;
      ref.invalidate(articlesProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Deals / Sales Pipeline Providers
// ─────────────────────────────────────────────────────────────────────────────

@riverpod
Stream<List<Deal>> deals(Ref ref) {
  final client = Supabase.instance.client;

  return client
      .from('deals')
      .stream(primaryKey: ['id'])
      .order('updated_at', ascending: false)
      .map((data) => data.map((json) => Deal.fromJson(json)).toList());
}

@riverpod
class DealController extends _$DealController {
  @override
  FutureOr<void> build() {}

  Future<void> createDeal({
    required String customerId,
    required String title,
    String stage = 'new',
    double value = 0,
    String? description,
    String? assignedTo,
    DateTime? expectedCloseDate,
  }) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('deals').insert({
        'customer_id': customerId,
        'title': title,
        'stage': stage,
        'value': value,
        'description': description,
        'assigned_to': assignedTo,
        'expected_close_date': expectedCloseDate
            ?.toIso8601String()
            .split('T')
            .first,
      });
      if (!ref.mounted) return;
      ref.invalidate(dealsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> updateDealStage(String dealId, String newStage) async {
    try {
      await Supabase.instance.client
          .from('deals')
          .update({
            'stage': newStage,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', dealId);
      if (ref.mounted) {
        ref.invalidate(dealsProvider);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> updateDeal({
    required String id,
    required String title,
    required String stage,
    required double value,
    String? description,
    String? assignedTo,
    DateTime? expectedCloseDate,
  }) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      await Supabase.instance.client
          .from('deals')
          .update({
            'title': title,
            'stage': stage,
            'value': value,
            'description': description,
            'assigned_to': assignedTo,
            'expected_close_date': expectedCloseDate
                ?.toIso8601String()
                .split('T')
                .first,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      if (!ref.mounted) return;
      ref.invalidate(dealsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteDeal(String id) async {
    if (!ref.mounted) return;
    state = const AsyncLoading();
    try {
      await Supabase.instance.client.from('deals').delete().eq('id', id);
      if (!ref.mounted) return;
      ref.invalidate(dealsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncError(e, st);
    }
  }
}
