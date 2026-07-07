import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/customer_provider.dart';

class AmcReminderPage extends ConsumerWidget {
  const AmcReminderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersListProvider);

    return MainLayout(
      currentPath: '/amc-reminder',
      child: Scaffold(
        backgroundColor: AppColors.slate50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: customersAsync.when(
              data: (customers) {
                final now = DateTime.now();
                final upcoming = customers
                    .where((customer) {
                      final expiry = customer.amcExpiryDate;
                      if (expiry == null) return false;
                      final daysRemaining = expiry.difference(now).inDays;
                      return daysRemaining >= 0 && daysRemaining <= 31;
                    })
                    .toList()
                  ..sort(
                    (a, b) => a.amcExpiryDate!.compareTo(b.amcExpiryDate!),
                  );

                final total = upcoming.length;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'AMC Reminder',
                      subtitle: total == 0
                          ? 'No renewals due in the next month'
                          : '$total customer${total == 1 ? '' : 's'} to call',
                      icon: LucideIcons.alertTriangle,
                      iconColor: AppColors.warning,
                      trailing: total == 0
                          ? null
                          : TextButton.icon(
                              onPressed: () {
                                // Scroll to top logic isn't necessary here; placeholder for future bulk actions
                              },
                              icon: const Icon(LucideIcons.phoneCall, size: 18),
                              label: const Text('Start Calling'),
                            ),
                    ),
                    const SizedBox(height: 16),
                    _ReminderSummaryCard(total: total),
                    const SizedBox(height: 24),
                    if (total == 0)
                      const Expanded(
                        child: EmptyStateCard(
                          icon: LucideIcons.sparkles,
                          title: 'All AMCs are covered',
                          subtitle:
                              'There are no contracts expiring within the next 30 days.',
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          itemCount: upcoming.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final customer = upcoming[index];
                            final expiry = customer.amcExpiryDate!;
                            final daysLeft = expiry.difference(now).inDays;
                            return _ReminderListTile(
                              companyName: customer.companyName,
                              expiryDate: expiry,
                              daysLeft: daysLeft,
                              contactPerson: customer.contactPerson,
                              phoneNumbers: customer.phoneNumbers,
                              contactEmail: customer.contactEmail,
                              onTap: () => context.push('/customer/${customer.id}'),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => EmptyStateCard(
                icon: LucideIcons.alertTriangle,
                title: 'Failed to load customers',
                subtitle: error.toString(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderSummaryCard extends StatelessWidget {
  const _ReminderSummaryCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.calendarClock,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  total == 0
                      ? 'No AMC renewals in the next 30 days'
                      : '$total AMC renewal${total == 1 ? '' : 's'} pending',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Call customers now to avoid lapses in coverage.',
                  style: TextStyle(
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
  }
}

class _ReminderListTile extends StatelessWidget {
  const _ReminderListTile({
    required this.companyName,
    required this.expiryDate,
    required this.daysLeft,
    required this.contactPerson,
    required this.phoneNumbers,
    required this.contactEmail,
    required this.onTap,
  });

  final String companyName;
  final DateTime expiryDate;
  final int daysLeft;
  final String? contactPerson;
  final List<String> phoneNumbers;
   final String? contactEmail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUrgent = daysLeft <= 7;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate900,
                    ),
                  ),
                ),
                _DaysChip(daysLeft: daysLeft, isUrgent: isUrgent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Expires on ${DateFormat('d MMM y').format(expiryDate)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate600,
              ),
            ),
            const SizedBox(height: 12),
            if (phoneNumbers.isEmpty)
              Row(
                children: [
                  const Icon(
                    LucideIcons.phone,
                    size: 16,
                    color: AppColors.slate300,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No phone on file',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slate400,
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  for (int i = 0; i < phoneNumbers.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        top: i == 0 ? 0 : 8,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.phone,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              phoneNumbers[i],
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.slate900,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy number',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: phoneNumbers[i]),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Copied ${phoneNumbers[i]}',
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            if (contactPerson != null && contactPerson!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Contact: ${contactPerson!}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate600,
                ),
              ),
            ],
            if (contactEmail != null && contactEmail!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    LucideIcons.mail,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      contactEmail!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.daysLeft, required this.isUrgent});

  final int daysLeft;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final color = isUrgent ? AppColors.error : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$daysLeft d left',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
