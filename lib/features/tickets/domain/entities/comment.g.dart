// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketComment _$TicketCommentFromJson(Map<String, dynamic> json) =>
    _TicketComment(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      author: json['author'] as String? ?? 'Unknown',
      body: json['body'] as String? ?? '',
      isInternal: json['internal'] as bool? ?? false,
      createdAt: const UtcDateTimeConverter().fromJson(
        json['created_at'] as String?,
      ),
    );

Map<String, dynamic> _$TicketCommentToJson(_TicketComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'author': instance.author,
      'body': instance.body,
      'internal': instance.isInternal,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
    };
