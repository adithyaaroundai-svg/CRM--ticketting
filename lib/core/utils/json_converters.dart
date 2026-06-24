import 'package:freezed_annotation/freezed_annotation.dart';

class UtcDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const UtcDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    
    final parsed = DateTime.parse(json);
    
    if (parsed.isUtc) {
      return parsed;
    }
    
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}
