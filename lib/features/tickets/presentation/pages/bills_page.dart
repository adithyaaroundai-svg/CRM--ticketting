import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/design_system/design_system.dart';
import '../providers/ticket_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/widgets/create_ticket_dialog.dart';

import '../../../dashboard/presentation/widgets/animated_create_ticket_fab.dart';

class BillsPage extends ConsumerStatefulWidget {
  const BillsPage({super.key});

  @override
  ConsumerState<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends ConsumerState<BillsPage> {
  DateTime? _selectedDate;
  String _searchQuery = '';
  String _amountQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? _markingTicketId;
  bool _showAnalytics = true;
  bool _selectionMode = false;
  final Set<String> _selectedTicketIds = <String>{};

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _searchQuery = '';
      _amountQuery = '';
      _searchController.clear();
      _amountController.clear();
    });
  }

  void _setSelectionMode(bool enabled) {
    setState(() {
      _selectionMode = enabled;
      if (!enabled) {
        _selectedTicketIds.clear();
      }
    });
  }

  void _toggleTicketSelection(String ticketId, bool selected) {
    setState(() {
      if (selected) {
        _selectedTicketIds.add(ticketId);
      } else {
        _selectedTicketIds.remove(ticketId);
      }
    });
  }

  void _selectAllVisible(List<Ticket> tickets) {
    setState(() {
      _selectedTicketIds
        ..clear()
        ..addAll(tickets.map((t) => t.ticketId));
    });
  }

  void _clearSelection() {
    setState(() => _selectedTicketIds.clear());
  }

  Future<void> _deleteSelectedTickets(List<Ticket> tickets) async {
    if (_selectedTicketIds.isEmpty) return;

    final currentUser = ref.read(authProvider);
    if (currentUser?.isAccountant != true) {
      return;
    }

    final toDelete = tickets
        .where((t) => _selectedTicketIds.contains(t.ticketId))
        .map((t) => t.ticketId)
        .toList();
    if (toDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete tickets?'),
          content: Text(
            'Delete ${toDelete.length} selected ticket(s)? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.deleteTickets(toDelete);
    result.fold(
      (failure) {},
      (_) {
        ref.invalidate(rawTicketsStreamProvider);
        ref.invalidate(ticketStatsProvider);
        ref.invalidate(rawAllTicketsStreamProvider);
        _clearSelection();
      },
    );
  }

  Future<void> _deleteTicket(Ticket ticket) async {
    final currentUser = ref.read(authProvider);
    if (currentUser?.isAccountant != true) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete ticket?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final repository = ref.read(ticketRepositoryProvider);
    final result = await repository.deleteTickets([ticket.ticketId]);
    result.fold(
      (failure) {},
      (_) {
        ref.invalidate(rawTicketsStreamProvider);
        ref.invalidate(ticketStatsProvider);
        ref.invalidate(rawAllTicketsStreamProvider);
      },
    );
  }

  Future<void> _markTicketAsBilled(Ticket ticket) async {
    if (_markingTicketId == ticket.ticketId) return;
    final currentUser = ref.read(authProvider);
    if (currentUser?.isAccountant != true) {
      return;
    }

    setState(() => _markingTicketId = ticket.ticketId);
    await ref
        .read(ticketStatusUpdaterProvider.notifier)
        .updateStatus(ticket.ticketId, 'Closed');
    if (!mounted) return;
    setState(() => _markingTicketId = null);
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);
    final agentsAsync = ref.watch(agentsListProvider);
    final currentUser = ref.watch(authProvider);
    final isAccountant = currentUser?.isAccountant == true;

    final currentPath = isAccountant ? '/accountant' : '/bills';
    final isMobile = MediaQuery.of(context).size.width < 800;

    return MainLayout(
      currentPath: currentPath,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        floatingActionButton: isAccountant
            ? AnimatedCreateTicketFab(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateTicketDialog(),
                  );
                },
              )
            : null,
        body: ticketsAsync.when(
          data: (tickets) {
            return customersAsync.when(
              data: (customers) {
                return agentsAsync.when(
                  data: (agents) {
                    // Filter logic
                    final filteredTickets = tickets.where((t) {
                      final hasBillAmount = (t.billAmount ?? 0) > 0;
                      final isBillTicket = t.status == 'BillRaised' ||
                          t.status == 'BillProcessed' ||
                          (t.status == 'Closed' && hasBillAmount);
                      if (!isBillTicket) return false;

                      // Date filter
                      if (_selectedDate != null) {
                        final updatedAt = t.updatedAt ?? DateTime(0);
                        if (updatedAt.year != _selectedDate!.year ||
                            updatedAt.month != _selectedDate!.month ||
                            updatedAt.day != _selectedDate!.day) {
                          return false;
                        }
                      }

                      // Search filter (Customer or Issue)
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        
                        // Check customer match
                        final customer = customers.firstWhere(
                          (c) => c.id == t.customerId,
                          orElse: () => const Customer(
                            id: '',
                            companyName: 'Unknown',
                          ),
                        );
                        final matchesCustomer = customer.companyName
                            .toLowerCase()
                            .contains(query);

                        // Check issue match
                        final matchesIssue = t.title
                            .toLowerCase()
                            .contains(query);

                        if (!matchesCustomer && !matchesIssue) {
                          return false;
                        }
                      }

                      // Amount filter
                      if (_amountQuery.isNotEmpty) {
                        final amount = t.billAmount?.toString() ?? '';
                        if (!amount.contains(_amountQuery)) {
                          return false;
                        }
                      }

                      return true;
                    }).toList();

                    bool isBilledStatus(String status) {
                      return status == 'Closed' || status == 'BillProcessed';
                    }

                    // Sort: newest first, but billed tickets go to the bottom.
                    filteredTickets.sort((a, b) {
                      final aBilled = isBilledStatus(a.status);
                      final bBilled = isBilledStatus(b.status);
                      if (aBilled != bBilled) {
                        return aBilled ? 1 : -1;
                      }
                      return (b.updatedAt ?? DateTime(0))
                          .compareTo(a.updatedAt ?? DateTime(0));
                    });

                    if (_selectionMode && _selectedTicketIds.isNotEmpty) {
                      final visibleIds =
                          filteredTickets.map((t) => t.ticketId).toSet();
                      final invalidIds =
                          _selectedTicketIds.difference(visibleIds);
                      if (invalidIds.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _selectedTicketIds.removeAll(invalidIds);
                          });
                        });
                      }
                    }

                    final billedStatuses = {'Closed'};
                    final billedTotal = filteredTickets
                        .where((t) => billedStatuses.contains(t.status))
                        .fold<double>(
                          0,
                          (prev, t) => prev + (t.billAmount ?? 0),
                        );
                    final awaitingBillingTotal = 0.0;
                    final pendingCompletionTotal = filteredTickets
                        .where((t) => t.status == 'BillRaised')
                        .fold<double>(
                          0,
                          (prev, t) => prev + (t.billAmount ?? 0),
                        );
                    final unbilledTotal =
                        awaitingBillingTotal + pendingCompletionTotal;

                    return SafeArea(
                      child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isAccountant) ...[
                            AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Icon(
                                    LucideIcons.info,
                                    size: 16,
                                    color: AppColors.warning,
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Read-only access: only accountants can mark tickets as billed.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slate700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: SectionHeader(
                                  title: 'Bills',
                                  subtitle: 'Manage raised bills and payments',
                                ),
                              ),
                              if (isAccountant)
                                FilledButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => const CreateTicketDialog(),
                                    );
                                  },
                                  icon: const Icon(LucideIcons.plus, size: 16),
                                  label: const Text('Create Ticket'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                if (isAccountant)
                                  TextButton.icon(
                                    onPressed: () => context.go('/active-claimed'),
                                    icon: const Icon(LucideIcons.activity, size: 16),
                                    label: const Text('Active tickets'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (isAccountant)
                                  TextButton.icon(
                                    onPressed: () => _setSelectionMode(!_selectionMode),
                                    icon: Icon(
                                      _selectionMode ? LucideIcons.x : LucideIcons.checkSquare,
                                      size: 16,
                                    ),
                                    label: Text(_selectionMode ? 'Cancel Select' : 'Select'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.slate500,
                                    ),
                                  ),
                                TextButton.icon(
                                  onPressed: _clearFilters,
                                  icon: const Icon(LucideIcons.rotateCcw, size: 16),
                                  label: const Text('Reset Filters'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Analytics Section with Hide/Show toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Analytics',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.slate900,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => setState(() => _showAnalytics = !_showAnalytics),
                                icon: Icon(
                                  _showAnalytics ? LucideIcons.eyeOff : LucideIcons.eye,
                                  size: 16,
                                ),
                                label: Text(_showAnalytics ? 'Hide' : 'Show'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                          if (_showAnalytics) ...[
                            const SizedBox(height: 10),
                            _buildTotalsCard(
                              billedTotal: billedTotal,
                              unbilledTotal: unbilledTotal,
                              awaitingBillingTotal: awaitingBillingTotal,
                              pendingCompletionTotal: pendingCompletionTotal,
                            ),
                          ],
                          const SizedBox(height: 16),
                          
                          // Filter Bar
                          _buildFilterBar(),
                          
                          const SizedBox(height: 16),

                          if (isAccountant && _selectionMode)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_selectedTicketIds.length} selected',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: filteredTickets.isEmpty
                                            ? null
                                            : () => _selectAllVisible(filteredTickets),
                                        icon: const Icon(LucideIcons.listChecks, size: 16),
                                        label: const Text('Select All'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: _selectedTicketIds.isEmpty
                                            ? null
                                            : _clearSelection,
                                        icon: const Icon(LucideIcons.xCircle, size: 16),
                                        label: const Text('Clear'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: _selectedTicketIds.isEmpty
                                            ? null
                                            : () => _deleteSelectedTickets(filteredTickets),
                                        icon: const Icon(LucideIcons.trash2, size: 16),
                                        label: const Text('Delete'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                          // Bills List
                          if (filteredTickets.isEmpty)
                            const EmptyStateCard(
                              icon: LucideIcons.receipt,
                              title: 'No bills found',
                              subtitle: 'Try adjusting your filters',
                            )
                          else
                            ...filteredTickets.map((ticket) {
                              final customer = customers.firstWhere(
                                (c) => c.id == ticket.customerId,
                                orElse: () => const Customer(id: '', companyName: 'Unknown'),
                              );
                              final agent = agents.firstWhere(
                                (a) => a['id'] == ticket.assignedTo,
                                orElse: () => <String, dynamic>{'username': 'Unknown'},
                              );
                              final agentName = agent['full_name'] ?? agent['username'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _BillListItem(
                                  ticket: ticket,
                                  customerName: customer.companyName,
                                  agentName: agentName,
                                  onDelete: isAccountant
                                      ? () => _deleteTicket(ticket)
                                      : null,
                                  showSelection: isAccountant && _selectionMode,
                                  isSelected: _selectedTicketIds.contains(ticket.ticketId),
                                  onSelectedChanged: (selected) {
                                    _toggleTicketSelection(ticket.ticketId, selected);
                                  },
                                  onMarkAsBilled: ticket.status == 'BillRaised'
                                      ? () => _markTicketAsBilled(ticket)
                                      : null,
                                  isProcessing: _markingTicketId == ticket.ticketId,
                                  canMarkAsBilled: isAccountant,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading bills: $err')),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Date Filter
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.slate200),
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, size: 14, color: AppColors.slate500),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? 'Filter by Date'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedDate == null
                              ? AppColors.slate400
                              : AppColors.slate900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 12),
                        onPressed: () => setState(() => _selectedDate = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Search Filter (Customer or Issue)
          Expanded(
            flex: 3,
            child: _buildSearchField(
              controller: _searchController,
              hint: 'Search Customer or Issue...',
              icon: LucideIcons.search,
              onChanged: (val) => setState(() => _searchQuery = val),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          const SizedBox(width: 8),
          // Amount Filter
          Expanded(
            flex: 2,
            child: _buildSearchField(
              controller: _amountController,
              hint: 'Amount (₹)...',
              icon: LucideIcons.indianRupee,
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _amountQuery = val),
              onClear: () {
                _amountController.clear();
                setState(() => _amountQuery = '');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.slate200),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 12),
          prefixIcon: Icon(icon, size: 14, color: AppColors.slate500),
          prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 12),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildTotalsCard({
    required double billedTotal,
    required double unbilledTotal,
    required double awaitingBillingTotal,
    required double pendingCompletionTotal,
  }) {
    final grandTotal = billedTotal + unbilledTotal;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.indianRupee,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Bill Amount',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₹${grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _AmountSummaryTile(
                label: 'Collected (Billed)',
                amount: billedTotal,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              _AmountSummaryTile(
                label: 'Unbilled Total',
                amount: unbilledTotal,
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AmountSummaryTile(
                label: 'Awaiting Billing (Closed)',
                amount: awaitingBillingTotal,
                color: AppColors.info,
              ),
              const SizedBox(width: 10),
              _AmountSummaryTile(
                label: 'Pending Completion (Bill Raised)',
                amount: pendingCompletionTotal,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillListItem extends StatelessWidget {
  final Ticket ticket;
  final String customerName;
  final String agentName;
  final VoidCallback? onMarkAsBilled;
  final VoidCallback? onDelete;
  final bool isProcessing;
  final bool canMarkAsBilled;
  final bool showSelection;
  final bool isSelected;
  final ValueChanged<bool>? onSelectedChanged;

  const _BillListItem({
    required this.ticket,
    required this.customerName,
    required this.agentName,
    required this.canMarkAsBilled,
    this.onMarkAsBilled,
    this.onDelete,
    this.isProcessing = false,
    this.showSelection = false,
    this.isSelected = false,
    this.onSelectedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showSelection) ...[
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                if (value == null) return;
                onSelectedChanged?.call(value);
              },
            ),
            const SizedBox(width: 8),
          ],
          // Left Section: Issue & Company
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(LucideIcons.building, size: 13, color: AppColors.slate400),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        customerName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
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
          const SizedBox(width: 16),
          // Right Section: Amount & Status & Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (onDelete != null) ...[
                IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 16),
                  onPressed: onDelete,
                  color: AppColors.slate500,
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 3),
              ],
              Text(
                '₹${ticket.billAmount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(
                    label: _statusLabel(ticket.status),
                    variant: _statusVariant(ticket.status),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ticket.updatedAt != null ? timeago.format(ticket.updatedAt!.toLocal()) : '',
                    style: const TextStyle(fontSize: 10, color: AppColors.slate400),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Raised by: $agentName',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                ),
              ),
              if (onMarkAsBilled != null && canMarkAsBilled) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: isProcessing ? null : onMarkAsBilled,
                    icon: isProcessing
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(LucideIcons.checkCircle, size: 14),
                    label: Text(
                      isProcessing ? 'Marking...' : 'Mark as Billed',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'BillRaised':
      return 'Pending';
    case 'BillProcessed':
      return 'Billed';
    case 'Closed':
      return 'Billed & Completed';
    default:
      return status;
  }
}

StatusVariant _statusVariant(String status) {
  switch (status) {
    case 'BillRaised':
      return StatusVariant.warning;
    case 'BillProcessed':
      return StatusVariant.success;
    case 'Closed':
      return StatusVariant.info;
    default:
      return StatusVariant.neutral;
  }
}

class _AmountSummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountSummaryTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = _darkenColor(color);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _darkenColor(Color color, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(color);
  final darkened = hsl.withLightness(
    (hsl.lightness - amount).clamp(0.0, 1.0),
  );
  return darkened.toColor();
}
