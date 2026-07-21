import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' as fr;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../../data/repositories/supabase_ticket_repository.dart';
import '../../domain/entities/ticket.dart';

part 'ticket_provider.g.dart';

// ── Realtime stream helper (same pattern as supabase_ticket_repository) ───────
Stream<List<Map<String, dynamic>>> _realtimeQuery({
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

  fetch();

  final channel = supabase
      .channel('tp_realtime_${table}_$channelSuffix')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => fetch(),
      )
      .subscribe();

  controller.onCancel = () => supabase.removeChannel(channel);
  return controller.stream;
}

// Repository provider
@riverpod
TicketRepository ticketRepository(Ref ref) {
  return SupabaseTicketRepository(Supabase.instance.client);
}

class TicketAlertEntry {
  final Ticket ticket;
  final DateTime referenceTime;
  final Duration elapsed;
  final Duration threshold;

  const TicketAlertEntry({
    required this.ticket,
    required this.referenceTime,
    required this.elapsed,
    required this.threshold,
  });

  Duration get overdue => elapsed - threshold;
}

const _claimedOverdueThreshold = Duration(hours: 12);
const _unclaimedOverdueThreshold = Duration(hours: 1);

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String) {
    final normalized = (value.endsWith('Z') || value.contains('+'))
        ? value
        : '${value}Z';
    return DateTime.tryParse(normalized)?.toUtc();
  }
  return null;
}

DateTime? _extractLastAssignmentAt(dynamic rawHistory) {
  if (rawHistory is List && rawHistory.isNotEmpty) {
    for (final entry in rawHistory.reversed) {
      if (entry is Map && entry['assigned_at'] != null) {
        final ts = _parseDate(entry['assigned_at']);
        if (ts != null) {
          return ts;
        }
      }
    }
  }
  return null;
}

bool _isResolvedOrBilled(String? status) {
  if (status == null) return false;
  final normalized = status.trim().toLowerCase();
  return const {
    'resolved',
    'closed',
    'billprocessed',
    'billraised',
  }.contains(normalized);
}

final overdueClaimedTicketsProvider =
    fr.StreamProvider<List<TicketAlertEntry>>((ref) {
  final supabase = Supabase.instance.client;
  final currentUser = ref.watch(authProvider);
  return _realtimeQuery(
    supabase: supabase,
    table: 'tickets',
    channelSuffix: 'overdue_claimed',
    fetcher: () => supabase
        .from('tickets')
        .select()
        .order('updated_at', ascending: false),
  ).map((rows) {
    final now = DateTime.now().toUtc();
    final entries = <TicketAlertEntry>[];
    for (final raw in rows) {
      final assignedTo = raw['assigned_to'];
      if (assignedTo == null || assignedTo.toString().isEmpty) continue;
      if (currentUser == null || assignedTo.toString() != currentUser.id) continue;
      final status = raw['status']?.toString();
      if (_isResolvedOrBilled(status)) continue;
      final assignmentAt = _extractLastAssignmentAt(raw['assignment_history']) ??
          _parseDate(raw['updated_at']) ??
          _parseDate(raw['created_at']);
      if (assignmentAt == null) continue;
      final elapsed = now.difference(assignmentAt);
      if (elapsed >= _claimedOverdueThreshold) {
        entries.add(TicketAlertEntry(
          ticket: Ticket.fromJson(Map<String, dynamic>.from(raw)),
          referenceTime: assignmentAt,
          elapsed: elapsed,
          threshold: _claimedOverdueThreshold,
        ));
      }
    }
    entries.sort((a, b) => b.elapsed.compareTo(a.elapsed));
    return entries;
  });
});

