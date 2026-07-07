import 'package:freezed_annotation/freezed_annotation.dart';

/// Parses a Supabase timestamp string safely as UTC.
/// Handles:
///   - Full timestamps without timezone: append Z  (e.g. "2026-07-01T04:57:00" → UTC)
///   - Full timestamps with Z or +offset: parse as-is
///   - Date-only strings (YYYY-MM-DD): treat as midnight UTC
DateTime parseUtcDate(String value) {
  final v = value.trim();
  // Date-only: YYYY-MM-DD (10 chars, no T)
  if (v.length == 10 && !v.contains('T')) {
    return DateTime.utc(
      int.parse(v.substring(0, 4)),
      int.parse(v.substring(5, 7)),
      int.parse(v.substring(8, 10)),
    );
  }
  // Full timestamp — append Z only if no timezone info present
  final normalized = (v.endsWith('Z') || v.contains('+')) ? v : '${v}Z';
  return DateTime.parse(normalized).toUtc();
}

/// Nullable variant of [parseUtcDate].
DateTime? tryParseUtcDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return parseUtcDate(value);
}

class UtcDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const UtcDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return parseUtcDate(json);
  }

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}
