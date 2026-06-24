// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => _ChatMessage(
  id: json['id'] as String,
  senderId: json['sender_id'] as String,
  receiverId: json['receiver_id'] as String?,
  senderName: json['sender_name'] as String,
  senderRole: json['sender_role'] as String,
  senderAvatarUrl: json['sender_avatar_url'] as String?,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isDeleted: json['is_deleted'] as bool? ?? false,
  reactions:
      (json['reactions'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ??
      const [],
  replyToMessageId: json['reply_to_message_id'] as String?,
  replyToSenderName: json['reply_to_sender_name'] as String?,
  replyToContent: json['reply_to_content'] as String?,
  fileUrl: json['file_url'] as String?,
  fileName: json['file_name'] as String?,
  fileType: json['file_type'] as String?,
  channel: json['channel'] as String? ?? 'support-chat',
  richTextDelta: json['rich_text_delta'] as List<dynamic>?,
);

Map<String, dynamic> _$ChatMessageToJson(_ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sender_id': instance.senderId,
      'receiver_id': instance.receiverId,
      'sender_name': instance.senderName,
      'sender_role': instance.senderRole,
      'sender_avatar_url': instance.senderAvatarUrl,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'is_deleted': instance.isDeleted,
      'reactions': instance.reactions,
      'reply_to_message_id': instance.replyToMessageId,
      'reply_to_sender_name': instance.replyToSenderName,
      'reply_to_content': instance.replyToContent,
      'file_url': instance.fileUrl,
      'file_name': instance.fileName,
      'file_type': instance.fileType,
      'channel': instance.channel,
      'rich_text_delta': instance.richTextDelta,
    };
