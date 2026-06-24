import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'ticket_remarks_provider.g.dart';

// Stream of remarks for a ticket — realtime (INSERT + UPDATE + DELETE)
@riverpod
Stream<List<Map<String, dynamic>>> ticketRemarks(Ref ref, String ticketId) {
  final supabase = Supabase.instance.client;
  final controller = StreamController<List<Map<String, dynamic>>>.broadcast();

  Future<void> fetch() async {
    try {
      final data = await supabase
          .from('ticket_remarks')
          .select()
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: false);
      if (!controller.isClosed) controller.add(List<Map<String, dynamic>>.from(data));
    } catch (e) {
      if (!controller.isClosed) controller.addError(e);
    }
  }

  fetch();

  final channel = supabase
      .channel('realtime_ticket_remarks_$ticketId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'ticket_remarks',
        callback: (_) => fetch(),
      )
      .subscribe();

  controller.onCancel = () => supabase.removeChannel(channel);
  return controller.stream;
}

// Add remark to ticket
@riverpod
class TicketRemarksAdder extends _$TicketRemarksAdder {
  @override
  bool build() => false;

  Future<bool> addRemark({
    required String ticketId,
    required String agentId,
    required String remark,
    String? stage,
  }) async {
    if (!ref.mounted) return false;
    state = true;
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('ticket_remarks').insert({
        'ticket_id': ticketId,
        'agent_id': agentId,
        'remark': remark,
        'remark_type': 'text',
        'stage': stage,
      });

      if (ref.mounted) {
        ref.invalidate(ticketRemarksProvider(ticketId));
      }
      // Insert succeeded - update state only if still mounted
      if (ref.mounted) {
        state = false;
      }
      return true; // Return true since insert succeeded
    } catch (e) {
      if (ref.mounted) {
        state = false;
      }
      return false;
    }
  }
}
