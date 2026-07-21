import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';

part 'chat_provider.g.dart';

// ── Chat stream — keepAlive so it never resets on navigation ─────────────────
@Riverpod(keepAlive: true)
class ChatStream extends _$ChatStream {
  RealtimeChannel? _channelSub;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  
  @override
  FutureOr<List<ChatMessage>> build(String channel) async {
    final repository = ref.watch(chatRepositoryProvider);
    final messages = await repository.getPaginatedMessages(channelName: channel, limit: 30);
    _hasMore = messages.length == 30;
    
    _channelSub = repository.subscribeToMessages(
      channelName: channel,
      onEvent: _handlePostgresEvent,
    );
    
    ref.onDispose(() {
      _channelSub?.unsubscribe();
    });
    
    return messages;
  }

  void _handlePostgresEvent(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert) {
      final newMsg = ChatMessage.fromJson(payload.newRecord);
      if (newMsg.channel != channel || newMsg.receiverId != null) return;
      final currentList = state.value ?? [];
      // Make sure we don't add duplicates (sometimes realtime events and manual inserts race)
      if (!currentList.any((m) => m.id == newMsg.id)) {
        state = AsyncData([...currentList, newMsg]);
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final updatedMsg = ChatMessage.fromJson(payload.newRecord);
      if (updatedMsg.channel != channel || updatedMsg.receiverId != null) return;
      final currentList = state.value ?? [];
      final index = currentList.indexWhere((m) => m.id == updatedMsg.id);
      if (index != -1) {
        final newList = List<ChatMessage>.from(currentList);
        newList[index] = updatedMsg;
        state = AsyncData(newList);
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final deletedId = payload.oldRecord['id'] as String?;
      if (deletedId != null) {
        final currentList = state.value ?? [];
        if (currentList.any((m) => m.id == deletedId)) {
          state = AsyncData(currentList.where((m) => m.id != deletedId).toList());
        }
      }
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final currentList = state.value ?? [];
    if (currentList.isEmpty) return;

    final oldestMsg = currentList.first;
    final repository = ref.read(chatRepositoryProvider);
    final olderMessages = await repository.getPaginatedMessages(
      channelName: channel,
      before: oldestMsg.createdAt,
      limit: 30,
    );

    if (olderMessages.length < 30) {
      _hasMore = false;
    }
    
    state = AsyncData([...olderMessages, ...currentList]);
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

// ── DM Chat stream — keepAlive so it never resets on navigation ──────────────
@Riverpod(keepAlive: true)
class DmStream extends _$DmStream {
  RealtimeChannel? _channelSub;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  
  @override
  FutureOr<List<ChatMessage>> build(String chatPartnerId) async {
    final repository = ref.watch(chatRepositoryProvider);
    final myId = ref.watch(authProvider)?.id;
    
    final messages = await repository.getPaginatedMessages(
      currentUserId: myId,
      chatPartnerId: chatPartnerId,
      limit: 30,
    );
    _hasMore = messages.length == 30;
    
    _channelSub = repository.subscribeToMessages(
      channelName: 'dm',
      currentUserId: myId,
      chatPartnerId: chatPartnerId,
      onEvent: _handlePostgresEvent,
    );
    
    ref.onDispose(() {
      _channelSub?.unsubscribe();
    });
    
    return messages;
  }

  void _handlePostgresEvent(PostgresChangePayload payload) {
    final myId = ref.read(authProvider)?.id;
    if (myId == null) return;

    if (payload.eventType == PostgresChangeEvent.insert) {
      final newMsg = ChatMessage.fromJson(payload.newRecord);
      final isRelevant = (newMsg.senderId == myId && newMsg.receiverId == chatPartnerId) ||
                         (newMsg.senderId == chatPartnerId && newMsg.receiverId == myId);
      if (!isRelevant) return;
      final currentList = state.value ?? [];
      if (!currentList.any((m) => m.id == newMsg.id)) {
        state = AsyncData([...currentList, newMsg]);
      }
    } else if (payload.eventType == PostgresChangeEvent.update) {
      final updatedMsg = ChatMessage.fromJson(payload.newRecord);
      final isRelevant = (updatedMsg.senderId == myId && updatedMsg.receiverId == chatPartnerId) ||
                         (updatedMsg.senderId == chatPartnerId && updatedMsg.receiverId == myId);
      if (!isRelevant) return;
      final currentList = state.value ?? [];
      final index = currentList.indexWhere((m) => m.id == updatedMsg.id);
      if (index != -1) {
        final newList = List<ChatMessage>.from(currentList);
        newList[index] = updatedMsg;
        state = AsyncData(newList);
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final deletedId = payload.oldRecord['id'] as String?;
      if (deletedId != null) {
        final currentList = state.value ?? [];
        if (currentList.any((m) => m.id == deletedId)) {
          state = AsyncData(currentList.where((m) => m.id != deletedId).toList());
        }
      }
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final currentList = state.value ?? [];
    if (currentList.isEmpty) return;

    final oldestMsg = currentList.first;
    final repository = ref.read(chatRepositoryProvider);
    final myId = ref.read(authProvider)?.id;
    
    final olderMessages = await repository.getPaginatedMessages(
      currentUserId: myId,
      chatPartnerId: chatPartnerId,
      before: oldestMsg.createdAt,
      limit: 30,
    );

    if (olderMessages.length < 30) {
      _hasMore = false;
    }
    
    state = AsyncData([...olderMessages, ...currentList]);
  }

  void refresh() {
    ref.invalidateSelf();
  }
}

// ── Last-seen timestamp per user, persisted in SharedPreferences ─────────────
@Riverpod(keepAlive: true)
class ChatLastSeen extends _$ChatLastSeen {
  static const _lastViewedKey = 'chat_last_viewed_at';

  @override
  Future<DateTime> build() async {
    final myId = ref.watch(authProvider)?.id;
    if (myId == null) return DateTime.now().toUtc();

    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastViewedKey}_$myId';
    final lastViewedStr = prefs.getString(key);

    if (lastViewedStr != null) {
      return DateTime.parse(lastViewedStr).toUtc();
    }

    // First login — treat everything currently in the DB as already read
    // by setting lastSeen to the latest message timestamp (or now if no
    // messages). This prevents the badge and toasts from firing for all
    // historical messages on first login.
    final messages = ref.read(chatStreamProvider('support-chat')).asData?.value;
    final DateTime baseline;
    if (messages != null && messages.isNotEmpty) {
      baseline = messages.last.createdAt.toUtc().add(
        const Duration(milliseconds: 500),
      );
    } else {
      baseline = DateTime.now().toUtc();
    }
    await prefs.setString(key, baseline.toIso8601String());
    return baseline;
  }

  Future<void> updateLastSeen(DateTime timestamp, {String? userId}) async {
    final activeUserId = ref.read(authProvider)?.id;
    final targetUserId = userId ?? activeUserId;
    if (targetUserId == null) return;

    final next = timestamp.toUtc();

    // Update in-memory state for the active user (only move forward)
    if (targetUserId == activeUserId) {
      final current =
          state.value ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      if (next.isAfter(current)) {
        state = AsyncData(next);
      }
    }

    // Persist — only write if newer than what's stored
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_lastViewedKey}_$targetUserId';
      final existing = prefs.getString(key);
      if (existing == null || next.isAfter(DateTime.parse(existing).toUtc())) {
        await prefs.setString(key, next.toIso8601String());
      }
    } catch (_) {}
  }
}

// ── Unread count — keepAlive so badge stays correct across navigation ─────────
@Riverpod(keepAlive: true)
class ChatUnreadCount extends _$ChatUnreadCount {
  @override
  int build() {
    final myId = ref.watch(authProvider)?.id;
    if (myId == null) return 0;

    final messagesAsync = ref.watch(chatStreamProvider('support-chat'));
    final lastSeenAsync = ref.watch(chatLastSeenProvider);

    // Set up callback to invalidate when tracker changes
    ReadReceiptsTracker.setOnChangeCallback(() {
      ref.invalidateSelf();
    });

    // Don't calculate unread count until lastSeen has loaded.
    // Otherwise every message appears unread on app restart.
    if (lastSeenAsync.isLoading) return 0;

    return messagesAsync.maybeWhen(
      data: (messages) {
        if (messages.isEmpty) return 0;
        final normalizedMyId = myId.toString().trim().toLowerCase();
        final lastSeen = lastSeenAsync.value;

        final unreadCount = messages.where((m) {
          if (m.senderId.trim().toLowerCase() == normalizedMyId) return false;

          // Primary: messages older than or equal to lastSeen are read
          if (lastSeen != null && !m.createdAt.toUtc().isAfter(lastSeen)) {
            return false;
          }

          // Secondary: explicit per-message read receipt
          final readBy = ReadReceiptsTracker.getReadBy(m.id);
          if (readBy.contains(normalizedMyId)) return false;

          return true;
        }).length;

        return unreadCount;
      },
      orElse: () => 0,
    );
  }

  /// Call this when the user opens the chat page.
  Future<void> markAsRead({DateTime? timestamp}) async {
    final myId = ref.read(authProvider)?.id;
    if (myId == null) return;

    DateTime effectiveTimestamp;

    if (timestamp != null) {
      effectiveTimestamp = timestamp;
    } else {
      final messages = ref.read(chatStreamProvider('support-chat')).asData?.value;
      if (messages != null && messages.isNotEmpty) {
        effectiveTimestamp = messages.last.createdAt;
      } else {
        effectiveTimestamp = DateTime.now().toUtc();
      }
    }

    // Add a small buffer so messages at the exact same millisecond are covered
    final safeTimestamp = effectiveTimestamp.toUtc().add(
      const Duration(milliseconds: 500),
    );

    await ref
        .read(chatLastSeenProvider.notifier)
        .updateLastSeen(safeTimestamp, userId: myId);

    // Also update in ReadReceiptsTracker for per-user tracking
    await ReadReceiptsTracker.updateUserLastSeen(myId, safeTimestamp);

    // Mark all visible messages as read in the read receipts tracker
    final messages = ref.read(chatStreamProvider('support-chat')).asData?.value ?? [];
    for (final message in messages) {
      if (message.senderId != myId) {
        // Only mark messages from others as read
        await ReadReceiptsTracker.markAsRead(message.id, myId);
      }
    }
  }
}

// ── New-message event for toast notifications ─────────────────────────────────
@Riverpod(keepAlive: true)
class ChatNewMessageEvent extends _$ChatNewMessageEvent {
  // Track IDs we've already notified so re-registering listeners never
  // re-fires for the same message (happens on every navigation rebuild or
  // provider re-creation within the same session).
  static final Set<String> _notifiedIds = {};

  @override
  ChatMessage? build() => null;

  /// Only fires if this message hasn't been notified before in this session
  /// AND the message is newer than the user's last-seen timestamp.
  void notify(ChatMessage message) {
    if (_notifiedIds.contains(message.id)) return;

    // Extra guard: never toast a message the user has already "seen"
    // (i.e. it was present before they logged in this session).
    final lastSeenAsync = ref.read(chatLastSeenProvider);
    final lastSeen = lastSeenAsync.value;
    if (lastSeen != null && !message.createdAt.toUtc().isAfter(lastSeen)) {
      // Message is older than or equal to lastSeen — mark as notified so
      // we never try again, but don't show a toast.
      _notifiedIds.add(message.id);
      return;
    }

    _notifiedIds.add(message.id);
    state = message;
  }

  void clear() => state = null;

  /// Call on logout to reset the notified-IDs set for the next user.
  static void resetSession() => _notifiedIds.clear();
}

// ════════════════════════════════════════════════════════════════════════════
// All-AroundTally channel — read state & notifications (mirrors support chat)
// ════════════════════════════════════════════════════════════════════════════
const String kAllAroundTallyChannel = 'all-aroundtally';

// ── Last-seen timestamp for all-aroundtally, persisted in SharedPreferences ──
@Riverpod(keepAlive: true)
class AllAroundTallyLastSeen extends _$AllAroundTallyLastSeen {
  static const _lastViewedKey = 'aroundtally_last_viewed_at';

  @override
  Future<DateTime> build() async {
    final myId = ref.watch(authProvider)?.id;
    if (myId == null) return DateTime.now().toUtc();

    final prefs = await SharedPreferences.getInstance();
    final key = '${_lastViewedKey}_$myId';
    final lastViewedStr = prefs.getString(key);

    if (lastViewedStr != null) {
      return DateTime.parse(lastViewedStr).toUtc();
    }

    // First login — treat everything currently in the DB as already read so
    // the badge and toasts don't fire for all historical messages.
    final messages =
        ref.read(chatStreamProvider(kAllAroundTallyChannel)).asData?.value;
    final DateTime baseline;
    if (messages != null && messages.isNotEmpty) {
      baseline = messages.last.createdAt.toUtc().add(
        const Duration(milliseconds: 500),
      );
    } else {
      baseline = DateTime.now().toUtc();
    }
    await prefs.setString(key, baseline.toIso8601String());
    return baseline;
  }

  Future<void> updateLastSeen(DateTime timestamp, {String? userId}) async {
    final activeUserId = ref.read(authProvider)?.id;
    final targetUserId = userId ?? activeUserId;
    if (targetUserId == null) return;

    final next = timestamp.toUtc();

    if (targetUserId == activeUserId) {
      final current =
          state.value ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      if (next.isAfter(current)) {
        state = AsyncData(next);
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${_lastViewedKey}_$targetUserId';
      final existing = prefs.getString(key);
      if (existing == null || next.isAfter(DateTime.parse(existing).toUtc())) {
        await prefs.setString(key, next.toIso8601String());
      }
    } catch (_) {}
  }
}

// ── Unread count for all-aroundtally — keepAlive so badge stays correct ──────
@Riverpod(keepAlive: true)
class AllAroundTallyUnreadCount extends _$AllAroundTallyUnreadCount {
  @override
  int build() {
    final myId = ref.watch(authProvider)?.id;
    if (myId == null) return 0;

    final messagesAsync = ref.watch(chatStreamProvider(kAllAroundTallyChannel));
    final lastSeenAsync = ref.watch(allAroundTallyLastSeenProvider);

    if (lastSeenAsync.isLoading) return 0;

    return messagesAsync.maybeWhen(
      data: (messages) {
        if (messages.isEmpty) return 0;
        final normalizedMyId = myId.toString().trim().toLowerCase();
        final lastSeen = lastSeenAsync.value;

        return messages.where((m) {
          if (m.senderId.trim().toLowerCase() == normalizedMyId) return false;
          if (m.isDeleted) return false;

          // Primary: messages older than or equal to lastSeen are read
          if (lastSeen != null && !m.createdAt.toUtc().isAfter(lastSeen)) {
            return false;
          }

          // Secondary: explicit per-message read receipt
          final readBy = ReadReceiptsTracker.getReadBy(m.id);
          if (readBy.contains(normalizedMyId)) return false;

          return true;
        }).length;
      },
      orElse: () => 0,
    );
  }

  /// Call this when the user opens the all-aroundtally channel page.
  Future<void> markAsRead({DateTime? timestamp}) async {
    final myId = ref.read(authProvider)?.id;
    if (myId == null) return;

    DateTime effectiveTimestamp;
    if (timestamp != null) {
      effectiveTimestamp = timestamp;
    } else {
      final messages =
          ref.read(chatStreamProvider(kAllAroundTallyChannel)).asData?.value;
      if (messages != null && messages.isNotEmpty) {
        effectiveTimestamp = messages.last.createdAt;
      } else {
        effectiveTimestamp = DateTime.now().toUtc();
      }
    }

    final safeTimestamp = effectiveTimestamp.toUtc().add(
      const Duration(milliseconds: 500),
    );

    await ref
        .read(allAroundTallyLastSeenProvider.notifier)
        .updateLastSeen(safeTimestamp, userId: myId);

    // Mark visible messages from others as read in the (channel-agnostic,
    // message-id keyed) read receipts tracker.
    final messages =
        ref.read(chatStreamProvider(kAllAroundTallyChannel)).asData?.value ?? [];
    for (final message in messages) {
      if (message.senderId != myId) {
        await ReadReceiptsTracker.markAsRead(message.id, myId);
      }
    }
  }
}

// ── New-message event for all-aroundtally toast notifications ────────────────
@Riverpod(keepAlive: true)
class AllAroundTallyNewMessageEvent extends _$AllAroundTallyNewMessageEvent {
  static final Set<String> _notifiedIds = {};

  @override
  ChatMessage? build() => null;

  void notify(ChatMessage message) {
    if (_notifiedIds.contains(message.id)) return;

    final lastSeenAsync = ref.read(allAroundTallyLastSeenProvider);
    final lastSeen = lastSeenAsync.value;
    if (lastSeen != null && !message.createdAt.toUtc().isAfter(lastSeen)) {
      _notifiedIds.add(message.id);
      return;
    }

    _notifiedIds.add(message.id);
    state = message;
  }

  void clear() => state = null;

  /// Call on logout to reset the notified-IDs set for the next user.
  static void resetSession() => _notifiedIds.clear();
}

// ── Read receipts tracking (client-side) ─────────────────────────────────────
class ReadReceiptsTracker {
  static const _readReceiptsKey = 'chat_read_receipts';
  static const _userLastSeenKey = 'chat_user_last_seen_';

  // In-memory cache for synchronous access
  static Map<String, Set<String>> _cache = {};
  static Map<String, DateTime> _userLastSeenCache = {};
  static bool _initialized = false;
  static bool _isInitializing = false; // Prevent concurrent initialization

  // Callback to notify when tracker changes
  static VoidCallback? _onChange;

  static void setOnChangeCallback(VoidCallback callback) {
    _onChange = callback;
  }

  static Future<void> _initialize() async {
    if (_initialized || _isInitializing) return;

    _isInitializing = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load read receipts
      final data = prefs.getString(_readReceiptsKey);
      if (data != null) {
        final Map<String, dynamic> decoded = jsonDecode(data);
        _cache = decoded.map(
          (key, value) => MapEntry(
            key,
            (value as List)
                .map((e) => e.toString().trim().toLowerCase())
                .toSet(),
          ),
        );
      }

      final remoteReceipts = await _loadRemoteReadReceipts();
      if (remoteReceipts.isNotEmpty) {
        for (final entry in remoteReceipts.entries) {
          _cache.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
        }
        await _saveReadReceipts();
      }

      // Load user last seen timestamps
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_userLastSeenKey)) {
          final userId = key.substring(_userLastSeenKey.length);
          final timestampStr = prefs.getString(key);
          if (timestampStr != null) {
            _userLastSeenCache[userId] = DateTime.parse(timestampStr);
          }
        }
      }

      _initialized = true;
      // Notify listeners that tracker is now initialized
      _onChange?.call();
    } catch (e) {
      // If loading fails, continue with empty cache
      debugPrint('Error loading ReadReceiptsTracker: $e');
    } finally {
      _isInitializing = false;
    }
  }