final staleUnclaimedTicketsProvider =
    fr.StreamProvider<List<TicketAlertEntry>>((ref) {
  final supabase = Supabase.instance.client;
  return _realtimeQuery(
    supabase: supabase,
    table: 'tickets',
    channelSuffix: 'stale_unclaimed',
    fetcher: () => supabase
        .from('tickets')
        .select()
        .order('created_at', ascending: false),
  ).map((rows) {
    final now = DateTime.now().toUtc();
    final entries = <TicketAlertEntry>[];
    for (final raw in rows) {
      final assignedTo = raw['assigned_to'];
      if (assignedTo != null && assignedTo.toString().isNotEmpty) continue;
      final status = raw['status']?.toString();
      if (_isResolvedOrBilled(status)) continue;
      final createdAt = _parseDate(raw['created_at']);
      if (createdAt == null) continue;
      final elapsed = now.difference(createdAt);
      if (elapsed >= _unclaimedOverdueThreshold) {
        entries.add(TicketAlertEntry(
          ticket: Ticket.fromJson(Map<String, dynamic>.from(raw)),
          referenceTime: createdAt,
          elapsed: elapsed,
          threshold: _unclaimedOverdueThreshold,
        ));
      }
    }
    entries.sort((a, b) => b.elapsed.compareTo(a.elapsed));
    return entries;
  });
});

// Filter state provider (null = all, 'Open', 'Closed')
@riverpod
class TicketFilter extends _$TicketFilter {
  @override
  String? build() => null;

  void setFilter(String? filter) {
    state = filter;
  }
}

@riverpod
class TicketSearchQuery extends _$TicketSearchQuery {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

@riverpod
Future<String> debouncedTicketSearchQuery(Ref ref) async {
  final query = ref.watch(ticketSearchQueryProvider);
  var didDispose = false;
  ref.onDispose(() => didDispose = true);
  await Future.delayed(const Duration(milliseconds: 500));
  if (didDispose) throw Exception('Cancelled');
  return query;
}

@Riverpod(keepAlive: true)
class PaginatedTickets extends _$PaginatedTickets {
  StreamSubscription? _eventSub;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  
  @override
  FutureOr<List<Ticket>> build() async {
    final repository = ref.watch(ticketRepositoryProvider);
    final statusFilter = ref.watch(ticketFilterProvider);
    final priorityFilter = ref.watch(ticketPriorityFilterProvider);
    final assigneeFilter = ref.watch(ticketAssigneeFilterProvider);
    final searchQuery = await ref.watch(debouncedTicketSearchQueryProvider.future);
    final currentUser = ref.watch(authProvider);

    // Initial limit: e.g., last 3 days
    final limit = 50;
    final before = DateTime.now().add(const Duration(days: 1)); // Just to ensure we get latest
    
    // We could filter by "created_at >= now - 3 days" but the user said "limit of last 3 day ticekt initally, and when scrolled down load others"
    // Since we order by created_at DESC, if we just use a limit of 50, it gets the latest 50. If we want exactly 3 days, we'd need a date filter, but limit 50 is safer for UI.
    // I will use limit 50, but we can also add a 3 days filter. Let's just use limit 50 which acts like "recent tickets". The prompt said "limit of last 3 day ticekt initally".
    // I will fetch tickets created in the last 3 days, but limit to 50 so it's not huge.
    
    final tickets = await repository.getPaginatedTickets(
      statusFilter: statusFilter,
      priorityFilter: priorityFilter,
      assigneeFilter: assigneeFilter,
      searchQuery: searchQuery,
      currentUserId: currentUser?.id,
      limit: limit,
    );
    
    // Filter to only include tickets from last 3 days initially
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    final initialTickets = tickets.where((t) => t.createdAt != null && t.createdAt!.isAfter(threeDaysAgo)).toList();
    
    // If there are less than 50 in the last 3 days, we might have more. If there are 50, we definitely have more.
    _hasMore = tickets.length == limit;

    // We use the full `tickets` list if the 3 days filter results in too few tickets (e.g. 0), but to strictly follow the prompt we only take the 3 days ones.
    // Actually, just fetching limit=50 is standard pagination. Let's stick to the 3-day filtered list, but if it's empty we still use it.
    
    _eventSub?.cancel();
    _eventSub = repository.ticketEvents.listen(_handleEvent);
    
    ref.onDispose(() {
      _eventSub?.cancel();
    });
    
    return initialTickets.isNotEmpty ? initialTickets : tickets; // fallback if no tickets in 3 days
  }

