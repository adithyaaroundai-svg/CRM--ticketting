// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Ticket _$TicketFromJson(Map<String, dynamic> json) => _Ticket(
  ticketId: json['id'] as String,
  customerId: json['customer_id'] as String,
  clientTicketUuid: json['client_ticket_uuid'] as String?,
  title: json['title'] as String? ?? '',
  description: json['description'] as String?,
  contactPhone: json['contact_phone'] as String?,
  screenshotUrl: json['screenshot_url'] as String?,
  category: json['category'] as String?,
  status: json['status'] as String? ?? 'New',
  priority: json['priority'] as String?,
  createdBy: json['created_by'] as String? ?? 'Unknown',
  assignedTo: json['assigned_to'] as String?,
  createdAt: const UtcDateTimeConverter().fromJson(
    json['created_at'] as String?,
  ),
  updatedAt: const UtcDateTimeConverter().fromJson(
    json['updated_at'] as String?,
  ),
  slaDue: const UtcDateTimeConverter().fromJson(json['sla_due'] as String?),
  billAmount: (json['bill_amount'] as num?)?.toDouble(),
  billingProcedure: json['billing_procedure'] as String?,
  paymentCollected: json['payment_collected'] as bool?,
  completedDate: const UtcDateTimeConverter().fromJson(
    json['completed_at'] as String?,
  ),
);

Map<String, dynamic> _$TicketToJson(_Ticket instance) => <String, dynamic>{
  'id': instance.ticketId,
  'customer_id': instance.customerId,
  'client_ticket_uuid': instance.clientTicketUuid,
  'title': instance.title,
  'description': instance.description,
  'contact_phone': instance.contactPhone,
  'screenshot_url': instance.screenshotUrl,
  'category': instance.category,
  'status': instance.status,
  'priority': instance.priority,
  'created_by': instance.createdBy,
  'assigned_to': instance.assignedTo,
  'created_at': const UtcDateTimeConverter().toJson(instance.createdAt),
  'updated_at': const UtcDateTimeConverter().toJson(instance.updatedAt),
  'sla_due': const UtcDateTimeConverter().toJson(instance.slaDue),
  'bill_amount': instance.billAmount,
  'billing_procedure': instance.billingProcedure,
  'payment_collected': instance.paymentCollected,
  'completed_at': const UtcDateTimeConverter().toJson(instance.completedDate),
};
