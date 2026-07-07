import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/design_system/design_system.dart';

class SupportSidebarNav extends StatelessWidget {
  final int myTickets;
  final int unclaimedTickets;
  final int inProgressTickets;
  final int resolvedToday;
  final int responseAlerts;

  const SupportSidebarNav({
    super.key,
    required this.myTickets,
    required this.unclaimedTickets,
    required this.inProgressTickets,
    required this.resolvedToday,
    required this.responseAlerts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Queue Navigator',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.slate900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Quick entry points into each ticket pool.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.slate500,
            ),
          ),
          const SizedBox(height: 24),
          _SidebarLinkTile(
            icon: LucideIcons.inbox,
            label: 'Unclaimed Tickets',
            value: unclaimedTickets.toString(),
            description: 'Waiting for claim',
            color: AppColors.warning,
            onTap: () => context.go('/tickets?view=unclaimed'),
          ),
          const SizedBox(height: 12),
          _SidebarLinkTile(
            icon: LucideIcons.userCheck,
            label: 'My Tickets',
            value: myTickets.toString(),
            description: 'Assigned to me',
            color: AppColors.primary,
            onTap: () => context.go('/tickets?view=my'),
          ),
          const SizedBox(height: 12),
          _SidebarLinkTile(
            icon: LucideIcons.clock,
            label: 'In Progress',
            value: inProgressTickets.toString(),
            description: 'Currently being worked',
            color: AppColors.info,
            onTap: () => context.go('/tickets?view=in_progress'),
          ),
          const SizedBox(height: 12),
          _SidebarLinkTile(
            icon: LucideIcons.checkCircle,
            label: 'Resolved Today',
            value: resolvedToday.toString(),
            description: 'Completed today',
            color: AppColors.success,
            onTap: () => context.go('/tickets?view=resolved_today'),
          ),
          const SizedBox(height: 12),
          _SidebarLinkTile(
            icon: LucideIcons.alertTriangle,
            label: 'Response Alerts',
            value: responseAlerts.toString(),
            description: 'Near or past SLA',
            color: AppColors.error,
            onTap: () => context.go('/tickets?view=response_alerts'),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          AppButton.ghost(
            label: 'Create Ticket',
            icon: LucideIcons.plus,
            onPressed: () => context.push('/tickets/new'),
          ),
        ],
      ),
    );
  }
}

class _SidebarLinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SidebarLinkTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          color: color.withValues(alpha: 0.05),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: color,
            ),
          ],
        ),
      ),
    );
  }
}