  void _handleEvent(Map<String, dynamic> event) {
    final eventType = event['eventType'] as String;
    final newRecord = event['newRecord'] as Map<String, dynamic>?;
    final oldRecord = event['oldRecord'] as Map<String, dynamic>?;
    
    if (eventType == 'INSERT' && newRecord != null) {
      final newTicket = Ticket.fromJson(newRecord);
      final currentList = state.value ?? [];
      if (!currentList.any((t) => t.ticketId == newTicket.ticketId)) {
        state = AsyncData([newTicket, ...currentList]);
      }
    } else if (eventType == 'UPDATE' && newRecord != null) {
      final updatedTicket = Ticket.fromJson(newRecord);
      final currentList = state.value ?? [];
      final index = currentList.indexWhere((t) => t.ticketId == updatedTicket.ticketId);
      if (index != -1) {
        final newList = List<Ticket>.from(currentList);
        newList[index] = updatedTicket;
        state = AsyncData(newList);
      }
    } else if (eventType == 'DELETE' && oldRecord != null) {
      final deletedId = oldRecord['ticket_id']; // The DB column is ticket_id
      final currentList = state.value ?? [];
      state = AsyncData(currentList.where((t) => t.ticketId != deletedId).toList());
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    final currentList = state.value ?? [];
    if (currentList.isEmpty) return;

    final oldestTicket = currentList.last; // Since it's sorted newest first
    final repository = ref.read(ticketRepositoryProvider);
    final statusFilter = ref.read(ticketFilterProvider);
    final priorityFilter = ref.read(ticketPriorityFilterProvider);
    final assigneeFilter = ref.read(ticketAssigneeFilterProvider);
    final searchQuery = ref.read(ticketSearchQueryProvider);
    final currentUser = ref.read(authProvider);

    final limit = 50;
    final olderTickets = await repository.getPaginatedTickets(
      statusFilter: statusFilter,
      priorityFilter: priorityFilter,
      assigneeFilter: assigneeFilter,
      searchQuery: searchQuery,
      currentUserId: currentUser?.id,
      before: oldestTicket.createdAt,
      limit: limit,
    );

    if (olderTickets.length < limit) {
      _hasMore = false;
    }
    
    state = AsyncData([...currentList, ...olderTickets]);
  }
}


@riverpod
class TicketPriorityFilter extends _$TicketPriorityFilter {
  @override
  String build() => 'All';

  void setFilter(String value) {
    state = value;
  }
}

@riverpod
class TicketAssigneeFilter extends _$TicketAssigneeFilter {
  @override
  String build() => 'all';

  void setAll() {
    state = 'all';
  }

  void setUnassigned() {
    state = 'unassigned';
  }

  void setMe() {
    state = 'me';
  }

  void setAgent(String agentId) {
    state = 'agent:$agentId';
  }
}

@riverpod
class TicketSort extends _$TicketSort {
  @override
  String build() => 'sla';

  void setSort(String value) {
    state = value;
  }
}

// Optimistic UI overrides (e.g. instant status updates before realtime catches up)
final ticketOptimisticStatusOverridesProvider =
    fr.NotifierProvider<_TicketOptimisticStatusOverrides, Map<String, String>>(
      _TicketOptimisticStatusOverrides.new,
    );

final ticketOptimisticAssigneeOverridesProvider =
    fr.NotifierProvider<
      _TicketOptimisticAssigneeOverrides,
      Map<String, String>
    >(_TicketOptimisticAssigneeOverrides.new);

class _TicketOptimisticStatusOverrides
    extends fr.Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => <String, String>{};

  void setOverride(String ticketId, String status) {
    state = <String, String>{...state, ticketId: status};
  }

