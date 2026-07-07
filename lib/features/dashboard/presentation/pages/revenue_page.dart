import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../tickets/domain/entities/ticket.dart';

class RevenuePage extends ConsumerStatefulWidget {
  const RevenuePage({super.key});

  @override
  ConsumerState<RevenuePage> createState() => _RevenuePageState();
}

class _RevenuePageState extends ConsumerState<RevenuePage> {
  String _selectedRole = 'all';
  String _selectedUser = 'all';
  String _selectedCompany = 'all';
  String _selectedPeriod = 'today';

  final List<String> _roleFilters = const [
    'all',
    'Admin',
    'Support Head',
    'Support',
    'Accountant',
  ];

  static const List<_FilterOption> _periodOptions = [
    _FilterOption(value: 'today', label: "Today's data"),
    _FilterOption(value: 'this_week', label: 'This week'),
    _FilterOption(value: 'this_month', label: 'This month'),
    _FilterOption(value: 'last_30_days', label: 'Last 30 days'),
    _FilterOption(value: 'all_time', label: 'All time'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final ticketsAsync = ref.watch(allTicketsStreamProvider);
    final agentsAsync = ref.watch(agentsListProvider);
    final customersAsync = ref.watch(customersListProvider);

    return MainLayout(
      currentPath: '/revenue',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: ticketsAsync.when(
          data: (tickets) => agentsAsync.when(
            data: (agentsRaw) => customersAsync.when(
              data: (customers) => _buildContent(
                currentUser: currentUser,
                tickets: tickets,
                agentsRaw: agentsRaw,
                customers: customers,
              ),
              loading: () => const _PageLoader(),
              error: (err, _) =>
                  _ErrorState(message: 'Failed to load customers', error: err),
            ),
            loading: () => const _PageLoader(),
            error: (err, _) =>
                _ErrorState(message: 'Failed to load agents', error: err),
          ),
          loading: () => const _PageLoader(),
          error: (err, _) =>
              _ErrorState(message: 'Failed to load tickets', error: err),
        ),
      ),
    );
  }

