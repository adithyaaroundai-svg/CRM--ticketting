import 'package:flutter/foundation.dart';
import '../../../../core/utils/json_converters.dart';

@immutable
class Activity {
  final String id;
  final String accountId;
  final String? contactId;
  final String? agentId;
  final String type;
  final String subject;
  final String? description;
  final DateTime occurredAt;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.accountId,
    this.contactId,
    this.agentId,
    required this.type,
    required this.subject,
    this.description,
    required this.occurredAt,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String? ?? '',
      accountId:
          json['account_id'] as String? ?? json['customer_id'] as String? ?? '',
      contactId: json['contact_id'] as String?,
      agentId: json['agent_id'] as String?,
      type: json['type'] as String? ?? 'general',
      subject: json['subject'] as String? ?? '',
      description: json['description'] as String?,
      occurredAt: tryParseUtcDate(json['occurred_at'] as String?) ?? DateTime.now().toUtc(),
      createdAt: tryParseUtcDate(json['created_at'] as String?) ?? DateTime.now().toUtc(),
    );
  }
}
