import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/design_system/design_system.dart';
import '../../domain/entities/customer.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../providers/customer_provider.dart';

class CustomerHistoryPage extends ConsumerWidget {
  final String customerId;

  const CustomerHistoryPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final agentsAsync = ref.watch(agentsListProvider);

    return MainLayout(
      currentPath: '/customer/$customerId/history',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          titleSpacing: 24,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.push('/customer/$customerId'),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.slate100,
              foregroundColor: AppColors.slate700,
            ),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Billing status, tickets, support context',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: customerAsync.when(
            data: (customer) {
              if (customer == null) {
                return const _ErrorNotice('Customer not found');
              }

              return ticketsAsync.when(
                data: (tickets) {
                  final agentNames = agentsAsync.maybeWhen(
                    data: (agents) => {
                      for (final agent in agents)
                        if (agent['id'] != null)
                          agent['id'] as String:
                              (agent['full_name'] as String?) ??
                                  (agent['username'] as String?) ??
                                  'Agent',
                    },
                    orElse: () => <String, String>{},
                  );

                  final customerTickets = tickets
                      .where((t) => t.customerId == customer.id)
                      .toList()
                    ..sort(
                      (a, b) => (b.createdAt ?? DateTime(0))
                          .compareTo(a.createdAt ?? DateTime(0)),
                    );

                  if (customerTickets.isEmpty) {
                    return const _EmptyHistory();
                  }

                  return ListView(
                    children: [
                      _HeaderSummary(customer: customer),
                      const SizedBox(height: 10),
                      _SummaryRow(tickets: customerTickets),
                      const SizedBox(height: 10),
                      _BillingStatusCard(tickets: customerTickets),
                      const SizedBox(height: 10),
                      _RecentAgentsSection(
                        tickets: customerTickets,
                        agentNames: agentNames,
                      ),
                      const SizedBox(height: 10),
                      _RecentTicketsSection(
                        tickets: customerTickets,
                        agentNames: agentNames,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _ErrorNotice('Failed to load history: $err'),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => _ErrorNotice('Error: $err'),
          ),
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  final String message;

  const _ErrorNotice(this.message);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.error),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(LucideIcons.history, size: 48, color: AppColors.slate300),
        SizedBox(height: 12),
        Text(
          'No ticket history yet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.slate700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'We will show ticket and billing details as soon as support work starts for this customer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.slate500),
        ),
      ],
    );
  }
}

class _HeaderSummary extends StatelessWidget {
  final Customer customer;

