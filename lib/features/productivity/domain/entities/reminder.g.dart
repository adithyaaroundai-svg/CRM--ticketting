// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Reminder _$ReminderFromJson(Map<String, dynamic> json) => _Reminder(
  id: json['id'] as String,
  companyName: json['companyName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  remindAt: DateTime.parse(json['remindAt'] as String),
  notes: json['notes'] as String? ?? '',
  isTriggered: json['isTriggered'] as bool? ?? false,
  isCompleted: json['isCompleted'] as bool? ?? false,
);

Map<String, dynamic> _$ReminderToJson(_Reminder instance) => <String, dynamic>{
  'id': instance.id,
  'companyName': instance.companyName,
  'phoneNumber': instance.phoneNumber,
  'createdAt': instance.createdAt.toIso8601String(),
  'remindAt': instance.remindAt.toIso8601String(),
  'notes': instance.notes,
  'isTriggered': instance.isTriggered,
  'isCompleted': instance.isCompleted,
};
