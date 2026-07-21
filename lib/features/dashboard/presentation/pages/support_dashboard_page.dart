import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/presentation/widgets/tickets_table_view.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../widgets/animated_create_ticket_fab.dart';
import '../widgets/create_ticket_dialog.dart';

class SupportDashboardPage extends ConsumerStatefulWidget {
  const SupportDashboardPage({super.key});

  @override
  ConsumerState<SupportDashboardPage> createState() => _SupportDashboardPageState();
}

class _SupportDashboardPageState extends ConsumerState<SupportDashboardPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  // Restricted agents check
  static const _allowedAroundTallyChannelIds = {
    'd7a9e726-9520-4cc8-95a6-b38a4afd1d7b',
    'dedce60a-56bd-49fd-bbe2-f88534b8e36f',
  };
  bool get _isRestrictedAgent {
    final currentUser = ref.read(authProvider);
    return _allowedAroundTallyChannelIds.contains(currentUser?.id ?? '');
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  List<Ticket> _filterTicketsByDateRange(List<Ticket> tickets) {
    if (_startDate == null || _endDate == null) {
      return tickets;
    }

    // Normalize dates to start and end of day
    final startOfDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);

    return tickets.where((ticket) {
      final ticketDate = ticket.createdAt ?? DateTime(1970);
      return ticketDate.isAfter(startOfDay.subtract(const Duration(days: 1))) &&
          ticketDate.isBefore(endOfDay.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _showCreateTicketDialog() async {
    print('=== Show Create Ticket Dialog ===');
    final createdTicket = await showDialog<Ticket>(
      context: context,
      builder: (context) => const CreateTicketDialog(
        isSupport: true,
        postToChat: false,
      ),
    );

    print('Dialog returned ticket: ${createdTicket != null}');
    if (createdTicket == null) {
      print('Ticket creation was cancelled or failed');
      return;
    }

    print('Ticket ID: ${createdTicket.ticketId}');
    await _sendCreatedTicketMessage(createdTicket);
    ref.invalidate(chatStreamProvider('support-chat'));
    ref.invalidate(chatUnreadCountProvider);
  }

  Future<void> _sendCreatedTicketMessage(Ticket ticket) async {
    print('=== Support Dashboard Chat Post ===');
    final agent = ref.read(authProvider);
    print('Agent: ${agent?.fullName}');
    if (agent == null) {
      print('Agent is null, skipping chat post');
      return;
    }

    // Get customer name from customer ID
    final customersAsync = ref.read(customersListProvider);
    String companyName = 'Unknown Company';
    
    if (customersAsync.hasValue) {
      final customers = customersAsync.value ?? [];
      try {
        final customer = customers.firstWhere(
          (c) => c.id == ticket.customerId,
        );
        companyName = customer.companyName;
      } catch (e) {
        // Customer not found, keep default company name
      }
    }

    final chatContent = [
      'Company: $companyName',
      'Issue: ${ticket.title}',
      'TicketID: ${ticket.ticketId}',
    ].join('\n');
    print('Chat content: $chatContent');

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            senderId: agent.id,
            senderName: agent.fullName,
            senderRole: agent.role,
            content: chatContent,
            senderAvatarUrl: agent.avatarUrl,
          );
      print('Chat message sent successfully');
    } catch (e) {
      print('Error sending chat message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final currentUser = ref.watch(authProvider);

    return MainLayout(
      currentPath: '/support',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: AnimatedCreateTicketFab(
          onPressed: _showCreateTicketDialog,
        ),
        body: ticketsAsync.when(
          data: (allTickets) {
            final myTickets =
                allTickets.where((t) => t.assignedTo == currentUser?.id).toList();
            final unclaimedTickets =
                allTickets
                    .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
                    .toList()
                  ..sort(
                    (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    ),
                  );

            final resolvedStatuses = {'Resolved', 'Closed', 'BillProcessed'};
            final myInProgress =
                myTickets.where((t) => t.status == 'In Progress').length;
            final myResolvedToday = myTickets.where((t) {
              final today = DateTime.now();
              final updatedAt = t.updatedAt ?? DateTime(1970);
              return resolvedStatuses.contains(t.status) &&
                  updatedAt.year == today.year &&
                  updatedAt.month == today.month &&
                  updatedAt.day == today.day;
            }).length;

            final now = DateTime.now();
            final mySlaWarnings = myTickets.where((t) {
              if (resolvedStatuses.contains(t.status)) return false;
              final slaDue = t.slaDue;
              if (slaDue == null) return false;
              return slaDue.difference(now).inMinutes <= 60;
            }).length;

            final queueStats = [
              _QueueStat(
                label: 'Unclaimed',
                subtitle: 'Waiting claim',
                icon: LucideIcons.inbox,
                count: unclaimedTickets.length,
                color: AppColors.warning,
                route: '/tickets?view=unclaimed',
              ),
              _QueueStat(
                label: 'My Tickets',
                subtitle: 'Assigned to me',
                icon: LucideIcons.userCheck,
                count: myTickets.length,
                color: AppColors.primary,
                route: '/tickets?view=assigned',
              ),
              _QueueStat(
                label: 'In Progress',
                subtitle: 'Currently active',
                icon: LucideIcons.playCircle,
                count: myInProgress,
                color: AppColors.info,
                route: '/tickets?view=in_progress',
              ),
              _QueueStat(
                label: 'Resolved Today',
                subtitle: 'Closed today',
                icon: LucideIcons.checkCircle2,
                count: myResolvedToday,
                color: AppColors.success,
                route: '/tickets?view=resolved',
              ),
              _QueueStat(
                label: 'Response Alerts',
                subtitle: 'Near SLA',
                icon: LucideIcons.alertTriangle,
                count: mySlaWarnings,
                color: AppColors.error,
                route: '/tickets?view=alerts',
              ),
            ];

            // Combine all tickets into a single list
            final allCombinedTickets = _filterTicketsByDateRange(
              allTickets
                ..sort((a, b) =>
                    (b.updatedAt ?? b.createdAt ?? DateTime(0))
                        .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(0))),
            );

            return Column(
              children: [
                // Top stats row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 700;
                    final actions = _buildTopActions(context, ref);

                    return Container(
                      color: context.adaptiveCard,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                WelcomeHeader(
                                  name: currentUser?.username ?? 'Support',
                                  subtitle: 'Your support dashboard and ticket queue',
                                ),
                                const SizedBox(height: 12),
                                actions,
                                const SizedBox(height: 12),
                                _QueueStatTiles(stats: queueStats),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: WelcomeHeader(
                                    name: currentUser?.username ?? 'Support',
                                    subtitle: 'Your support dashboard and ticket queue',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 4,
                                  child: _QueueStatTiles(stats: queueStats),
                                ),
                                const SizedBox(width: 8),
                                actions,
                              ],
                            ),
                    );
                  },
                ),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                // Single Table View
                Expanded(
                  child: FocusScope(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TicketsTableView(
                        tickets: allCombinedTickets,
                        showAllTickets: true,
                        showOnlyMine: false,
                        showOnlyUnclaimed: false,
                        groupResolved: false,
                        isUnclaimedTab: false,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Error loading dashboard: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopActions(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              icon: const Icon(LucideIcons.calendar, size: 14),
              label: Text(
                _startDate != null && _endDate != null
                    ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                    : 'Filter Date',
                style: const TextStyle(fontSize: 11),
              ),
              onPressed: _selectDateRange,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
              ),
            ),
            if (_startDate != null && _endDate != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: _clearDateFilter,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
              ),
          ],
        ),
        if (!_isRestrictedAgent)
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.hourglass, size: 14),
            label: const Text('Unclaimed > 1h', style: TextStyle(fontSize: 11)),
            onPressed: () => context.push('/tickets?view=stale_unclaimed'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
            ),
          ),
        if (!_isRestrictedAgent)
          OutlinedButton.icon(
            icon: const Icon(LucideIcons.alertTriangle, size: 14),
            label: const Text('Claimed > 12h', style: TextStyle(fontSize: 11)),
            onPressed: () => context.push('/tickets?view=claimed_overdue'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () => ref.invalidate(rawTicketsStreamProvider),
          tooltip: 'Refresh',
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
        ),
      ],
    );
  }

}

class _QueueStat {
  final String label;
  final String subtitle;
  final IconData icon;
  final int count;
  final Color color;
  final String? route;

  const _QueueStat({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.count,
    required this.color,
    this.route,
  });
}

class _QueueStatTiles extends StatelessWidget {
  final List<_QueueStat> stats;

  const _QueueStatTiles({required this.stats});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stats
            .map((stat) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _QueueStatTile(stat: stat),
            ))
            .toList(growable: false),
      ),
    );
  }
}

class _QueueStatTile extends StatelessWidget {
  final _QueueStat stat;

  const _QueueStatTile({required this.stat});

  @override
  Widget build(BuildContext context) {
    final tile = SizedBox(
      width: 140,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: context.adaptiveCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: stat.color.withValues(alpha: 0.15),
                  child: Icon(stat.icon, size: 18, color: stat.color),
                ),
                const SizedBox(height: 8),
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleSmall?.color ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.subtitle,
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color ?? Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            Text(
              '${stat.count}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.titleLarge?.color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );

    if (stat.route == null) return tile;

    return InkWell(
      onTap: () => context.push(stat.route!),
      child: tile,
    );
  }
}
