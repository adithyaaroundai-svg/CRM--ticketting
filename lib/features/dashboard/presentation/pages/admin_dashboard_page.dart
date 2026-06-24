import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../widgets/ticket_card_with_amc.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../providers/app_settings_provider.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../widgets/animated_create_ticket_fab.dart';
import '../widgets/create_ticket_dialog.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedTab = 0; // 0: New/Open, 1: In Progress, 2: Resolved/Closed

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

    final chatContent = [
      'Company: ${ticket.customerId}',
      'Issue: ${ticket.title}',
      'TicketID: ${ticket.ticketId}',
    ].join('\n');

    await ref.read(chatRepositoryProvider).sendMessage(
          senderId: agent.id,
          senderName: agent.fullName ?? agent.username,
          senderRole: agent.role,
          content: chatContent,
          senderAvatarUrl: agent.avatarUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final ticketStatsAsync = ref.watch(ticketStatsProvider);
    final amcStatsAsync = ref.watch(amcStatsProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);
    final appSettings = ref
        .watch(appSettingsProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);

    return MainLayout(
      currentPath: '/admin',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        floatingActionButton: AnimatedCreateTicketFab(
          onPressed: _showCreateTicketDialog,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              WelcomeHeader(
                greeting: 'Admin Dashboard',
                name: user?.fullName ?? 'Admin',
                trailing: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (!_isRestrictedAgent)
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.hourglass, size: 16),
                      label: const Text('Unclaimed > 1h'),
                      onPressed: () => context.push('/tickets?view=stale_unclaimed'),
                    ),
                    if (!_isRestrictedAgent)
                    OutlinedButton.icon(
                      icon: const Icon(LucideIcons.alertTriangle, size: 16),
                      label: const Text('Claimed > 12h'),
                      onPressed: () => context.push('/tickets?view=claimed_overdue'),
                    ),
                    AppButton.ghost(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () {
                        ref.invalidate(ticketStatsProvider);
                        ref.invalidate(amcStatsProvider);
                        ref.invalidate(rawTicketsStreamProvider);
                        ref.invalidate(customersListProvider);
                        ref.invalidate(appSettingsProvider);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppButton.ghost(
                    label: 'View Reports',
                    icon: LucideIcons.barChart3,
                    onPressed: () => context.push('/reports'),
                  ),
                  AppButton.ghost(
                    label: 'All Tickets',
                    icon: LucideIcons.ticket,
                    onPressed: () => context.push('/tickets'),
                  ),
                  AppButton.ghost(
                    label: 'App Settings',
                    icon: LucideIcons.settings,
                    onPressed: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Row: Ticket stats
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 1100;
                  final crossAxisCount = isWide
                      ? 3
                      : (constraints.maxWidth > 700 ? 2 : 1);
                  // When the layout collapses to fewer columns the cards need
                  // additional vertical space, otherwise the fixed
                  // mainAxisExtent would clip the KPI content and trigger the
                  // yellow/black overflow warning banner. Give compact grids a
                  // touch more height so the text + chip fit comfortably.
                  final tileHeight = crossAxisCount >= 3 ? 190.0 : 220.0;

                  return GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: tileHeight,
                    ),
                    children: [
                      AppCard(
                        child: ticketStatsAsync.when(
                          data: (stats) {
                            final open = stats['Open'] ?? 0;
                            final inProgress = stats['In Progress'] ?? 0;
                            final total = open + inProgress;

                            return _KpiTile(
                              label: 'Live Queue',
                              primaryValue: total.toString(),
                              secondaryLabel: 'Open / In Progress',
                              secondaryValue: '$open / $inProgress',
                              icon: LucideIcons.inbox,
                              accentColor: AppColors.info,
                            );
                          },
                          loading: () => const _KpiLoading(),
                          error: (err, _) =>
                              _KpiError(message: 'Ticket stats error'),
                        ),
                      ),
                      AppCard(
                        child: amcStatsAsync.when(
                          data: (stats) {
                            final active = stats['active'] ?? 0;
                            final expired = stats['expired'] ?? 0;
                            return _KpiTile(
                              label: 'AMC Coverage',
                              primaryValue: active.toString(),
                              secondaryLabel: 'Expired',
                              secondaryValue: expired.toString(),
                              icon: LucideIcons.shield,
                              accentColor: AppColors.success,
                            );
                          },
                          loading: () => const _KpiLoading(),
                          error: (err, _) =>
                              _KpiError(message: 'AMC stats error'),
                        ),
                      ),
                      AppCard(
                        child: ticketsAsync.when(
                          data: (tickets) {
                            final now = DateTime.now();
                            var createdToday = 0;
                            var resolvedToday = 0;

                            for (final t in tickets) {
                              final created = t.createdAt;
                              if (created != null &&
                                  created.year == now.year &&
                                  created.month == now.month &&
                                  created.day == now.day) {
                                createdToday++;
                              }

                              if (t.status == 'Resolved') {
                                final updated = t.updatedAt;
                                if (updated != null &&
                                    updated.year == now.year &&
                                    updated.month == now.month &&
                                    updated.day == now.day) {
                                  resolvedToday++;
                                }
                              }
                            }

                            return _KpiTile(
                              label: 'Today\'s Flow',
                              primaryValue: '$createdToday new',
                              secondaryLabel: 'Resolved today',
                              secondaryValue: resolvedToday.toString(),
                              icon: LucideIcons.activity,
                              accentColor: AppColors.accent,
                            );
                          },
                          loading: () => const _KpiLoading(),
                          error: (err, _) =>
                              _KpiError(message: 'Today stats error'),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              const SizedBox(height: 16),

              ticketsAsync.when(
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.inbox,
                              size: 48,
                              color: AppColors.slate300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tickets found',
                              style: TextStyle(color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final now = DateTime.now();
                  final openTicketsForHealth = tickets
                      .where(
                        (t) => ![
                          'Resolved',
                          'Closed',
                          'BillProcessed',
                        ].contains(t.status),
                      )
                      .toList();

                  Duration totalAge = Duration.zero;
                  var bucket0to4h = 0;
                  var bucket4to24h = 0;
                  var bucket1to3d = 0;
                  var bucketOver3d = 0;
                  var slaBreachedCount = 0;

                  for (final t in openTicketsForHealth) {
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

                    if (t.slaDue != null && t.slaDue!.isBefore(now)) {
                      slaBreachedCount++;
                    }
                  }

                  final avgAgeHours = openTicketsForHealth.isEmpty
                      ? 0.0
                      : totalAge.inMinutes / openTicketsForHealth.length / 60.0;

                  int compareTicketUrgency(a, b) {
                    if (a.slaDue != null && b.slaDue != null) {
                      return a.slaDue!.compareTo(b.slaDue!);
                    }
                    if (a.slaDue != null) return -1;
                    if (b.slaDue != null) return 1;
                    return (b.createdAt ?? DateTime(0)).compareTo(
                      a.createdAt ?? DateTime(0),
                    );
                  }

                  // Group tickets by status for board view
                  final newOpenTickets =
                      tickets
                          .where((t) => t.status == 'New' || t.status == 'Open')
                          .toList()
                        ..sort(compareTicketUrgency);
                  final inProgressTickets =
                      tickets
                          .where((t) => t.status.contains('Progress'))
                          .toList()
                        ..sort(compareTicketUrgency);
                  final resolvedTickets =
                      tickets
                          .where(
                            (t) => [
                              'Resolved',
                              'Closed',
                              'BillProcessed',
                            ].contains(t.status),
                          )
                          .toList()
                        ..sort(compareTicketUrgency);


                  final enableRevenueRadar = appSettings == null
                      ? true
                      : (appSettings['enable_revenue_radar'] ?? true);
                  final enableBoardView = appSettings == null
                      ? true
                      : (appSettings['enable_board_view'] ?? true);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      if (enableRevenueRadar)
                        customersAsync.when(
                          data: (customers) {
                            final lookbackStart = now.subtract(
                              const Duration(days: 15),
                            );

                            final ticketCounts = <String, int>{};
                            for (final t in tickets) {
                              if ((t.createdAt ?? DateTime(0)).isAfter(
                                lookbackStart,
                              )) {
                                ticketCounts[t.customerId] =
                                    (ticketCounts[t.customerId] ?? 0) + 1;
                              }
                            }

                            final entries = <Map<String, dynamic>>[];
                            for (final c in customers) {
                              final amcDate = c.amcExpiryDate;
                              final tssDate = c.tssExpiryDate;
                              
                              // Check AMC
                              bool amcExpiring = false;
                              int amcDays = 0;
                              if (amcDate != null) {
                                amcDays = amcDate.difference(now).inDays;
                                if (amcDays <= 15) amcExpiring = true;
                              }

                              // Check TSS
                              bool tssExpiring = false;
                              int tssDays = 0;
                              if (tssDate != null) {
                                tssDays = tssDate.difference(now).inDays;
                                if (tssDays <= 15) tssExpiring = true;
                              }

                              if (!amcExpiring && !tssExpiring) continue;

                              final ticketsLast15d = ticketCounts[c.id] ?? 0;
                              if (ticketsLast15d == 0) continue;

                              String band;
                              Color color;

                              // Prioritize AMC status for the color/band in the list, 
                              // but the dialog will show details for both.
                              if (amcDays < 0 || tssDays < 0) {
                                band = 'Expired';
                                color = AppColors.error;
                              } else {
                                band = 'Expiring soon';
                                color = AppColors.warning;
                              }

                              entries.add({
                                'name': c.companyName,
                                'amcDays': amcDate != null ? amcDays : null,
                                'tssDays': tssDate != null ? tssDays : null,
                                'tickets': ticketsLast15d,
                                'band': band,
                                'color': color,
                              });
                            }

                            entries.sort((a, b) {
                              final ad = (a['amcDays'] as int?) ?? 999;
                              final bd = (b['amcDays'] as int?) ?? 999;
                              final at = (a['tssDays'] as int?) ?? 999;
                              final bt = (b['tssDays'] as int?) ?? 999;
                              // Sort by earliest expiry
                              final minA = ad < at ? ad : at;
                              final minB = bd < bt ? bd : bt;
                              return minA.compareTo(minB);
                            });

                            return AppCard(
                              onTap: () => _showExpiringAmcDialog(context, entries),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'AMC & TSS Status',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate900,
                                        ),
                                      ),
                                      Icon(
                                        LucideIcons.chevronRight,
                                        size: 18,
                                        color: AppColors.slate400,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${entries.length} customers with expiring or expired AMC/TSS and tickets in last 15 days.',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const AppCard(
                            child: SizedBox(
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          error: (err, _) => AppCard(
                            child: Text(
                              'Error loading AMC & TSS Status: $err',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (enableBoardView) ...[
                        const Text(
                          'Ticket Board',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Custom Tab Bar
                        Row(
                          children: [
                            _buildTabButton(
                              label: 'New / Open',
                              count: newOpenTickets.length,
                              index: 0,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              label: 'In Progress',
                              count: inProgressTickets.length,
                              index: 1,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            _buildTabButton(
                              label: 'Resolved / Closed',
                              count: resolvedTickets.length,
                              index: 2,
                              color: AppColors.success,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Line-by-line Ticket List
                        ...(() {
                          final activeTickets = _selectedTab == 0
                              ? newOpenTickets
                              : (_selectedTab == 1
                                  ? inProgressTickets
                                  : resolvedTickets);

                          if (activeTickets.isEmpty) {
                            return [
                              const Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Center(
                                  child: Text(
                                    'No tickets in this category',
                                    style: TextStyle(color: AppColors.slate500),
                                  ),
                                ),
                              )
                            ];
                          }

                          return activeTickets.map((ticket) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: TicketCardWithAmc(ticket: ticket),
                              ));
                        })(),
                        const SizedBox(height: 32),
                      ],


                      // Live Ticket Board (Sorted by Response Time)
                      Row(
                        children: [
                          const Text(
                            'Live Ticket Grid',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '(Sorted by Urgency)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Sort tickets by response time due date
                          final sortedTickets = List.of(tickets);
                          sortedTickets.sort((a, b) {
                            if (a.slaDue != null && b.slaDue != null) {
                              return a.slaDue!.compareTo(b.slaDue!);
                            }
                            if (a.slaDue != null) return -1;
                            if (b.slaDue != null) return 1;
                            return (b.createdAt ?? DateTime(0)).compareTo(
                              a.createdAt ?? DateTime(0),
                            );
                          });

                          final isWide = constraints.maxWidth > 900;
                          final crossAxisCount = isWide ? 2 : 1;
                          final totalSpacing =
                              16.0 * (crossAxisCount > 1 ? crossAxisCount - 1 : 0);
                          final itemWidth =
                              (constraints.maxWidth - totalSpacing) / crossAxisCount;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              for (final ticket in sortedTickets)
                                SizedBox(
                                  width: itemWidth,
                                  child: TicketCardWithAmc(ticket: ticket),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required int count,
    required int index,
    required Color color,
  }) {
    final isActive = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color : AppColors.slate200,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isActive)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              '$label ($count)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? color : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _KpiTile extends StatelessWidget {
  final String label;
  final String primaryValue;
  final String secondaryLabel;
  final String secondaryValue;
  final IconData? icon;
  final Color? accentColor;

  const _KpiTile({
    required this.label,
    required this.primaryValue,
    required this.secondaryLabel,
    required this.secondaryValue,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.slate500,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          primaryValue,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.slate900,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.slate50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                secondaryLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate500,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                secondaryValue,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiLoading extends StatelessWidget {
  const _KpiLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 60,
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}

class _KpiError extends StatelessWidget {
  final String message;

  const _KpiError({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.error, fontSize: 12),
        ),
      ),
    );
  }
}

void _showExpiringAmcDialog(
  BuildContext context,
  List<Map<String, dynamic>> entries,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.calendar, color: AppColors.primary),
          const SizedBox(width: 8),
          const Text('AMC & TSS Expiry Details'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customers with expiring or expired AMC/TSS and tickets in the last 15 days.',
                style: TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
              const SizedBox(height: 16),
              ...entries.map((entry) {
                final name = entry['name'] as String? ?? 'Customer';
                final amcDays = entry['amcDays'] as int?;
                final tssDays = entry['tssDays'] as int?;
                final ticketsLast15d = entry['tickets'] as int? ?? 0;

                Widget buildExpiryText(String label, int? days) {
                  if (days == null) return const SizedBox.shrink();
                  final isExpired = days < 0;
                  final text = isExpired ? 'Expired ${-days}d ago' : 'Expiring in ${days}d';
                  final color = isExpired ? AppColors.error : (days <= 7 ? AppColors.warning : AppColors.success);
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6, top: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$label: $text',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.slate900,
                                ),
                              ),
                            ),
                            Text(
                              '$ticketsLast15d tickets',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slate500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          children: [
                            buildExpiryText('AMC', amcDays),
                            buildExpiryText('TSS', tssDays),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
