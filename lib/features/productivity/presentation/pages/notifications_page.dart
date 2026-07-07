import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/layout/main_layout.dart';
import '../../../../core/design_system/theme/app_colors.dart';
import '../../../../core/design_system/components/app_card.dart';
import '../../../../core/design_system/components/app_button.dart';
import '../../../customers/domain/entities/customer.dart';
import '../../../customers/presentation/providers/customer_provider.dart';
import '../../../tickets/domain/entities/ticket.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../providers/productivity_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final ticketsAsync = ref.watch(allTicketsStreamProvider);
    final customersAsync = ref.watch(customersListProvider);

    return MainLayout(
      currentPath: '/notifications',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.slate900,
                    ),
                  ),
                  notificationsAsync.maybeWhen(
                    data: (notifications) {
                      final hasUnread = notifications.any((n) => !n.isRead);
                      if (!hasUnread) return const SizedBox.shrink();

                      return AppButton.secondary(
                        label: 'Mark all as read',
                        icon: LucideIcons.checkCheck,
                        onPressed: () {
                          ref
                              .read(notificationControllerProvider.notifier)
                              .markAllAsRead();
                        },
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _OperationalAlertsSection(
                ticketsAsync: ticketsAsync,
                customersAsync: customersAsync,
                onPendingTap: () => context.push('/alerts/unclaimed'),
                onAmcTap: () => context.push('/amc-reminder'),
              ),
              const SizedBox(height: 24),
              notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          children: [
                            Icon(
                              LucideIcons.bell,
                              size: 64,
                              color: AppColors.slate300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: notifications.map((notification) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          child: InkWell(
                            onTap: () {
                              if (!notification.isRead) {
                                ref
                                    .read(
                                      notificationControllerProvider.notifier,
                                    )
                                    .markAsRead(notification.id);
                              }
                              if (notification.link != null) {
                                context.push(notification.link!);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: notification.isRead
                                    ? Colors.transparent
                                    : AppColors.primary.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _getIconColor(
                                        notification.type,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getIcon(notification.type),
                                      color: _getIconColor(notification.type),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notification.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      notification.isRead
                                                      ? FontWeight.w500
                                                      : FontWeight.bold,
                                                  color: AppColors.slate900,
                                                ),
                                              ),
                                            ),
                                            if (!notification.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (notification.message != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            notification.message!,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.slate600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          timeago.format(
                                            notification.createdAt.toLocal(),
                                          ),
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
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Text(
                      'Error loading notifications: $err',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'assignment':
        return LucideIcons.userCheck;
      case 'comment':
        return LucideIcons.messageSquare;
      case 'sla':
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.bell;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'assignment':
        return AppColors.primary;
      case 'comment':
        return AppColors.info;
      case 'sla':
        return AppColors.error;
      default:
        return AppColors.slate500;
    }
  }
}

class _OperationalAlertsSection extends StatelessWidget {
  const _OperationalAlertsSection({
    required this.ticketsAsync,
    required this.customersAsync,
    required this.onPendingTap,
    required this.onAmcTap,
  });

  final AsyncValue<List<Ticket>> ticketsAsync;
  final AsyncValue<List<Customer>> customersAsync;
  final VoidCallback onPendingTap;
  final VoidCallback onAmcTap;

  @override
  Widget build(BuildContext context) {
    final pendingCount = ticketsAsync.maybeWhen(
      data: _countPendingUnclaimedTickets,
      orElse: () => null,
    );
    final weeklyAmcCount = customersAsync.maybeWhen(
      data: (customers) => _countAmcExpiring(
        customers,
        maxDays: 7,
      ),
      orElse: () => null,
    );
    final monthlyAmcCount = customersAsync.maybeWhen(
      data: (customers) => _countAmcExpiring(
        customers,
        minDays: 8,
        maxDays: 30,
      ),
      orElse: () => null,
    );

    final ticketsLoading = ticketsAsync.isLoading && pendingCount == null;
    final customersLoading = customersAsync.isLoading && weeklyAmcCount == null;
    final hasError = ticketsAsync.hasError || customersAsync.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Operational alerts',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.slate900,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 700
                ? constraints.maxWidth
                : 320.0;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _OperationalAlertCard(
                    title: 'Pending tickets',
                    subtitle: pendingCount == 0
                        ? 'Every new ticket has already been claimed.'
                        : 'Tickets created but not yet picked up by any agent.',
                    icon: LucideIcons.ticket,
                    accentColor: AppColors.primary,
                    count: pendingCount,
                    isLoading: ticketsLoading,
                    actionLabel: 'Review unclaimed',
                    onTap: onPendingTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _OperationalAlertCard(
                    title: 'AMC expiring this week',
                    subtitle: 'Contracts ending within the next 7 days.',
                    icon: LucideIcons.calendarClock,
                    accentColor: AppColors.warning,
                    count: weeklyAmcCount,
                    isLoading: customersLoading,
                    actionLabel: 'View reminder list',
                    onTap: onAmcTap,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _OperationalAlertCard(
                    title: 'AMC expiring this month',
                    subtitle: 'Renewals due in the next 30 days.',
                    icon: LucideIcons.calendarDays,
                    accentColor: AppColors.info,
                    count: monthlyAmcCount,
                    isLoading: customersLoading,
                    actionLabel: 'Plan follow-ups',
                    onTap: onAmcTap,
                  ),
                ),
              ],
            );
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: const [
                Icon(
                  LucideIcons.alertTriangle,
                  size: 14,
                  color: AppColors.error,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Some insight cards could not be loaded. Pull to refresh to try again.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _OperationalAlertCard extends StatelessWidget {
  const _OperationalAlertCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.actionLabel,
    required this.onTap,
    this.count,
    this.isLoading = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String actionLabel;
  final VoidCallback onTap;
  final int? count;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: accentColor),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  count?.toString() ?? '—',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: accentColor,
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(LucideIcons.arrowUpRight, size: 16),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

int _countPendingUnclaimedTickets(List<Ticket> tickets) {
  return tickets.where((ticket) {
    final assignee = ticket.assignedTo?.trim() ?? '';
    return assignee.isEmpty && !_isResolvedTicket(ticket.status);
  }).length;
}

int _countAmcExpiring(
  List<Customer> customers, {
  int minDays = 0,
  required int maxDays,
}) {
  final now = DateTime.now();
  return customers.where((customer) {
    final expiry = customer.amcExpiryDate;
    if (expiry == null) return false;
    final days = expiry.difference(now).inDays;
    return days >= minDays && days <= maxDays;
  }).length;
}

bool _isResolvedTicket(String? status) {
  if (status == null) return false;
  final normalized = status.trim().toLowerCase();
  const resolvedStatuses = {
    'resolved',
    'closed',
    'billprocessed',
    'billraised',
  };
  return resolvedStatuses.contains(normalized);
}