  static Future<void> _saveReadReceipts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _cache.map((key, value) => MapEntry(key, value.toList())),
    );
    await prefs.setString(_readReceiptsKey, encoded);
  }

  static Future<void> _saveUserLastSeen(
    String userId,
    DateTime timestamp,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_userLastSeenKey$userId',
      timestamp.toIso8601String(),
    );
    _userLastSeenCache[userId] = timestamp;
  }

  static Future<void> markAsRead(String messageId, String userId) async {
    await _initialize();
    if (!_cache.containsKey(messageId)) {
      _cache[messageId] = {};
    }
    _cache[messageId]!.add(userId.trim().toLowerCase());
    await _saveReadReceipts();
    await _saveRemoteReadReceipt(messageId, userId);
    // Notify listeners that tracker changed
    _onChange?.call();
  }

  static Future<void> markMultipleAsRead(List<String> messageIds, String userId) async {
    if (messageIds.isEmpty) return;
    await _initialize();
    
    for (final messageId in messageIds) {
      if (!_cache.containsKey(messageId)) {
        _cache[messageId] = {};
      }
      _cache[messageId]!.add(userId.trim().toLowerCase());
    }
    
    await _saveReadReceipts();
    
    try {
      final payload = messageIds.map((id) => {
        'message_id': id,
        'user_id': userId,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();
      await Supabase.instance.client.from('chat_read_receipts').upsert(payload, onConflict: 'message_id,user_id');
    } catch (e) {
      debugPrint('Unable to save multiple remote chat read receipts: $e');
    }
    
    _onChange?.call();
  }

  static Future<void> updateUserLastSeen(
    String userId,
    DateTime timestamp,
  ) async {
    await _initialize();
    await _saveUserLastSeen(userId, timestamp);
  }

  static DateTime? getUserLastSeen(String userId) {
    // Return cached value even if not fully initialized
    return _userLastSeenCache[userId];
  }

  static Set<String> getReadBy(String messageId) {
    // Return cached value even if not fully initialized
    // The initialization happens asynchronously in preload()
    return _cache[messageId] ?? {};
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readReceiptsKey);
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_userLastSeenKey)) {
        await prefs.remove(key);
      }
    }
    _cache = {};
    _userLastSeenCache = {};
    _initialized = false;
  }

  static Future<void> preload() async {
    await _initialize();
  }

  static Future<Map<String, Set<String>>> _loadRemoteReadReceipts() async {
    try {
      final rows = await Supabase.instance.client
          .from('chat_read_receipts')
          .select('message_id, user_id');

      final receipts = <String, Set<String>>{};
      for (final row in rows) {
        final messageId = row['message_id']?.toString();
        final userId = row['user_id']?.toString();
        if (messageId == null || userId == null) continue;

        receipts
            .putIfAbsent(messageId, () => <String>{})
            .add(userId.trim().toLowerCase());
      }
      return receipts;
    } catch (e) {
      debugPrint('Unable to load remote chat read receipts: $e');
      return {};
    }
  }

  static Future<void> _saveRemoteReadReceipt(
    String messageId,
    String userId,
  ) async {
    try {
      await Supabase.instance.client.from('chat_read_receipts').upsert({
        'message_id': messageId,
        'user_id': userId,
        'read_at': DateTime.now().toUtc().toIso8601String(),
      }, onConflict: 'message_id,user_id');
    } catch (e) {
      debugPrint('Unable to save remote chat read receipt: $e');
    }
  }
}

