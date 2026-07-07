import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/animated_create_ticket_fab.dart';
import '../../../dashboard/presentation/widgets/create_ticket_dialog.dart';

/// Converts a DateTime to local time for display
DateTime _toLocalTime(DateTime dateTime) {
  if (dateTime.isUtc) {
    return dateTime.toLocal();
  }
  return dateTime;
}

class SalesDashboardPage extends ConsumerWidget {
  final String currentPath;
  
  const SalesDashboardPage({super.key, this.currentPath = '/sales'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      currentPath: currentPath,
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
        body: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(rawAllTicketsStreamProvider);
            ref.invalidate(customersListProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                _WelcomeHeader(userName: currentUser?.username ?? 'Sales'),
                
                // Stats Cards
                ticketsAsync.when(
                  data: (allTickets) {
                    final myTickets = currentUser == null
                        ? <Ticket>[]
                        : allTickets.where((t) => t.createdBy == currentUser.id).toList();
                    final pending = myTickets.where((t) => 
                        !['resolved', 'closed'].contains(t.status.toLowerCase())).length;
                    final resolved = myTickets.where((t) => 
                        ['resolved', 'closed'].contains(t.status.toLowerCase())).length;
                    final unassigned = myTickets.where((t) => 
                        t.assignedTo == null || t.assignedTo!.isEmpty).length;
                    
                    return _StatsSection(
                      totalRaised: myTickets.length,
                      pending: pending,
                      resolved: resolved,
                      unassigned: unassigned,
                    );
                  },
                  loading: () => const _StatsSection(
                    totalRaised: 0,
                    pending: 0,
                    resolved: 0,
                    unassigned: 0,
                    isLoading: true,
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                
                const SizedBox(height: 24),
                
                // Recent Tickets Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Recent Tickets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/tickets'),
                        icon: const Text('View All'),
                        label: const Icon(LucideIcons.arrowRight, size: 16),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Tickets List
                ticketsAsync.when(
                  data: (allTickets) {
                    return customersAsync.when(
                      data: (customers) {
                        final customersById = {for (final c in customers) c.id: c};
                        final myTickets = currentUser == null
                            ? <Ticket>[]
                            : allTickets.where((t) => t.createdBy == currentUser.id).toList()
                          ..sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
                        
                        if (myTickets.isEmpty) {
                          return _EmptyTicketsCard();
                        }
                        
                        // Show only recent 5 tickets
                        final recentTickets = myTickets.take(5).toList();
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: recentTickets.map((ticket) {
                              final customer = customersById[ticket.customerId];
                              final assignedAgent = _getAssignedAgent(ticket, agentsById, isAgentsLoading);
                              
                              return _TicketCard(
                                ticket: ticket,
                                customerName: customer?.companyName ?? 'Unknown Customer',
                                assignedAgent: assignedAgent,
                                isAmc: customer?.isAmcActive ?? false,
                              );
                            }).toList(),
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Center(child: Text('Error: $err')),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  String _getAssignedAgent(Ticket ticket, Map<String, Map<String, dynamic>> agentsById, bool isLoading) {
    final id = ticket.assignedTo;
    if (id == null || id.isEmpty) return 'Waiting for assignment';
    final agent = agentsById[id];
    if (agent == null) return isLoading ? 'Loading...' : 'Assigned';
    return (agent['full_name'] ?? agent['username'] ?? 'Assigned').toString();
  }
}

class _WelcomeHeader extends StatelessWidget {
  final String userName;
  
  const _WelcomeHeader({required this.userName});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = LucideIcons.sun;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = LucideIcons.sunMedium;
    } else {
      greeting = 'Good Evening';
      greetingIcon = LucideIcons.moon;
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(greetingIcon, color: Colors.white.withValues(alpha: 0.9), size: 20),
                const SizedBox(width: 8),
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              userName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Here\'s your ticket overview for today',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int totalRaised;
  final int pending;
  final int resolved;
  final int unassigned;
  final bool isLoading;

  const _StatsSection({
    required this.totalRaised,
    required this.pending,
    required this.resolved,
    required this.unassigned,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: LucideIcons.ticket,
              label: 'Total Raised',
              value: totalRaised.toString(),
              color: AppColors.primary,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: LucideIcons.clock,
              label: 'Pending',
              value: pending.toString(),
              color: AppColors.warning,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: LucideIcons.checkCircle,
              label: 'Resolved',
              value: resolved.toString(),
              color: AppColors.success,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: LucideIcons.userX,
              label: 'Unassigned',
              value: unassigned.toString(),
              color: AppColors.error,
              isLoading: isLoading,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isLoading;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(4),
              ),
            )
          else
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
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
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
                              margin: const EdgeInsets.only(left: 8),
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
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(LucideIcons.building2, size: 13, color: AppColors.slate400),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              customerName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.slate600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(LucideIcons.userCheck, size: 13, color: AppColors.slate400),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              assignedAgent,
                              style: TextStyle(
                                fontSize: 12,
                                color: assignedAgent.contains('Waiting') 
                                    ? AppColors.warning 
                                    : AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Right side - status and time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        ticket.status,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('dd MMM, hh:mm a').format(createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate400,
                        ),
                      ),
                    ],
                  ],
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
}

class _EmptyTicketsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.ticket,
                size: 40,
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
            const Text(
              'Create your first ticket using the + button',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.slate500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
