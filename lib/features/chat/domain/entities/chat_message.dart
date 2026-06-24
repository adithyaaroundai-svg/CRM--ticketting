import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/json_converters.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'receiver_id') String? receiverId,
    @JsonKey(name: 'sender_name') required String senderName,
    @JsonKey(name: 'sender_role') required String senderRole,
    @JsonKey(name: 'sender_avatar_url') String? senderAvatarUrl,
    required String content,
    @JsonKey(name: 'created_at') @UtcDateTimeConverter() required DateTime createdAt,
    @Default(false) @JsonKey(name: 'is_deleted') bool isDeleted,
    @Default([]) @JsonKey(name: 'reactions') List<Map<String, dynamic>> reactions,
    @JsonKey(name: 'reply_to_message_id') String? replyToMessageId,
    @JsonKey(name: 'reply_to_sender_name') String? replyToSenderName,
    @JsonKey(name: 'reply_to_content') String? replyToContent,
    @JsonKey(name: 'file_url') String? fileUrl,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'file_type') String? fileType,
    @Default('support-chat') @JsonKey(name: 'channel') String channel,
    @JsonKey(name: 'rich_text_delta') List<dynamic>? richTextDelta,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
