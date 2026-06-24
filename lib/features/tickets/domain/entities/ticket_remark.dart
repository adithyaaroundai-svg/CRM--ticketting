// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/json_converters.dart';

part 'ticket_remark.freezed.dart';
part 'ticket_remark.g.dart';

@freezed
abstract class TicketRemark with _$TicketRemark {
  const factory TicketRemark({
    required String id,
    @JsonKey(name: 'ticket_id') required String ticketId,
    @JsonKey(name: 'agent_id') String? agentId,
    @JsonKey(name: 'customer_id') String? customerId,
    String? remark,
    @JsonKey(name: 'remark_type') @Default('text') String remarkType,
    @JsonKey(name: 'voice_url') String? voiceUrl,
    @JsonKey(name: 'duration_seconds') int? durationSeconds,
    String? stage,
    @JsonKey(name: 'created_at') @UtcDateTimeConverter() DateTime? createdAt,
    @JsonKey(name: 'updated_at') @UtcDateTimeConverter() DateTime? updatedAt,
  }) = _TicketRemark;

  factory TicketRemark.fromJson(Map<String, dynamic> json) =>
      _$TicketRemarkFromJson(json);
}
