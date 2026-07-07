import '../../../../core/utils/json_converters.dart';

class Deal {
  final String id;
  final String customerId;
  final String title;
  final String
  stage; // 'new', 'qualified', 'proposal', 'negotiation', 'won', 'lost'
  final double value;
  final String? description;
  final String? assignedTo;
  final DateTime? expectedCloseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Deal({
    required this.id,
    required this.customerId,
    required this.title,
    required this.stage,
    required this.value,
    this.description,
    this.assignedTo,
    this.expectedCloseDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      title: json['title'] as String,
      stage: json['stage'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] as String?,
      expectedCloseDate: tryParseUtcDate(json['expected_close_date'] as String?),
      createdAt: parseUtcDate(json['created_at'] as String),
      updatedAt: parseUtcDate(json['updated_at'] as String),
    );
  }

  Deal copyWith({
    String? id,
    String? customerId,
    String? title,
    String? stage,
    double? value,
    String? description,
    String? assignedTo,
    DateTime? expectedCloseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Deal(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      stage: stage ?? this.stage,
      value: value ?? this.value,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      expectedCloseDate: expectedCloseDate ?? this.expectedCloseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static const stages = [
    'new',
    'qualified',
    'proposal',
    'negotiation',
    'won',
    'lost',
  ];

  static String stageLabel(String stage) {
    switch (stage) {
      case 'new':
        return 'New';
      case 'qualified':
        return 'Qualified';
      case 'proposal':
        return 'Proposal';
      case 'negotiation':
        return 'Negotiation';
      case 'won':
        return 'Won';
      case 'lost':
        return 'Lost';
      default:
        return stage;
    }
  }
}