// ── Chat controller ───────────────────────────────────────────────────────────
@Riverpod(keepAlive: true)
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {}

  Future<String> sendMessage({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    String? receiverId,
    String? senderAvatarUrl,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToContent,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String channel = 'support-chat',
    List<dynamic>? richTextDelta,
  }) async {
    state = const AsyncLoading();
    String newId = '';
    state = await AsyncValue.guard(
      () async {
        newId = await ref
            .read(chatRepositoryProvider)
            .sendMessage(
              senderId: senderId,
              senderName: senderName,
              senderRole: senderRole,
              content: content,
              receiverId: receiverId,
              senderAvatarUrl: senderAvatarUrl,
              replyToMessageId: replyToMessageId,
              replyToSenderName: replyToSenderName,
              richTextDelta: richTextDelta,
              replyToContent: replyToContent,
              fileUrl: fileUrl,
              fileName: fileName,
              fileType: fileType,
              channel: channel,
            );
      },
    );
    return newId;
  }

  Future<void> deleteMessage(String messageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).deleteMessage(messageId),
    );
  }

  Future<void> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    await ref.read(chatRepositoryProvider).toggleReaction(
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );
  }
}

// ── Message status model ─────────────────────────────────────────────────────
class MessageStatus {
  final String messageId;
  final List<Map<String, dynamic>> readBy;
  final List<Map<String, dynamic>> deliveredTo;

