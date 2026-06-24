import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/ticket_repository.dart';

/// Creates a realtime stream for a Supabase table that fires on ANY change
/// (INSERT, UPDATE, DELETE) — not just inserts like .stream() does.
Stream<List<Map<String, dynamic>>> _realtimeStream({
  required SupabaseClient supabase,
  required String table,
  required String channelSuffix,
  required Future<List<Map<String, dynamic>>> Function() fetcher,
}) {
  final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

  Future<void> fetch() async {
    try {
      final data = await fetcher();
      if (!controller.isClosed) controller.add(data);
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  // Initial load
  fetch();

  // Fallback polling every 10 seconds in case realtime events are missed
  final fallbackTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetch());

  // Subscribe to all changes
  final channel = supabase
      .channel('realtime_${table}_$channelSuffix')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => fetch(),
      )
      .subscribe();

  controller.onCancel = () {
    fallbackTimer.cancel();
    supabase.removeChannel(channel);
  };

  return controller.stream;
}

class SupabaseTicketRepository implements TicketRepository {
  final SupabaseClient _supabase;

  SupabaseTicketRepository(this._supabase);

  @override
  Stream<List<Ticket>> getTickets({String? statusFilter}) {
    return _realtimeStream(
      supabase: _supabase,
      table: 'tickets',
      channelSuffix: 'all_${statusFilter ?? 'none'}',
      fetcher: () => _supabase
          .from('tickets')
          .select()
          .order('created_at', ascending: false),
    ).map((list) {
      var tickets = list.map((map) => Ticket.fromJson(map)).toList();
      if (statusFilter == 'Open') {
        tickets = tickets
            .where((t) => [
                  'New', 'Open', 'In Progress',
                  'Waiting for Customer', 'BillRaised',
                ].contains(t.status))
            .toList();
      } else if (statusFilter == 'Closed') {
        tickets = tickets
            .where((t) => ['Resolved', 'Closed', 'BillProcessed'].contains(t.status))
            .toList();
      }
      return tickets;
    });
  }