  Widget _buildContent({
    required Agent? currentUser,
    required List<Ticket> tickets,
    required List<Map<String, dynamic>> agentsRaw,
    required List<Customer> customers,
  }) {
    final isAdmin = currentUser?.isAdmin == true;
    final isSupport = currentUser?.isSupport == true;
    final isSupportHead = currentUser?.isSupportHead == true;

    final agentDirectory = _buildAgentDirectory(agentsRaw);
    final customerDirectory = {
      for (final customer in customers) customer.id: customer,
    };

    final allEntries = _mapTicketsToRevenueEntries(
      tickets: tickets,
      agents: agentDirectory,
      customers: customerDirectory,
    );

    final userOptions = _buildUserOptions(allEntries, agentDirectory);
    final companyOptions = _buildCompanyOptions(allEntries);

    final effectiveRole = _roleFilters.contains(_selectedRole)
        ? _selectedRole
        : 'all';
    final effectiveUser = _sanitizeSelection(_selectedUser, userOptions);
    final effectiveCompany = _sanitizeSelection(
      _selectedCompany,
      companyOptions,
    );
    final effectivePeriod = _sanitizeSelection(_selectedPeriod, _periodOptions);

    final filteredEntries = _applyFilters(
      entries: allEntries,
      showGlobalFilters: isAdmin,
      currentUserId: currentUser?.id,
      role: effectiveRole,
      agentId: effectiveUser,
      companyId: effectiveCompany,
      period: effectivePeriod,
    );

    final summaryCards = _buildSummaryCards(filteredEntries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: 'Revenue Overview',
            subtitle: isAdmin
                ? 'Monitor revenue performance across the team'
                : 'Track your own revenue and billing impact',
          ),
          const SizedBox(height: 24),
          _SummaryRow(cards: summaryCards),
          const SizedBox(height: 24),
          if (isAdmin)
            _FiltersCard(
              selectedRole: effectiveRole,
              selectedUser: effectiveUser,
              selectedCompany: effectiveCompany,
              selectedPeriod: effectivePeriod,
              roles: _roleFilters,
              userOptions: userOptions,
              companyOptions: companyOptions,
              periodOptions: _periodOptions,
              onRoleChanged: (value) => setState(() => _selectedRole = value),
              onUserChanged: (value) => setState(() => _selectedUser = value),
              onCompanyChanged: (value) =>
                  setState(() => _selectedCompany = value),
              onPeriodChanged: (value) =>
                  setState(() => _selectedPeriod = value),
            )
          else
            _AgentScopeBanner(
              roleLabel: isSupport
                  ? 'Support'
                  : isSupportHead
                  ? 'Support Head'
                  : 'User',
            ),
          const SizedBox(height: 24),
          _RevenueTable(entries: filteredEntries),
        ],
      ),
    );
  }

  List<_SummaryCardData> _buildSummaryCards(List<_RevenueEntry> entries) {
    double todayTotal = 0;
    double monthTotal = 0;
    double lifetimeTotal = 0;

    final now = DateTime.now();
    for (final entry in entries) {
      lifetimeTotal += entry.revenue;
      if (entry.date.year == now.year && entry.date.month == now.month) {
        monthTotal += entry.revenue;
      }
      if (_isSameDay(entry.date, now)) {
        todayTotal += entry.revenue;
      }
    }

    return [
      _SummaryCardData(
        label: "Today's Revenue",
        amount: todayTotal,
        caption: "Today's processed bills",
        icon: LucideIcons.sun,
        accent: AppColors.success,
      ),
      _SummaryCardData(
        label: 'This Month',
        amount: monthTotal,
        caption: 'Month-to-date performance',
        icon: LucideIcons.calendarDays,
        accent: AppColors.warning,
      ),
      _SummaryCardData(
        label: 'Total Revenue',
        amount: lifetimeTotal,
        caption: 'All time across applied filters',
        icon: LucideIcons.indianRupee,
        accent: AppColors.primary,
      ),
    ];
  }

  Map<String, _AgentInfo> _buildAgentDirectory(
    List<Map<String, dynamic>> agentsRaw,
  ) {
    final directory = <String, _AgentInfo>{};
    for (final agent in agentsRaw) {
      final id = agent['id'] as String?;
      if (id == null) continue;
      final fullName = (agent['full_name'] as String?)?.trim();
      final username = (agent['username'] as String?)?.trim();
      directory[id] = _AgentInfo(
        id: id,
        name: (fullName?.isNotEmpty == true)
            ? fullName!
            : (username?.isNotEmpty == true ? username! : 'Agent'),
        role: (agent['role'] as String?) ?? 'Agent',
      );
    }
    return directory;
  }

  List<_RevenueEntry> _mapTicketsToRevenueEntries({
    required List<Ticket> tickets,
    required Map<String, _AgentInfo> agents,
    required Map<String, Customer> customers,
  }) {
    final entries = <_RevenueEntry>[];
    for (final ticket in tickets) {
      final amount = ticket.billAmount;
      if (amount == null || amount <= 0) continue;

      final status = ticket.status.toLowerCase();
      // Only include tickets that have been processed/billed (Cash Basis)
      // Exclude 'billraised' (Pending) until they are marked as Billed.
      if (!(status == 'billprocessed' || status == 'closed')) continue;

      final ownerId = (ticket.assignedTo?.isNotEmpty ?? false)
          ? ticket.assignedTo!
          : ticket.createdBy;
      if (ownerId.isEmpty) continue;

      final agent = agents[ownerId];
      final customer = customers[ticket.customerId];

      entries.add(
        _RevenueEntry(
          ticketId: ticket.ticketId,
          agentId: ownerId,
          agentName: agent?.name ?? 'Unassigned',
          agentRole: agent?.role ?? 'Agent',
          companyId: customer?.id ?? ticket.customerId,
          companyName: customer?.companyName ?? 'Unknown company',
          date: ticket.updatedAt ?? DateTime.now(),
          revenue: amount,
          billCount: 1,
        ),
      );
    }
    return entries;
  }

  List<_FilterOption> _buildUserOptions(
    List<_RevenueEntry> entries,
    Map<String, _AgentInfo> agents,
  ) {
    final options = <_FilterOption>[
      const _FilterOption(value: 'all', label: 'All Users'),
    ];
    final seen = <String>{};
    for (final entry in entries) {
      if (entry.agentId.isEmpty) continue;
      if (seen.add(entry.agentId)) {
        options.add(
          _FilterOption(
            value: entry.agentId,
            label: agents[entry.agentId]?.name ?? entry.agentName,
          ),
        );
      }
    }
    if (options.length == 1) {
      for (final agent in agents.values) {
        if (seen.add(agent.id)) {
          options.add(_FilterOption(value: agent.id, label: agent.name));
        }
      }
    }
    return options;
  }

  List<_FilterOption> _buildCompanyOptions(List<_RevenueEntry> entries) {
    final options = <_FilterOption>[
      const _FilterOption(value: 'all', label: 'All Companies'),
    ];
    final seen = <String>{};
    for (final entry in entries) {
      if (entry.companyId.isEmpty) continue;
      if (seen.add(entry.companyId)) {
        options.add(
          _FilterOption(value: entry.companyId, label: entry.companyName),
        );
      }
    }
    return options;
  }

  String _sanitizeSelection(String value, List<_FilterOption> options) {
    return options.any((option) => option.value == value)
        ? value
        : options.first.value;
  }

  List<_RevenueEntry> _applyFilters({
    required List<_RevenueEntry> entries,
    required bool showGlobalFilters,
    required String? currentUserId,
    required String role,
    required String agentId,
    required String companyId,
    required String period,
  }) {
    return entries.where((entry) {
      if (!showGlobalFilters) {
        if (currentUserId == null) return false;
        if (entry.agentId != currentUserId) return false;
      } else {
        if (role != 'all' &&
            entry.agentRole.toLowerCase() != role.toLowerCase()) {
          return false;
        }
        if (agentId != 'all' && entry.agentId != agentId) return false;
        if (companyId != 'all' && entry.companyId != companyId) return false;
      }
      return _isWithinPeriod(entry.date, period);
    }).toList();
  }

  bool _isWithinPeriod(DateTime date, String period) {
    final now = DateTime.now();
    switch (period) {
      case 'today':
        return _isSameDay(date, now);
      case 'this_week':
        final startOfWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
      case 'this_month':
        return date.year == now.year && date.month == now.month;
      case 'last_30_days':
        return now.difference(date).inDays <= 30;
      case 'all_time':
      default:
        return true;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _SummaryRow extends StatelessWidget {
  final List<_SummaryCardData> cards;

  const _SummaryRow({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) => SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : double.infinity,
                  child: AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: card.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(card.icon, color: card.accent, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                card.label,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatCurrency(card.amount),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.caption,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  static String _formatCurrency(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(1)} Cr';
    }
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)} L';
    }
    return '₹${value.toStringAsFixed(0)}';
  }
}