  void clearOverride(String ticketId) {
    final next = <String, String>{...state};
    next.remove(ticketId);
    state = next;
  }
}

class _TicketOptimisticAssigneeOverrides
    extends fr.Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => <String, String>{};

  void setOverride(String ticketId, String assigneeId) {
    state = <String, String>{...state, ticketId: assigneeId};
  }

  void clearOverride(String ticketId) {
    final next = <String, String>{...state};
    next.remove(ticketId);
    state = next;
  }
}

// Raw Tickets stream with filtering (status only; search is applied client-side)
@riverpod
Stream<List<Ticket>> rawTicketsStream(Ref ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  final filter = ref.watch(ticketFilterProvider);
  return repository.getTickets(statusFilter: filter);
}

// Tickets stream with filtering
@riverpod
AsyncValue<List<Ticket>> ticketsStream(Ref ref) {
  final rawAsync = ref.watch(rawTicketsStreamProvider);
  final overrides = ref.watch(ticketOptimisticStatusOverridesProvider);
  final assigneeOverrides = ref.watch(
    ticketOptimisticAssigneeOverridesProvider,
  );
  final currentUser = ref.watch(authProvider);

  return rawAsync.whenData((tickets) {
    var result = tickets.map((t) {
      final status = overrides[t.ticketId];
      final assigneeId = assigneeOverrides[t.ticketId];
      if (status == null && assigneeId == null) return t;
      return t.copyWith(
        status: status ?? t.status,
        assignedTo: assigneeId ?? t.assignedTo,
        updatedAt: DateTime.now(),
      );
    }).toList();

    // Tele Caller can only see tickets they created
    if (currentUser?.isTeleCaller == true) {
      result = result
          .where((t) => t.createdBy == currentUser!.id)
          .toList();
    }

    return result;
  });
}

// Unfiltered raw tickets stream
@riverpod
Stream<List<Ticket>> rawAllTicketsStream(Ref ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTickets(statusFilter: null);
}

// Unfiltered tickets stream (for Revenue page etc)
@riverpod
AsyncValue<List<Ticket>> allTicketsStream(Ref ref) {
  final rawAsync = ref.watch(rawAllTicketsStreamProvider);
  final overrides = ref.watch(ticketOptimisticStatusOverridesProvider);
  final assigneeOverrides = ref.watch(
    ticketOptimisticAssigneeOverridesProvider,
  );

  return rawAsync.whenData((tickets) {
    if (overrides.isEmpty && assigneeOverrides.isEmpty) return tickets;
    return tickets.map((t) {
      final status = overrides[t.ticketId];
      final assigneeId = assigneeOverrides[t.ticketId];
      if (status == null && assigneeId == null) return t;
      return t.copyWith(
        status: status ?? t.status,
        assignedTo: assigneeId ?? t.assignedTo,
        updatedAt: DateTime.now(),
      );
    }).toList();
  });
}

// Get customer for a specific ticket (for AMC badge)
@riverpod
Future<Map<String, dynamic>?> ticketCustomer(Ref ref, String customerId) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getCustomer(customerId);
}

// Stream for a single ticket by its UUID
final singleTicketStreamProvider =
    fr.StreamProvider.autoDispose.family<Ticket?, String>((ref, ticketId) {
  final supabase = Supabase.instance.client;
  return _realtimeQuery(
    supabase: supabase,
    table: 'tickets',
    channelSuffix: 'single_$ticketId',
    fetcher: () => supabase
        .from('tickets')
        .select()
        .eq('id', ticketId)
        .limit(1),
  ).map((rows) =>
      rows.isEmpty ? null : Ticket.fromJson(Map<String, dynamic>.from(rows.first)));
});

// Stats stream
@riverpod
Stream<Map<String, int>> ticketStats(Ref ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getTicketStats();
}

// Agents list provider
@riverpod
Future<List<Map<String, dynamic>>> agentsList(Ref ref) async {
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getAgents();
}

