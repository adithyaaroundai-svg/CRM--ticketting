import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/design_system/design_system.dart';
import '../providers/ticket_provider.dart';

class ActiveClaimedTicketsPage extends ConsumerWidget {
  const ActiveClaimedTicketsPage({super.key});

  bool _isCompleted(String status) {
    final s = status.toLowerCase();
    return s == 'resolved' ||
        s == 'closed' ||
        s == 'billraised' ||
        s == 'billprocessed';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(allTicketsStreamProvider);
    final agentsAsync = ref.watch(agentsListProvider);

    return MainLayout(
      currentPath: '/active-claimed',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Active Claimed Tickets',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tickets that are currently being worked on by agents',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/tickets');
                      }
                    },
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.slate100,
                      foregroundColor: AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.slate200),
            Expanded(
              child: ticketsAsync.when(
                data: (allTickets) {
                  final activeClaimed = allTickets.where((t) {
                    final isClaimed =
                        t.assignedTo != null && t.assignedTo!.isNotEmpty;
                    return isClaimed && !_isCompleted(t.status);
                  }).toList();

                  if (activeClaimed.isEmpty) {
                    return const Center(
                        child: Text('No active claimed tickets.'));
                  }

                  return agentsAsync.when(
                    data: (agentsList) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: activeClaimed.length,
                        itemBuilder: (context, index) {
                          final ticket = activeClaimed[index];
                          final agent = agentsList.firstWhere(
                            (a) => a['id'] == ticket.assignedTo,
                            orElse: () =>
                                <String, dynamic>{'full_name': 'Unknown'},
                          );
                          final agentName =
                              agent['full_name'] ?? 'Unknown Agent';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    context.push('/ticket/${ticket.ticketId}'),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ticket.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.slate900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            LucideIcons.clock,
                                            size: 14,
                                            color: AppColors.slate400,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            ticket.createdAt != null
                                                ? 'Created ${timeago.format(ticket.createdAt!.toLocal())}'
                                                : 'Created time unavailable',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.slate600,
                                            ),
                                          ),
                                          if (ticket.updatedAt != null) ...[
                                            const SizedBox(width: 12),
                                            Icon(
                                              LucideIcons.refreshCcw,
                                              size: 14,
                                              color: AppColors.slate400,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Updated ${timeago.format(ticket.updatedAt!.toLocal())}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.slate600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if ((ticket.description ?? '').isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            ticket.description!,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.slate700,
                                            ),
                                          ),
                                        ),
                                      if ((ticket.contactPhone ?? '').isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6.0),
                                          child: Row(
                                            children: [
                                              Icon(
                                                LucideIcons.phone,
                                                size: 14,
                                                color: AppColors.slate400,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                ticket.contactPhone!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.slate700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.info
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Claimed by: $agentName',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.info,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.slate100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Status: ${ticket.status}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.slate700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                        child: Text('Error loading agents: $error')),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
