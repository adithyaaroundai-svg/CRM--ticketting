import 'package:freezed_annotation/freezed_annotation.dart';

part 'reminder.freezed.dart';
part 'reminder.g.dart';

@freezed
abstract class Reminder with _$Reminder {
  const factory Reminder({
    required String id,
    required String companyName,
    required String phoneNumber,
    required DateTime createdAt,
    required DateTime remindAt,
    @Default('') String notes,
    @Default(false) bool isTriggered,
    @Default(false) bool isCompleted,
  }) = _Reminder;

  factory Reminder.fromJson(Map<String, dynamic> json) => _$ReminderFromJson(json);
}