// Get assigned agent for a ticket
@riverpod
Future<Map<String, dynamic>?> ticketAssignedAgent(
  Ref ref,
  String? agentId,
) async {
  if (agentId == null || agentId.isEmpty) return null;
  final repository = ref.watch(ticketRepositoryProvider);
  return repository.getAgent(agentId);
}

// Update ticket status
@riverpod
class TicketStatusUpdater extends _$TicketStatusUpdater {
  @override
  bool build() => false;

  Future<String?> updateStatus(String ticketId, String status) async {
    // Keep provider alive during async operation
    final link = ref.keepAlive();

    try {
      if (!ref.mounted) return 'Component not mounted';
      final currentUser = ref.read(authProvider);
      final canProcessBilling = currentUser?.isAccountant == true ||
          currentUser?.isSupport == true ||
          currentUser?.isHR == true ||
          currentUser?.isProjectCoordinator == true ||
          currentUser?.isSupportHead == true;
      final supabase = Supabase.instance.client;
      String? previousStatus;
      try {
        final before = await supabase
            .from('tickets')
            .select('status')
            .eq('id', ticketId)
            .single();
        previousStatus = before['status'] as String?;
      } catch (_) {}

      if (status == 'BillProcessed') {
        if (!canProcessBilling) {
          return 'Only accountants and support heads can mark tickets as billed';
        }
        if (previousStatus != 'Closed') {
          return 'Complete the ticket before billing it';
        }
      }

      if (!ref.mounted) return 'Component not mounted';
      ref
          .read(ticketOptimisticStatusOverridesProvider.notifier)
          .setOverride(ticketId, status);
      final repository = ref.read(ticketRepositoryProvider);
      final result = await repository.updateTicketStatus(ticketId, status);

      if (!ref.mounted) {
        return result.fold((l) => l.message, (r) => null);
      }

      if (result.isRight() && currentUser != null) {
        try {
          await supabase.from('audit_log').insert({
            'ticket_id': ticketId,
            'action': 'ticket_status_changed',
            'performed_by': currentUser.username,
            'payload': {
              'performed_by_id': currentUser.id,
              'performed_by_role': currentUser.role,
              'from': previousStatus,
              'to': status,
            },
          });
        } catch (_) {}
      }

      if (result.isRight() && ref.mounted) {
        ref.invalidate(rawTicketsStreamProvider);
        ref.invalidate(rawAllTicketsStreamProvider);
        ref.invalidate(ticketStatsProvider);
        Timer(const Duration(seconds: 10), () {
          if (!ref.mounted) return;
          ref
              .read(ticketOptimisticStatusOverridesProvider.notifier)
              .clearOverride(ticketId);
        });
        return null;
      } else {
        if (ref.mounted) {
          ref
              .read(ticketOptimisticStatusOverridesProvider.notifier)
              .clearOverride(ticketId);
        }
        return result.fold((l) => l.message, (r) => null);
      }
    } finally {
      link.close();
    }
  }

  Future<bool> resolveAndBill(String ticketId, double amount) async {
    if (!ref.mounted) return false;

    // Optimistic update
    ref
        .read(ticketOptimisticStatusOverridesProvider.notifier)
        .setOverride(ticketId, 'BillRaised');

    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.resolveAndBillTicket(ticketId, amount);

    if (result.isRight() && ref.mounted) {
      ref.invalidate(rawTicketsStreamProvider);
      ref.invalidate(rawAllTicketsStreamProvider);
      ref.invalidate(ticketStatsProvider);
      final currentUser = ref.read(authProvider);
      if (currentUser != null) {
        try {
          await Supabase.instance.client.from('audit_log').insert({
            'ticket_id': ticketId,
            'action': 'ticket_resolved_bill_raised',
            'performed_by': currentUser.username,
            'payload': {'performed_by_id': currentUser.id, 'amount': amount},
          });
        } catch (_) {}
      }

      Timer(const Duration(seconds: 10), () {
        if (!ref.mounted) return;
        ref
            .read(ticketOptimisticStatusOverridesProvider.notifier)
            .clearOverride(ticketId);
      });
    } else if (ref.mounted) {
      ref
          .read(ticketOptimisticStatusOverridesProvider.notifier)
          .clearOverride(ticketId);
    }

    return result.isRight();
  }
}

