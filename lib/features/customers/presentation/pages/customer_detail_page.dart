import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/models/tally_customization_entry.dart';
import '../../../../core/models/tally_software_entry.dart';
import '../../../../core/utils/tally_customization_utils.dart';
import '../../../../core/utils/tally_software_history_utils.dart';
import '../providers/customer_provider.dart';
import '../widgets/customer_info_card.dart';
import '../widgets/customer_notes_section.dart';
import '../providers/customer_notes_provider.dart';
import '../providers/customer_contacts_provider.dart';
import '../providers/customer_activities_provider.dart';
import '../../../tickets/presentation/providers/ticket_provider.dart';
import '../../../dashboard/presentation/widgets/ticket_card_with_amc.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerProvider(customerId));
    final ticketsAsync = ref.watch(ticketsStreamProvider);
    final notesAsync = ref.watch(customerNotesProvider(customerId));
    final contactsAsync = ref.watch(customerContactsProvider(customerId));
    final activitiesAsync = ref.watch(customerActivitiesProvider(customerId));
    final currentUser = ref.watch(authProvider);

    return MainLayout(
      currentPath: '/customer/$customerId',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleSpacing: 24,
          toolbarHeight: 72,
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/customers');
              }
            },
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            style: IconButton.styleFrom(
              backgroundColor: AppColors.slate100,
              foregroundColor: AppColors.slate700,
            ),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Account overview and service history',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: customerAsync.when(
            data: (customer) {
              if (customer == null) {
                return Center(
                  child: Text(
                    'Customer not found',
                    style: TextStyle(color: AppColors.slate500),
                  ),
                );
              }

              final historyEntries =
                  parseTallySoftwareHistory(
                    customer.tallySoftwareHistory,
                  ).where((entry) => entry.hasName).toList()..sort((a, b) {
                    final aDate = a.toDate ?? a.fromDate ?? DateTime(1900);
                    final bDate = b.toDate ?? b.fromDate ?? DateTime(1900);
                    return bDate.compareTo(aDate);
                  });
              final customizationEntries = parseTallyCustomizations(
                customer.tallyCustomizations,
              ).where((entry) => entry.hasModule).toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            context.push('/customer/${customer.id}/history');
                          },
                          icon: const Icon(LucideIcons.history),
                          label: const Text('Detailed history'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Customer Info Card
                    CustomerInfoCard(customer: customer),
                    const SizedBox(height: 32),

                    // Customer Health
                    Builder(
                      builder: (context) {
                        // Basic health based on AMC days remaining
                        final amcActive = customer.isAmcActive;
                        final daysRemaining = customer.amcDaysRemaining;

                        String healthLabel;
                        Color healthColor;

                        if (!amcActive) {
                          healthLabel = 'Critical';
                          healthColor = AppColors.error;
                        } else if (daysRemaining <= 30) {
                          healthLabel = 'At Risk';
                          healthColor = AppColors.warning;
                        } else {
                          healthLabel = 'Healthy';
                          healthColor = AppColors.success;
                        }

                        return Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: healthColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                LucideIcons.heartPulse,
                                size: 18,
                                color: healthColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Customer Health: $healthLabel',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                if (amcActive)
                                  Text(
                                    'AMC expires in ${daysRemaining}d',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate600,
                                    ),
                                  )
                                else
                                  const Text(
                                    'AMC has expired',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate600,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    if (customizationEntries.isNotEmpty) ...[
                      _buildCustomizationSection(customizationEntries),
                      const SizedBox(height: 24),
                    ],

                    if (historyEntries.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildHistorySection(historyEntries),
                      const SizedBox(height: 24),
                    ],

                    // Customer Notes / Pinned Notes
                    notesAsync.when(
                      data: (notes) {
                        if (notes.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final pinnedCount = notes
                            .where((n) => (n['is_pinned'] as bool?) ?? false)
                            .length;
                        final total = notes.length;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.stickyNote,
                                size: 16,
                                color: AppColors.slate500,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                pinnedCount > 0
                                    ? '$pinnedCount pinned · $total notes'
                                    : '$total notes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    CustomerNotesSection(customerId: customerId),
                    const SizedBox(height: 24),

                    contactsAsync.when(
                      data: (contacts) {
                        if (contacts.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    LucideIcons.users,
                                    size: 18,
                                    color: AppColors.slate700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Contacts',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const Spacer(),
                                if (currentUser != null &&
                                    (currentUser.isAdmin ||
                                        currentUser.isSupportHead ||
                                        currentUser.isAccountant))
                                  IconButton(
                                    icon: const Icon(
                                      LucideIcons.plus,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    tooltip: 'Add contact',
                                    onPressed: () {
                                      _showAddContactDialog(
                                        context,
                                        ref,
                                        customerId,
                                      );
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: contacts.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final contact = contacts[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          LucideIcons.user,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              contact.fullName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.slate900,
                                              ),
                                            ),
                                            if (contact.role != null &&
                                                contact.role!.isNotEmpty)
                                              Text(
                                                contact.role!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.slate600,
                                                ),
                                              ),
                                            if (contact.email != null &&
                                                contact.email!.isNotEmpty)
                                              Text(
                                                contact.email!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.slate700,
                                                ),
                                              ),
                                            if (contact.phone != null &&
                                                contact.phone!.isNotEmpty)
                                              Text(
                                                contact.phone!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.slate700,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (contact.isPrimary)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                'Primary',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          if (contact.isBillingContact)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.slate100,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Billing',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.slate700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 8),
                    CustomerActivityForm(customerId: customerId),
                    const SizedBox(height: 16),

                    activitiesAsync.when(
                      data: (activities) {
                        if (activities.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    LucideIcons.activity,
                                    size: 18,
                                    color: AppColors.slate700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Recent Activities',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.slate900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activities.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final activity = activities[index];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.slate50,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.clock,
                                          size: 16,
                                          color: AppColors.slate600,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activity.subject,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.slate900,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              activity.type,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.slate600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (activity.description != null &&
                                                activity
                                                    .description!
                                                    .isNotEmpty)
                                              Text(
                                                activity.description!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.slate700,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              activity.occurredAt
                                                  .toLocal()
                                                  .toString(),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.slate500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Service History Section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.history,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Service History',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate900,
                                ),
                              ),
                              Text(
                                'Previous tickets and support requests',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: () {
                            context.push('/customer/${customer.id}/history');
                          },
                          icon: const Icon(LucideIcons.history),
                          label: const Text('Detailed history'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tickets List & Analytics
                    ticketsAsync.when(
                      data: (allTickets) {
                        final customerTickets = allTickets
                            .where((t) => t.customerId == customerId)
                            .toList();

                        // Sort by date (newest first)
                        customerTickets.sort(
                          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
                            a.createdAt ?? DateTime(0),
                          ),
                        );

                        // Statistics
                        final totalTickets = customerTickets.length;
                        final resolvedTickets = customerTickets
                            .where(
                              (t) => [
                                'Resolved',
                                'Closed',
                                'BillProcessed',
                              ].contains(t.status),
                            )
                            .length;
                        final pendingTickets = totalTickets - resolvedTickets;
                        final pendingBills = customerTickets
                            .where((t) => t.status == 'BillRaised')
                            .toList();
                        final billedTickets = customerTickets
                            .where(
                              (t) =>
                                  t.status == 'BillProcessed' ||
                                  t.status == 'Closed',
                            )
                            .toList();

                        return Column(
                          children: [
                            // Statistics Row (always visible)
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatBox(
                                    'Total Tickets',
                                    totalTickets.toString(),
                                    LucideIcons.ticket,
                                    AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatBox(
                                    'Resolved',
                                    resolvedTickets.toString(),
                                    LucideIcons.checkCircle,
                                    AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatBox(
                                    'Pending',
                                    pendingTickets.toString(),
                                    LucideIcons.clock,
                                    AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (pendingBills.isNotEmpty ||
                                billedTickets.isNotEmpty) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatBox(
                                      'Pending bills',
                                      pendingBills.length.toString(),
                                      LucideIcons.receipt,
                                      AppColors.warning,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatBox(
                                      'Billed tickets',
                                      billedTickets.length.toString(),
                                      LucideIcons.receipt,
                                      AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              if (billedTickets.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.receipt,
                                      size: 18,
                                      color: AppColors.slate600,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Recent billed tickets',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.slate900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: billedTickets
                                      .take(3)
                                      .map(
                                        (t) => ListTile(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                            LucideIcons.ticket,
                                            size: 18,
                                            color: AppColors.primary,
                                          ),
                                          title: Text(
                                            t.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            'ID: ${t.ticketId} · Status: ${t.status}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.slate600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],

                            // Tickets List or Empty State
                            if (customerTickets.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(48),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        LucideIcons.inbox,
                                        size: 48,
                                        color: AppColors.slate300,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No service history',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.slate600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'This customer has no previous tickets',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.slate500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: customerTickets
                                    .map(
                                      (ticket) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        child: TicketCardWithAmc(
                                          ticket: ticket,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Error loading tickets: $err',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Error loading customer: $err',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
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

  Widget _buildCustomizationSection(List<TallyCustomizationEntry> entries) {
    final formatter = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.settings2,
                size: 18,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tally Customizations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(entries.length, (index) {
              final entry = entries[index];
              final lastUpdated = entry.lastUpdated != null
                  ? formatter.format(entry.lastUpdated!)
                  : 'Not specified';

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == entries.length - 1 ? 0 : 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.puzzle,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.moduleName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.calendarClock,
                                size: 14,
                                color: AppColors.slate500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Last updated: $lastUpdated',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(List<TallySoftwareEntry> entries) {
    final formatter = DateFormat('dd MMM yyyy');

    String formatRange(TallySoftwareEntry entry) {
      final from = entry.fromDate;
      final to = entry.toDate;
      if (from == null && to == null) return 'Dates not specified';
      final fromLabel = from != null ? formatter.format(from) : 'Unknown start';
      final toLabel = to != null ? formatter.format(to) : 'Present';
      return '$fromLabel → $toLabel';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.box, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            const Text(
              'Tally Software History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(entries.length, (index) {
              final entry = entries[index];
              final rangeText = formatRange(entry);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == entries.length - 1 ? 0 : 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      LucideIcons.box,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rangeText,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class CustomerActivityForm extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerActivityForm({super.key, required this.customerId});

  @override
  ConsumerState<CustomerActivityForm> createState() =>
      _CustomerActivityFormState();
}

class _CustomerActivityFormState extends ConsumerState<CustomerActivityForm> {
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'note';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) return;

    final currentUser = ref.read(authProvider);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final client = Supabase.instance.client;
      await client.from('activities').insert({
        'account_id': widget.customerId,
        'agent_id': currentUser?.id,
        'type': _type,
        'subject': subject,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'occurred_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Ensure recent activities streams pick up this new entry immediately
      ref.invalidate(customerActivitiesProvider(widget.customerId));

      if (!mounted) return;

      _subjectController.clear();
      _descriptionController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity logged'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log activity: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider);
    final canLogActivity =
        currentUser != null &&
        (currentUser.isAdmin ||
            currentUser.isSupportHead ||
            currentUser.isSupport);

    if (!canLogActivity) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.activity,
                size: 18,
                color: AppColors.slate700,
              ),
              const SizedBox(width: 8),
              const Text(
                'Log activity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'call', child: Text('Call')),
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'meeting', child: Text('Meeting')),
              DropdownMenuItem(value: 'note', child: Text('Note')),
              DropdownMenuItem(value: 'task', child: Text('Task')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _type = value;
              });
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              hintText: 'Subject',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Description (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: const Icon(LucideIcons.check, size: 16),
              label: Text(_isSubmitting ? 'Saving...' : 'Save activity'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddContactDialog(
  BuildContext context,
  WidgetRef ref,
  String customerId,
) async {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final roleController = TextEditingController();

  bool isPrimary = false;
  bool isBilling = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add contact'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                  TextField(
                    controller: roleController,
                    decoration: const InputDecoration(labelText: 'Role'),
                  ),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: isPrimary,
                        onChanged: (value) {
                          setState(() {
                            isPrimary = value ?? false;
                          });
                        },
                      ),
                      const Text('Primary'),
                      const SizedBox(width: 16),
                      Checkbox(
                        value: isBilling,
                        onChanged: (value) {
                          setState(() {
                            isBilling = value ?? false;
                          });
                        },
                      ),
                      const Text('Billing'),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final fullName = nameController.text.trim();
                  if (fullName.isEmpty) {
                    return;
                  }

                  try {
                    final client = Supabase.instance.client;
                    await client.from('contacts').insert({
                      'account_id': customerId,
                      'full_name': fullName,
                      'role': roleController.text.trim().isEmpty
                          ? null
                          : roleController.text.trim(),
                      'email': emailController.text.trim().isEmpty
                          ? null
                          : emailController.text.trim(),
                      'phone': phoneController.text.trim().isEmpty
                          ? null
                          : phoneController.text.trim(),
                      'is_primary': isPrimary,
                      'is_billing_contact': isBilling,
                    });

                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Contact added'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to add contact: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