  const MessageStatus({
    required this.messageId,
    required this.readBy,
    required this.deliveredTo,
  });
}

// ── Message status provider (manual implementation) ───────────────────────
final messageStatusProvider =
    Provider.family<MessageStatus, Map<String, dynamic>>((ref, args) {
      final currentUser = ref.watch(authProvider);
      if (currentUser == null) {
        return const MessageStatus(messageId: '', readBy: [], deliveredTo: []);
      }

      final agentsAsync = ref.watch(agentsListProvider);
      final agents = agentsAsync.value ?? [];

      final messageId = args['messageId'] as String;
      final messageTimestamp = args['messageTimestamp'] as DateTime?;

      // Get read receipts from in-memory cache (synchronous)
      final readByUserIds = ReadReceiptsTracker.getReadBy(messageId);

      // Track delivered and read status
      final readBy = <Map<String, dynamic>>[];
      final deliveredTo = <Map<String, dynamic>>[];

      for (final agent in agents) {
        final agentId = agent['id']?.toString() ?? '';
        if (agentId.isEmpty) continue;

        // Normalize agent ID for comparison
        final normalizedAgentId = agentId.trim().toLowerCase();

        // Skip the sender for delivery (they don't "deliver" to themselves)
        if (agentId != currentUser.id) {
          deliveredTo.add(agent);
        }

        // Skip the sender for read status (they don't "read" their own message)
        if (agentId == currentUser.id) {
          continue;
        }

        // Check if this user has read the message
        // First check read receipts, then fallback to user's lastSeen timestamp
        bool hasRead = false;
        if (readByUserIds.contains(normalizedAgentId)) {
          hasRead = true;
        } else if (messageTimestamp != null) {
          // Fallback: Check if user's lastSeen is after message timestamp
          final userLastSeen = ReadReceiptsTracker.getUserLastSeen(
            normalizedAgentId,
          );
          if (userLastSeen != null) {
            hasRead = messageTimestamp.toUtc().isBefore(userLastSeen);
          }
        }

        if (hasRead) {
          readBy.add(agent);
        }
      }

      return MessageStatus(
        messageId: messageId,
        readBy: readBy,
        deliveredTo: deliveredTo,
      );
    });


