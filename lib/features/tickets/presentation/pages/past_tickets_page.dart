import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/ticket_provider.dart';
import '../../../dashboard/presentation/widgets/ticket_card_with_amc.dart';
import '../../domain/entities/ticket.dart';

class PastTicketsPage extends ConsumerStatefulWidget {
  const PastTicketsPage({super.key});

  @override
  ConsumerState<PastTicketsPage> createState() => _PastTicketsPageState();
}

class _PastTicketsPageState extends ConsumerState<PastTicketsPage> {
  static const _closedStatuses = {
    'resolved',
    'closed',
    'billprocessed',
  };

  final Set<String> _dismissedTicketIds = <String>{};
  static const _storageKey = 'past_tickets_dismissed_ids';

  @override
  void initState() {
    super.initState();
    _loadDismissedTickets();
  }

  Future<void> _loadDismissedTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? <String>[];
    setState(() {
      _dismissedTicketIds
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _persistDismissedTickets() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _dismissedTicketIds.toList());
  }

  String _normalizeStatus(String? status) => status?.trim().toLowerCase() ?? '';

  void _dismissTicket(Ticket ticket) {
    setState(() {
      _dismissedTicketIds.add(ticket.ticketId);
    });
    _persistDismissedTickets();
  }

  Future<void> _clearAllTickets(List<Ticket> tickets) async {
    setState(() {
      _dismissedTicketIds.addAll(tickets.map((t) => t.ticketId));
    });
    await _persistDismissedTickets();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsStreamProvider);
    final currentUser = ref.watch(authProvider);

    return MainLayout(
      currentPath: '/past-tickets',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: SafeArea(
          child: ticketsAsync.when(
            data: (tickets) {
              final closedTickets = tickets
                  .where(
                    (ticket) => _closedStatuses.contains(
                      _normalizeStatus(ticket.status),
                    ),
                  )
                  .where((ticket) => !_dismissedTicketIds.contains(ticket.ticketId))
                  .toList()
                ..sort(
                  (a, b) => (b.updatedAt ?? b.createdAt ?? DateTime(0))
                      .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(0)),
                );

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft),
                          tooltip: 'Back to dashboard',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.slate700,
                          ),
                          onPressed: () {
                            if (currentUser?.isAdmin == true) {
                              context.go('/admin');
                            } else if (currentUser?.isAccountant == true) {
                              context.go('/accountant');
                            } else if (currentUser?.isSupport == true || currentUser?.isHR == true || currentUser?.isProjectCoordinator == true) {
                              context.go('/support');
                            } else {
                              context.go('/');
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Past Tickets',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Reference archive of closed and resolved tickets',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (closedTickets.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          AppButton.ghost(
                            label: 'Clear all',
                            icon: LucideIcons.trash2,
                            onPressed: () => _clearAllTickets(closedTickets),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (closedTickets.isEmpty)
                      const EmptyStateCard(
                        icon: LucideIcons.archive,
                        title: 'No past tickets yet',
                        subtitle:
                            'Closed and resolved tickets will appear here for future reference.',
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: closedTickets.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ticket = closedTickets[index];
                          return Stack(
                            children: [
                              TicketCardWithAmc(ticket: ticket),
                              Positioned(
                                right: 16,
                                bottom: 16,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: IconButton(
                                    tooltip: 'Remove from Past Tickets',
                                    iconSize: 20,
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => _dismissTicket(ticket),
                                    icon: const Icon(
                                      LucideIcons.trash2,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (err, _) => Center(
              child: Text(
                'Failed to load past tickets: $err',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
