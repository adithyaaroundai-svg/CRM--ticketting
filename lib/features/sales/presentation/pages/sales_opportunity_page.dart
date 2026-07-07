import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/create_ticket_dialog.dart';
import '../../../dashboard/presentation/widgets/animated_create_ticket_fab.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Converts a DateTime to local time for display
DateTime _toLocalTime(DateTime dateTime) {
  if (!dateTime.isUtc) return dateTime;
  return dateTime.toLocal();
}

class SalesOpportunityPage extends ConsumerStatefulWidget {
  const SalesOpportunityPage({super.key});

  @override
  ConsumerState<SalesOpportunityPage> createState() => _SalesOpportunityPageState();
}

class _SalesOpportunityPageState extends ConsumerState<SalesOpportunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(allTicketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);
    final currentUser = ref.watch(authProvider);
    final agentsAsync = ref.watch(agentsListProvider);
    final agentsById = {
      for (final agent in agentsAsync.asData?.value ?? const <Map<String, dynamic>>[])
        if ((agent['id'] ?? '').toString().isNotEmpty)
          (agent['id'] as String): agent,
    };
    final isAgentsLoading = agentsAsync.isLoading;

    return MainLayout(
      currentPath: '/sales-opportunity',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        floatingActionButton: AnimatedCreateTicketFab(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const CreateTicketDialog(isSupport: false),
            );
          },
        ),
        body: Column(
          children: [
            // Header with welcome and stats
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${currentUser?.username ?? 'Sales'}!',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Manage your tickets and track their progress',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Quick Stats
                  ticketsAsync.when(
                    data: (allTickets) {
                      final myTickets = currentUser == null
                          ? <Ticket>[]
                          : allTickets.where((t) => t.createdBy == currentUser.id).toList();
                      final pending = myTickets.where((t) => 
                          t.status.toLowerCase() != 'resolved' && 
                          t.status.toLowerCase() != 'closed').length;
                      final resolved = myTickets.where((t) => 
                          t.status.toLowerCase() == 'resolved' || 
                          t.status.toLowerCase() == 'closed').length;
                      
                      return Row(
                        children: [
                          _QuickStatCard(
                            icon: LucideIcons.ticket,
                            label: 'Total Raised',
                            value: myTickets.length.toString(),
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          _QuickStatCard(
                            icon: LucideIcons.clock,
                            label: 'Pending',
                            value: pending.toString(),
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 16),
                          _QuickStatCard(
                            icon: LucideIcons.checkCircle,
                            label: 'Resolved',
                            value: resolved.toString(),
                            color: AppColors.success,
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            
            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.slate500,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(LucideIcons.fileText, size: 18),
                    text: 'My Tickets',
                  ),
                  Tab(
                    icon: Icon(LucideIcons.inbox, size: 18),
                    text: 'Unclaimed Tickets',
                  ),
                ],
              ),
            ),
            
            // Tab Content
            Expanded(
              child: ticketsAsync.when(
                data: (allTickets) {
                  final unclaimedTickets = allTickets
                      .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
                      .toList()
                    ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

                  final myTickets = currentUser == null
                      ? const <Ticket>[]
                      : allTickets.where((t) => t.createdBy == currentUser.id).toList()
                    ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));

                  return customersAsync.when(
                    data: (customers) {
                      final customersById = {for (final c in customers) c.id: c};

                      return TabBarView(
                        controller: _tabController,
                        children: [
                          // My Tickets Tab
                          _MyTicketsView(
                            tickets: myTickets,
                            customersById: customersById,
                            agentsById: agentsById,
                            isAgentsLoading: isAgentsLoading,
                          ),
                          // Unclaimed Tickets Tab
                          _UnclaimedTicketsView(
                            tickets: unclaimedTickets,
                            customersById: customersById,
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: color,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.slate600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyTicketsView extends StatelessWidget {
  final List<Ticket> tickets;
  final Map<String, Customer> customersById;
  final Map<String, Map<String, dynamic>> agentsById;
  final bool isAgentsLoading;

  const _MyTicketsView({
    required this.tickets,
    required this.customersById,
    required this.agentsById,
    required this.isAgentsLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.ticket,
                size: 48,
                color: AppColors.slate400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tickets yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to create your first ticket',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final customer = customersById[ticket.customerId];
        final assignedAgent = _getAssignedAgent(ticket);
        
        return _TicketCard(
          ticket: ticket,
          customerName: customer?.companyName ?? 'Unknown Customer',
          assignedAgent: assignedAgent,
          isAmc: customer?.isAmcActive ?? false,
        );
      },
    );
  }

  String _getAssignedAgent(Ticket ticket) {
    final id = ticket.assignedTo;
    if (id == null || id.isEmpty) return 'Waiting for assignment';
    final agent = agentsById[id];
    if (agent == null) return isAgentsLoading ? 'Loading...' : 'Assigned';
    return (agent['full_name'] ?? agent['username'] ?? 'Assigned').toString();
  }
}

/// User-friendly ticket card for sales view
class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final String customerName;
  final String assignedAgent;
  final bool isAmc;

  const _TicketCard({
    required this.ticket,
    required this.customerName,
    required this.assignedAgent,
    required this.isAmc,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);
    final createdAt = ticket.createdAt != null 
        ? _toLocalTime(ticket.createdAt!) 
        : null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/ticket/${ticket.ticketId}'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with title and status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(LucideIcons.building2, size: 14, color: AppColors.slate400),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  customerName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.slate600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isAmc) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.info,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'AMC',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        ticket.status,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Info row
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Priority
                      _InfoChip(
                        icon: LucideIcons.flag,
                        label: ticket.priority ?? 'Medium',
                        color: priorityColor,
                      ),
                      const SizedBox(width: 16),
                      // Assigned
                      Expanded(
                        child: _InfoChip(
                          icon: LucideIcons.userCheck,
                          label: assignedAgent,
                          color: assignedAgent.contains('Waiting') 
                              ? AppColors.warning 
                              : AppColors.success,
                        ),
                      ),
                      // Time
                      if (createdAt != null) ...[
                        const SizedBox(width: 16),
                        _InfoChip(
                          icon: LucideIcons.clock,
                          label: DateFormat('dd MMM, hh:mm a').format(createdAt),
                          color: AppColors.slate500,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
      case 'open':
        return AppColors.info;
      case 'in progress':
      case 'inprogress':
        return AppColors.warning;
      case 'resolved':
      case 'closed':
        return AppColors.success;
      default:
        return AppColors.slate500;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return Colors.orange;
      case 'low':
        return AppColors.slate400;
      default:
        return AppColors.info;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Unclaimed tickets view with simple card layout
class _UnclaimedTicketsView extends StatelessWidget {
  final List<Ticket> tickets;
  final Map<String, Customer> customersById;

  const _UnclaimedTicketsView({
    required this.tickets,
    required this.customersById,
  });

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.checkCircle,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'All tickets are claimed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great work - no pending tickets',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final customer = customersById[ticket.customerId];
        
        return _UnclaimedTicketCard(
          ticket: ticket,
          customerName: customer?.companyName ?? 'Unknown Customer',
          isAmc: customer?.isAmcActive ?? false,
        );
      },
    );
  }
}

class _UnclaimedTicketCard extends StatelessWidget {
  final Ticket ticket;
  final String customerName;
  final bool isAmc;

  const _UnclaimedTicketCard({
    required this.ticket,
    required this.customerName,
    required this.isAmc,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = ticket.createdAt != null 
        ? _toLocalTime(ticket.createdAt!) 
        : null;
    final priorityColor = _getPriorityColor(ticket.priority);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAmc ? AppColors.info.withValues(alpha: 0.5) : AppColors.border,
          width: isAmc ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/ticket/${ticket.ticketId}'),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ticket.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAmc)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.info,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(LucideIcons.sparkles, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'AMC Priority',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(LucideIcons.building2, size: 14, color: AppColors.slate400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              customerName,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.slate600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (createdAt != null) ...[
                            Icon(LucideIcons.clock, size: 14, color: AppColors.slate400),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Arrow
                Icon(
                  LucideIcons.chevronRight,
                  size: 20,
                  color: AppColors.slate400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return AppColors.error;
      case 'high':
        return Colors.orange;
      case 'low':
        return AppColors.slate400;
      default:
        return AppColors.info;
    }
  }
}

