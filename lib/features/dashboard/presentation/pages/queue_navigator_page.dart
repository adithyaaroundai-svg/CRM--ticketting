import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../widgets/support_sidebar_nav.dart';

class QueueNavigatorPage extends ConsumerWidget {
  const QueueNavigatorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final ticketsAsync = ref.watch(ticketsStreamProvider);

    return MainLayout(
      currentPath: '/queue-navigator',
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ticketsAsync.when(
          data: (allTickets) {
            final myTickets = allTickets
                .where((t) => t.assignedTo == currentUser?.id)
                .toList();

            final unclaimedTickets = allTickets
                .where((t) => t.assignedTo == null || t.assignedTo!.isEmpty)
                .toList();

            final myInProgress = myTickets
                .where((t) => t.status == 'In Progress')
                .length;

            final myResolvedToday = myTickets.where((t) {
              final today = DateTime.now();
              final updatedAt = t.updatedAt ?? DateTime(1970);
              final resolvedStatuses = {'Resolved', 'Closed', 'BillProcessed'};
              return resolvedStatuses.contains(t.status) &&
                  updatedAt.year == today.year &&
                  updatedAt.month == today.month &&
                  updatedAt.day == today.day;
            }).length;

            final now = DateTime.now();
            final mySlaWarnings = myTickets.where((t) {
              final resolvedStatuses = {'Resolved', 'Closed', 'BillProcessed'};
              if (resolvedStatuses.contains(t.status)) return false;
              final slaDue = t.slaDue;
              if (slaDue == null) return false;
              return slaDue.difference(now).inMinutes <= 60;
            }).toList();

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(LucideIcons.arrowLeft),
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Queue Navigator',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slate900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Jump into any ticket pool from one place.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SupportSidebarNav(
                        myTickets: myTickets.length,
                        unclaimedTickets: unclaimedTickets.length,
                        inProgressTickets: myInProgress,
                        resolvedToday: myResolvedToday,
                        responseAlerts: mySlaWarnings.length,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              'Unable to load tickets: $err',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ),
      ),
    );
  }
}