class _SummaryCardData {
  final String label;
  final double amount;
  final String caption;
  final IconData icon;
  final Color accent;

  const _SummaryCardData({
    required this.label,
    required this.amount,
    required this.caption,
    required this.icon,
    required this.accent,
  });
}

class _FiltersCard extends StatelessWidget {
  final String selectedRole;
  final String selectedUser;
  final String selectedCompany;
  final String selectedPeriod;
  final List<String> roles;
  final List<_FilterOption> userOptions;
  final List<_FilterOption> companyOptions;
  final List<_FilterOption> periodOptions;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onUserChanged;
  final ValueChanged<String> onCompanyChanged;
  final ValueChanged<String> onPeriodChanged;

  const _FiltersCard({
    required this.selectedRole,
    required this.selectedUser,
    required this.selectedCompany,
    required this.selectedPeriod,
    required this.roles,
    required this.userOptions,
    required this.companyOptions,
    required this.periodOptions,
    required this.onRoleChanged,
    required this.onUserChanged,
    required this.onCompanyChanged,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(LucideIcons.filter, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles.map((role) {
                final isSelected = selectedRole == role;
                return FilterChip(
                  label: Text(role == 'all' ? 'All Roles' : role),
                  selected: isSelected,
                  onSelected: (_) => onRoleChanged(role),
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.primary.withValues(alpha: 0.12),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;
                final children = [
                  Expanded(
                    child: _DropdownFilter(
                      label: 'User',
                      value: selectedUser,
                      items: userOptions,
                      onChanged: onUserChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DropdownFilter(
                      label: 'Company',
                      value: selectedCompany,
                      items: companyOptions,
                      onChanged: onCompanyChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DropdownFilter(
                      label: 'Period',
                      value: selectedPeriod,
                      items: periodOptions,
                      onChanged: onPeriodChanged,
                    ),
                  ),
                ];

                if (isNarrow) {
                  return Column(
                    children: [
                      for (var i = 0; i < children.length; i += 2)
                        Padding(
                          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                          child: i + 1 < children.length
                              ? Row(children: children.sublist(i, i + 2))
                              : children[i],
                        ),
                    ],
                  );
                }

                return Row(children: children);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<_FilterOption> items;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item.value,
              child: Text(item.label),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _AgentScopeBanner extends StatelessWidget {
  final String roleLabel;

  const _AgentScopeBanner({required this.roleLabel});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.shield, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$roleLabel access only',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You can only view revenue generated from your own tickets and bills.',
                  style: TextStyle(fontSize: 13, color: AppColors.slate600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueTable extends StatelessWidget {
  final List<_RevenueEntry> entries;

  const _RevenueTable({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyStateCard(
        icon: LucideIcons.indianRupee,
        title: 'No revenue recorded',
        subtitle: 'Adjust your filters or date range to see data.',
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Revenue & Bills',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          ...entries.map((entry) {
            return Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: const Icon(
                      LucideIcons.user,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    entry.agentName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.companyName,
                        style: const TextStyle(color: AppColors.slate600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(entry.date),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _SummaryRow._formatCurrency(entry.revenue),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${entry.billCount} bill${entry.billCount == 1 ? '' : 's'}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _PageLoader extends StatelessWidget {
  const _PageLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Object? error;

  const _ErrorState({required this.message, this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.slate900,
              ),
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevenueEntry {
  final String ticketId;
  final String agentId;
  final String agentName;
  final String agentRole;
  final String companyId;
  final String companyName;
  final DateTime date;
  final double revenue;
  final int billCount;

  const _RevenueEntry({
    required this.ticketId,
    required this.agentId,
    required this.agentName,
    required this.agentRole,
    required this.companyId,
    required this.companyName,
    required this.date,
    required this.revenue,
    required this.billCount,
  });
}

class _FilterOption {
  final String value;
  final String label;

  const _FilterOption({required this.value, required this.label});
}

class _AgentInfo {
  final String id;
  final String name;
  final String role;

  const _AgentInfo({required this.id, required this.name, required this.role});
}
