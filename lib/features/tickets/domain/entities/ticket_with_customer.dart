import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../../core/utils/json_converters.dart';

part 'ticket_with_customer.freezed.dart';

@freezed
abstract class TicketWithCustomer with _$TicketWithCustomer {
  const factory TicketWithCustomer({
    required String ticketId,
    required String customerId,
    String? clientTicketUuid,
    required String title,
    String? description,
    String? category,
    required String status,
    required String priority,
    required String createdBy,
    String? assignedTo,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? slaDue,
    // Customer information
    Customer? customer,
  }) = _TicketWithCustomer;

  factory TicketWithCustomer.fromJson(Map<String, dynamic> json) {
    // Extract customer data if present
    Customer? customer;
    if (json['customers'] != null) {
      customer = Customer.fromJson(json['customers'] as Map<String, dynamic>);
    }

    return TicketWithCustomer(
      ticketId: json['id'] as String,
      customerId: json['customer_id'] as String,
      clientTicketUuid: json['client_ticket_uuid'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      status: json['status'] as String,
      priority: json['priority'] as String,
      createdBy: json['created_by'] as String,
      assignedTo: json['assigned_to'] as String?,
      createdAt: const UtcDateTimeConverter().fromJson(json['created_at'] as String?)!,
      updatedAt: const UtcDateTimeConverter().fromJson(json['updated_at'] as String?)!,
      slaDue: const UtcDateTimeConverter().fromJson(json['sla_due'] as String?),
      customer: customer,
    );
  }
}
