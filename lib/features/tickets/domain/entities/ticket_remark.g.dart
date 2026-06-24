// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_remark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TicketRemark _$TicketRemarkFromJson(Map<String, dynamic> json) =>
    _TicketRemark(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      agentId: json['agent_id'] as String?,
      customerId: json['customer_id'] as String?,
      remark: json['remark'] as String?,
      remarkType: json['remark_type'] as String? ?? 'text',
      voiceUrl: json['voice_url'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      stage: json['stage'] as String?,
      createdAt: const UtcDateTimeConverter().fromJson(
        json['created_at'] as String?,
      ),
      updatedAt: const UtcDateTimeConverter().fromJson(
        json['updated_at'] as String?,
      ),
    );

Map<String, dynamic> _$TicketRemarkToJson(_TicketRemark instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ticket_id': instance.ticketId,
      'agent_id': instance.agentId,
      'customer_id': instance.customerId,
      'remark': instance.remark,
      'remark_type': instance.remarkType,
      'voice_url': instance.voiceUrl,
      'duration_seconds': instance.durationSeconds,
      'stage': instance.stage,
      'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
      'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
    };
