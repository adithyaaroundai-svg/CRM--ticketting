import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/design_system/design_system.dart';
import '../../presentation/providers/ticket_provider.dart';

class OverdueClaimedTicketsPage extends ConsumerWidget {
  const OverdueClaimedTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(overdueClaimedTicketsProvider);
    final agentsAsync = ref.watch(agentsListProvider);

    return _TicketAlertsShell(
      currentPath: '/alerts/claimed-overdue',
      title: 'Overdue Claimed Tickets',
      subtitle: 'Claimed tickets that are still unresolved/billed even after 12 hours.',
      emptyMessage: 'All caught up! No claimed tickets waiting beyond 12 hours.',
      highlights: const ['Monitors SLA breaches after a ticket is claimed.', 'Shows who owns the ticket and how long it has been overdue.'],
      icon: LucideIcons.alarmClock,
      accentColor: AppColors.error,
      alertsAsync: alertsAsync,
      agentsAsync: agentsAsync,
      showAssignee: true,
      referenceLabel: 'Claimed on',
      thresholdLabel: '12h SLA',
    );
  }
}

class StaleUnclaimedTicketsPage extends ConsumerWidget {
  const StaleUnclaimedTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(staleUnclaimedTicketsProvider);
    final agentsAsync = ref.watch(agentsListProvider);

    return _TicketAlertsShell(
      currentPath: '/alerts/unclaimed',
      title: 'Unclaimed Tickets (1h+)',
      subtitle: 'Tickets that stayed unclaimed for more than an hour after creation.',
      emptyMessage: 'Every new ticket has been picked up within the first hour. Great job!',
      highlights: const ['Proactively highlights neglected fresh tickets.', 'Ideal for dispatchers to nudge agents to claim work.'],
      icon: LucideIcons.hourglass,
      accentColor: AppColors.warning,
      alertsAsync: alertsAsync,
      agentsAsync: agentsAsync,
      showAssignee: false,
      referenceLabel: 'Created at',
      thresholdLabel: '1h pickup target',
    );
  }
}

class _TicketAlertsShell extends StatelessWidget {
  final String currentPath;
  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<String> highlights;
  final IconData icon;
  final Color accentColor;
  final AsyncValue<List<TicketAlertEntry>> alertsAsync;
  final AsyncValue<List<Map<String, dynamic>>> agentsAsync;
  final bool showAssignee;
  final String referenceLabel;
  final String thresholdLabel;

  const _TicketAlertsShell({
    required this.currentPath,
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.highlights,
    required this.icon,
    required this.accentColor,
    required this.alertsAsync,
    required this.agentsAsync,
    required this.showAssignee,
    required this.referenceLabel,
    required this.thresholdLabel,
  });

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentPath: currentPath,
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Column(
          children: [
            _Header(
              title: title,
              subtitle: subtitle,
              icon: icon,
              accentColor: accentColor,
              highlights: highlights,
              thresholdLabel: thresholdLabel,
            ),
            const Divider(height: 1, color: AppColors.slate200),
            Expanded(
              child: alertsAsync.when(
                data: (alerts) {
                  final agents = agentsAsync.asData?.value ??
                      const <Map<String, dynamic>>[];
                  final agentsById = {
                    for (final agent in agents)
                      if (agent['id'] != null) agent['id'].toString(): agent,
                  };

                  if (alerts.isEmpty) {
                    return _EmptyState(message: emptyMessage);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final entry = alerts[index];
                      final ticket = entry.ticket;
                      final assignedTo = ticket.assignedTo;
                      final agentName = assignedTo == null || assignedTo.isEmpty
                          ? 'Unassigned'
                          : (agentsById[assignedTo]?['full_name'] ?? 'Unknown agent');

                      return _TicketAlertCard(
                        entry: entry,
                        agentName: agentName,
                        showAssignee: showAssignee,
                        referenceLabel: referenceLabel,
                        accentColor: accentColor,
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, stack) => _ErrorState(message: error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<String> highlights;
  final String thresholdLabel;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.highlights,
    required this.thresholdLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: accentColor.withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.target, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      thresholdLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: highlights
                .map(
                  (point) => _HighlightPill(
                    text: point,
                    accentColor: accentColor,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HighlightPill extends StatelessWidget {
  final String text;
  final Color accentColor;

  const _HighlightPill({required this.text, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.activity, size: 16, color: accentColor),
          const SizedBox(width: 8),
          Text(
            text,
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

class _TicketAlertCard extends StatelessWidget {
  final TicketAlertEntry entry;
  final String agentName;
  final bool showAssignee;
  final String referenceLabel;
  final Color accentColor;

  const _TicketAlertCard({
    required this.entry,
    required this.agentName,
    required this.showAssignee,
    required this.referenceLabel,
    required this.accentColor,
  });

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    if (minutes > 0) {
      final seconds = duration.inSeconds % 60;
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    }
    return '${duration.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final ticket = entry.ticket;
    final overdueLabel = _formatDuration(entry.overdue);
    final referenceAgo = timeago.format(entry.referenceTime.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/ticket/${ticket.ticketId}'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.title.isEmpty ? 'Untitled Ticket' : ticket.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'ID: ${ticket.ticketId}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.alertTriangle,
                              size: 14, color: accentColor),
                          const SizedBox(width: 6),
                          Text(
                            '+$overdueLabel',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _InfoChip(
                      icon: LucideIcons.clock3,
                      label: referenceLabel,
                      value: referenceAgo,
                    ),
                    if (showAssignee)
                      _InfoChip(
                        icon: LucideIcons.user,
                        label: 'Assigned to',
                        value: agentName,
                      )
                    else
                      _InfoChip(
                        icon: LucideIcons.timerReset,
                        label: 'Waiting',
                        value: timeago.format(entry.referenceTime.toLocal(), allowFromNow: true),
                      ),
                    _InfoChip(
                      icon: LucideIcons.badgeCheck,
                      label: 'Status',
                      value: ticket.status,
                    ),
                  ],
                ),
                if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    ticket.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => context.push('/ticket/${ticket.ticketId}'),
                      icon: const Icon(LucideIcons.externalLink, size: 16),
                      label: const Text('Open ticket'),
                    ),
                    const Spacer(),
                    Text(
                      'Updated ${timeago.format((ticket.updatedAt ?? ticket.createdAt ?? entry.referenceTime).toLocal())}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.slate500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.slate500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.sparkles,
                    size: 36, color: AppColors.slate400),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
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

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.alertCircle, size: 32, color: AppColors.error),
          const SizedBox(height: 12),
          const Text(
            'Unable to load alerts',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate600,
            ),
          ),
        ],
      ),
    );
  }
}