  const _HeaderSummary({required this.customer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate200),
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
                      customer.companyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.contactPerson ?? 'No contact person',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(
                    label: customer.isAmcActive ? 'AMC active' : 'AMC expired',
                    color: customer.isAmcActive
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(height: 6),
                  _StatusChip(
                    label: customer.isTssActive ? 'TSS active' : 'TSS expired',
                    color: customer.isTssActive
                        ? AppColors.primary
                        : AppColors.slate400,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (customer.primaryPhone != null)
                _InfoChip(
                  icon: LucideIcons.phone,
                  label: customer.primaryPhone!,
                ),
              if ((customer.contactEmail ?? '').isNotEmpty)
                _InfoChip(
                  icon: LucideIcons.mail,
                  label: customer.contactEmail!,
                ),
              _InfoChip(
                icon: LucideIcons.calendar,
                label: customer.amcExpiryDate != null
                    ? 'AMC till ${DateFormat('d MMM y').format(customer.amcExpiryDate!)}'
                    : 'AMC not set',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final List<Ticket> tickets;

  const _SummaryRow({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final openStatuses = {
      'New',
      'Open',
      'InProgress',
      'OnHold',
      'WaitingForCustomer',
      'Reopened',
    };
    final openCount =
        tickets.where((t) => openStatuses.contains(t.status)).length;
    final paidCount = tickets
        .where((t) => t.status == 'BillProcessed' || t.status == 'Closed')
        .length;
    final pendingBills = tickets.where((t) => t.status == 'BillRaised').length;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total tickets',
            value: tickets.length.toString(),
            icon: LucideIcons.ticket,
            iconColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Open / Pending',
            value: openCount.toString(),
            icon: LucideIcons.clock3,
            iconColor: AppColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            label: 'Bills pending',
            value: pendingBills.toString(),
            icon: LucideIcons.receipt,
            iconColor: pendingBills == 0 ? AppColors.success : AppColors.error,
            subtitle:
                pendingBills == 0 ? 'All paid' : '$paidCount paid so far',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate100),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slate500,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.slate600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BillingStatusCard extends StatelessWidget {
  final List<Ticket> tickets;

  const _BillingStatusCard({required this.tickets});

  @override
  Widget build(BuildContext context) {
    final pendingBills =
        tickets.where((ticket) => ticket.status == 'BillRaised').toList();
    final paidBills = tickets
        .where((ticket) =>
            ticket.status == 'BillProcessed' || ticket.status == 'Closed')
        .toList();

    final bool hasPending = pendingBills.isNotEmpty;
    final bool hasPaid = paidBills.isNotEmpty;

    final color = hasPending
        ? AppColors.error
        : hasPaid
            ? AppColors.success
            : AppColors.info;
    final bgColor = color.withValues(alpha: 0.12);

    String statusText;
    if (hasPending) {
      statusText = '${pendingBills.length} bill(s) waiting for payment';
    } else if (hasPaid) {
      statusText = 'All raised bills are settled';
    } else {
      statusText = 'No bills raised yet';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: bgColor,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.wallet, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Billing status',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (hasPending)
                  Text(
                    'Follow up with accounts to collect payment.',
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAgentsSection extends StatelessWidget {
  final List<Ticket> tickets;
  final Map<String, String> agentNames;

  const _RecentAgentsSection({
    required this.tickets,
    required this.agentNames,
  });

  @override
  Widget build(BuildContext context) {
    final handlers = LinkedHashSet<String>();
    for (final ticket in tickets) {
      final assignedId = ticket.assignedTo;
      if (assignedId == null || assignedId.isEmpty) continue;
      final display = agentNames[assignedId] ?? assignedId;
      handlers.add(display);
      if (handlers.length >= 6) break;
    }

    if (handlers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(LucideIcons.users, size: 16, color: AppColors.slate500),
            SizedBox(width: 8),
            Text(
              'Support agents involved',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: handlers
              .map(
                (name) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.slate100,
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate700,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _RecentTicketsSection extends StatelessWidget {
  final List<Ticket> tickets;
  final Map<String, String> agentNames;

  const _RecentTicketsSection({
    required this.tickets,
    required this.agentNames,
  });

  @override
  Widget build(BuildContext context) {
    final recent = tickets.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(LucideIcons.listChecks, size: 16, color: AppColors.slate500),
            SizedBox(width: 8),
            Text(
              'Recent tickets',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.slate800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recent.map((ticket) => _TicketCard(
              ticket: ticket,
              agentName: _resolveAgentName(ticket, agentNames),
            )),
      ],
    );
  }

  String _resolveAgentName(Ticket ticket, Map<String, String> agentNames) {
    final assignedId = ticket.assignedTo;
    if (assignedId == null || assignedId.isEmpty) return 'Unassigned';
    return agentNames[assignedId] ?? assignedId;
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final String agentName;

  const _TicketCard({required this.ticket, required this.agentName});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('d MMM, h:mm a');
    final createdLabel = ticket.createdAt != null
        ? dateFormatter.format(ticket.createdAt!.toLocal())
        : 'Unknown date';
    final billingLabel = _billingLabel(ticket);
    final billingColor = _billingColor(ticket);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.slate100),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
              ),
              _StatusChip(
                label: _formatStatus(ticket.status),
                color: _statusColor(ticket.status),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.hash, size: 13, color: AppColors.slate400),
              const SizedBox(width: 6),
              Text(
                ticket.ticketId,
                style: const TextStyle(fontSize: 11, color: AppColors.slate600),
              ),
              const Spacer(),
              Icon(LucideIcons.calendar, size: 13, color: AppColors.slate400),
              const SizedBox(width: 6),
              Text(
                createdLabel,
                style: const TextStyle(fontSize: 11, color: AppColors.slate600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.userCheck, size: 13, color: AppColors.slate400),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Handled by $agentName',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(LucideIcons.wallet, size: 13, color: billingColor),
              const SizedBox(width: 6),
              Text(
                billingLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: billingColor,
                ),
              ),
              if (ticket.billAmount != null) ...[
                const SizedBox(width: 6),
                Text(
                  '₹${ticket.billAmount!.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11, color: billingColor),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _formatStatus(String status) {
    return status.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'Closed':
      case 'Resolved':
      case 'BillProcessed':
        return AppColors.success;
      case 'InProgress':
      case 'Open':
      case 'Reopened':
        return AppColors.primary;
      case 'WaitingForCustomer':
      case 'OnHold':
        return AppColors.warning;
      case 'BillRaised':
        return AppColors.warning;
      default:
        return AppColors.slate500;
    }
  }

  static String _billingLabel(Ticket ticket) {
    switch (ticket.status) {
      case 'BillRaised':
        return 'Bill raised · awaiting payment';
      case 'BillProcessed':
      case 'Closed':
        return 'Bill paid';
      default:
        return 'Bill not raised yet';
    }
  }

  static Color _billingColor(Ticket ticket) {
    switch (ticket.status) {
      case 'BillRaised':
        return AppColors.warning;
      case 'BillProcessed':
      case 'Closed':
        return AppColors.success;
      default:
        return AppColors.slate500;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
