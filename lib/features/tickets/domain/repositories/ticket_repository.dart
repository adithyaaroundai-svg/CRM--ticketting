import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ticket.dart';
import '../entities/comment.dart';

abstract class TicketRepository {
  Stream<List<Ticket>> getTickets({String? statusFilter});
  Stream<List<Ticket>> getTicketsByStatuses(List<String> statuses);
  Future<Either<Failure, Ticket>> createTicket(Ticket ticket);
  Future<Either<Failure, Unit>> updateTicketStatus(
    String ticketId,
    String status,
  );
  Future<Either<Failure, Unit>> updateTicket(Ticket ticket);
  Future<Either<Failure, Unit>> assignTicket(
    String ticketId,
    String agentId, {
    required String assignedBy,
    String? note,
  });
  Future<Either<Failure, Unit>> resolveAndBillTicket(
    String ticketId,
    double amount,
  );
  Future<Either<Failure, Unit>> deleteTickets(List<String> ticketIds);
  Stream<Map<String, int>> getTicketStats();
  Future<List<Map<String, dynamic>>> getAgents();
  Future<Map<String, dynamic>?> getAgent(String agentId);

  // Customers
  Future<Map<String, dynamic>?> getCustomer(String customerId);

  // Comments
  Stream<List<TicketComment>> getComments(String ticketId);
  Future<Either<Failure, Unit>> addComment({
    required String ticketId,
    required String author,
    required String body,
    required bool isInternal,
  });

  Future<List<Ticket>> getPaginatedTickets({
    String? statusFilter,
    String? priorityFilter,
    String? assigneeFilter,
    String? searchQuery,
    String? currentUserId, // For assignee filters (e.g. 'me')
    DateTime? before,
    int limit = 50,
  });

  Stream<Map<String, dynamic>> get ticketEvents;
}

