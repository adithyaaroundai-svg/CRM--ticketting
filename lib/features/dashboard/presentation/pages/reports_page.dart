import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../customers/domain/entities/customer.dart';
import '../providers/app_settings_provider.dart';

enum ReportPeriod { daily, weekly, monthly }

enum ReportType { overview, customerWise, supportStaffWise }

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportPeriod _selectedPeriod = ReportPeriod.daily;
  ReportType _selectedType = ReportType.overview;

  String _priorityFilter = 'All';
  String _categoryFilter = 'All';
  String _statusFilter = 'All';

  bool _isSettingsLoading = true;
  bool _reportsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final client = Supabase.instance.client;
      final List<dynamic> response = await client
          .from('app_settings')
          .select()
          .eq('setting_key', 'enable_reports');

      bool enabled = true;

      if (response.isNotEmpty) {
        final row = response.first;
        final value = row['setting_value'] as Map<String, dynamic>?;
        enabled = value?['enabled'] as bool? ?? true;
      }

      if (!mounted) return;

      setState(() {
        _reportsEnabled = enabled;
        _isSettingsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSettingsLoading = false;
        _reportsEnabled = true; // Fallback to enabled on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final advancedSettings = ref
        .watch(advancedSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return MainLayout(
      currentPath: '/reports',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: _isSettingsLoading
            ? const Center(child: CircularProgressIndicator())
            : !_reportsEnabled
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      Icon(
                        LucideIcons.barChart,
                        size: 40,
                        color: AppColors.slate300,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Reports are disabled by admin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You can enable them from App Settings if you are an admin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slate500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - using unified PageHeader
                    const PageHeader(
                      title: 'Reports & Analytics',
                      subtitle:
                          'View ticket statistics and performance metrics',
                    ),
                    const SizedBox(height: 32),

                    // Filters
                    Row(
                      children: [
                        // Period Filter
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Period',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<ReportPeriod>(
                                  initialValue: _selectedPeriod,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: ReportPeriod.daily,
                                      child: Text('Daily'),
                                    ),
                                    DropdownMenuItem(
                                      value: ReportPeriod.weekly,
                                      child: Text('Weekly'),
                                    ),
                                    DropdownMenuItem(
                                      value: ReportPeriod.monthly,
                                      child: Text('Monthly'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedPeriod = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Report Type Filter
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Report Type',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<ReportType>(
                                  isExpanded: true,
                                  initialValue: _selectedType,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem(
                                      value: ReportType.overview,
                                      child: Text('Overview'),
                                    ),
                                    const DropdownMenuItem(
                                      value: ReportType.customerWise,
                                      child: Text('Customer-wise'),
                                    ),
                                    if (currentUser?.isAccountant == true ||
                                        currentUser?.isAdmin == true ||
                                        currentUser?.isSupportHead == true)
                                      const DropdownMenuItem(
                                        value: ReportType.supportStaffWise,
                                        child: Text('Support Staff-wise'),
                                      ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedType = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Priority Filter
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Priority',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _priorityFilter,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'All',
                                      child: Text('All priorities'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Low',
                                      child: Text('Low'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Normal',
                                      child: Text('Normal'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'High',
                                      child: Text('High'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Critical',
                                      child: Text('Critical'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _priorityFilter = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Category Filter
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Category',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  initialValue: _categoryFilter,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'All',
                                      child: Text('All categories'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Technical',
                                      child: Text('Technical'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Billing',
                                      child: Text('Billing'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'General',
                                      child: Text('General'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Hardware',
                                      child: Text('Hardware'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Software',
                                      child: Text('Software'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _categoryFilter = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status Filter
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _statusFilter,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'All',
                                child: Text('All statuses'),
                              ),
                              DropdownMenuItem(
                                value: 'Open',
                                child: Text('Open'),
                              ),
                              DropdownMenuItem(
                                value: 'Resolved',
                                child: Text('Resolved'),
                              ),
                              DropdownMenuItem(
                                value: 'Closed',
                                child: Text('Closed'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _statusFilter = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Statistics Cards
                    ticketsAsync.when(
                      data: (data) {
                        final tickets = data.cast<Ticket>();
                        final filteredTickets = _applyMetaFilters(tickets);
                        final stats = _calculateStats(
                          filteredTickets,
                          currentUser,
                        );
                        return Column(
                          children: [
                            // Summary Cards
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isMobile = constraints.maxWidth < 800;
                                final totalCard = _buildStatCard(
                                  title: 'Total Tickets',
                                  value: stats['total'].toString(),
                                  icon: LucideIcons.ticket,
                                  color: AppColors.primary,
                                );
                                final resolvedCard = _buildStatCard(
                                  title: 'Resolved',
                                  value: stats['resolved'].toString(),
                                  icon: LucideIcons.checkCircle,
                                  color: AppColors.success,
                                );
                                final pendingCard = _buildStatCard(
                                  title: 'Pending',
                                  value: stats['pending'].toString(),
                                  icon: LucideIcons.clock,
                                  color: AppColors.warning,
                                );
                                final billedCard = _buildStatCard(
                                  title: 'Billed',
                                  value: stats['billed'].toString(),
                                  icon: LucideIcons.receipt,
                                  color: AppColors.info,
                                );

                                if (isMobile) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: totalCard),
                                          const SizedBox(width: 16),
                                          Expanded(child: resolvedCard),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(child: pendingCard),
                                          const SizedBox(width: 16),
                                          Expanded(child: billedCard),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: totalCard),
                                    const SizedBox(width: 16),
                                    Expanded(child: resolvedCard),
                                    const SizedBox(width: 16),
                                    Expanded(child: pendingCard),
                                    const SizedBox(width: 16),
                                    Expanded(child: billedCard),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),

                            if (_selectedType == ReportType.overview) ...[
                              _buildQueueHealth(
                                filteredTickets,
                                advancedSettings,
                              ),
                              const SizedBox(height: 24),
                              _buildResponseTimeAnalytics(
                                filteredTickets,
                                advancedSettings,
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Detailed Report based on type
                            if (_selectedType == ReportType.overview)
                              _buildOverviewReport(filteredTickets)
                            else if (_selectedType == ReportType.customerWise)
                              ref
                                  .watch(customersListProvider)
                                  .when(
                                    data: (customers) =>
                                        _buildCustomerWiseReport(
                                          filteredTickets,
                                          customers,
                                        ),
                                    loading: () => const Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    error: (err, _) => Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'Error loading customers: $err',
                                        style: const TextStyle(
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ),
                                  )
                            else if (_selectedType ==
                                ReportType.supportStaffWise)
                              _buildSupportStaffWiseReport(filteredTickets),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (error, _) => Center(
                        child: Text(
                          'Error loading reports: $error',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQueueHealth(List<Ticket> tickets, dynamic advancedSettings) {
    final now = DateTime.now();
    final openTickets = tickets
        .where(
          (t) => !['Resolved', 'Closed', 'BillProcessed'].contains(t.status),
        )
        .toList();

    if (openTickets.isEmpty) {
      return AppCard(
        child: Row(
          children: const [
            Icon(LucideIcons.smile, size: 18, color: AppColors.success),
            SizedBox(width: 8),
            Text(
              'No active tickets in the queue – great job!',
              style: TextStyle(fontSize: 13, color: AppColors.slate700),
            ),
          ],
        ),
      );
    }

    Duration totalAge = Duration.zero;
    var bucket0to4h = 0;
    var bucket4to24h = 0;
    var bucket1to3d = 0;
    var bucketOver3d = 0;
    var responseTimeBreached = 0;

    for (final t in openTickets) {
      final age = now.difference(t.createdAt ?? now);
      totalAge += age;
      final hours = age.inHours;
      if (hours < 4) {
        bucket0to4h++;
      } else if (hours < 24) {
        bucket4to24h++;
      } else if (hours < 72) {
        bucket1to3d++;
      } else {
        bucketOver3d++;
      }

      final due = _computeTargetDue(t, advancedSettings);
      if (due != null && due.isBefore(now)) {
        responseTimeBreached++;
      }
    }

    final avgAgeHours =
        totalAge.inMinutes / openTickets.length.toDouble() / 60.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Queue Health',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Average age of active tickets: ${avgAgeHours.toStringAsFixed(1)}h',
            style: const TextStyle(fontSize: 13, color: AppColors.slate700),
          ),
          const SizedBox(height: 4),
          Text(
            '0–4h: ${bucket0to4h.toString()}   4–24h: ${bucket4to24h.toString()}   1–3d: ${bucket1to3d.toString()}   >3d: ${bucketOver3d.toString()}',
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          if (responseTimeBreached > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Tickets past response time target: $responseTimeBreached',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseTimeAnalytics(
    List<Ticket> tickets,
    dynamic advancedSettings,
  ) {
    if (advancedSettings == null || tickets.isEmpty) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    int openWithTarget = 0;
    int openOverdue = 0;
    int openAtRisk = 0;

    int closedWithTarget = 0;
    int closedOnTime = 0;

    for (final t in tickets) {
      final due = _computeTargetDue(t, advancedSettings);
      if (due == null) continue;

      final isClosed = [
        'Resolved',
        'Closed',
        'BillProcessed',
      ].contains(t.status);

      if (!isClosed) {
        openWithTarget++;
        final minutes = due.difference(now).inMinutes;
        if (minutes < 0) {
          openOverdue++;
        } else if (minutes < 60) {
          openAtRisk++;
        }
      } else {
        closedWithTarget++;
        // Use updatedAt as a proxy for resolution time
        if (!(t.updatedAt ?? DateTime.now()).isAfter(due)) {
          closedOnTime++;
        }
      }
    }

    final onTimePct = closedWithTarget == 0
        ? 0
        : ((closedOnTime / closedWithTarget) * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Time Performance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Open tickets with a response time target: $openWithTarget',
            style: const TextStyle(fontSize: 13, color: AppColors.slate700),
          ),
          const SizedBox(height: 4),
          Text(
            'Overdue: $openOverdue   At risk (next 60 min): $openAtRisk',
            style: const TextStyle(fontSize: 12, color: AppColors.slate500),
          ),
          const SizedBox(height: 8),
          Text(
            'Closed tickets meeting response time target: $onTimePct%',
            style: const TextStyle(fontSize: 13, color: AppColors.slate700),
          ),
        ],
      ),
    );
  }

  DateTime? _computeTargetDue(Ticket t, dynamic advancedSettings) {
    if (t.slaDue != null) {
      return t.slaDue;
    }
    if (advancedSettings == null) return null;
    try {
      final minutes = advancedSettings.slaMinutesForPriority(t.priority);
      if (minutes <= 0) return null;
      return (t.createdAt ?? DateTime.now()).add(Duration(minutes: minutes));
    } catch (_) {
      return null;
    }
  }

  List<Ticket> _applyMetaFilters(List<Ticket> tickets) {
    return tickets.where((t) {
      final matchesPriority =
          _priorityFilter == 'All' || t.priority == _priorityFilter;
      final matchesCategory =
          _categoryFilter == 'All' ||
          (t.category != null && t.category == _categoryFilter);

      bool matchesStatus = true;
      if (_statusFilter != 'All') {
        if (_statusFilter == 'Open') {
          matchesStatus = ![
            'Resolved',
            'Closed',
            'BillProcessed',
          ].contains(t.status);
        } else {
          matchesStatus = t.status == _statusFilter;
        }
      }

      return matchesPriority && matchesCategory && matchesStatus;
    }).toList();
  }

  Map<String, int> _calculateStats(List<Ticket> tickets, dynamic currentUser) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.weekly:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    final filteredTickets = tickets
        .where((t) => (t.createdAt ?? DateTime(0)).isAfter(startDate))
        .toList();

    return {
      'total': filteredTickets.length,
      'resolved': filteredTickets
          .where((t) => ['Resolved', 'Closed'].contains(t.status))
          .length,
      'pending': filteredTickets
          .where(
            (t) => !['Resolved', 'Closed', 'BillProcessed'].contains(t.status),
          )
          .length,
      'billed': filteredTickets
          .where((t) => t.status == 'BillProcessed' || t.status == 'Closed')
          .length,
    };
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.slate600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewReport(List<Ticket> tickets) {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedPeriod) {
      case ReportPeriod.daily:
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case ReportPeriod.weekly:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case ReportPeriod.monthly:
        startDate = DateTime(now.year, now.month, 1);
        break;
    }

    final filteredTickets = tickets
        .where((t) => (t.createdAt ?? DateTime(0)).isAfter(startDate))
        .toList();

    final dailyMap = <DateTime, int>{};
    for (final t in filteredTickets) {
      final created = t.createdAt ?? DateTime.now();
      final dayKey = DateTime(created.year, created.month, created.day);
      dailyMap[dayKey] = (dailyMap[dayKey] ?? 0) + 1;
    }
    final dailyEntries = dailyMap.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final categoryMap = <String, int>{};
    for (final t in filteredTickets) {
      final category = t.category ?? 'Uncategorized';
      categoryMap[category] = (categoryMap[category] ?? 0) + 1;
    }
    final categoryEntries = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ticket Status Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusRow(
            'New',
            tickets.where((t) => t.status == 'New').length,
          ),
          _buildStatusRow(
            'In Progress',
            tickets.where((t) => t.status == 'In Progress').length,
          ),
          _buildStatusRow(
            'Resolved',
            tickets.where((t) => t.status == 'Resolved').length,
          ),
          _buildStatusRow(
            'Bill Raised',
            tickets.where((t) => t.status == 'BillRaised').length,
          ),
          _buildStatusRow(
            'Bill Processed',
            tickets
                .where(
                  (t) => t.status == 'BillProcessed' || t.status == 'Closed',
                )
                .length,
          ),
          const SizedBox(height: 24),
          const Text(
            'Tickets per Day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          if (dailyEntries.isEmpty)
            const Text(
              'No tickets in the selected period.',
              style: TextStyle(fontSize: 13, color: AppColors.slate600),
            )
          else
            ...dailyEntries.take(10).map((entry) {
              final date = entry.key;
              final label =
                  '${date.day.toString().padLeft(2, '0')}/'
                  '${date.month.toString().padLeft(2, '0')}';
              return _buildStatusRow(label, entry.value);
            }),
          const SizedBox(height: 24),
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 12),
          if (categoryEntries.isEmpty)
            const Text(
              'No categories available for the selected period.',
              style: TextStyle(fontSize: 13, color: AppColors.slate600),
            )
          else
            ...categoryEntries.take(8).map((entry) {
              return _buildStatusRow(entry.key, entry.value);
            }),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String status, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              status,
              style: const TextStyle(fontSize: 14, color: AppColors.slate700),
            ),
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerWiseReport(
    List<Ticket> tickets,
    List<Customer> customers,
  ) {
    final customerMap = {for (final c in customers) c.id: c};

    final customerGroups = <String, Map<String, int>>{};
    for (var ticket in tickets) {
      final id = ticket.customerId;
      final metrics = customerGroups.putIfAbsent(
        id,
        () => {'total': 0, 'open': 0, 'resolved': 0, 'billed': 0},
      );

      metrics['total'] = (metrics['total'] ?? 0) + 1;

      final isBilled =
          ticket.status == 'BillProcessed' || ticket.status == 'Closed';
      final isResolved = ['Resolved', 'Closed'].contains(ticket.status);
      final isOpen = ![
        'Resolved',
        'Closed',
        'BillProcessed',
      ].contains(ticket.status);

      if (isOpen) {
        metrics['open'] = (metrics['open'] ?? 0) + 1;
      }
      if (isResolved) {
        metrics['resolved'] = (metrics['resolved'] ?? 0) + 1;
      }
      if (isBilled) {
        metrics['billed'] = (metrics['billed'] ?? 0) + 1;
      }
    }

    final sortedCustomers = customerGroups.entries.toList()
      ..sort(
        (a, b) => (b.value['total'] ?? 0).compareTo(a.value['total'] ?? 0),
      );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer-wise Ticket Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          if (sortedCustomers.isEmpty)
            const Text(
              'No tickets for the selected filters.',
              style: TextStyle(fontSize: 13, color: AppColors.slate600),
            )
          else
            ...sortedCustomers.take(10).map((entry) {
              final customerId = entry.key;
              final metrics = entry.value;
              final customer = customerMap[customerId];

              final name =
                  customer?.companyName ??
                  'Customer ${customerId.substring(0, 8)}';

              final total = metrics['total'] ?? 0;
              final open = metrics['open'] ?? 0;
              final resolved = metrics['resolved'] ?? 0;
              final billed = metrics['billed'] ?? 0;

              final hasAmc = customer?.amcExpiryDate != null;
              final amcActive = customer?.isAmcActive ?? false;

              String? amcLabel;
              Color? amcColor;
              if (hasAmc) {
                amcLabel = amcActive ? 'AMC Active' : 'AMC Expired';
                amcColor = amcActive ? AppColors.success : AppColors.error;
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                        ),
                        Text(
                          '$total tickets',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Open: $open   Resolved: $resolved   Billed: $billed',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.slate600,
                      ),
                    ),
                    if (amcLabel != null && amcColor != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: amcColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              amcLabel,
                              style: TextStyle(
                                fontSize: 11,
                                color: amcColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSupportStaffWiseReport(List<Ticket> tickets) {
    final staffGroups = <String, Map<String, int>>{};
    for (var ticket in tickets) {
      if (ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty) {
        final id = ticket.assignedTo!;
        final metrics = staffGroups.putIfAbsent(
          id,
          () => {'total': 0, 'open': 0, 'inProgress': 0, 'resolved': 0},
        );

        metrics['total'] = (metrics['total'] ?? 0) + 1;

        if (['Resolved', 'Closed', 'BillProcessed'].contains(ticket.status)) {
          metrics['resolved'] = (metrics['resolved'] ?? 0) + 1;
        } else if (ticket.status.contains('Progress')) {
          metrics['inProgress'] = (metrics['inProgress'] ?? 0) + 1;
        } else {
          metrics['open'] = (metrics['open'] ?? 0) + 1;
        }
      }
    }

    final sortedStaff = staffGroups.entries.toList()
      ..sort(
        (a, b) => (b.value['total'] ?? 0).compareTo(a.value['total'] ?? 0),
      );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Support Staff Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedStaff.map((entry) {
            final metrics = entry.value;
            final total = metrics['total'] ?? 0;
            final open = metrics['open'] ?? 0;
            final inProgress = metrics['inProgress'] ?? 0;
            final resolved = metrics['resolved'] ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ref
                        .watch(ticketAssignedAgentProvider(entry.key))
                        .when(
                          data: (agentData) => Text(
                            agentData?['username'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slate700,
                            ),
                          ),
                          loading: () => const Text('Loading...'),
                          error: (_, __) => const Text('Unknown'),
                        ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total: $total',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Open: $open   In progress: $inProgress   Resolved: $resolved',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
