import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/ticket_provider.dart';
import '../../domain/entities/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../../core/design_system/theme/app_colors.dart';

class TicketsTableView extends ConsumerStatefulWidget {
  final List<Ticket> tickets;
  final bool showAllTickets;
  final bool showOnlyMine;
  final bool showOnlyUnclaimed;
  final bool groupResolved;
  final bool isUnclaimedTab;

  const TicketsTableView({
    super.key,
    required this.tickets,
    this.showAllTickets = false,
    this.showOnlyMine = false,
    this.showOnlyUnclaimed = false,
    this.groupResolved = false,
    this.isUnclaimedTab = false,
  });

  @override
  ConsumerState<TicketsTableView> createState() => _TicketsTableViewState();
}

class _TicketsTableViewState extends ConsumerState<TicketsTableView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final agentsAsync = ref.watch(agentsListProvider);
    final customersAsync = ref.watch(customersListProvider);

    // Group tickets by date
    final groupedTickets = _groupTicketsByDate(widget.tickets);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        thickness: 8,
        radius: const Radius.circular(4),
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
          width: 1600,
          child: Column(
            children: [
              // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Name of Customer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Contact No.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Claimed by',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Task',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Bill Amount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Payment Collected',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Completed Date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
                SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Reported Date',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Content
          Expanded(
            child: groupedTickets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.inbox,
                          size: 48,
                          color: AppColors.slate300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No tickets found',
                          style: TextStyle(
                            color: AppColors.slate500,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : customersAsync.when(
                    data: (customers) {
                      return agentsAsync.when(
                        data: (agents) {
                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: groupedTickets.length,
                            itemBuilder: (context, index) {
                              final group = groupedTickets[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Date Header
                                  if (group['date'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      color: AppColors.slate50,
                                      child: Text(
                                        group['date'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate600,
                                        ),
                                      ),
                                    ),
                                  // Tickets for this date
                                  ...group['tickets'].map<Widget>((ticket) {
                                    return TicketTableRow(
                                      ticket: ticket,
                                      currentUser: currentUser,
                                      agents: agents,
                                      customers: customers,
                                      isUnclaimedTab: widget.isUnclaimedTab,
                                    );
                                  }).toList(),
                                ],
                              );
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(
                          child: Text(
                            'Error loading agents: $error',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Text(
                        'Error loading customers: $error',
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ),
          ),
        ],
      ),
        ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupTicketsByDate(List<Ticket> tickets) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final thisWeek = today.subtract(const Duration(days: 7));
    final lastWeek = today.subtract(const Duration(days: 14));
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final Map<String, List<Ticket>> groups = {};

    for (final ticket in tickets) {
      final dateToUse = ticket.createdAt ?? ticket.updatedAt ?? DateTime.now();
      
      final ticketDate = DateTime(
        dateToUse.year,
        dateToUse.month,
        dateToUse.day,
      );

      String dateGroup;
      if (ticketDate.isAtSameMomentAs(today)) {
        dateGroup = 'Today';
      } else if (ticketDate.isAtSameMomentAs(yesterday)) {
        dateGroup = 'Yesterday';
      } else if (ticketDate.isAfter(thisWeek)) {
        dateGroup = 'This Week';
      } else if (ticketDate.isAfter(lastWeek)) {
        dateGroup = 'Last Week';
      } else if (ticketDate.isAfter(thisMonth)) {
        dateGroup = 'This Month';
      } else if (ticketDate.isAfter(lastMonth)) {
        dateGroup = 'Last Month';
      } else {
        dateGroup = 'Older';
      }

      groups.putIfAbsent(dateGroup, () => []).add(ticket);
    }

    // Sort groups by date (most recent first)
    final sortedGroupKeys = [
      'Today',
      'Yesterday',
      'This Week',
      'Last Week',
      'This Month',
      'Last Month',
      'Older'
    ];

    final result = <Map<String, dynamic>>[];
    for (final key in sortedGroupKeys) {
      if (groups.containsKey(key)) {
        final groupTickets = groups[key]!;
        // Sort tickets within each group by creation time (newest first)
        groupTickets.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        result.add({
          'date': key,
          'tickets': groupTickets,
        });
      }
    }

    return result;
  }
}

class TicketTableRow extends ConsumerWidget {
  final Ticket ticket;
  final dynamic currentUser;
  final List<dynamic> agents;
  final List<dynamic> customers;
  final bool isUnclaimedTab;

  const TicketTableRow({
    super.key,
    required this.ticket,
    required this.currentUser,
    required this.agents,
    required this.customers,
    this.isUnclaimedTab = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // agents is List<Map<String, dynamic>> (raw from Supabase)
    Map<String, dynamic>? assignedAgentMap;
    if (ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty) {
      for (final a in agents) {
        final map = a as Map<String, dynamic>;
        if (map['id'] == ticket.assignedTo) {
          assignedAgentMap = map;
          break;
        }
      }
    }
    final assignedAgentName = assignedAgentMap != null
        ? ((assignedAgentMap['full_name'] ?? assignedAgentMap['username']) ?? 'Unknown Agent')
            .toString()
        : 'Unassigned';

    // customers is List<Customer> (typed objects)
    dynamic customer;
    for (final c in customers) {
      if (c.id == ticket.customerId) {
        customer = c;
        break;
      }
    }
    final customerName =
        customer != null ? (customer.companyName ?? 'Unknown Customer') : 'Unknown Customer';


    return InkWell(
      onTap: () => context.push('/ticket/${ticket.ticketId}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status
            Expanded(
              flex: 2,
              child: _buildStatusChip(ticket.status, isUnclaimedTab, ticket.assignedTo != null),
            ),
            const SizedBox(width: 32),
            // Customer Name
            Expanded(
              flex: 2,
              child: Text(
                customerName,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate800,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 32),
            // Contact Number
            Expanded(
              flex: 2,
              child: Text(
                ticket.contactPhone ?? 'N/A',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 32),
            // Allocated to
            Expanded(
              flex: 2,
              child: Text(
                assignedAgentName,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate600,
                  fontWeight: ticket.assignedTo != null ? FontWeight.w500 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 32),
            // Task (Title)
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  ticket.title,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Billing Procedure
            Expanded(
              flex: 2,
              child: Text(
                (ticket.billAmount != null && ticket.billAmount! > 0)
                    ? '₹ ${ticket.billAmount!.toStringAsFixed(2)}'
                    : '',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 32),
            // Payment collected
            Expanded(
              flex: 1,
              child: currentUser?.isAccountant == true
                  ? DropdownButton<bool>(
                      value: ticket.paymentCollected ?? false,
                      items: const [
                        DropdownMenuItem(value: false, child: Text('No')),
                        DropdownMenuItem(value: true, child: Text('Yes')),
                      ],
                      selectedItemBuilder: (BuildContext context) {
                        return [
                          Text(
                            'No',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.slate600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ];
                      },
                      onChanged: (val) async {
                        if (val != null && val != ticket.paymentCollected) {
                          final updated = ticket.copyWith(paymentCollected: val);
                          await ref.read(ticketUpdaterProvider.notifier).updateTicket(updated);
                        }
                      },
                      isDense: true,
                      underline: const SizedBox(),
                      iconSize: 20,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.slate700,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : Text(
                      (ticket.paymentCollected ?? false) ? 'Yes' : 'No',
                      style: TextStyle(
                        fontSize: 13,
                        color: (ticket.paymentCollected ?? false) ? Colors.green : AppColors.slate600,
                        fontWeight: (ticket.paymentCollected ?? false) ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
            ),
            const SizedBox(width: 32),
            // Completed Date
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(LucideIcons.calendarDays, size: 14, color: AppColors.slate400),
                  const SizedBox(width: 4),
                  Text(
                    () {
                      // Use completedDate (completed_at) if available
                      if (ticket.completedDate != null) {
                        return DateFormat('dd/MM/yyyy').format(ticket.completedDate!.toLocal());
                      }
                      // For resolved/closed/billed tickets without completed_at, fall back to updatedAt
                      const resolvedStatuses = {'Resolved', 'Closed', 'BillRaised', 'BillProcessed'};
                      if (resolvedStatuses.contains(ticket.status) && ticket.updatedAt != null) {
                        return DateFormat('dd/MM/yyyy').format(ticket.updatedAt!.toLocal());
                      }
                      return '';
                    }(),
                    style: TextStyle(fontSize: 13, color: AppColors.slate600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            // Reported Date
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Icon(LucideIcons.calendarDays, size: 14, color: AppColors.slate400),
                  const SizedBox(width: 4),
                  Text(
                    ticket.createdAt != null ? DateFormat('dd/MM/yyyy').format(ticket.createdAt!) : '',
                    style: TextStyle(fontSize: 13, color: AppColors.slate600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isUnclaimedTab, bool isClaimed) {
    Color textColor;
    String displayText;

    switch (status.toLowerCase()) {
      case 'new':
        // If the ticket is claimed (has assignedTo), show "In Progress"
        // Otherwise show "Unclaimed"
        if (isClaimed) {
          textColor = const Color(0xFFEA580C);
          displayText = 'In Progress';
        } else {
          textColor = const Color(0xFFDC2626);
          displayText = 'Unclaimed';
        }
        break;
      case 'open':
        textColor = const Color(0xFF1E40AF);
        displayText = 'Open';
        break;
      case 'inprogress':
      case 'in_progress':
        textColor = const Color(0xFFEA580C);
        displayText = 'In Progress';
        break;
      case 'resolved':
        textColor = const Color(0xFF16A34A);
        displayText = 'Resolved';
        break;
      case 'closed':
        textColor = AppColors.slate600;
        displayText = 'Closed';
        break;
      case 'onhold':
      case 'on_hold':
        textColor = const Color(0xFFD97706);
        displayText = 'On Hold';
        break;
      case 'waitingforcustomer':
      case 'waiting_for_customer':
        textColor = AppColors.slate600;
        displayText = 'Waiting';
        break;
      case 'billraised':
      case 'bill_raised':
        textColor = const Color(0xFFDC2626);
        displayText = 'Bill Raised';
        break;
      case 'billprocessed':
      case 'bill_processed':
        textColor = const Color(0xFF059669);
        displayText = 'Billed';
        break;
      default:
        textColor = AppColors.slate600;
        displayText = status;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