  // New method to get tickets with customer data (for detail view)
  Future<Map<String, dynamic>?> getTicketWithCustomer(String ticketId) async {
    try {
      final response = await _supabase
          .from('tickets')
          .select('*, customers(*)')
          .eq('id', ticketId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }  

  // Get customer by ID
  @override
  Future<Map<String, dynamic>?> getCustomer(String customerId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('id', customerId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<List<Ticket>> getTicketsByStatuses(List<String> statuses) {
    if (statuses.isEmpty) return getTickets(statusFilter: null);

    return _realtimeStream(
      supabase: _supabase,
      table: 'tickets',
      channelSuffix: 'byStatuses_${statuses.join('_')}',
      fetcher: () => _supabase
          .from('tickets')
          .select()
          .inFilter('status', statuses)
          .order('created_at', ascending: false),
    ).map((list) => list.map(Ticket.fromJson).toList());
  }

  @override
  Future<Either<Failure, Ticket>> createTicket(Ticket ticket) async {
    try {
      final data = ticket.toJson();
      final id = data['id'];
      if (id is String && id.isEmpty) {
        data.remove('id');
      }

      // Remove UI-only fields that might not be in the database yet
      data.remove('bill_amount');
      data.remove('billing_procedure');
      data.remove('payment_collected');

      print('=== Supabase Insert Ticket Payload ===');
      print(data);

      final response = await _supabase
          .from('tickets')
          .insert(data)
          .select()
          .single();
      return Right(Ticket.fromJson(response));
    } catch (e, stackTrace) {
      print('=== Supabase Insert Ticket Error ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      appLogger.error(
        'Failed to create ticket',
        error: e,
        stackTrace: stackTrace,
        context: {
          'ticketId': ticket.ticketId,
          'customerId': ticket.customerId,
          'priority': ticket.priority,
        },
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTicketStatus(
    String ticketId,
    String status,
  ) async {
    try {
      // First verify the ticket exists and get current status
      final ticketExists = await _supabase
          .from('tickets')
          .select('id, status')
          .eq('id', ticketId)
          .maybeSingle();

      if (ticketExists == null) {
        appLogger.error(
          'Ticket not found for status update',
          context: {'ticketId': ticketId, 'status': status},
        );
        return Left(ServerFailure('Ticket not found'));
      }

      final previousStatus = ticketExists['status'] as String?;

      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (status == 'Resolved' || status == 'Closed' || status == 'BillRaised' || status == 'BillProcessed') {
        updateData['completed_at'] = DateTime.now().toUtc().toIso8601String();
      }

      // Perform the update and get the updated row in one call
      // Using .select() ensures we get an error if the update fails
      final updatedRow = await _supabase
          .from('tickets')
          .update(updateData)
          .eq('id', ticketId)
          .select('status')
          .single();

      // Verify the update actually persisted
      final updatedStatus = updatedRow['status'] as String?;
      if (updatedStatus != status) {
        appLogger.error(
          'Ticket status update verification failed',
          context: {
            'ticketId': ticketId,
            'expectedStatus': status,
            'actualStatus': updatedStatus,
          },
        );
        return Left(
          ServerFailure('Status update did not persist. Please try again.'),
        );
      }

      appLogger.info(
        'Ticket status updated successfully',
        context: {'ticketId': ticketId, 'from': previousStatus, 'to': status},
      );

      return const Right(unit);
    } on PostgrestException catch (e, stackTrace) {
      appLogger.error(
        'Postgrest error updating ticket status',
        error: e,
        stackTrace: stackTrace,
        context: {
          'ticketId': ticketId,
          'status': status,
          'code': e.code,
          'message': e.message,
        },
      );
      // If it's a permission error, provide a more helpful message
      if (e.code == 'PGRST116' || e.message.contains('permission denied')) {
        return Left(
          ServerFailure(
            'Permission denied. Please check RLS policies for tickets table.',
          ),
        );
      }
      return Left(ServerFailure(e.message));
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update ticket status',
        error: e,
        stackTrace: stackTrace,
        context: {'ticketId': ticketId, 'status': status},
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateTicket(Ticket ticket) async {
    try {
      final data = {
        'title': ticket.title,
        'description': ticket.description,
        'category': ticket.category,
        'priority': ticket.priority,
        'contact_phone': ticket.contactPhone,
        'payment_collected': ticket.paymentCollected,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('tickets').update(data).eq('id', ticket.ticketId);

      appLogger.info(
        'Ticket updated successfully',
        context: {'ticketId': ticket.ticketId},
      );

      return const Right(unit);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to update ticket',
        error: e,
        stackTrace: stackTrace,
        context: {'ticketId': ticket.ticketId},
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> assignTicket(
    String ticketId,
    String agentId, {
    required String assignedBy,
    String? note,
  }) async {
    try {
      await _supabase.rpc(
        'append_ticket_assignment',
        params: {
          'p_ticket_id': ticketId,
          'p_to': agentId,
          'p_assigned_by': assignedBy,
          'p_note': note,
        },
      );

      final updated = await _supabase
          .from('tickets')
          .select('assigned_to')
          .eq('id', ticketId)
          .single();

      final assignedTo = updated['assigned_to'] as String?;
      if (assignedTo != agentId) {
        appLogger.error(
          'Ticket assignment verification failed',
          context: {
            'ticketId': ticketId,
            'expectedAssignedTo': agentId,
            'actualAssignedTo': assignedTo,
          },
        );
        return Left(
          ServerFailure('Assignment did not persist. Please try again.'),
        );
      }

      return const Right(unit);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to assign ticket to agent',
        error: e,
        stackTrace: stackTrace,
        context: {
          'ticketId': ticketId,
          'agentId': agentId,
          'assignedBy': assignedBy,
        },
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAgents() async {
    try {
      final response = await _supabase
          .from('agents')
          .select('id, username, full_name, role, display_color, last_seen, avatar_url')
          .order('username');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getAgent(String agentId) async {
    try {
      final response = await _supabase
          .from('agents')
          .select('id, username, full_name, role')
          .eq('id', agentId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<Map<String, int>> getTicketStats() {
    return _realtimeStream(
      supabase: _supabase,
      table: 'tickets',
      channelSuffix: 'stats',
      fetcher: () => _supabase.from('tickets').select('status'),
    ).map((list) {
      final stats = <String, int>{'Open': 0, 'In Progress': 0, 'Resolved': 0};
      for (var map in list) {
        final status = map['status'] as String? ?? 'New';
        if (['New', 'Open', 'Waiting for Customer'].contains(status)) {
          stats['Open'] = (stats['Open'] ?? 0) + 1;
        } else if (status == 'In Progress') {
          stats['In Progress'] = (stats['In Progress'] ?? 0) + 1;
        } else if (['Resolved', 'Closed'].contains(status)) {
          stats['Resolved'] = (stats['Resolved'] ?? 0) + 1;
        }
      }
      return stats;
    });
  }

  @override
  Stream<List<TicketComment>> getComments(String ticketId) {
    return _realtimeStream(
      supabase: _supabase,
      table: 'ticket_comments',
      channelSuffix: 'ticket_$ticketId',
      fetcher: () => _supabase
          .from('ticket_comments')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true),
    ).map((list) => list.map((map) => TicketComment.fromJson(map)).toList());
  }

  @override
  Future<Either<Failure, Unit>> addComment({
    required String ticketId,
    required String author,
    required String body,
    required bool isInternal,
  }) async {
    try {
      await _supabase.from('ticket_comments').insert({
        'ticket_id': ticketId,
        'author': author,
        'body': body,
        'internal': isInternal,
      });
      return const Right(unit);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to add ticket comment',
        error: e,
        stackTrace: stackTrace,
        context: {
          'ticketId': ticketId,
          'author': author,
          'isInternal': isInternal,
        },
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> resolveAndBillTicket(
    String ticketId,
    double amount,
  ) async {
    try {
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      final updatedRow = await _supabase
          .from('tickets')
          .update({
            'status': 'BillRaised',
            'bill_amount': amount,
            'completed_at': nowUtc,
            'updated_at': nowUtc,
          })
          .eq('id', ticketId)
          .select('status, bill_amount')
          .single();

      // Verify
      final status = updatedRow['status'] as String?;
      final billed = (updatedRow['bill_amount'] as num?)?.toDouble();

      if (status != 'BillRaised' || billed != amount) {
        return Left(ServerFailure('Update verification failed'));
      }

      return const Right(unit);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to resolve and bill ticket',
        error: e,
        stackTrace: stackTrace,
        context: {'ticketId': ticketId, 'amount': amount},
      );
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTickets(List<String> ticketIds) async {
    if (ticketIds.isEmpty) {
      return const Right(unit);
    }

    try {
      await _supabase.from('tickets').delete().inFilter('id', ticketIds);
      return const Right(unit);
    } catch (e, stackTrace) {
      appLogger.error(
        'Failed to delete tickets',
        error: e,
        stackTrace: stackTrace,
        context: {'ticketIds': ticketIds},
      );
      return Left(ServerFailure(e.toString()));
    }
  }
}