// ── Starred messages stream ─────────────────────────────────────────────────────
final starredMessagesStreamProvider = StreamProvider.family<List<ChatMessage>, String>((ref, userId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.getStarredMessages(userId);
});

// ── DM conversations provider — real-time updates for left pane ──
final dmConversationsProvider = StreamProvider<Map<String, Map<String, dynamic>>>((ref) {
  final currentUser = ref.watch(authProvider);
  if (currentUser == null) return Stream.value({});

  final repository = ref.watch(chatRepositoryProvider);
  return repository.getDmConversations(currentUser.id);
});

// ── Read overrides: partners whose count should be immediately forced to 0 ────
// Populated when user opens a DM — cleared when a new message arrives from that partner.
final _dmReadOverrides = <String, DateTime>{};   // partnerId -> override timestamp

void markDmAsReadLocally(String partnerId, DateTime timestamp) {
  _dmReadOverrides[partnerId] = timestamp;
}

// ── DM unread count per partner ───────────────────────────────────────────────
final dmUnreadCountProvider = Provider.family<int, String>((ref, partnerId) {
  final conversationsAsync = ref.watch(dmConversationsProvider);

  final conv = conversationsAsync.value?[partnerId];
  if (conv == null) return 0;
  
  final realCount = (conv['unread_count'] as int?) ?? 0;
  final lastMessageAt = conv['last_message_at'] as DateTime?;

  final overrideTime = _dmReadOverrides[partnerId];

  if (overrideTime != null && lastMessageAt != null) {
    if (!lastMessageAt.isAfter(overrideTime)) {
      return 0;
    }
  }

  return realCount;
});
