import 'package:flutter/foundation.dart';
import '../../../../core/utils/json_converters.dart';

@immutable
class Contact {
  final String id;
  final String accountId;
  final String fullName;
  final String? email;
  final String? phone;
  final String? role;
  final bool isPrimary;
  final bool isBillingContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Contact({
    required this.id,
    required this.accountId,
    required this.fullName,
    this.email,
    this.phone,
    this.role,
    required this.isPrimary,
    required this.isBillingContact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String?,
      isPrimary: (json['is_primary'] as bool?) ?? false,
      isBillingContact: (json['is_billing_contact'] as bool?) ?? false,
      createdAt: parseUtcDate(json['created_at'] as String),
      updatedAt: parseUtcDate(json['updated_at'] as String),
    );
  }
}
