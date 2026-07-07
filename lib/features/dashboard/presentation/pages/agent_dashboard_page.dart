import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/design_system.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../widgets/create_ticket_dialog.dart';
import '../widgets/animated_create_ticket_fab.dart';

class AgentDashboardPage extends ConsumerStatefulWidget {
  final String currentPath;
  const AgentDashboardPage({super.key, this.currentPath = '/'});

  @override
  ConsumerState<AgentDashboardPage> createState() => _AgentDashboardPageState();
}

class _AgentDashboardPageState extends ConsumerState<AgentDashboardPage> {
  // Restricted agents check
  static const _allowedAroundTallyChannelIds = {
    'd7a9e726-9520-4cc8-95a6-b38a4afd1d7b',
    'dedce60a-56bd-49fd-bbe2-f88534b8e36f',
  };
  bool get _isRestrictedAgent {
    final currentUser = ref.read(authProvider);
    return _allowedAroundTallyChannelIds.contains(currentUser?.id ?? '');
  }

  Future<void> _showCreateTicketDialog() async {
    final createdTicket = await showDialog<Ticket>(
      context: context,
      builder: (context) => const CreateTicketDialog(
        isSupport: true,
        postToChat: false,
      ),
    );

    if (createdTicket == null) return;

    await _sendCreatedTicketMessage(createdTicket);
    ref.invalidate(chatStreamProvider('support-chat'));
    ref.invalidate(chatUnreadCountProvider);
  }

  Future<void> _sendCreatedTicketMessage(Ticket ticket) async {
    final agent = ref.read(authProvider);
    if (agent == null) return;

    // Get customer name from customer ID
    final customersAsync = ref.read(customersListProvider);
    String companyName = ticket.customerId;
    
    if (customersAsync.hasValue) {
      final customers = customersAsync.value ?? [];
      try {
        final customer = customers.firstWhere((c) => c.id == ticket.customerId);
        companyName = customer.companyName;
      } catch (e) {
        // Customer not found, keep default
      }
    }

    final chatContent = [
      'Company: $companyName',
      'Issue: ${ticket.title}',
      'TicketID: ${ticket.ticketId}',
    ].join('\n');

    await ref.read(chatRepositoryProvider).sendMessage(
          senderId: agent.id,
          senderName: agent.fullName,
          senderRole: agent.role,
          content: chatContent,
          senderAvatarUrl: agent.avatarUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return MainLayout(
      currentPath: widget.currentPath,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        floatingActionButton: AnimatedCreateTicketFab(
          onPressed: _showCreateTicketDialog,
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: WelcomeHeader(
                name: user?.username ?? 'Agent',
                subtitle: "Here's what's happening today",
                trailing: Builder(
                  builder: (context) {
                    final isWide = MediaQuery.of(context).size.width >= 600;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: isWide ? WrapAlignment.end : WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!_isRestrictedAgent) ...[
                          OutlinedButton.icon(
                            icon: const Icon(LucideIcons.hourglass, size: 16),
                            label: const Text('Unclaimed > 1h'),
                            onPressed: () => context.push('/tickets?view=stale_unclaimed'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(LucideIcons.alertTriangle, size: 16),
                            label: const Text('Claimed > 12h'),
                            onPressed: () => context.push('/tickets?view=claimed_overdue'),
                          ),
                        ],
                        TextButton.icon(
                          onPressed: () {
                            ref.invalidate(rawTicketsStreamProvider);
                            ref.invalidate(customersListProvider);
                          },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Refresh',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/tickets?view=unclaimed'),
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text(
                            'View All Unclaimed',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Tickets List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ticketsAsync.when(
                  data: (tickets) {
                    final customersAsync = ref.watch(customersListProvider);

                    return customersAsync.when(
                      data: (customers) {
                        final customerMap = {for (var c in customers) c.id: c};
                        final today = DateTime.now();

                        // Filter unclaimed tickets
                        final allUnclaimed = tickets
                            .where((t) {
                              final isClosed = ['Resolved', 'Closed'].contains(t.status);
                              final hasAssignee = t.assignedTo != null && t.assignedTo!.isNotEmpty;
                              return !isClosed && !hasAssignee;
                            })
                            .toList();

                        // Today's unclaimed tickets
                        final todayUnclaimed = allUnclaimed
                            .where((t) {
                              final createdDate = (t.createdAt ?? DateTime(1970)).toLocal();
                              return createdDate.year == today.year &&
                                  createdDate.month == today.month &&
                                  createdDate.day == today.day;
                            })
                            .toList()
                          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                                a.createdAt ?? DateTime(0),
                              ));

                        final canClaim = user?.isSupportHead == true ||
                            user?.isSupport == true ||
                            user?.isAgent == true;

                        return _UnclaimedTicketsListView(
                          tickets: todayUnclaimed,
                          customerMap: customerMap,
                          title: "Today's Unclaimed",
                          canClaim: canClaim,
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          Center(child: Text('Error loading customers: $err')),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnclaimedTicketsListView extends ConsumerWidget {
  final List<dynamic> tickets;
  final Map<String, dynamic> customerMap;
  final String title;
  final bool canClaim;

  const _UnclaimedTicketsListView({
    required this.tickets,
    required this.customerMap,
    required this.title,
    required this.canClaim,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: AppColors.sidebarGradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.calendar, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                "$title (${tickets.length})",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // List Content
        Expanded(
          child: _buildTicketsList(context, ref),
        ),
      ],
    );
  }

  Widget _buildTicketsList(BuildContext context, WidgetRef ref) {
    if (tickets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.checkCircle,
              size: 48,
              color: AppColors.slate300,
            ),
            const SizedBox(height: 16),
            Text(
              'No unclaimed tickets',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final customer = customerMap[ticket.customerId];
        final isAmc = customer?.isAmcActive ?? false;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.push('/ticket/${ticket.ticketId}'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    customer?.companyName ?? 'Unknown Customer',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAmc)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.info,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.info.withValues(alpha: 0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'AMC',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Footer Row
                  Row(
                    children: [
                      Text(
                        isAmc ? 'AMC Priority' : 'Standard Ticket',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(ticket.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                  if (canClaim) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.userCheck, size: 16),
                        label: const Text('Claim ticket'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.info,
                          side: BorderSide(
                            color: AppColors.info.withValues(alpha: 0.6),
                          ),
                        ),
                        onPressed: () {
                          final currentUser = ref.read(authProvider);
                          if (currentUser == null) return;

                          ref
                              .read(ticketAssignerProvider.notifier)
                              .assignTicket(ticket.ticketId, currentUser.id);

                          context.push('/ticket/${ticket.ticketId}');
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final localTime = _toLocalTime(date);
    return DateFormat('dd MMM yyyy • hh:mm a').format(localTime);
  }
}

/// Normalises timestamps for display by converting any UTC values to local time.
DateTime _toLocalTime(DateTime dateTime) {
  if (dateTime.isUtc) {
    return dateTime.toLocal();
  }

  return dateTime;
}
