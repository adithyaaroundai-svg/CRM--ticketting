import '../../../../core/utils/json_converters.dart';

class Lead {
  final String id;
  final String companyName;
  final String status; // 'pending', 'win', 'loss'
  final double amount;
  final DateTime createdAt;
  final String? createdBy;

  Lead({
    required this.id,
    required this.companyName,
    required this.status,
    required this.amount,
    required this.createdAt,
    this.createdBy,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String,
      companyName: json['company_name'] as String,
      status: json['status'] as String? ?? 'pending',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseUtcDate(json['created_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }
}
