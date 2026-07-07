import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../widgets/animated_create_ticket_fab.dart';
import '../widgets/create_ticket_dialog.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../../chat/presentation/providers/chat_provider.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../widgets/ticket_card_with_amc.dart';

class ModeratorDashboardPage extends ConsumerStatefulWidget {
  const ModeratorDashboardPage({super.key});

  @override
  ConsumerState<ModeratorDashboardPage> createState() => _ModeratorDashboardPageState();
}

class _ModeratorDashboardPageState extends ConsumerState<ModeratorDashboardPage> {
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

    // Get customer name from customer ID
    final customersAsync = ref.read(customersListProvider);
    String companyName = ticket.customerId;
    
    if (customersAsync.hasValue) {
      final customers = customersAsync.value ?? [];
      try {
        final customer = customers.firstWhere((c) => c.id == ticket.customerId);
        companyName = customer.companyName;
      } catch (e) {
        // Customer not found, keep default
      }
    }

    final chatContent = [
      'Company: $companyName',
      'Issue: ${ticket.title}',
      'TicketID: ${ticket.ticketId}',
    ].join('\n');

    await ref.read(chatRepositoryProvider).sendMessage(
          senderId: agent.id,
          senderName: agent.fullName,
          senderRole: agent.role,
          content: chatContent,
          senderAvatarUrl: agent.avatarUrl,
        );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return MainLayout(
      currentPath: '/moderator',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        floatingActionButton: AnimatedCreateTicketFab(
          onPressed: _showCreateTicketDialog,
        ),
        body: ticketsAsync.when(
          data: (tickets) {
            // Calculate statistics
            final unclaimedTickets = tickets
                .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
                .toList();

            final criticalTickets = tickets
                .where(
                  (t) =>
                      t.priority == 'Critical' &&
                      ![
                        'Resolved',
                        'Closed',
                        'BillProcessed',
                      ].contains(t.status),
                )
                .toList();

            final pendingBilling = tickets
                .where((t) => t.status == 'BillRaised')
                .length;

            final resolvedToday = tickets.where((t) {
              final today = DateTime.now();
              final updatedAt = t.updatedAt;
              if (updatedAt == null) return false;
              return t.status == 'Resolved' &&
                  updatedAt.year == today.year &&
                  updatedAt.month == today.month &&
                  updatedAt.day == today.day;
            }).length;

            // Response time violations (unclaimed > 30 min)
            final slaViolations = unclaimedTickets.where((t) {
              final diff = DateTime.now().difference(
                t.createdAt ?? DateTime.now(),
              );
              return diff.inMinutes > 30;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  WelcomeHeader(
                    greeting: 'Moderator Dashboard',
                    name: 'Real-time floor monitoring',
                    trailing: AppButton.ghost(
                      label: 'Refresh',
                      icon: Icons.refresh,
                      onPressed: () => ref.invalidate(rawTicketsStreamProvider),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      AppButton.ghost(
                        label: 'All Tickets',
                        icon: LucideIcons.ticket,
                        onPressed: () => context.push('/tickets'),
                      ),
                      AppButton.ghost(
                        label: 'Reports',
                        icon: LucideIcons.barChart3,
                        onPressed: () => context.push('/reports'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Statistics Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              mainAxisExtent: 110,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _StatCard(
                            title: 'Unclaimed',
                            value: unclaimedTickets.length.toString(),
                            icon: LucideIcons.alertCircle,
                            color: AppColors.warning,
                          ),
                          _StatCard(
                            title: 'Response Time Violations',
                            value: slaViolations.length.toString(),
                            icon: LucideIcons.alertTriangle,
                            color: AppColors.error,
                          ),
                          _StatCard(
                            title: 'Critical',
                            value: criticalTickets.length.toString(),
                            icon: LucideIcons.zap,
                            color: AppColors.error,
                          ),
                          _StatCard(
                            title: 'Pending Billing',
                            value: pendingBilling.toString(),
                            icon: LucideIcons.receipt,
                            color: AppColors.info,
                          ),
                          _StatCard(
                            title: 'Resolved Today',
                            value: resolvedToday.toString(),
                            icon: LucideIcons.checkCircle,
                            color: AppColors.success,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Response Time Violations
                  if (slaViolations.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Response Time Violations',
                      subtitle:
                          '${slaViolations.length} tickets need attention',
                      icon: LucideIcons.alertTriangle,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    ...slaViolations
                        .take(3)
                        .map(
                          (ticket) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TicketCardWithAmc(ticket: ticket),
                          ),
                        ),
                    const SizedBox(height: 32),
                  ],

                  // Critical Tickets
                  if (criticalTickets.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Critical Tickets',
                      subtitle: '${criticalTickets.length} high-priority',
                      icon: LucideIcons.zap,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    ...criticalTickets
                        .take(3)
                        .map(
                          (ticket) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TicketCardWithAmc(ticket: ticket),
                          ),
                        ),
                    const SizedBox(height: 32),
                  ],

                  // Unclaimed Tickets
                  _SectionHeader(
                    title: 'Unclaimed Tickets',
                    subtitle: '${unclaimedTickets.length} waiting',
                    icon: LucideIcons.userX,
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 16),
                  if (unclaimedTickets.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(48.0),
                        child: Text('All tickets claimed!'),
                      ),
                    )
                  else
                    ...unclaimedTickets
                        .take(5)
                        .map(
                          (ticket) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TicketCardWithAmc(ticket: ticket),
                          ),
                        ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
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
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
          ],
        ),
      ],
    );
  }
}
