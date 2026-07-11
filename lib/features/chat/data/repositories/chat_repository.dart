import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client;

  ChatRepository(this._client);

  // ── Real-time stream for chat messages — fires on INSERT, UPDATE, DELETE ─────
  Stream<List<ChatMessage>> getMessages({String? currentUserId, String? chatPartnerId, String channelName = 'support-chat'}) {
    final controller = StreamController<List<ChatMessage>>.broadcast();

    Future<void> fetch() async {
      try {
        final data = await _client
            .from('chat_messages')
            .select()
            .eq('channel', channelName)
            .order('created_at', ascending: true);

        final messages = data
            .map((json) => ChatMessage.fromJson(json))
            .where((msg) {
              if (chatPartnerId == null) {
                return msg.receiverId == null;
              } else {
                return (msg.senderId == currentUserId && msg.receiverId == chatPartnerId) ||
                       (msg.senderId == chatPartnerId && msg.receiverId == currentUserId);
              }
            })
            .toList();

        messages.sort((a, b) {
          final t = a.createdAt.toUtc().compareTo(b.createdAt.toUtc());
          return t != 0 ? t : a.id.compareTo(b.id);
        });

        if (!controller.isClosed) controller.add(messages);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    // Initial load
    fetch();

    // Polling fallback to ensure messages update even if Realtime is disabled
    Timer? fallbackTimer;
    fallbackTimer = Timer.periodic(const Duration(seconds: 3), (_) => fetch());

    // Subscribe to all changes — INSERT (new message), UPDATE (reaction, delete),
    // DELETE — fires instantly, no polling delay
    final realtimeChannelName = chatPartnerId != null
        ? 'chat_dm_${currentUserId}_$chatPartnerId'
        : 'chat_${channelName}';

    final realtimeChannel = _client
        .channel(realtimeChannelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => fetch(),
        )
        .subscribe();

    controller.onCancel = () {
      fallbackTimer?.cancel();
      _client.removeChannel(realtimeChannel);
    };
    return controller.stream;
  }

  // Send a message
  Future<String> sendMessage({
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    String? receiverId,
    String? senderAvatarUrl,
    String? parentMessageId,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToContent,
    String? fileUrl,
    String? fileName,
    String? fileType,
    String channel = 'support-chat',
    List<dynamic>? richTextDelta,
  }) async {
    final payload = {
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'content': content,
      'channel': channel,
    };
    if (receiverId != null) {
      payload['receiver_id'] = receiverId;
    }
    if (senderAvatarUrl != null) {
      payload['sender_avatar_url'] = senderAvatarUrl;
    }
    if (replyToMessageId != null) {
      payload['reply_to_message_id'] = replyToMessageId;
    }
    if (replyToSenderName != null) {
      payload['reply_to_sender_name'] = replyToSenderName;
    }
    if (replyToContent != null) {
      payload['reply_to_content'] = replyToContent;
    }
    if (richTextDelta != null) {
      // payload['rich_text_delta'] = jsonEncode(richTextDelta);
    }
    if (fileUrl != null) {
      payload['file_url'] = fileUrl;
    }
    if (fileName != null) {
      payload['file_name'] = fileName;
    }
    if (fileType != null) {
      payload['file_type'] = fileType;
    }
    
    final response = await _client.from('chat_messages').insert(payload).select('id').single();
    return response['id'] as String;
  }

  // Insert a call-event system message.
  // [callType] is 'audio' or 'video'.
  // [event] is 'started' | 'ended' | 'missed' | 'ongoing'.
  // [duration] is optional (e.g., '5m 32s'), used for 'ended' event.
  Future<void> sendCallMessage({
    required String senderId,
    required String senderName,
    required String senderRole,
    String callType = 'audio', // 'audio' | 'video'
    String event = 'started',  // 'started' | 'ended' | 'missed' | 'ongoing'
    String? duration,
    String? receiverId,
    String channel = 'support-chat',
  }) async {
    // Format: __CALL_AUDIO_STARTED__ or __CALL_VIDEO_ENDED__:5m 32s
    final suffix = duration != null ? ':$duration' : '';
    final content = '__CALL_${callType.toUpperCase()}_${event.toUpperCase()}__$suffix';
    final payload = <String, dynamic>{
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_role': senderRole,
      'content': content,
      'channel': channel,
    };
    if (receiverId != null) payload['receiver_id'] = receiverId;
    await _client.from('chat_messages').insert(payload);
  }


  Future<void> deleteMessage(String messageId) async {
    await _client
        .from('chat_messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  Future<Map<String, Set<String>>> getReadReceipts() async {
    final rows = await _client
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
  }

  Future<void> markAsRead(String messageId, String userId) async {
    await _client.from('chat_read_receipts').upsert({
      'message_id': messageId,
      'user_id': userId,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'message_id,user_id');
  }

  // Mark multiple messages as read efficiently
  Future<void> markMessagesAsRead(List<String> messageIds, String userId) async {
    if (messageIds.isEmpty) return;
    
    final payload = messageIds.map((id) => {
      'message_id': id,
      'user_id': userId,
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).toList();

    await _client.from('chat_read_receipts').upsert(payload, onConflict: 'message_id,user_id');
  }

  // Add or remove a reaction from a message
  Future<void> toggleReaction({
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    // Get current message
    final response = await _client
        .from('chat_messages')
        .select('reactions')
        .eq('id', messageId)
        .single();

    final currentReactions = response['reactions'] as List<dynamic>? ?? [];

    // Check if user already reacted with any emoji
    final existingIndex = currentReactions.indexWhere(
      (r) => r['user_id'] == userId,
    );

    List<dynamic> updatedReactions;

    if (existingIndex != -1) {
      if (currentReactions[existingIndex]['emoji'] == emoji) {
        // Same emoji -> remove the reaction (toggle off)
        updatedReactions = List.from(currentReactions)..removeAt(existingIndex);
      } else {
        // Different emoji -> replace the reaction
        updatedReactions = List.from(currentReactions);
        updatedReactions[existingIndex] = {
          'user_id': userId,
          'emoji': emoji,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
      }
    } else {
      // No existing reaction -> add the reaction
      updatedReactions = [
        ...currentReactions,
        {
          'user_id': userId,
          'emoji': emoji,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ];
    }

    // Update the message
    await _client
        .from('chat_messages')
        .update({'reactions': updatedReactions})
        .eq('id', messageId);
  }

  // Toggle starred status of a message
  Future<void> toggleStarred(String messageId, String userId) async {
    // Check if already starred
    final existing = await _client
        .from('starred_messages')
        .select()
        .eq('message_id', messageId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      // Remove star
      await _client
          .from('starred_messages')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId);
    } else {
      // Add star
      await _client.from('starred_messages').insert({
        'message_id': messageId,
        'user_id': userId,
      });
    }
  }

  // Get starred messages for a user
  Stream<List<ChatMessage>> getStarredMessages(String userId) {
    return _client
        .from('starred_messages')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((starredData) async {
      final messageIds = starredData
          .map((s) => s['message_id']?.toString())
          .whereType<String>()
          .toList();

      if (messageIds.isEmpty) return <ChatMessage>[];

      final messagesData = await _client
          .from('chat_messages')
          .select()
          .inFilter('id', messageIds)
          .order('created_at', ascending: false);

      return messagesData
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    });
  }

  // Get DM conversation metadata — realtime, fires on any message INSERT/UPDATE/DELETE
  // Returns per-partner: last_message_at, unread_count (messages from partner not yet read)
  Future<Map<String, Map<String, dynamic>>> getDmConversationsOnce(String currentUserId) async {
    final data = await _client
        .from('chat_messages')
        .select('id, sender_id, receiver_id, created_at')
        .not('receiver_id', 'is', null)
        .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
        .order('created_at', ascending: true);

    final conversations = <String, Map<String, dynamic>>{};

    for (final msg in data) {
      final msgId = msg['id']?.toString();
      final senderId = msg['sender_id']?.toString();
      final receiverId = msg['receiver_id']?.toString();
      final createdAt = DateTime.tryParse(msg['created_at']?.toString() ?? '');
      if (msgId == null || receiverId == null || createdAt == null) continue;

      final partnerId = senderId == currentUserId ? receiverId : senderId;
      if (partnerId == null || partnerId == currentUserId) continue;

      conversations.putIfAbsent(partnerId, () => {
        'last_message_at': createdAt,
        'messages_from_partner': <String>[],
      });

      final currentLast = conversations[partnerId]!['last_message_at'] as DateTime;
      if (createdAt.isAfter(currentLast)) {
        conversations[partnerId]!['last_message_at'] = createdAt;
      }

      if (senderId != currentUserId) {
        (conversations[partnerId]!['messages_from_partner'] as List<String>).add(msgId);
      }
    }

    final receiptsData = await _client
        .from('chat_read_receipts')
        .select('message_id')
        .eq('user_id', currentUserId);
    final readMessageIds = receiptsData.map((row) => row['message_id'].toString()).toSet();

    for (final partnerId in conversations.keys) {
      final messagesFromPartner = conversations[partnerId]!['messages_from_partner'] as List<String>;
      
      int unread = 0;
      for (final msgId in messagesFromPartner) {
        if (!readMessageIds.contains(msgId)) unread++;
      }

      conversations[partnerId]!['unread_count'] = unread;
      conversations[partnerId]!.remove('messages_from_partner');
    }

    return conversations;
  }

  Stream<Map<String, Map<String, dynamic>>> getDmConversations(String currentUserId) {
    final controller = StreamController<Map<String, Map<String, dynamic>>>.broadcast();

    Future<void> fetch() async {
      try {
        // Fetch all DM messages involving this user
        final data = await _client
            .from('chat_messages')
            .select('id, sender_id, receiver_id, created_at')
            .not('receiver_id', 'is', null)
            .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
            .order('created_at', ascending: true);

        final conversations = <String, Map<String, dynamic>>{};

        for (final msg in data) {
          final msgId = msg['id']?.toString();
          final senderId = msg['sender_id']?.toString();
          final receiverId = msg['receiver_id']?.toString();
          final createdAt = DateTime.tryParse(msg['created_at']?.toString() ?? '');
          if (msgId == null || receiverId == null || createdAt == null) continue;

          final partnerId = senderId == currentUserId ? receiverId : senderId;
          if (partnerId == null || partnerId == currentUserId) continue;

          conversations.putIfAbsent(partnerId, () => {
            'last_message_at': createdAt,
            'messages_from_partner': <String>[],
          });

          // Track the latest message time
          final currentLast = conversations[partnerId]!['last_message_at'] as DateTime;
          if (createdAt.isAfter(currentLast)) {
            conversations[partnerId]!['last_message_at'] = createdAt;
          }

          // Collect message IDs FROM the partner (not sent by me)
          if (senderId != currentUserId) {
            (conversations[partnerId]!['messages_from_partner'] as List<String>).add(msgId);
          }
        }

        final receiptsData = await _client
            .from('chat_read_receipts')
            .select('message_id')
            .eq('user_id', currentUserId);
        final readMessageIds = receiptsData.map((row) => row['message_id'].toString()).toSet();

        for (final partnerId in conversations.keys) {
          final messagesFromPartner = conversations[partnerId]!['messages_from_partner'] as List<String>;
          
          int unread = 0;
          for (final msgId in messagesFromPartner) {
            if (!readMessageIds.contains(msgId)) unread++;
          }

          conversations[partnerId]!['unread_count'] = unread;
          conversations[partnerId]!.remove('messages_from_partner'); // cleanup
        }

        if (!controller.isClosed) controller.add(conversations);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    fetch();

    // Polling fallback to ensure counters update even if Realtime is disabled
    Timer? fallbackTimer;
    fallbackTimer = Timer.periodic(const Duration(seconds: 3), (_) => fetch());

    void delayedFetch() {
      Future.delayed(const Duration(milliseconds: 300), fetch);
    }

    final channelMessages = _client
        .channel('dm_convos_msg_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => delayedFetch(),
        )
        .subscribe();

    final channelReceipts = _client
        .channel('dm_convos_rcpt_$currentUserId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_read_receipts',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: currentUserId,
          ),
          callback: (_) => delayedFetch(),
        )
        .subscribe();

    controller.onCancel = () {
      fallbackTimer?.cancel();
      _client.removeChannel(channelMessages);
      _client.removeChannel(channelReceipts);
    };
    return controller.stream;
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});