// Assign ticket to agent
@riverpod
class TicketAssigner extends _$TicketAssigner {
  @override
  bool build() => false;

  Future<bool> assignTicket(String ticketId, String assigneeId) async {
    final link = ref.keepAlive();
    final optimisticAssigneeOverrides = ref.read(
      ticketOptimisticAssigneeOverridesProvider.notifier,
    );
    final repository = ref.read(ticketRepositoryProvider);
    final currentUser = ref.read(authProvider);
    final supabase = Supabase.instance.client;
    try {
      try {
        final before = await supabase
            .from('tickets')
            .select('assigned_to')
            .eq('id', ticketId)
            .single();
        before['assigned_to'] as String?;
      } catch (_) {}

      if (!ref.mounted) return false;
      optimisticAssigneeOverrides.setOverride(ticketId, assigneeId);

      if (currentUser == null) {
        optimisticAssigneeOverrides.clearOverride(ticketId);
        return false;
      }

      final result = await repository.assignTicket(
        ticketId,
        assigneeId,
        assignedBy: currentUser.id,
      );

      if (!ref.mounted) return result.isRight();

      if (result.isRight() && ref.mounted) {
        Timer(const Duration(seconds: 10), () {
          if (!ref.mounted) return;
          optimisticAssigneeOverrides.clearOverride(ticketId);
        });
      } else if (ref.mounted) {
        optimisticAssigneeOverrides.clearOverride(ticketId);
      }
      return result.isRight();
    } finally {
      link.close();
    }
  }
}

final ticketAssignmentHistoryProvider =
    fr.StreamProvider.family<List<Map<String, dynamic>>, String>((ref, ticketId) {
  final supabase = Supabase.instance.client;
  return _realtimeQuery(
    supabase: supabase,
    table: 'tickets',
    channelSuffix: 'assignment_history_$ticketId',
    fetcher: () => supabase
        .from('tickets')
        .select('assignment_history')
        .eq('id', ticketId)
        .limit(1),
  ).map((rows) {
    if (rows.isEmpty) return <Map<String, dynamic>>[];
    final raw = rows.first['assignment_history'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  });
});

final ticketFirstAssignedToProvider = fr.FutureProvider.family<String?, String>(
  (ref, ticketId) async {
    final supabase = Supabase.instance.client;
    try {
      final row = await supabase
          .from('tickets')
          .select('first_assigned_to')
          .eq('id', ticketId)
          .single();
      return row['first_assigned_to'] as String?;
    } catch (_) {
      return null;
    }
  },
);

// Create new ticket
@riverpod
class TicketCreator extends _$TicketCreator {
  @override
  bool build() => false;

  Future<Ticket?> createTicket(Ticket ticket) async {
    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.createTicket(ticket);
    return result.fold((failure) {
      print('=== TicketCreator.createTicket Failed ===');
      print('Failure message: ${failure.message}');
      return null;
    }, (createdTicket) {
      // Immediately refresh ticket streams so Recent Tickets sidebar and Tickets
      // tab update without waiting for the 3-minute periodic timer.
      if (ref.mounted) {
        ref.invalidate(rawTicketsStreamProvider);
        ref.invalidate(rawAllTicketsStreamProvider);
        ref.invalidate(ticketStatsProvider);
      }
      return createdTicket;
    });
  }
}

// Update ticket
@Riverpod(keepAlive: true)
class TicketUpdater extends _$TicketUpdater {
  @override
  bool build() => false;

  Future<String?> updateTicket(Ticket ticket) async {
    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.updateTicket(ticket);

    return result.fold((l) => l.message, (r) {
      ref.invalidate(rawTicketsStreamProvider);
      ref.invalidate(rawAllTicketsStreamProvider);
      return null;
    });
  }
}



