import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/json_converters.dart';

// Freezed uses JsonKey on constructor parameters; ignore analyzer complaining
// about invalid annotation targets.
// ignore_for_file: invalid_annotation_target

part 'comment.freezed.dart';
part 'comment.g.dart';

@freezed
abstract class TicketComment with _$TicketComment {
  const factory TicketComment({
    required String id,
    @JsonKey(name: 'ticket_id') required String ticketId,
    @Default('Unknown') String author,
    @Default('') String body,
    @JsonKey(name: 'internal') @Default(false) bool isInternal,
    @JsonKey(name: 'created_at') @UtcDateTimeConverter() DateTime? createdAt,
  }) = _TicketComment;

  factory TicketComment.fromJson(Map<String, dynamic> json) =>
      _$TicketCommentFromJson(json);
}
