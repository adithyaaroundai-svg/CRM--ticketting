import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'tickets_page.dart';

/// Split-pane view for unclaimed tickets, separated by customer AMC status
class UnclaimedTicketsSplitPage extends ConsumerWidget {
  const UnclaimedTicketsSplitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Column(
        children: [
          // Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unclaimed Tickets',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Partitioned by customer service tier',
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
                    final currentUser = ref.read(authProvider);
                    if (currentUser?.isAdmin == true) {
                      context.go('/admin');
                    } else if (currentUser?.isAccountant == true) {
                      context.go('/accountant');
                    } else if (currentUser?.isSupport == true || currentUser?.isHR == true || currentUser?.isProjectCoordinator == true) {
                      context.go('/support');
                    } else {
                      context.go('/'); // Default to agent dashboard
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Dashboard',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.slate100,
                    foregroundColor: AppColors.slate700,
                  ),
                ),
              ],
            ),
          ),
          // Split Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Normal Tickets (Expired or No AMC)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Normal Tickets',
                          subtitle: 'Expired or No AMC',
                        ),
                        const SizedBox(height: 12),
                        const TicketsView(
                          showAllTickets: false,
                          showOnlyUnclaimed: true,
                          showCustomerTabs: false,
                          forcedCustomerCategory: CustomerCategoryFilter.normal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right: Priority Tickets (Active AMC)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          title: 'Priority Tickets',
                          subtitle: 'Active AMC Customers',
                        ),
                        const SizedBox(height: 12),
                        const TicketsView(
                          showAllTickets: false,
                          showOnlyUnclaimed: true,
                          showCustomerTabs: false,
                          forcedCustomerCategory:
                              CustomerCategoryFilter.priority,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
