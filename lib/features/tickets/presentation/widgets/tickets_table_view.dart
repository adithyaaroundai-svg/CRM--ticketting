import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/ticket_provider.dart';
import '../../domain/entities/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
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
  String? _addingTicketGroup;
  final TextEditingController _newCustomerController = TextEditingController();
  final TextEditingController _newContactController = TextEditingController();
  final TextEditingController _newTaskController = TextEditingController();
  final TextEditingController _newBillAmountController = TextEditingController();
  String? _newClaimedById;
  String _newStatus = 'Open';
  String _newPaymentCollected = 'No';
  DateTime? _newCompletedDate;
  DateTime? _newReportedDate;

  @override
  void dispose() {
    _scrollController.dispose();
    _newCustomerController.dispose();
    _newContactController.dispose();
    _newTaskController.dispose();
    _newBillAmountController.dispose();
    super.dispose();
  }

  void _startAddingTicket(String groupDateKey) {
    setState(() {
      _addingTicketGroup = groupDateKey;
      _newCustomerController.clear();
      _newContactController.clear();
      _newTaskController.clear();
      _newBillAmountController.clear();
      _newClaimedById = null;
      _newStatus = 'Open';
      _newPaymentCollected = 'No';
      _newCompletedDate = null;
      _newReportedDate = null;
    });
    // Scroll table to the left so the new inline row is fully visible from the first column
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _cancelAddingTicket() {
    setState(() {
      _addingTicketGroup = null;
      _newCustomerController.clear();
      _newContactController.clear();
      _newTaskController.clear();
      _newBillAmountController.clear();
      _newClaimedById = null;
      _newCompletedDate = null;
      _newReportedDate = null;
    });
  }

  Future<void> _saveNewTicket() async {
    final customerName = _newCustomerController.text.trim();
    final contactNumber = _newContactController.text.trim();
    final task = _newTaskController.text.trim();
    final billAmount = _newBillAmountController.text.trim();

    if (customerName.isEmpty || task.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in Customer Name and Task'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      // Create customer if needed
      String customerId;
      final customersAsync = ref.read(customersListProvider);
      final customers = customersAsync.value ?? [];
      final existingCustomer = customers.firstWhere(
        (c) => c.companyName.toLowerCase() == customerName.toLowerCase(),
        orElse: () => const Customer(id: '', companyName: ''),
      );

      if (existingCustomer.id.isNotEmpty) {
        customerId = existingCustomer.id;
        // Update contact number if provided
        if (contactNumber.isNotEmpty) {
          await Supabase.instance.client
              .from('customers')
              .update({'contact_phone': contactNumber})
              .eq('id', customerId);
        }
      } else {
        final newCustomer = await Supabase.instance.client
            .from('customers')
            .insert({
              'company_name': customerName,
              'contact_phone': contactNumber.isEmpty ? null : contactNumber,
            })
            .select()
            .single();
        customerId = newCustomer['id'].toString();
        ref.invalidate(customersListProvider);
      }

      // Create ticket
      final currentUser = ref.read(authProvider);
      final newTicketData = {
        'customer_id': customerId,
        'title': task,
        'status': _newStatus,
        'assigned_to': _newClaimedById,
        'bill_amount': billAmount.isEmpty ? null : double.tryParse(billAmount),
        'payment_collected': _newPaymentCollected == 'Yes',
        'completed_at': _newCompletedDate?.toIso8601String(),
        'created_at': _newReportedDate?.toIso8601String(),
        'created_by': currentUser?.id,
      };

      await Supabase.instance.client.from('tickets').insert(newTicketData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully'), backgroundColor: Colors.green),
        );
        _cancelAddingTicket();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ticket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final agentsAsync = ref.watch(agentsListProvider);
    final customersAsync = ref.watch(customersListProvider);

    // Group tickets by date
    final groupedTickets = _groupTicketsByDate(widget.tickets);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Force desktop table view on mobile as well per user request
        final isMobile = false;

        if (isMobile) {
          return _buildMobileView(
            context,
            groupedTickets,
            currentUser,
            agentsAsync,
            customersAsync,
          );
        }

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
                          // Optimize lookups by creating maps
                          final agentsMap = {for (final a in agents) a['id'].toString(): a};
                          final customersMap = {for (final c in customers) c.id.toString(): c};

                          return ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: groupedTickets.length,
                            itemBuilder: (context, index) {
                              final group = groupedTickets[index];
                              final groupDateKey = '${group['date']}-$index'; // Unique key for each group
                              final isAdding = _addingTicketGroup == groupDateKey;
                              return Padding(
                                padding: EdgeInsets.only(
                                  top: index == 0 ? 0 : 20,
                                  bottom: 4,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Date Header
                                      if (group['date'] != null)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.slate100,
                                            border: Border(
                                              bottom: BorderSide(color: AppColors.border),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                LucideIcons.calendarDays,
                                                size: 13,
                                                color: AppColors.slate500,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                group['date'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.slate700,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${(group['tickets'] as List).length} ticket${(group['tickets'] as List).length == 1 ? '' : 's'}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: AppColors.slate400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Tickets for this date
                                      ...group['tickets'].map<Widget>((ticket) {
                                        return TicketTableRow(
                                          ticket: ticket,
                                          currentUser: currentUser,
                                          agents: agents,
                                          customers: customers,
                                          agentsMap: agentsMap,
                                          customersMap: customersMap,
                                          isUnclaimedTab: widget.isUnclaimedTab,
                                        );
                                      }).toList(),
                                      // Add item button
                                      InkWell(
                                        onTap: isAdding ? null : () => _startAddingTicket(groupDateKey),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              top: BorderSide(color: AppColors.border),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                LucideIcons.plus,
                                                size: 16,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isAdding ? 'Adding new ticket...' : 'Add item',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Inline new ticket row
                                      if (isAdding)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: AppColors.slate50,
                                            border: Border(
                                              top: BorderSide(color: AppColors.border),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Fields row - exact same flex ratios and gaps as table header
                                              Row(
                                                children: [
                                                  // Status dropdown (flex: 2)
                                                  Expanded(
                                                    flex: 2,
                                                    child: DropdownButtonFormField<String>(
                                                      isDense: true,
                                                      isExpanded: true,
                                                      initialValue: _newStatus,
                                                      decoration: const InputDecoration(
                                                        border: OutlineInputBorder(),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                      ),
                                                      items: ['Open', 'In Progress', 'Resolved', 'Closed'].map((s) {
                                                        return DropdownMenuItem(value: s, child: Text(s, style: TextStyle(fontSize: 11)));
                                                      }).toList(),
                                                      onChanged: (v) => setState(() => _newStatus = v ?? 'Open'),
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Customer Name text field (flex: 2)
                                                  Expanded(
                                                    flex: 2,
                                                    child: TextFormField(
                                                      controller: _newCustomerController,
                                                      decoration: const InputDecoration(
                                                        hintText: 'Customer Name',
                                                        border: OutlineInputBorder(),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      ),
                                                      style: TextStyle(fontSize: 11),
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Contact Number text field (flex: 2)
                                                  Expanded(
                                                    flex: 2,
                                                    child: TextFormField(
                                                      controller: _newContactController,
                                                      decoration: const InputDecoration(
                                                        hintText: 'Contact No.',
                                                        border: OutlineInputBorder(),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      ),
                                                      style: TextStyle(fontSize: 11),
                                                      keyboardType: TextInputType.phone,
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Claimed by dropdown (flex: 2)
                                                  Expanded(
                                                    flex: 2,
                                                    child: DropdownButtonFormField<String>(
                                                      isDense: true,
                                                      isExpanded: true,
                                                      initialValue: _newClaimedById,
                                                      decoration: const InputDecoration(
                                                        border: OutlineInputBorder(),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                      ),
                                                      items: agents.map((agent) {
                                                        return DropdownMenuItem(
                                                          value: agent['id']?.toString(),
                                                          child: Text(
                                                            agent['full_name'] ?? agent['username'] ?? '',
                                                            style: TextStyle(fontSize: 11),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        );
                                                      }).toList(),
                                                      selectedItemBuilder: (context) {
                                                        return agents.map((agent) {
                                                          return Text(
                                                            agent['full_name'] ?? agent['username'] ?? '',
                                                            style: TextStyle(fontSize: 11),
                                                            overflow: TextOverflow.ellipsis,
                                                          );
                                                        }).toList();
                                                      },
                                                      onChanged: (v) => setState(() => _newClaimedById = v),
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Task text field (flex: 3)
                                                  Expanded(
                                                    flex: 3,
                                                    child: TextFormField(
                                                      controller: _newTaskController,
                                                      decoration: const InputDecoration(
                                                        hintText: 'Task',
                                                        border: OutlineInputBorder(),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      ),
                                                      style: TextStyle(fontSize: 11),
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Bill Amount text field (flex: 2)
                                                  Expanded(
                                                    flex: 2,
                                                    child: TextFormField(
                                                      controller: _newBillAmountController,
                                                      decoration: const InputDecoration(
                                                        hintText: 'Bill Amount',
                                                        border: OutlineInputBorder(),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      ),
                                                      style: TextStyle(fontSize: 11),
                                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Payment Collected dropdown (flex: 1)
                                                  Expanded(
                                                    flex: 1,
                                                    child: DropdownButtonFormField<String>(
                                                      isDense: true,
                                                      isExpanded: true,
                                                      initialValue: _newPaymentCollected,
                                                      decoration: const InputDecoration(
                                                        border: OutlineInputBorder(),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                      ),
                                                      items: ['Yes', 'No'].map((p) {
                                                        return DropdownMenuItem(value: p, child: Text(p, style: TextStyle(fontSize: 11)));
                                                      }).toList(),
                                                      onChanged: (v) => setState(() => _newPaymentCollected = v ?? 'No'),
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Completed Date (flex: 2)
                                                  Expanded(
                                                    flex: 2,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        final date = await showDatePicker(
                                                          context: context,
                                                          initialDate: DateTime.now(),
                                                          firstDate: DateTime(2020),
                                                          lastDate: DateTime(2030),
                                                        );
                                                        if (date != null) {
                                                          setState(() => _newCompletedDate = date);
                                                        }
                                                      },
                                                      child: InputDecorator(
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                        ),
                                                        child: Text(
                                                          _newCompletedDate == null
                                                              ? 'Completed Date'
                                                              : DateFormat('d/M/yy').format(_newCompletedDate!),
                                                          style: TextStyle(fontSize: 11),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: 32),
                                                  // Reported Date (flex: 2)
                                                  Expanded(
                                                    flex: 2,
                                                    child: InkWell(
                                                      onTap: () async {
                                                        final date = await showDatePicker(
                                                          context: context,
                                                          initialDate: DateTime.now(),
                                                          firstDate: DateTime(2020),
                                                          lastDate: DateTime(2030),
                                                        );
                                                        if (date != null) {
                                                          setState(() => _newReportedDate = date);
                                                        }
                                                      },
                                                      child: InputDecorator(
                                                        decoration: const InputDecoration(
                                                          border: OutlineInputBorder(),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                        ),
                                                        child: Text(
                                                          _newReportedDate == null
                                                              ? 'Reported Date'
                                                              : DateFormat('d/M/yy').format(_newReportedDate!),
                                                          style: TextStyle(fontSize: 11),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              // Save/Cancel buttons row - placed after all column fields
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  ElevatedButton(
                                                    onPressed: _saveNewTicket,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.primary,
                                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    ),
                                                    child: Text('Save', style: TextStyle(fontSize: 12, color: Colors.white)),
                                                  ),
                                                  SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: _cancelAddingTicket,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.grey,
                                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    ),
                                                    child: Text('Cancel', style: TextStyle(fontSize: 12, color: Colors.white)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
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
  },
);
  }

  List<Map<String, dynamic>> _groupTicketsByDate(List<Ticket> tickets) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Group by exact calendar date (yyyy-MM-dd key for sorting)
    final Map<String, List<Ticket>> groups = {};
    final Map<String, DateTime> keyToDate = {};

    for (final ticket in tickets) {
      final dateToUse = (ticket.createdAt ?? ticket.updatedAt ?? DateTime.now()).toLocal();
      final ticketDate = DateTime(dateToUse.year, dateToUse.month, dateToUse.day);
      final sortKey = '${ticketDate.year.toString().padLeft(4, '0')}-${ticketDate.month.toString().padLeft(2, '0')}-${ticketDate.day.toString().padLeft(2, '0')}';

      groups.putIfAbsent(sortKey, () => []).add(ticket);
      keyToDate[sortKey] = ticketDate;
    }

    // Sort keys newest first
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    final result = <Map<String, dynamic>>[];
    for (final key in sortedKeys) {
      final groupTickets = groups[key]!;
      // Sort tickets within each group by creation time (newest first)
      groupTickets.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      final date = keyToDate[key]!;
      String label;
      if (date.isAtSameMomentAs(today)) {
        label = 'Today  ·  ${DateFormat('d MMM yyyy').format(date)}';
      } else if (date.isAtSameMomentAs(yesterday)) {
        label = 'Yesterday  ·  ${DateFormat('d MMM yyyy').format(date)}';
      } else {
        label = DateFormat('d MMM yyyy').format(date);
      }

      result.add({'date': label, 'tickets': groupTickets});
    }

    return result;
  }

  // ignore: unused_element
  Widget _buildMobileView(
    BuildContext context,
    List<Map<String, dynamic>> groupedTickets,
    dynamic currentUser,
    AsyncValue<List<dynamic>> agentsAsync,
    AsyncValue<List<Customer>> customersAsync,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: customersAsync.when(
        data: (customers) {
          return agentsAsync.when(
            data: (agents) {
              final agentsMap = {for (final a in agents) a['id'].toString(): a};
              final customersMap = {for (final c in customers) c.id.toString(): c};
              if (groupedTickets.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.inbox, size: 48, color: AppColors.slate300),
                        const SizedBox(height: 16),
                        Text('No tickets found', style: TextStyle(color: AppColors.slate500, fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                itemCount: groupedTickets.length,
                itemBuilder: (context, index) {
                  final group = groupedTickets[index];
                  final groupDateKey = '${group['date']}-$index';
                  final isAdding = _addingTicketGroup == groupDateKey;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: AppColors.border)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.slate100,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.calendarDays, size: 13, color: AppColors.slate500),
                              const SizedBox(width: 6),
                              Text(
                                group['date'],
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate700),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(group['tickets'] as List).length} ticket${(group['tickets'] as List).length == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                              ),
                            ],
                          ),
                        ),
                        // Tickets
                        ...group['tickets'].map<Widget>((ticket) {
                          return _buildMobileTicketCard(ticket, currentUser, agentsMap, customersMap);
                        }).toList(),
                        // Add item button
                        InkWell(
                          onTap: isAdding ? null : () => _startAddingTicket(groupDateKey),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: AppColors.border)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.plus, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  isAdding ? 'Adding new ticket...' : 'Add item',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isAdding) _buildMobileInlineAddForm(context, agents),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading agents: $error', style: const TextStyle(color: AppColors.error)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error loading customers: $error', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildMobileTicketCard(
    Ticket ticket,
    dynamic currentUser,
    Map<String, dynamic> agentsMap,
    Map<String, Customer> customersMap,
  ) {
    final assignedAgentMap = ticket.assignedTo != null ? agentsMap[ticket.assignedTo.toString()] : null;
    final assignedAgentName = assignedAgentMap != null
        ? ((assignedAgentMap['full_name'] ?? assignedAgentMap['username']) ?? 'Unknown Agent').toString()
        : 'Unassigned';

    final customer = customersMap[ticket.customerId.toString()];
    final customerName = customer != null ? (customer.companyName ?? 'Unknown Customer') : 'Unknown Customer';

    final statusColor = _statusColor(ticket.status);
    final statusText = _statusText(ticket.status, ticket.assignedTo != null);

    return InkWell(
      onTap: () => context.push('/ticket/${ticket.ticketId}'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                ),
                const Spacer(),
                Expanded(
                  child: Text(
                    '#${ticket.ticketId.length > 8 ? ticket.ticketId.substring(0, 8) : ticket.ticketId}',
                    style: TextStyle(fontSize: 11, color: AppColors.slate400),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(customerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate800)),
            const SizedBox(height: 4),
            _mobileInfoRow(LucideIcons.phone, ticket.contactPhone ?? 'N/A'),
            _mobileInfoRow(LucideIcons.user, assignedAgentName),
            _mobileInfoRow(LucideIcons.fileText, ticket.title, isLast: true),
            if (ticket.billAmount != null || (ticket.paymentCollected != null) || ticket.completedDate != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (ticket.billAmount != null)
                    _mobileTag('Bill: ${ticket.billAmount}'),
                  if (ticket.paymentCollected != null)
                    _mobileTag('Paid: ${ticket.paymentCollected == true ? 'Yes' : 'No'}'),
                  if (ticket.completedDate != null)
                    _mobileTag('Completed: ${DateFormat('d/M/yy').format(ticket.completedDate!)}'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mobileInfoRow(IconData icon, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.slate400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, color: AppColors.slate600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, color: AppColors.slate600)),
    );
  }

  Widget _buildMobileInlineAddForm(BuildContext context, List<dynamic> agents) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  initialValue: _newStatus,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  items: ['Open', 'In Progress', 'Resolved', 'Closed'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (v) => setState(() => _newStatus = v ?? 'Open'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  initialValue: _newClaimedById,
                  decoration: const InputDecoration(labelText: 'Claimed by', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  items: agents.map((agent) {
                    return DropdownMenuItem(
                      value: agent['id']?.toString(),
                      child: Text(agent['full_name'] ?? agent['username'] ?? '', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _newClaimedById = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newCustomerController,
            decoration: const InputDecoration(labelText: 'Customer Name', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newContactController,
            decoration: const InputDecoration(labelText: 'Contact No.', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            style: const TextStyle(fontSize: 12),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newTaskController,
            decoration: const InputDecoration(labelText: 'Task', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _newBillAmountController,
                  decoration: const InputDecoration(labelText: 'Bill Amount', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isDense: true,
                  isExpanded: true,
                  initialValue: _newPaymentCollected,
                  decoration: const InputDecoration(labelText: 'Payment', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                  items: ['Yes', 'No'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)));
                  }).toList(),
                  onChanged: (v) => setState(() => _newPaymentCollected = v ?? 'No'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (date != null) setState(() => _newCompletedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Completed Date', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    child: Text(
                      _newCompletedDate == null ? 'Select' : DateFormat('d/M/yy').format(_newCompletedDate!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                    if (date != null) setState(() => _newReportedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Reported Date', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
                    child: Text(
                      _newReportedDate == null ? 'Select' : DateFormat('d/M/yy').format(_newReportedDate!),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveNewTicket,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _cancelAddingTicket,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, padding: const EdgeInsets.symmetric(vertical: 10)),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return const Color(0xFFDC2626);
      case 'open':
        return const Color(0xFF1E40AF);
      case 'inprogress':
      case 'in_progress':
        return const Color(0xFFEA580C);
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'closed':
        return AppColors.slate600;
      case 'onhold':
      case 'on_hold':
        return const Color(0xFFD97706);
      case 'waitingforcustomer':
      case 'waiting_for_customer':
        return AppColors.slate600;
      case 'billraised':
      case 'bill_raised':
        return const Color(0xFFDC2626);
      case 'billprocessed':
      case 'bill_processed':
        return const Color(0xFF059669);
      default:
        return AppColors.slate600;
    }
  }

  String _statusText(String status, bool isClaimed) {
    switch (status.toLowerCase()) {
      case 'new':
        return isClaimed ? 'In Progress' : 'Unclaimed';
      case 'open':
        return 'Open';
      case 'inprogress':
      case 'in_progress':
        return 'In Progress';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      case 'onhold':
      case 'on_hold':
        return 'On Hold';
      case 'waitingforcustomer':
      case 'waiting_for_customer':
        return 'Waiting';
      case 'billraised':
      case 'bill_raised':
        return 'Bill Raised';
      case 'billprocessed':
      case 'bill_processed':
        return 'Billed';
      default:
        return status;
    }
  }
}

class TicketTableRow extends ConsumerStatefulWidget {
  final Ticket ticket;
  final dynamic currentUser;
  final List<dynamic> agents;
  final List<dynamic> customers;
  final Map<String, dynamic> agentsMap;
  final Map<String, Customer> customersMap;
  final bool isUnclaimedTab;

  const TicketTableRow({
    super.key,
    required this.ticket,
    required this.currentUser,
    required this.agents,
    required this.customers,
    required this.agentsMap,
    required this.customersMap,
    this.isUnclaimedTab = false,
  });

  @override
  ConsumerState<TicketTableRow> createState() => _TicketTableRowState();
}

class _TicketTableRowState extends ConsumerState<TicketTableRow> {
  bool _editingCustomer = false;
  bool _editingTask = false;
  bool _savingCustomer = false;
  bool _savingTask = false;
  bool _suppressNextTap = false;

  late TextEditingController _customerCtrl;
  late TextEditingController _taskCtrl;

  @override
  void initState() {
    super.initState();
    _customerCtrl = TextEditingController();
    _taskCtrl = TextEditingController(text: widget.ticket.title);
  }

  @override
  void dispose() {
    _customerCtrl.dispose();
    _taskCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCustomerName(String customerId, String newName) async {
    setState(() => _savingCustomer = true);
    try {
      await Supabase.instance.client
          .from('customers')
          .update({'company_name': newName.trim()})
          .eq('id', customerId);
      ref.invalidate(customersListProvider);
      if (mounted) setState(() => _editingCustomer = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update customer name: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _savingCustomer = false);
    }
  }

  Future<void> _saveTask(String newTitle) async {
    setState(() => _savingTask = true);
    // Capture notifier and context before any async gap to avoid use-after-dispose
    final notifier = ref.read(ticketUpdaterProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = widget.ticket.copyWith(title: newTitle.trim());
      await notifier.updateTicket(updated);
      if (mounted) setState(() => _editingTask = false);
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to update task: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _savingTask = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final currentUser = widget.currentUser;
    final agentsMap = widget.agentsMap;
    final customersMap = widget.customersMap;
    final isUnclaimedTab = widget.isUnclaimedTab;

    final assignedAgentMap = ticket.assignedTo != null ? agentsMap[ticket.assignedTo.toString()] : null;
    final assignedAgentName = assignedAgentMap != null
        ? ((assignedAgentMap['full_name'] ?? assignedAgentMap['username']) ?? 'Unknown Agent')
            .toString()
        : 'Unassigned';

    final customer = customersMap[ticket.customerId.toString()];
    final customerName =
        customer != null ? (customer.companyName ?? 'Unknown Customer') : 'Unknown Customer';

    // Only the agent who claimed the ticket can edit
    final isClaimedByMe = currentUser != null && ticket.assignedTo == currentUser.id;

    return InkWell(
      onTap: (_editingCustomer || _editingTask || _suppressNextTap)
          ? null
          : () => context.push('/ticket/${ticket.ticketId}'),
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
              child: isClaimedByMe
                  ? _editingCustomer
                      ? Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _customerCtrl,
                                autofocus: true,
                                style: const TextStyle(fontSize: 13, color: AppColors.slate800),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  border: OutlineInputBorder(),
                                ),
                                onSubmitted: (_) => _saveCustomerName(ticket.customerId, _customerCtrl.text),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (_savingCustomer)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            else ...[
                              InkWell(
                                onTap: () => _saveCustomerName(ticket.customerId, _customerCtrl.text),
                                child: const Icon(LucideIcons.check, size: 16, color: Colors.green),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => setState(() {
                                  _editingCustomer = false;
                                  _customerCtrl.text = customerName;
                                }),
                                child: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            Flexible(
                              child: Text(
                                customerName,
                                style: const TextStyle(fontSize: 13, color: AppColors.slate800, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            _EditButton(
                              onTap: () => setState(() {
                                _suppressNextTap = true;
                                _customerCtrl.text = customerName;
                                _editingCustomer = true;
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (mounted) setState(() => _suppressNextTap = false);
                                });
                              }),
                            ),
                          ],
                        )
                  : Text(
                      customerName,
                      style: const TextStyle(fontSize: 13, color: AppColors.slate800, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            const SizedBox(width: 32),
            // Contact Number
            Expanded(
              flex: 2,
              child: Text(
                ticket.contactPhone ?? 'N/A',
                style: const TextStyle(fontSize: 13, color: AppColors.slate600),
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
                child: isClaimedByMe
                    ? _editingTask
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _taskCtrl,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 13, color: AppColors.slate700),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (_) => _saveTask(_taskCtrl.text),
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (_savingTask)
                                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              else ...[
                                InkWell(
                                  onTap: () => _saveTask(_taskCtrl.text),
                                  child: const Icon(LucideIcons.check, size: 16, color: Colors.green),
                                ),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => setState(() {
                                    _editingTask = false;
                                    _taskCtrl.text = ticket.title;
                                  }),
                                  child: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
                                ),
                              ],
                            ],
                          )
                        : Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ticket.title,
                                  style: const TextStyle(fontSize: 13, color: AppColors.slate700),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _EditButton(
                                onTap: () => setState(() {
                                  _suppressNextTap = true;
                                  _taskCtrl.text = ticket.title;
                                  _editingTask = true;
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (mounted) setState(() => _suppressNextTap = false);
                                  });
                                }),
                              ),
                            ],
                          )
                    : Text(
                        ticket.title,
                        style: const TextStyle(fontSize: 13, color: AppColors.slate700),
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

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Absorb the event so it doesn't bubble to the row's InkWell
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Listener(
        onPointerDown: (event) {},
        child: Tooltip(
          message: 'Click to edit',
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(LucideIcons.pencil, size: 12, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
